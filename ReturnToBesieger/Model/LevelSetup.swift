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

struct BudgetItem: Identifiable {
    var object: any PhysicsObject
    var count: Int

    var id: UUID { object.id }
}

enum LevelPhase: Hashable {
    /// The user can place walls
    case placeWalls
    /// The game is currently playing
    case playing
    /// The game is currently paused, but the user cannot place walls.
    case paused
    /// The user has won
    case win
    /// The user has lost
    case lose
}
