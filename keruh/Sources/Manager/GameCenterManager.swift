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
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first,
                   let rootVC = window.rootViewController {
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
    
    var currentPlayerID: String {
        GKLocalPlayer.local.gamePlayerID
    }

    func submitScore(_ score: Int, leaderboardID: String = "com.keruh.leaderboard") {
        GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local, leaderboardIDs: [leaderboardID]) { error in
            if let error = error {
                print("Failed to submit score: \(error.localizedDescription)")
            } else {
                print("Score submitted: \(score)")
            }
        }
    }
    
    func showLeaderboard() {
        let viewController = GKGameCenterViewController(state: .leaderboards)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(viewController, animated: true)
        }
    }
    
    func showSpecificLeaderboard(leaderboardID: String) {
        let viewController = GKGameCenterViewController(leaderboardID: leaderboardID, playerScope: .global, timeScope: .allTime)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(viewController, animated: true)
        }
    }
    
    func loadTopScores(leaderboardID: String, count: Int = 10, completion: @escaping ([Leaderboard]) -> Void) {
        GKLeaderboard.loadLeaderboards(IDs: [leaderboardID]) { leaderboards, error in
            if let error = error {
                print("Error loading leaderboards: \(error.localizedDescription)")
                completion([])
                return
            }
            
            guard let leaderboard = leaderboards?.first else {
                print("No leaderboard found.")
                completion([])
                return
            }
            
            leaderboard.loadEntries(for: .global, timeScope: .allTime, range: NSRange(location: 1, length: count)) { localPlayerEntry, entries, totalPlayerCount, error in
                if let error = error {
                    print("Error loading entries: \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                guard let entries = entries else {
                    print("No entries found.")
                    completion([])
                    return
                }
                
                let leaderboardEntries: [Leaderboard] = entries.enumerated().map { index, entry in
                    Leaderboard(
                        player: entry.player,
                        score: Int(entry.score),
                        rank: index + 1
                    )
                }
                completion(leaderboardEntries)
            }
        }
    }
}
