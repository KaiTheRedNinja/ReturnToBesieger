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
    var id: UUID { get set }
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

    func isReposition(_ other: Self) -> Bool
}

extension PhysicsObject {
    mutating func updateCenter(to newCenter: CGPoint) {
        self.hitbox.center = newCenter
    }
    mutating func updateAngle(to newAngle: Angle) {
        self.hitbox.angle = newAngle
    }

    func isReposition(_ other: any PhysicsObject) -> Bool {
        guard let other = other as? Self else { return false }
        return isReposition(other)
    }
}

protocol KillableObject: PhysicsObject {
    var totalHealth: Int { get }
    var currentHealth: Int { get set }
}

struct Ball: PhysicsObject {
    var id: UUID = .init()
    var hitbox: CircleHitbox
    var velocity: CGPoint
    var dragCoefficient: CGFloat { 0 }
    var mass: CGFloat { .pi*hitbox.radius*hitbox.radius } // ball mass is equal to area

    func isReposition(_ other: Ball) -> Bool {
        other.hitbox.radius == self.hitbox.radius
    }
}

struct Wall: PhysicsObject {
    var id: UUID = .init()
    var hitbox: RotatableRectangleHitbox
    var velocity: CGPoint
    var dragCoefficient: CGFloat { 1.0 }
    var mass: CGFloat { hitbox.size.width*hitbox.size.height } // wall mass is equal to area

    func isReposition(_ other: Wall) -> Bool {
        other.hitbox.size == self.hitbox.size
    }
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
        case .rock: 4.0
        case .cannonball: 6.0
        case .fireball: 8.0
        }
    }
    var mass: CGFloat { density * .pi*hitbox.radius*hitbox.radius }

    func isReposition(_ other: BallProjectile) -> Bool {
        other.hitbox.radius == self.hitbox.radius && other.kind == self.kind
    }
}

struct WallObstacle: PhysicsObject, KillableObject {
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
    /// Whether or not the obstacle is moveable by the user
    var moveable: Bool = true
    /// A one way wall obstacle blocks items coming in from the right, while allowing items through from the left
    var oneWay: Bool = false
    var density: CGFloat {
        if !moveable { return 1_000_000 }
        return switch kind {
        case .wood: 0.8
        case .stone: 1.2
        case .metal: 5.0
        case .magical: 1_000_000
        }
    }
    var mass: CGFloat { density * hitbox.size.width*hitbox.size.height }

    var totalHealth: Int {
        switch kind {
        case .wood: 1_000
        case .stone: 1_000
        case .metal: 1_000
        case .magical: 1_000_000
        }
    }
    var currentHealth: Int

    init(kind: ObstacleKind, hitbox: RotatableRectangleHitbox, velocity: CGPoint, moveable: Bool = true, oneWay: Bool = false) {
        self.kind = kind
        self.hitbox = hitbox
        self.velocity = velocity
        self.moveable = moveable
        self.oneWay = oneWay
        self.currentHealth = 0

        self.currentHealth = totalHealth
    }

    func isReposition(_ other: WallObstacle) -> Bool {
        other.hitbox.size == self.hitbox.size &&
        other.kind == self.kind &&
        other.moveable == self.moveable &&
        other.oneWay == self.oneWay
    }
}

struct ProjectileFactory: PhysicsObject, KillableObject {
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
    var fireInterval: TimeInterval
    var lastFire: Date = .distantPast
    var density: CGFloat {
        return switch kind {
        case .slinger: 0.8
        case .cannon: 1.2
        case .dragon: 5.0
        }
    }
    var mass: CGFloat { density * hitbox.size.width*hitbox.size.height }

    let totalHealth: Int = 500
    var currentHealth: Int = 500

    init(kind: FactoryKind, position: CGPoint, fixedAngle: Angle? = nil, velocity: CGPoint) {
        self.kind = kind
        self.hitbox = .init(size: .init(width: 100, height: 70), center: position, angle: fixedAngle ?? .zero)
        self.velocity = velocity
        self.rotateToFaceEnemyKing = fixedAngle == nil
        self.fireInterval = switch kind {
        case .slinger: 3.0
        case .cannon: 5.0
        case .dragon: 8.0
        }
        self.lastFire = .distantPast
    }

    func createProjectile() -> BallProjectile {
        // calculate where to position yourself. The ball is created at 1x width, to the right of center, rotated accordingly.
        let displacement = CGPoint(x: 1, y: 0).rotating(acw: hitbox.angle)
        let newLocation = hitbox.center + hitbox.size.width * displacement
        let newSpeed = switch kind {
        case .slinger: 400.0
        case .cannon: 300.0
        case .dragon: 500.0
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

    func isReposition(_ other: ProjectileFactory) -> Bool { false }
}

struct King: PhysicsObject, KillableObject {
    var id: UUID = .init()
    var isPlayerKing: Bool
    var hitbox: CircleHitbox
    var velocity: CGPoint
    var dragCoefficient: CGFloat { 5 }
    var density: CGFloat { 10.0 }
    var mass: CGFloat { density * .pi*hitbox.radius*hitbox.radius }

    let totalHealth: Int
    var currentHealth: Int

    init(isPlayerKing: Bool, position: CGPoint, velocity: CGPoint) {
        self.isPlayerKing = isPlayerKing
        self.hitbox = .init(radius: 30, center: position)
        self.velocity = velocity

        if isPlayerKing {
            totalHealth = 200
            currentHealth = 200
        } else {
            totalHealth = 100
            currentHealth = 100
        }
    }

    func isReposition(_ other: King) -> Bool { false }
}
