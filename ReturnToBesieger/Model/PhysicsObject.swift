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
    /// The velocity of the object
    var velocity: CGPoint { get set }
    /// If this object is fixed. Fixed objects do not move and cannot be moved by collisions.
    var isFixed: Bool { get }

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
    var isFixed: Bool { false }
}

struct Wall: PhysicsObject {
    var id: UUID = .init()
    var hitbox: RotatableRectangleHitbox
    var velocity: CGPoint
    var isFixed: Bool { true }
}
