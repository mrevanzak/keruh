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
                            VStack(spacing: 12) {
                                Text("Leaderboard")
                                    .font(.title2.bold())
                                    .foregroundColor(.black)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("1. Rani - 340 KG")
                                    Text("2. Budi - 320 KG")
                                    Text("3. Andi - 295 KG")
                                }
                                .font(.subheadline)
                                .foregroundColor(.black)

                                Button("Tutup") {
                                    closeLeaderboard()
                                }
                                .padding(.top, 10)
                                .font(.caption)
                                .foregroundColor(.yellow)
                            }
                            .padding()
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
