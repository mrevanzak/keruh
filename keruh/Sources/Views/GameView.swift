//
//  GameView.swift
//  keruh
//
//  Created by Elizabeth Celine Liong on 14/07/25.
//

import SpriteKit
import SwiftUI

struct GameView: View {
    @Binding var currentScreen: ScreenState
    @StateObject private var viewModel = GameViewModel()

    let namespace: Namespace.ID

    var body: some View {
        ZStack {
            // Background Game Scene
            BackgroundSceneView(viewModel: viewModel)

            // Menu Content
            if viewModel.gameState.playState == .menu {
                MenuContentView(
                    onStartGame: {
                        print("startGameplay")
                        viewModel.startGameplay()
                    },
                    namespace: namespace
                )
            } else {
                GameOverlayView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Menu Content View
private struct MenuContentView: View {
    let onStartGame: () -> Void
    @State private var showPlayText = false

    let namespace: Namespace.ID

    var body: some View {
        VStack {
            Spacer()

            // Title
            GameTitleView(namespace: namespace)

            // Animated Play Text
            AnimatedPlayText(isVisible: showPlayText)
        }
        .padding(.vertical, 72)
        .onTapGesture {
            onStartGame()
        }
        .onAppear {
            setupPlayTextAnimation()
        }
    }

    private func setupPlayTextAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showPlayText = true
            }
        }
    }
}

// MARK: - Game Title View
private struct GameTitleView: View {
    let namespace: Namespace.ID

    var body: some View {
        Text("KERUH")
            .font(.system(size: 80, weight: .bold))
            .padding(.vertical, 24)
            .foregroundColor(.white)
            .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 2)
            .fixedSize()
            .matchedGeometryEffect(id: "title", in: namespace)
    }
}

// MARK: - Animated Play Text
private struct AnimatedPlayText: View {
    let isVisible: Bool
    private let animatedText = Array("Tap to Play")

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<animatedText.count, id: \.self) { index in
                Text(String(animatedText[index]))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .offset(y: isVisible ? 0 : 20)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.5)
                            .delay(Double(index) * 0.05),
                        value: isVisible
                    )
            }
        }
        .opacity(isVisible ? 1 : 0)
    }
}

private struct BackgroundSceneView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        GeometryReader { geometry in
            GameSceneView(viewModel: viewModel)
                .onAppear {
                    setupGameScene(with: geometry)
                }
                .transition(.opacity)
        }
        .ignoresSafeArea()
    }

    private func setupGameScene(with geometry: GeometryProxy) {
        viewModel.setupGame(
            screenSize: geometry.size,
            safeAreaInsets: UIEdgeInsets(
                top: geometry.safeAreaInsets.top,
                left: geometry.safeAreaInsets.leading,
                bottom: geometry.safeAreaInsets.bottom,
                right: geometry.safeAreaInsets.trailing
            )
        )
        viewModel.setupScene()
    }
}

// MARK: - Game Overlay View
private struct GameOverlayView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        VStack {
            HStack {
                GameStatsView(viewModel: viewModel)
                Spacer()
            }
            Spacer()
        }
    }
}

// MARK: - Game Stats View
private struct GameStatsView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.scoreText)
                .foregroundColor(.white)
                .font(.headline)

            Text(viewModel.healthText)
                .foregroundColor(.white)
                .font(.subheadline)
        }
        .padding(.horizontal)
        .padding(.top, 20)
    }
}

// MARK: - Preview
#Preview {
    struct MenuPreview: View {
        @Namespace private var namespace

        var body: some View {
            GameView(
                currentScreen: .constant(.menu),
                namespace: namespace
            )
        }
    }

    return MenuPreview()
}
