//
//  LeaderboardViewModel.swift
//  keruh
//
//  Created by Richie Reuben Hermanto on 16/07/25.
//

import Foundation

class LeaderboardViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var topPlayers: [Leaderboard] = []

    func authenticate() {
        GameCenterManager.shared.authenticateLocalPlayer { success in
            DispatchQueue.main.async {
                self.isAuthenticated = success
            }
        }
    }

    func submitDummyScore() {
        let dummyScore = 19999
        GameCenterManager.shared.submitScore(dummyScore, leaderboardID: "com.keruh.leaderboard")
    }

    func showLeaderboard() {
        GameCenterManager.shared.showLeaderboard()
    }

    func loadTopPlayers() {
        GameCenterManager.shared.loadTopScores(leaderboardID: "com.keruh.leaderboard", count: 10) { players in
            DispatchQueue.main.async {
                self.topPlayers = players
            }
        }
    }
}
