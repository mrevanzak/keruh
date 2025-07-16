//
//  GameCenterManager.swift
//  keruh
//
//  Created by Richie Reuben Hermanto on 16/07/25.
//

import GameKit

class GameCenterManager {
    static let shared = GameCenterManager()

    private init() {}

    func authenticateLocalPlayer(completion: @escaping (Bool) -> Void) {
        let localPlayer = GKLocalPlayer.local
        localPlayer.authenticateHandler = { viewController, error in
            if let vc = viewController {
                if let rootVC = UIApplication.shared.windows.first?.rootViewController {
                    rootVC.present(vc, animated: true)
                }
            } else if localPlayer.isAuthenticated {
                print("Game Center Authenticated")
                completion(true)
            } else {
                print("Game Center Failed: \(error?.localizedDescription ?? "Unknown error")")
                completion(false)
            }
        }
    }

    func submitScore(_ score: Int, leaderboardID: String) {
        let scoreReporter = GKScore(leaderboardIdentifier: leaderboardID)
        scoreReporter.value = Int64(score)
        GKScore.report([scoreReporter]) { error in
            if let error = error {
                print("Failed to submit score: \(error.localizedDescription)")
            } else {
                print("Score submitted: \(score)")
            }
        }
    }

    func showLeaderboard() {
        let viewController = GKGameCenterViewController()
        viewController.viewState = .leaderboards
        viewController.leaderboardIdentifier = "com.keruh.leaderboard"
        if let rootVC = UIApplication.shared.windows.first?.rootViewController {
            rootVC.present(viewController, animated: true)
        }
    }
    
    func loadTopScores(leaderboardID: String, count: Int = 10, completion: @escaping ([Leaderboard]) -> Void) {
        let leaderboard = GKLeaderboard()
        leaderboard.identifier = leaderboardID
        leaderboard.playerScope = .global
        leaderboard.timeScope = .allTime
        leaderboard.range = NSRange(location: 1, length: count)

        leaderboard.loadScores { scores, error in
            if let error = error {
                print("❌ Error loading scores: \(error.localizedDescription)")
                completion([])
                return
            }

            guard let scores = scores else {
                print("⚠️ No scores found.")
                completion([])
                return
            }

            let leaderboardEntries: [Leaderboard] = scores.enumerated().map { index, score in
                Leaderboard(
                    playerName: score.player.alias,
                    score: Int(score.value),
                    rank: score.rank
                )
            }

            completion(leaderboardEntries)
        }
    }

}
