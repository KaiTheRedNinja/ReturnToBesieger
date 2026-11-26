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
    /// The drag coefficient with the ground. 0 means the object experiences no friction.
    /// Acceleration is equal to `-drag * gravity` where gravity is defined as 10.
    var dragCoefficient: CGFloat { get }

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
    var dragCoefficient: CGFloat { 0 }
    var mass: CGFloat { .pi*hitbox.radius*hitbox.radius } // ball mass is equal to area
}

struct Wall: PhysicsObject {
    var id: UUID = .init()
    var hitbox: RotatableRectangleHitbox
    var velocity: CGPoint
    var dragCoefficient: CGFloat { 1.0 }
    var mass: CGFloat { hitbox.size.width*hitbox.size.height } // wall mass is equal to area
}

struct BallProjectile: PhysicsObject {
    enum ProjectileKind {
        case rock
        case cannonball
        case fireball
    }

    var id: UUID = .init()
    var kind: ProjectileKind
    var hitbox: CircleHitbox
    var velocity: CGPoint
    var dragCoefficient: CGFloat { 0 }
    var density: CGFloat {
        switch kind {
        case .rock: 1.0
        case .cannonball: 5.0
        case .fireball: 10.0
        }
    }
    var mass: CGFloat { density * .pi*hitbox.radius*hitbox.radius }
}

struct WallObstacle: PhysicsObject {
    enum ObstacleKind {
        case wood
        case stone
        case metal
        case magical
    }

    var id: UUID = .init()
    var kind: ObstacleKind
    var hitbox: RotatableRectangleHitbox
    var velocity: CGPoint
    var dragCoefficient: CGFloat { 5.0 }
    var density: CGFloat {
        switch kind {
        case .wood: 1.0
        case .stone: 5.0
        case .metal: 10.0
        case .magical: .infinity
        }
    }
    var mass: CGFloat { density * hitbox.size.width*hitbox.size.height }
}
