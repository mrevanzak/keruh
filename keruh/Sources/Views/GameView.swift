//
//  GameView.swift
//  keruh
//
//  Created by Revanza Kurniawan on 11/07/25.
//

import SpriteKit
import SwiftUI

struct GameView: View {
    @StateObject private var viewModel = GameViewModel()

    var body: some View {
        GeometryReader { geometry in
            GameSceneView(viewModel: viewModel)
                .ignoresSafeArea()
                .onAppear {
                    viewModel.setupGame(
                        screenSize: geometry.size,
                        safeAreaInsets: UIEdgeInsets(
                            top: geometry.safeAreaInsets.top,
                            left: geometry.safeAreaInsets.leading,
                            bottom: geometry.safeAreaInsets.bottom,
                            right: geometry.safeAreaInsets.trailing
                        )
                    )
                }
        }
        .overlay(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.scoreText)
                    .foregroundColor(.white)
                    .padding(.horizontal)
                    .font(.headline)
                Text(viewModel.missedText)
                    .foregroundColor(.white)
                    .padding(.horizontal)
                    .font(.subheadline)
            }
            .padding(.top, 20)
        }
    }
}

#Preview {
    GameView()
}
