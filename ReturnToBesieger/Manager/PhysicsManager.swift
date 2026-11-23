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
                guard let normalCandidate = normalOfCollision(object1: object1, object2: object2) else { continue }
                // the normal must be in the opposite direction of the velocity
                guard normalCandidate.dot(object1.velocity) < 0 else { continue }
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
    func normalOfCollision(object1: any PhysicsObject, object2: any PhysicsObject) -> CGPoint? {
        // for now, we only have ball-line collisions handled
        if let circle = object1.hitbox as? CircleHitbox,
           let rect = object2.hitbox as? RotatableRectangleHitbox {
            var normal: CGPoint = .zero
            for edge in rect.edges {
                normal += edge.normalUnitVector(circle: circle)
            }
            // if still zero, that means no collisions occured
            guard normal != .zero else { return nil }
            // normalise then return
            return normal.unitVec()
        } else {
            // not handled yet
            print("Interactions between \(object1) and \(object2) are not supported yet")
            return nil
        }
    }
}
