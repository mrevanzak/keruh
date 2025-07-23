//
//  Leaderboard.swift
//  keruh
//
//  Created by Richie Reuben Hermanto on 16/07/25.
//

import Foundation
import GameKit

struct Leaderboard: Identifiable {
    let id = UUID()
    let player: GKPlayer
    let score: Int
    let rank: Int
    var playerImage: UIImage? = nil

    var playerName: String {
        player.displayName
    }
}

