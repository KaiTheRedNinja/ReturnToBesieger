//
//  GameManager.swift
//  ReturnToBesieger
//
//  Created by Kai Quan Tay on 27/11/26.
//

import SwiftUI

@Observable
class GameManager: PhysicsManager {
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
        super.update(dt: dt)
    }

    func startSimulation() {
        physicsEnabled = true
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
    }
}
