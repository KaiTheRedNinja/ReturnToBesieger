//
//  PhysicsManager.swift
//  ReturnToBesieger
//
//  Created by Kai Quan Tay on 23/11/26.
//

import SwiftUI

@MainActor
@Observable
class PhysicsManager {
    var objects: [any PhysicsObject] = []
    var hitInteractions: [any HitInteraction] = [
        CircleCircleHitInteraction(),
        CircleLineHitInteraction(),
        LineLineHitInteraction()
    ]
    /// NOTE: this physics manager is a top-down view, gravity is only used for friction purposes
    var gravity: CGFloat = 100
    /// The bounds of the simulation. When an object completely exits the bounds, the delegate is informed.
    var bounds: CGRect = .init(center: .zero, size: simulationSize)
    /// The delegate, which is informed of collisions.
    var delegate: (any PhysicsManagerDelegate)?

    init(
        objects: [any PhysicsObject] = [],
        bounds: CGRect = .init(center: .zero, size: simulationSize),
        delegate: (any PhysicsManagerDelegate)? = nil
    ) {
        self.objects = objects
        self.bounds = bounds
        self.delegate = delegate
    }

    /// Informs the physics manager that the given object's hitbox, angle, and/or velocity should be changed.
    func changeObjectProperties(
        _ objectId: UUID,
        center: CGPoint? = nil,
        angle: Angle? = nil,
        velocity: CGPoint? = nil,
        isRelease: Bool = false
    ) {
        guard let index = objects.firstIndex(where: { $0.id == objectId }) else { return }
        var objectCopy = objects[index]
        if let center { objectCopy.updateCenter(to: center) }
        if let angle { objectCopy.updateAngle(to: angle) }
        if let velocity { objectCopy.velocity = velocity }
        objects[index] = objectCopy

        if isRelease, !bounds.intersects(objectCopy.hitbox.frame) {
            delegate?.objectDidExitBounds(object: objectCopy)
        }
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
                let newVelocity = object.velocity + dt * frictionAcceleration
                if newVelocity.dot(object.velocity.unitVec()) < 0 {
                    // friction has caused this object to stop
                    objectCopy.velocity = .zero
                } else {
                    // friction has caused this object to slow, but not stop outright
                    objectCopy.velocity = newVelocity
                }
            }
            // update the displacement
            objectCopy.updateCenter(to: object.hitbox.center + dt * objectCopy.velocity)
            newObjects.append(objectCopy)
        }

        // check for collisions. If there are, we calculate where they should move.
        // collisions are calculated in array order, so items that appear first in the array will have their collisions calculated first.
        var collided: Set<Set<UUID>> = []
        for (index1, object1) in newObjects.enumerated() {
            var normal: CGPoint = .zero
            var otherObject: (Int, any PhysicsObject)?
            // we can skip everything before the current object because its redundant
            for (index2, object2) in newObjects.enumerated().dropFirst(index1+1) {

                guard // make sure the objects are not the same object, or have collided before
                      !collided.contains([object1.id, object2.id]), object2.id != object1.id,
                      // check for a collision. The collision uses a cheap ABBA (? is that its name) frame detection first,
                      // so failure is pretty cheap
                      let normalCandidate = normalOfCollision(hitBox1: object1.hitbox, hitBox2: object2.hitbox),
                      // the normal must be in the opposite direction of the net velocity (object1's velocity adjusting for object 2 as stationary)
                      normalCandidate.dot(object1.velocity - object2.velocity) < 0,
                      // ask the delegate if we should allow the two objects to collide
                      delegate?.objectsShoudlCollide(object1: object1, object2: object2) ?? true
                else { continue }
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
            var object2Copy = object2
            object2Copy.velocity = object2Final

            // update their health
            if var object1Killable = object1Copy as? any KillableObject {
                let deltaV = (object1Final - object1.velocity).magnitude
                object1Killable.currentHealth -= Int(deltaV)
                object1Copy = object1Killable
            }
            if var object2Killable = object2Copy as? any KillableObject {
                let deltaV = (object2Final - object2.velocity).magnitude
                object2Killable.currentHealth -= Int(deltaV)
                object2Copy = object2Killable
            }

            newObjects[index1] = object1Copy
            newObjects[index2] = object2Copy
        }

        self.objects = newObjects

        // inform the delegate of collisions
        for ids in collided {
            guard ids.count == 2 else { continue }
            let collidedObjects = ids.compactMap { id in objects.first(where: { $0.id == id }) }
            guard collidedObjects.count == 2 else { continue }
            delegate?.objectsDidCollide(object1: collidedObjects[0], object2: collidedObjects[1])
        }

        // inform the delegate of deaths
        for object in objects {
            guard let killable = object as? any KillableObject, killable.currentHealth <= 0 else { continue }
            delegate?.objectDidDie(object: killable)
        }

        // inform object out of bounds. Note that we do not use a for loop here, as the delegate may
        // delete objects and we don't want to cause looping problems.
        objects
            .filter { !bounds.intersects($0.hitbox.frame) }
            .forEach { delegate?.objectDidExitBounds(object: $0) }
    }

    /// Returns the normal vector of a collision, or `nil` if the objects do not collide.
    func normalOfCollision(hitBox1: any HitBox, hitBox2: any HitBox) -> CGPoint? {
        // do a trivial frame check first
        guard hitBox1.frame.intersects(hitBox2.frame) else { return nil }

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

        // no hit interaction for the hitbox type is given. We split them up if they're compound, then try again.
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

        // not handled yet
        print("Interactions between \(hitBox1) and \(hitBox2) are not supported yet")
        return nil
    }

    /// Whether an object would hit others. This is not called by the object itself, and should be called externally
    /// to check if a candidate position works
    func candidateOverlapsOthers(_ candidate: any PhysicsObject) -> Bool {
        for object in objects where object.id != candidate.id {
            let normal = normalOfCollision(hitBox1: object.hitbox, hitBox2: candidate.hitbox)
            let collides = (normal != nil && normal != .zero)
                || object.hitbox.frame.contains(candidate.hitbox.frame)
                || candidate.hitbox.frame.contains(object.hitbox.frame)
            if collides, delegate?.objectsShoudlCollide(object1: candidate, object2: object) != true {
                // normal exists, is non-zero, and the delegate allows it to collide
                return true
            }
        }

        return false
    }
}

protocol PhysicsManagerDelegate {
    /// Asks the delegate whether or not two objects should collide with each other. Returns `true` if the objects
    /// should collide, or `false` if they should phase through each other.
    func objectsShoudlCollide(object1: any PhysicsObject, object2: any PhysicsObject) -> Bool
    /// Informs the delegate that two objects have collided
    func objectsDidCollide(object1: any PhysicsObject, object2: any PhysicsObject)
    /// Informs the delegate that an object has exited the bounds of the field
    func objectDidExitBounds(object: any PhysicsObject)
    /// Informs the delegate that a killable object has fallen to or below 0 health
    func objectDidDie(object: any KillableObject)
}
