//
//  LevelSetup.swift
//  ReturnToBesieger
//
//  Created by Kai Quan Tay on 27/11/26.
//

import Foundation

struct LevelSetup {
    var name: String

    /// The structure representing your king
    var myKing: King
    /// The budget available to the user, in pieces that they have available
    var budget: [BudgetItem]

    /// The structure representing the enemy's king
    var enemyKing: King
    /// Structures that the player is not allowed to move
    var enemyStructure: [any PhysicsObject]
}

struct BudgetItem {
    var object: any PhysicsObject
    var count: Int
}
