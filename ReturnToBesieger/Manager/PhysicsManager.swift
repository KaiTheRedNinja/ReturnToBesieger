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
        CircleLineHitInteraction()
    ]

    init(objects: [any PhysicsObject] = []) {
        self.objects = objects
    }

    /// Updates all of the objects. Note that you must NOT remove or add objects during an update.
    func update(dt: TimeInterval) {
        // move all objects
        var newObjects: [any PhysicsObject] = []
        for object in objects {
            guard !object.isFixed else { newObjects.append(object); continue }
            var objectCopy = object
            objectCopy.updateCenter(to: object.hitbox.center + object.velocity)
            newObjects.append(objectCopy)
        }

        // check for collisions. If there are, we revert the motion.
        // O(n^2) when no collisions, slightly higher if there are.
        for (index, object1) in newObjects.enumerated() {
            var normal: CGPoint = .zero
            for object2 in newObjects {
                // skip if they're the same object
                guard object2.id != object1.id else { continue }
                // use a cheap hitbox check at first
                guard object1.hitbox.frame.intersects(object2.hitbox.frame) else { continue }

                // check for a collision
                guard let normalCandidate = normalOfCollision(hitBox1: object1.hitbox, hitBox2: object2.hitbox) else { continue }
                // the normal must be in the opposite direction of the net velocity (object1's velocity adjusting for object 2 as stationary)
                guard normalCandidate.dot(object1.velocity - object2.velocity) < 0 else { continue }
                normal += normalCandidate
            }
            // if still zero, that means no collisions occured
            guard normal != .zero else { continue }
            normal = normal.unitVec()

            // flip the velocity along the line perpendicular to the normal
            var objectCopy = object1
            let scale = objectCopy.velocity.dot(normal)
            let newVelocity = objectCopy.velocity - 2 * (scale * normal)
            objectCopy.velocity = newVelocity
            newObjects[index] = objectCopy
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
