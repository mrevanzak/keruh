//
//  GameCenterView.swift
//  keruh
//
//  Created by Richie Reuben Hermanto on 16/07/25.
//

import Foundation
import SwiftUI

struct GameCenterView: View {
    @StateObject private var viewModel = LeaderboardViewModel()

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text(viewModel.isAuthenticated ? "Authenticated ✅" : "Not Authenticated ❌")
                    .font(.headline)

                Button("Submit Dummy Score") {
                    viewModel.submitDummyScore()
                }
                .disabled(!viewModel.isAuthenticated)

                Button("Show Native Leaderboard") {
                    viewModel.showLeaderboard()
                }
                .disabled(!viewModel.isAuthenticated)

                NavigationLink(destination: LeaderboardView()) {
                    Text("Show Custom Leaderboard")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(!viewModel.isAuthenticated)
                .padding(.top, 10)

                Spacer()
            }
            .padding()
            .navigationTitle("Game Center")
            .onAppear {
                viewModel.authenticate()
            }
        }
    }
}
