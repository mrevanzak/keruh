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
    @Published var isLoading = true

    let leaderboardID = "com.keruh.leaderboard"

    func authenticate() {
        GameCenterManager.shared.authenticateLocalPlayer { success in
            DispatchQueue.main.async {
                self.isAuthenticated = success
            }
        }
    }

    func submitDummyScore() {
        let dummyScore = 19999
        GameCenterManager.shared.submitScore(dummyScore, leaderboardID: leaderboardID)
    }

    func showLeaderboard() {
        GameCenterManager.shared.showLeaderboard()
    }

    func loadTopPlayers() {
        isLoading = true
        GameCenterManager.shared.loadTopScores(leaderboardID: leaderboardID, count: 10) { players in
            DispatchQueue.main.async {
                self.topPlayers = players
                self.loadProfileImages()
                self.isLoading = false
            }
        }
    }

    private func loadProfileImages() {
        for (index, player) in topPlayers.enumerated() {
            player.player.loadPhoto(for: .small) { image, error in
                guard let image = image, error == nil else { return }
                DispatchQueue.main.async {
                    self.topPlayers[index].playerImage = image 
                    self.objectWillChange.send()
                }
            }
        }
    }

}
