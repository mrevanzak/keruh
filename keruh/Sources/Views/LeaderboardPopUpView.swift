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
            let scale = min(widthScale, heightScale)

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
                                if viewModel.topPlayers.isEmpty {
                                    Text("There are no players yet. Be the first to play!")
                                        .foregroundColor(.gray)
                                        .font(.figtree(size: 16 * scale))
                                        .offset(x: 20 * scale)
                                } else {
                                    HStack(
                                        alignment: .bottom,
                                        spacing: -85 * scale
                                    ) {
                                        // Rank 2
                                        Group {
                                            if viewModel.topPlayers.count >= 2 {
                                                LeaderboardTopThreeView(
                                                    rank: viewModel.topPlayers[
                                                        1
                                                    ].rank,
                                                    name: displayName(
                                                        for:
                                                            viewModel.topPlayers[
                                                                1
                                                            ]
                                                    ),
                                                    score: viewModel.topPlayers[
                                                        1
                                                    ].score,
                                                    image: viewModel.topPlayers[
                                                        1
                                                    ].playerImage
                                                )
                                            } else {
                                                LeaderboardTopThreeView(
                                                    rank: 2,
                                                    name: "-",
                                                    score: 0
                                                )
                                            }
                                        }
                                        .scaleEffect(0.65 * scale)
                                        .offset(y: 10 * scale)

                                        // Rank 1
                                        Group {
                                            if viewModel.topPlayers.count >= 1 {
                                                LeaderboardTopThreeView(
                                                    rank: viewModel.topPlayers[
                                                        0
                                                    ].rank,
                                                    name: displayName(
                                                        for:
                                                            viewModel.topPlayers[
                                                                0
                                                            ]
                                                    ),
                                                    score: viewModel.topPlayers[
                                                        0
                                                    ].score,
                                                    image: viewModel.topPlayers[
                                                        0
                                                    ].playerImage
                                                )
                                            } else {
                                                LeaderboardTopThreeView(
                                                    rank: 1,
                                                    name: "-",
                                                    score: 0,
                                                    rankFrameImage: Image(
                                                        "rankframe_rank1"
                                                    ),
                                                    borderRankImage: Image(
                                                        "border_rank1"
                                                    ),
                                                    scoreViewImage: Image(
                                                        "score_view"
                                                    )
                                                )
                                            }
                                        }
                                        .scaleEffect(0.75 * scale)
                                        .offset(y: 0)

                                        // Rank 3
                                        Group {
                                            if viewModel.topPlayers.count >= 3 {
                                                LeaderboardTopThreeView(
                                                    rank: viewModel.topPlayers[
                                                        2
                                                    ].rank,
                                                    name: displayName(
                                                        for:
                                                            viewModel.topPlayers[
                                                                2
                                                            ]
                                                    ),
                                                    score: viewModel.topPlayers[
                                                        2
                                                    ].score,
                                                    image: viewModel.topPlayers[
                                                        2
                                                    ].playerImage
                                                )
                                            } else {
                                                LeaderboardTopThreeView(
                                                    rank: 3,
                                                    name: "-",
                                                    score: 0
                                                )
                                            }
                                        }
                                        .scaleEffect(0.65 * scale)
                                        .offset(y: 10 * scale)
                                    }
                                    .offset(y: -10 * scale)
                                    .offset(x: 18 * scale)

                                    VStack(spacing: 0.3 * scale) {
                                        ForEach(3..<8) { i in
                                            if i < viewModel.topPlayers.count {
                                                LeaderboardRowView(
                                                    rank: viewModel.topPlayers[
                                                        i
                                                    ].rank,
                                                    name: displayName(
                                                        for:
                                                            viewModel.topPlayers[
                                                                i
                                                            ]
                                                    ),
                                                    score: viewModel.topPlayers[
                                                        i
                                                    ].score
                                                )
                                                .scaleEffect(0.5 * scale)
                                            } else {
                                                LeaderboardRowView(
                                                    rank: i + 1,
                                                    name: "-",
                                                    score: 0
                                                )
                                                .scaleEffect(0.5 * scale)
                                            }
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
                        Image("button_close")
                            .resizable()
                            .frame(width: 50 * scale, height: 50 * scale)
                            .padding(20 * scale)
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
