//
//  PhysicsManager.swift
//  ReturnToBesieger
//
//  Created by Kai Quan Tay on 23/11/26.
//

import SwiftUI

@Observable
class PhysicsManager {
    var objects: [any PhysicsObject] = []
    var hitInteractions: [any HitInteraction] = [
        CircleCircleHitInteraction(),
        CircleLineHitInteraction(),
        LineLineHitInteraction()
    ]
    /// NOTE: this physics manager is a top-down view, gravity is only used for friction purposes
    var gravity: CGFloat = 0

    init(objects: [any PhysicsObject] = []) {
        self.objects = objects
    }

    /// Updates all of the objects. Note that you must NOT remove or add objects during an update.
    func update(dt: TimeInterval) {
        // move all objects
        var newObjects: [any PhysicsObject] = []
        for object in objects {
            var objectCopy = object
            // determine the vector force of friction, and reduce velocity as needed
            if object.velocity != .zero {
                let frictionAcceleration = object.dragCoefficient * gravity * (-object.velocity.unitVec())
                let newVelocity = object.velocity - frictionAcceleration
                if newVelocity.dot(object.velocity.unitVec()) < 0 {
                    // friction has caused this object to stop
                    objectCopy.velocity = .zero
                } else {
                    // friction has caused this object to slow, but not stop outright
                    objectCopy.velocity = newVelocity
                }
            }
            // update the displacement
            objectCopy.updateCenter(to: object.hitbox.center + objectCopy.velocity)
            newObjects.append(objectCopy)
        }

        // check for collisions. If there are, we calculate where they should move.
        // collisions are calculated in array order, so items that appear first in the array will have their collisions calculated first.
        var collided: Set<Set<UUID>> = []
        for (index1, object1) in newObjects.enumerated() {
            var normal: CGPoint = .zero
            var otherObject: (Int, any PhysicsObject)?
            for (index2, object2) in newObjects.enumerated().dropFirst(index1+1) { // we can skip everything before the current object because its redundant
                // make sure the objects are not the same object, or have collided before
                guard !collided.contains([object1.id, object2.id]), object2.id != object1.id else { continue }
                // check for a collision. The collision uses a cheap ABBA (? is that its name) frame detection first, so failure is
                // pretty cheap
                guard let normalCandidate = normalOfCollision(hitBox1: object1.hitbox, hitBox2: object2.hitbox) else { continue }
                // the normal must be in the opposite direction of the net velocity (object1's velocity adjusting for object 2 as stationary)
                guard normalCandidate.dot(object1.velocity - object2.velocity) < 0 else { continue }
                normal = normalCandidate
                otherObject = (index2, object2)
                break
            }
            // if still zero, that means no collisions occured
            guard normal != .zero, let (index2, object2) = otherObject else { continue }
            normal = normal.unitVec()
            // add this object to collisions
            collided.insert([object1.id, object2.id])

            // the two objects have collided. We make use of completely elastic collision to calculate their velocities:
            //
            // Conservation of linear momentum:     m1v1 + m2v2 = m1u1 + m2u2
            // Conservation of mechanical energy:   v1 + u1 = v2 + u2

            // only velocity in the direction of the normal actually change, so we split the velocities into normal and tangential components:
            let object1Par = object1.velocity.dot(normal)
            let object2Par = object2.velocity.dot(normal)
            let object1TanVec = object1.velocity - (object1Par*normal) // these stay unchanged
            let object2TanVec = object2.velocity - (object2Par*normal) // these stay unchanged

            // following the laws of elastic collision (stolen from my physics notes):
            // u1 = (v1(m1 - m2) + v2(2m2))/(m1+m2)
            // u2 = v1 + u1 - v2
            let object1ParFinal = (object1Par * (object1.mass - object2.mass) + object2Par * 2 * object2.mass)/(object1.mass + object2.mass)
            let object2ParFinal = object1Par + object1ParFinal - object2Par

            // combine parallel and tangential components back
            let object1Final = object1ParFinal * normal + object1TanVec
            let object2Final = object2ParFinal * normal + object2TanVec

            // copy them back
            var object1Copy = object1
            object1Copy.velocity = object1Final
            newObjects[index1] = object1Copy
            var object2Copy = object2
            object2Copy.velocity = object2Final
            newObjects[index2] = object2Copy
        }

        self.objects = newObjects
    }

    /// Returns the normal vector of a collision, or `nil` if the objects do not collide.
    func normalOfCollision(hitBox1: any HitBox, hitBox2: any HitBox) -> CGPoint? {
        // do a trivial frame check first
        guard hitBox1.frame.intersects(hitBox2.frame) else { return nil }

        // if object1 is a compound hitbox, break it up and check each individual segment
        if let compound1 = hitBox1 as? CompoundHitbox {
            let normal = compound1.lines.reduce(CGPoint.zero) { partialResult, segment in
                partialResult + (normalOfCollision(
                    hitBox1: segment,
                    hitBox2: hitBox2
                ) ?? .zero)
            } + compound1.circles.reduce(CGPoint.zero) { partialResult, circle in
                partialResult + (normalOfCollision(
                    hitBox1: circle,
                    hitBox2: hitBox2
                ) ?? .zero)
            }
            if normal == .zero { return nil }
            return normal
        }
        // same for hitbox 2
        if let compound2 = hitBox2 as? CompoundHitbox {
            let normal = compound2.lines.reduce(CGPoint.zero) { partialResult, segment in
                partialResult + (normalOfCollision(
                    hitBox1: hitBox1,
                    hitBox2: segment
                ) ?? .zero)
            } + compound2.circles.reduce(CGPoint.zero) { partialResult, circle in
                partialResult + (normalOfCollision(
                    hitBox1: hitBox1,
                    hitBox2: circle
                ) ?? .zero)
            }
            if normal == .zero { return nil }
            return normal
        }

        // we should have a single hitbox comparing to another single hitbox
        // time to compare with our hit interactions
        for hitInteraction in hitInteractions {
            do {
                let intersects = try hitInteraction.intersects(hitBox1: hitBox1, hitBox2: hitBox2)
                // if it succeeded but returned false, they do not intersect, we return nil
                guard intersects else { return nil }
                // return the normal
                return try hitInteraction.normalUnitVector(to: hitBox1, from: hitBox2)
            } catch {
                // did not succeed, try the next one
                continue
            }
        }
        // we try the exact same thing but swapping orders reverse
        for hitInteraction in hitInteractions {
            do {
                let intersects = try hitInteraction.intersects(hitBox1: hitBox2, hitBox2: hitBox1)
                // if it succeeded but returned false, they do not intersect, we return nil
                guard intersects else { return nil }
                // return the normal (but invert it to account for the flipped order)
                return try -hitInteraction.normalUnitVector(to: hitBox2, from: hitBox1)
            } catch {
                // did not succeed, try the next one
                continue
            }
        }

        // not handled yet
        print("Interactions between \(hitBox1) and \(hitBox2) are not supported yet")
        return nil
    }
}
