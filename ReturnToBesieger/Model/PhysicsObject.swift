//
//  PhysicsObject.swift
//  ReturnToBesieger
//
//  Created by Kai Quan Tay on 23/11/26.
//

import SwiftUI

protocol PhysicsObject: Identifiable {
    associatedtype HB: HitBox

    /// The ID
    var id: UUID { get }
    /// The hitbox of the object
    var hitbox: HB { get set }
    /// The mass of the object. A mass of `.infinity` implies an immovable object.
    var mass: CGFloat { get }
    /// The velocity of the object
    var velocity: CGPoint { get set }

    mutating func updateCenter(to newCenter: CGPoint)
}

extension PhysicsObject {
    mutating func updateCenter(to newCenter: CGPoint) {
        self.hitbox.center = newCenter
    }
}

struct Ball: PhysicsObject {
    var id: UUID = .init()
    var hitbox: CircleHitbox
    var velocity: CGPoint
    var mass: CGFloat { .pi*hitbox.radius*hitbox.radius } // ball mass is equal to area
}

struct Wall: PhysicsObject {
    var id: UUID = .init()
    var hitbox: RotatableRectangleHitbox
    var velocity: CGPoint
    var mass: CGFloat { hitbox.size.width*hitbox.size.height } // wall mass is equal to area
}
