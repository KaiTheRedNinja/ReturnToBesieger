//
//  GameManager.swift
//  ReturnToBesieger
//
//  Created by Kai Quan Tay on 27/11/26.
//

import SwiftUI

@Observable
class GameManager: PhysicsManager, PhysicsManagerDelegate {
    /// Whether physics are active or not
    var physicsEnabled: Bool = false
    /// The rate at which physics runs, i.e. the number of simulation seconds per real world second
    var timeRate: CGFloat = 1
    /// A backup of the objects, used to restore the positions of everything upon reset
    @ObservationIgnored var objectsBackup: [any PhysicsObject] = []
    /// The current level setup, if any
    var level: LevelSetup?
    /// The current phase within the level
    var levelPhase: LevelPhase = .placeWalls
    /// The current budget
    var currentBudget: [BudgetItem] = []

    override func update(dt: TimeInterval) {
        guard physicsEnabled else { return }

        // update any projectile factories
        let king = objects.first { $0.id == level?.myKing.id }
        let now = Date.now
        var newObjects: [any PhysicsObject] = []
        for (index, object) in objects.enumerated() {
            guard var factory = object as? ProjectileFactory,
                  now.timeIntervalSince(factory.lastFire) > factory.fireInterval
            else { continue }
            // face to king
            if let king, factory.rotateToFaceEnemyKing {
                let factoryToKing = king.hitbox.center - factory.hitbox.center
                factory.updateAngle(to: -factoryToKing.angle + Angle.degrees(.random(in: -1..<1)))
            }
            // create a new object
            let newProjectile = factory.createProjectile()
            newObjects.append(newProjectile)
            factory.lastFire = now
            objects[index] = factory
        }
        objects += newObjects

        super.update(dt: dt * timeRate)
    }

    func startSimulation(timeRate: CGFloat = 1) {
        physicsEnabled = true
        levelPhase = .playing
        objectsBackup = objects
        self.timeRate = timeRate
    }

    func endSimulation() {
        physicsEnabled = false
        levelPhase = .paused
        timeRate = 1
    }

    func resetToBackup() {
        endSimulation()
        objects = objectsBackup
        levelPhase = .placeWalls
        timeRate = 1
    }

    func load(level: LevelSetup) {
        endSimulation()
        self.level = level
        self.objects = []
        self.objectsBackup = []
        delegate = self

        // load all of the objects in
        self.currentBudget = level.budget
        self.objects = level.enemyStructure + [
            level.myKing,
            level.enemyKing
        ]

        // update any projectile factories
        for (index, object) in objects.enumerated() {
            guard var factory = object as? ProjectileFactory,
                  factory.rotateToFaceEnemyKing
            else { continue }
            // face to king
            let factoryToKing = level.myKing.hitbox.center - factory.hitbox.center
            factory.updateAngle(to: -factoryToKing.angle)
            objects[index] = factory
        }

        levelPhase = .placeWalls
    }
}

extension GameManager {
    func objectsShoudlCollide(object1: any PhysicsObject, object2: any PhysicsObject) -> Bool {
        // during wall placement, everything collides
        guard levelPhase != .placeWalls else { return true }
        // walls don't intersect with other walls
        if object1 is WallObstacle, object2 is WallObstacle {
            return false
        }

        guard let (wall, ball) = (object1, object2) as? (WallObstacle, BallProjectile)
                              ?? (object2, object1) as? (WallObstacle, BallProjectile),
              wall.oneWay
        else {
            return true
        }

        // determine the direction vector of the right of the wall, accounting for rotation
        let permitDirection = CGPoint(x: 1, y: 0).rotating(acw: wall.hitbox.angle)
        let ballInPermitDirection = ball.velocity.dot(permitDirection) > 0

        // if ball is in permit direction, do not collide as we allow in that direction.
        return !ballInPermitDirection
    }

    func objectsDidCollide(object1: any PhysicsObject, object2: any PhysicsObject) {
        guard let level else { return }
        if object1.id == level.myKing.id || object2.id == level.myKing.id {
            // king hit!!!
            print("MY KING HIT")
        }
        if object1.id == level.enemyKing.id || object2.id == level.enemyKing.id {
            // king hit!!!
            print("ENEMY KING HIT")
        }
        // TODO: process if archers are hit
    }

    func objectDidExitBounds(object: any PhysicsObject) {
        // if this is during placement and its in the tray, delete it
        if levelPhase == .placeWalls, let budgetIndex = level?.budget.firstIndex(where: { object.isReposition($0.object) }) {
            // refund the budget item
            level?.budget[budgetIndex].count += 1
        }

        // remove the object
        objects.removeAll(where: { $0.id == object.id })
    }

    func objectDidDie(object: any KillableObject) {
        print("OBJECT DIED: \(object)")
        if object is King {
            endSimulation()
        }
    }

    /// Adds an instance of the object
    func addInstance(budgetIndex: Int) {
        guard !physicsEnabled, let level, level.budget[budgetIndex].count > 0 else { return }
        var newObject = level.budget[budgetIndex].object
        newObject.id = UUID()
        objects.append(newObject)
        self.level?.budget[budgetIndex].count -= 1
    }
}
