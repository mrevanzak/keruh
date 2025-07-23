//
//  LeaderboardView.swift
//  keruh
//
//  Created by Richie Reuben Hermanto on 16/07/25.
//

import SwiftUI

struct LeaderboardView: View {
    @StateObject private var viewModel = LeaderboardViewModel()

    var body: some View {
        VStack {
            Text("Top Players")
                .font(.largeTitle)
                .bold()
                .padding()

            if viewModel.topPlayers.isEmpty {
                Text("Loading...")
                    .foregroundColor(.gray)
            } else {
                List(viewModel.topPlayers) { player in
                    HStack {
                        if let uiImage = player.playerImage {
                            Image(uiImage: uiImage)
                                .resizable()
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 40, height: 40)
                        }

                        Text("#\(player.rank)")
                            .font(.headline)
                            .frame(width: 40)

                        Text(player.playerName)
                            .font(.body)
                            .lineLimit(1)

                        Spacer()

                        Text("\(player.score)")
                            .bold()
                    }
                }

            }

            Button("Refresh Leaderboard") {
                viewModel.loadTopPlayers()
            }
            .padding()
        }
        .onAppear {
            viewModel.authenticate()
            viewModel.loadTopPlayers()
        }
    }
}
