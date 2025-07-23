//
//  LeaderboardPopUpView.swift
//  keruh
//
//  Created by Richie Reuben Hermanto on 22/07/25.
//

import GameKit
import SwiftUI

struct LeaderboardPopUpView: View {
    @Binding var showLeaderboard: Bool
    @State private var scale: CGFloat = 0.8
    @State private var bgOpacity: Double = 0.1
    @State private var contentOpacity: Double = 0.1
    @StateObject private var viewModel = LeaderboardViewModel()
    let currentID = GameCenterManager.shared.currentPlayerID

    
    var body: some View {
        ZStack {
            Color.black.opacity(bgOpacity)
                .ignoresSafeArea()
            
            VStack {
                ZStack {
                    Image("bg_leaderboard")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 1500, maxHeight: 1500)
                        .cornerRadius(20)
                        .overlay(
                            VStack(spacing: 8) {
                                if viewModel.topPlayers.isEmpty {
                                    Text("Loading...")
                                        .foregroundColor(.gray)
                                } else {
                                    HStack(alignment: .bottom, spacing: -63) {
                                        // Rank 2
                                        Group {
                                            if viewModel.topPlayers.count >= 2 {
                                                LeaderboardTopThreeView(
                                                    rank: viewModel.topPlayers[1].rank,
                                                    name: displayName(for: viewModel.topPlayers[1]),
                                                    score: viewModel.topPlayers[1].score,
                                                    image: viewModel.topPlayers[1].playerImage
                                                )
                                            } else {
                                                LeaderboardTopThreeView(rank: 2, name: "-", score: 0)
                                            }
                                        }
                                        .scaleEffect(0.65)
                                        .offset(y: 10)
                                        
                                        // Rank 1
                                        Group {
                                            if viewModel.topPlayers.count >= 1 {
                                                LeaderboardTopThreeView(
                                                    rank: viewModel.topPlayers[0].rank,
                                                    name: displayName(for: viewModel.topPlayers[0]),
                                                    score: viewModel.topPlayers[0].score,
                                                    image: viewModel.topPlayers[0].playerImage
                                                )
                                            } else {
                                                LeaderboardTopThreeView(rank: 1, name: "-", score: 0, rankFrameImage: Image("rankframe_rank1"), borderRankImage: Image("border_rank1"), scoreViewImage: Image("score_view"))
                                            }
                                        }
                                        .scaleEffect(0.75)
                                        .offset(y: 0)
                                        
                                        // Rank 3
                                        Group {
                                            if viewModel.topPlayers.count >= 3 {
                                                LeaderboardTopThreeView(
                                                    rank: viewModel.topPlayers[2].rank,
                                                    name: displayName(for: viewModel.topPlayers[2]),
                                                    score: viewModel.topPlayers[2].score,
                                                    image: viewModel.topPlayers[2].playerImage
                                                )
                                            } else {
                                                LeaderboardTopThreeView(rank: 3, name: "-", score: 0)
                                            }
                                        }
                                        .scaleEffect(0.65)
                                        .offset(y: 10)
                                    }
                                    .offset(y: -10)
                                    .offset(x: 18)
                                    
                                    
                                    VStack(spacing: 0.3) {
                                        ForEach(3..<8) { i in
                                            if i < viewModel.topPlayers.count {
                                                LeaderboardRowView(
                                                    rank: viewModel.topPlayers[i].rank,
                                                    name: displayName(for: viewModel.topPlayers[i]),
                                                    score: viewModel.topPlayers[i].score
                                                )
                                                .scaleEffect(0.5)
                                            } else {
                                                LeaderboardRowView(rank: i + 1, name: "-", score: 0)
                                                    .scaleEffect(0.5)
                                            }
                                        }
                                    }
                                    .offset(x:18, y: -10)
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
                        .frame(maxWidth: 329, maxHeight: 200)
                        .cornerRadius(20)
                        .offset(y: -185)
                        .offset(x: 14)
                    Image("sampahs")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 329, maxHeight: 200)
                        .cornerRadius(20)
                        .offset(y: 230)
                        .offset(x: 18)
                    Button(action: {
                        closeLeaderboard()
                    }) {
                        Image("button_close")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .padding(20)
                    }
                    .offset(x: 170)
                    .offset(y: -270)
                    
                }
                .offset(x: -15, y: 40)
                .scaleEffect(scale)
                .opacity(contentOpacity)
                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: scale)
                .animation(.easeInOut(duration: 0.3), value: contentOpacity)
            }
            
        }
        .onAppear {
            withAnimation {
                scale = 1.0
                bgOpacity = 0.45
                contentOpacity = 1.0
            }
        }
    }
    
    private func closeLeaderboard() {
        withAnimation {
            scale = 0.8
            bgOpacity = 0.0
            contentOpacity = 0.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            showLeaderboard = false
        }
    }
    
    private func displayName(for entry: Leaderboard) -> String {
        return entry.player.gamePlayerID == currentID ? "You" : entry.playerName
    }
}

#Preview {
    LeaderboardPopUpView(showLeaderboard: .constant(true))
}
