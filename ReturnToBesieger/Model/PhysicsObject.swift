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
    mutating func updateAngle(to newAngle: Angle)
}

extension PhysicsObject {
    mutating func updateCenter(to newCenter: CGPoint) {
        self.hitbox.center = newCenter
    }
    mutating func updateAngle(to newAngle: Angle) {
        self.hitbox.angle = newAngle
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
    var moveable: Bool = true
    var density: CGFloat {
        if moveable { return 1_000_000 }
        return switch kind {
        case .wood: 5.0
        case .stone: 25.0
        case .metal: 50.0
        case .magical: 1_000_000
        }
    }
    var mass: CGFloat { density * hitbox.size.width*hitbox.size.height }
}

struct ProjectileFactory: PhysicsObject {
    enum FactoryKind {
        case slinger
        case cannon
        case dragon
    }

    var id: UUID = .init()
    var kind: FactoryKind
    var hitbox: RotatableRectangleHitbox
    var velocity: CGPoint
    var dragCoefficient: CGFloat { 5.0 }
    var rotateToFaceEnemyKing: Bool = true
    var density: CGFloat { 5.0 }
    var mass: CGFloat { density * hitbox.size.width*hitbox.size.height }

    func createProjectile() -> BallProjectile {
        // calculate where to position yourself. The ball is created at 1x width, to the right of center, rotated accordingly.
        let displacement = CGPoint(x: 1, y: 0).rotating(acw: hitbox.angle)
        let newLocation = hitbox.center + hitbox.size.width * displacement
        let newSpeed = switch kind {
        case .slinger: 2.0
        case .cannon: 5.0
        case .dragon: 7.0
        }
        let newVelocity = newSpeed * displacement
        let newKind = switch kind {
        case .slinger: BallProjectile.ProjectileKind.rock
        case .cannon: BallProjectile.ProjectileKind.cannonball
        case .dragon: BallProjectile.ProjectileKind.fireball
        }
        let newRadius: CGFloat = switch kind {
        case .slinger: 10.0
        case .cannon: 15.0
        case .dragon: 20.0
        }

        return .init(
            kind: newKind,
            hitbox: .init(radius: newRadius, center: newLocation),
            velocity: newVelocity
        )
    }
}

struct King: PhysicsObject {
    var id: UUID = .init()
    var isPlayerKing: Bool
    var hitbox: CircleHitbox
    var velocity: CGPoint
    var dragCoefficient: CGFloat { 5 }
    var density: CGFloat { 10.0 }
    var mass: CGFloat { density * .pi*hitbox.radius*hitbox.radius }

    init(isPlayerKing: Bool, position: CGPoint, velocity: CGPoint) {
        self.isPlayerKing = isPlayerKing
        self.hitbox = .init(radius: 30, center: position)
        self.velocity = velocity
    }
}
