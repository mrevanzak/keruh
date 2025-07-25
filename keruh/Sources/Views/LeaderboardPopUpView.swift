//
//  LeaderboardPopUpView.swift
//  keruh
//
//  Created by Richie Reuben Hermanto on 22/07/25.
//

import GameKit
import SwiftUI

struct LeaderboardPopUpView: View {
    @StateObject private var viewModel = LeaderboardViewModel()

    let onClose: () -> Void
    let currentID = GameCenterManager.shared.currentPlayerID

    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height
            let baseWidth: CGFloat = 414
            let baseHeight: CGFloat = 896
            let widthScale = screenWidth / baseWidth
            let heightScale = screenHeight / baseHeight
            let scale = min(max(min(widthScale, heightScale), 0.8), 1.0)

            ZStack {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .transition(.opacity)

                ZStack {
                    Image("bg_leaderboard")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 400 * scale)
                        .cornerRadius(20 * scale)
                        .overlay(
                            VStack(spacing: 8 * scale) {
                                if viewModel.isLoading {
                                    Text("Loading...")
                                        .foregroundColor(
                                            Color(
                                                red: 26 / 255,
                                                green: 134 / 255,
                                                blue: 153 / 255
                                            )
                                        )
                                        .font(.figtree(size: 17 * scale))
                                        .offset(x: 20 * scale)
                                } else if viewModel.topPlayers.isEmpty {
                                    Text("Jadilah yang pertama bermain!")
                                        .foregroundColor(
                                            Color(
                                                red: 26 / 255,
                                                green: 134 / 255,
                                                blue: 153 / 255
                                            )
                                        )
                                        .font(.figtree(size: 17 * scale))
                                        .offset(x: 20 * scale)
                                } else {
                                    HStack(
                                        alignment: .bottom,
                                        spacing: max(-85 * scale, -75)
                                    ) {
                                        if viewModel.topPlayers.count >= 2 {
                                            LeaderboardTopThreeView(
                                                rank: viewModel.topPlayers[1]
                                                    .rank,
                                                name: displayName(
                                                    for: viewModel.topPlayers[1]
                                                ),
                                                score: viewModel.topPlayers[1]
                                                    .score,
                                                image: viewModel.topPlayers[1]
                                                    .playerImage
                                            )
                                            .scaleEffect(0.65 * scale)
                                            .offset(y: 10 * scale)
                                        }

                                        if viewModel.topPlayers.count >= 1 {
                                            LeaderboardTopThreeView(
                                                rank: viewModel.topPlayers[0]
                                                    .rank,
                                                name: displayName(
                                                    for: viewModel.topPlayers[0]
                                                ),
                                                score: viewModel.topPlayers[0]
                                                    .score,
                                                image: viewModel.topPlayers[0]
                                                    .playerImage
                                            )
                                            .scaleEffect(0.75 * scale)
                                            .offset(y: 0)
                                        }

                                        if viewModel.topPlayers.count >= 3 {
                                            LeaderboardTopThreeView(
                                                rank: viewModel.topPlayers[2]
                                                    .rank,
                                                name: displayName(
                                                    for: viewModel.topPlayers[2]
                                                ),
                                                score: viewModel.topPlayers[2]
                                                    .score,
                                                image: viewModel.topPlayers[2]
                                                    .playerImage
                                            )
                                            .scaleEffect(0.65 * scale)
                                            .offset(y: 10 * scale)
                                        }
                                    }
                                    .offset(y: -10 * scale)
                                    .offset(x: 18 * scale)

                                    let otherPlayers = viewModel.topPlayers
                                        .prefix(8).dropFirst(3)

                                    VStack(spacing: 0.3 * scale) {
                                        ForEach(otherPlayers) { player in
                                            LeaderboardRowView(
                                                rank: player.rank,
                                                name: displayName(for: player),
                                                score: player.score
                                            )
                                            .scaleEffect(0.5 * scale)
                                        }
                                    }
                                    .offset(x: 18 * scale, y: -10 * scale)
                                }
                            }
                            .onAppear {
                                viewModel.authenticate()
                                viewModel.loadTopPlayers()
                            }
                        )

                    Image("title_leaderboard 1")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 329 * scale, maxHeight: 200 * scale)
                        .cornerRadius(20 * scale)
                        .offset(y: -185 * scale)
                        .offset(x: 14 * scale)

                    Image("sampahs")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 329 * scale, maxHeight: 200 * scale)
                        .cornerRadius(20 * scale)
                        .offset(y: 230 * scale)
                        .offset(x: 18 * scale)

                    Button(action: {
                        closeLeaderboard()
                    }) {
                        MenuButton(
                            icon: "xmark",
                            size: 35 * scale,
                            padding: 9 * scale
                        )
                    }
                    .offset(x: 170 * scale)
                    .offset(y: -270 * scale)
                }
                .offset(x: -15 * scale, y: 40 * scale)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }

    private func closeLeaderboard() {
        onClose()
    }

    private func displayName(for entry: Leaderboard) -> String {
        return entry.player.gamePlayerID == currentID ? "You" : entry.playerName
    }
}

#Preview {
    LeaderboardPopUpView(onClose: {})
}
