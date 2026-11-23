//
//  PhysicsObject.swift
//  ReturnToBesieger
//
//  Created by Kai Quan Tay on 23/11/26.
//

import SwiftUI

protocol PhysicsObject {
    associatedtype HB: HitBox

    /// The hitbox of the object
    var hitbox: HB { get }
    /// The velocity of the object
    var velocity: CGPoint { get }
}

struct Ball: PhysicsObject {
    var hitbox: CircleHitbox
    var velocity: CGPoint
}

struct Wall: PhysicsObject {
    var hitbox: RotatableRectangleHitbox
    var velocity: CGPoint
}
