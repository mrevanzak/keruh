// LeaderboardView.swift

import SwiftUI
import GameKit

struct CustomLeaderboardView: View {
    @State private var entries: [LeaderboardEntry] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("🏆 Top 5 Players")
                .font(.largeTitle)
                .bold()

            if isLoading {
                ProgressView("Loading...")
            } else if let error = errorMessage {
                Text("❌ \(error)")
                    .foregroundColor(.red)
            } else {
                ForEach(entries) { entry in
                    HStack {
                        Text(entry.playerName)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("\(entry.score)")
                            .bold()
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .onAppear {
            authenticatePlayer()
        }
    }

    // MARK: - Game Center Authentication
    func authenticatePlayer() {
        let localPlayer = GKLocalPlayer.local

        localPlayer.authenticateHandler = { viewController, error in
            if let error = error {
                self.errorMessage = "Game Center error: \(error.localizedDescription)"
                self.isLoading = false
                return
            }

            if let vc = viewController {
                // NOTE: SwiftUI tidak bisa present UIKit VC secara langsung
                // Solusi: Autentikasi sebaiknya dilakukan sebelumnya via UIKit wrapper
                print("⚠️ Game Center login UI required. Handle in UIKit.")
                self.errorMessage = "Please login to Game Center via Settings"
                self.isLoading = false
                return
            }

            if localPlayer.isAuthenticated {
                print("✅ Game Center authenticated")
                loadLeaderboardData()
            } else {
                self.errorMessage = "Game Center authentication failed"
                self.isLoading = false
            }
        }
    }

    // MARK: - Load Leaderboard
    func loadLeaderboardData() {
        let leaderboard = GKLeaderboard()
        leaderboard.identifier = "keruh_leaderboard"
        leaderboard.playerScope = .global
        leaderboard.timeScope = .allTime
        leaderboard.range = NSRange(location: 1, length: 5)

        leaderboard.loadScores { scores, error in
            DispatchQueue.main.async {
                self.isLoading = false

                if let error = error {
                    self.errorMessage = "Error loading leaderboard: \(error.localizedDescription)"
                } else if let scores = scores {
                    self.entries = scores.map {
                        LeaderboardEntry(
                            playerName: $0.player.alias,
                            score: Int($0.value)
                        )
                    }
                } else {
                    self.errorMessage = "No scores found"
                }
            }
        }
    }
}
