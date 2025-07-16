//
//  Leaderboard.swift
//  keruh
//
//  Created by Richie Reuben Hermanto on 16/07/25.
//

import Foundation

struct Leaderboard: Identifiable {
    let id = UUID()
    let playerName: String
    let score: Int
    let rank: Int
}
