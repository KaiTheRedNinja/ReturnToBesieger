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
    /// A backup of the objects, used to restore the positions of everything upon reset
    @ObservationIgnored var objectsBackup: [any PhysicsObject] = []
    /// The current level setup, if any
    var level: LevelSetup?
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
                factory.updateAngle(to: -factoryToKing.angle + Angle.degrees(.random(in: -3..<3)))
            }
            // create a new object
            let newProjectile = factory.createProjectile()
            newObjects.append(newProjectile)
            factory.lastFire = now
            objects[index] = factory
        }
        objects += newObjects

        super.update(dt: dt)
    }

    func startSimulation() {
        physicsEnabled = true
        delegate = self
        objectsBackup = objects
    }

    func endSimulation() {
        physicsEnabled = false
    }

    func resetToBackup() {
        endSimulation()
        objects = objectsBackup
    }

    func load(level: LevelSetup) {
        endSimulation()
        self.level = level
        self.objects = []
        self.objectsBackup = []

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
    }
}

extension GameManager {
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
        // remove the object
        objects.removeAll(where: { $0.id == object.id })
    }
}
