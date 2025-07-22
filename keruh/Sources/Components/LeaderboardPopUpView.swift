//
//  LeaderboardPopUpView.swift
//  keruh
//
//  Created by Richie Reuben Hermanto on 22/07/25.
//

import SwiftUI

struct LeaderboardPopUpView: View {
    @Binding var showLeaderboard: Bool
    @State private var scale: CGFloat = 0.8
    @State private var bgOpacity: Double = 0.1
    @State private var contentOpacity: Double = 0.1
    @StateObject private var viewModel = LeaderboardViewModel()
    
    var body: some View {
        ZStack {
            Color.black.opacity(bgOpacity)
                .ignoresSafeArea()
                .onTapGesture {
                    closeLeaderboard()
                }
            
            VStack {
                ZStack {
                    Image("Bg_full")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 1500, maxHeight: 1500)
                        .cornerRadius(20)
                        .overlay(
                            VStack(spacing: 16) {
                                if viewModel.topPlayers.isEmpty {
                                    Text("Loading...")
                                        .foregroundColor(.gray)
                                } else {
                                    VStack(spacing: 0.3) {
                                        ForEach(viewModel.topPlayers.prefix(3)) { player in
                                            LeaderboardRowView(
                                                rank: player.rank,
                                                name: player.playerName,
                                                score: player.score
                                            )
                                            .scaleEffect(0.5)
                                        }
                                    }
                                    .offset(x:10)
                                    
                                }
                                
                                Button("Refresh Leaderboard") {
                                    viewModel.loadTopPlayers()
                                }
                                .padding(.bottom)
                            }
                                .onAppear {
                                    viewModel.authenticate()
                                    viewModel.loadTopPlayers()
                                }
                        )
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
}

#Preview {
    LeaderboardPopUpView(showLeaderboard: .constant(true))
}
