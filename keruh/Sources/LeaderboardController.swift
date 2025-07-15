//
//  LeaderboardController.swift
//  keruh
//
//  Created by Richie Reuben Hermanto on 11/07/25.
//

import UIKit
import GameKit

class LeaderboardController: UIViewController, GKGameCenterControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        authenticatePlayer()
        setupShowLeaderboardButton()
    }

    // MARK: - Autentikasi Game Center
    func authenticatePlayer() {
        let localPlayer = GKLocalPlayer.local
        localPlayer.authenticateHandler = { viewController, error in
            if let vc = viewController {
                self.present(vc, animated: true, completion: nil)
            } else if localPlayer.isAuthenticated {
                print("✅ Player authenticated")
                self.submitDummyScore()
            } else {
                print("❌ Game Center authentication failed: \(error?.localizedDescription ?? "unknown error")")
            }
        }
    }

    // MARK: - Submit Dummy Score
    func submitDummyScore() {
        guard GKLocalPlayer.local.isAuthenticated else {
            print("⚠️ Player not authenticated, cannot submit score.")
            return
        }

        let dummyScore = GKScore(leaderboardIdentifier: "keruh_leaderboard")
        dummyScore.value = Int64(Int.random(in: 100...1000)) // Skor acak antara 100–1000
        GKScore.report([dummyScore]) { error in
            if let error = error {
                print("❌ Failed to submit score: \(error.localizedDescription)")
            } else {
                print("✅ Dummy score submitted: \(dummyScore.value)")
            }
        }
    }

    // MARK: - Button Leaderboard
    func setupShowLeaderboardButton() {
        let button = UIButton(type: .system)
        button.setTitle("Lihat Leaderboard", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        button.backgroundColor = .systemBlue
        button.tintColor = .white
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(showLeaderboard), for: .touchUpInside)
        view.addSubview(button)

        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            button.widthAnchor.constraint(equalToConstant: 200),
            button.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    // MARK: - Show Leaderboard
    @objc func showLeaderboard() {
        let viewController = GKGameCenterViewController(leaderboardID: "keruh_leaderboard", playerScope: .global, timeScope: .allTime)
        viewController.gameCenterDelegate = self
        present(viewController, animated: true, completion: nil)
    }

    // MARK: - Delegate Dismiss
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true, completion: nil)
    }
    
    func loadTopPlayers(completion: @escaping ([GKScore]) -> Void) {
        let leaderboard = GKLeaderboard()
        leaderboard.identifier = "keruh_leaderboard"
        leaderboard.timeScope = .allTime
        leaderboard.playerScope = .global
        leaderboard.range = NSRange(location: 1, length: 5) // Top 5

        leaderboard.loadScores { scores, error in
            if let error = error {
                print("❌ Failed to load leaderboard: \(error.localizedDescription)")
                completion([])
            } else if let scores = scores {
                print("✅ Loaded top players")
                completion(scores)
            } else {
                print("⚠️ No scores found")
                completion([])
            }
        }
    }
}
