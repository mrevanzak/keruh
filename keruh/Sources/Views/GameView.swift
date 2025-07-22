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
    @StateObject private var tutorialManager = TutorialManager()

    let namespace: Namespace.ID

    var body: some View {
        ZStack {
            // Background Game Scene
            BackgroundSceneView(viewModel: viewModel)

            switch viewModel.gameState.playState {
            case .menu:
                MenuContentView(
                    tutorialManager: tutorialManager,
                    namespace: namespace,
                ).onTapGesture {
                    viewModel.startGameplay()
                }
            case .playing, .paused:
                GameOverlayView(
                    viewModel: viewModel,
                    tutorialManager: tutorialManager
                )
            case .gameOver:
                ZStack {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                        .transition(.opacity)

                    GameOverView(
                        score: viewModel.gameState.score,
                        onReplay: {
                            viewModel.resetGame()
                        },
                        onHome: {
                            viewModel.resetToMenu()
                            currentScreen = .menu
                        }
                    )
                    .transition(.scale.combined(with: .opacity))
                }.onAppear {
                    AudioManager.shared.playGameOverSFX()
                }
            }

            TutorialOverlayView(tutorialManager: tutorialManager)
        }
        .onAppear {
            // Set up tutorial trigger when catcher spawns
            viewModel.onCatcherSpawned = {
                if tutorialManager.shouldShowTutorial() {
                    viewModel.pauseGame()
                    tutorialManager.startTutorial()
                    tutorialManager.onCompleted(
                        completion: {
                            viewModel.resumeGame()
                        }
                    )
                }
            }
        }
        .animation(
            .spring(response: 0.4, dampingFraction: 0.8),
            value: viewModel.gameState.playState
        )
    }
}

// MARK: - Menu Content View
private struct MenuContentView: View {
    @State private var showPlayText = false
    @ObservedObject var tutorialManager: TutorialManager

    let namespace: Namespace.ID

    var body: some View {
        VStack {
            Spacer()

            // Title
            GameTitleView(namespace: namespace)

            // Animated Play Text
            AnimatedPlayText(isVisible: showPlayText)

            // Tutorial button
            if showPlayText {
                Button("Show Tutorial") {
                    tutorialManager.forceStartTutorial()
                }
                .padding(.top, 20)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.vertical, 72)
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
    @ObservedObject var tutorialManager: TutorialManager

    var body: some View {
        VStack {
            HStack {
                GameStatsView(viewModel: viewModel)
                Spacer()

                // Tutorial button during gameplay
                if viewModel.gameState.playState == .playing {
                    Button("?") {
                        tutorialManager.forceStartTutorial()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(.black.opacity(0.3)))
                    .padding(.trailing)
                }
            }
            Spacer()
        }
    }
}

// MARK: - Game Over View
private struct GameOverView: View {
    let score: Int
    let onReplay: () -> Void
    let onHome: () -> Void

    var body: some View {
        ZStack {
            Image("game_over")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 480)

            GeometryReader { geo in
                let imageHeight = geo.size.height
                let buttonTopPadding = imageHeight * 0.67

                VStack(spacing: 16) {
                    (Text("\(score) KG\n")
                        .font(.custom("PaperInko", size: 36))
                        .fontWeight(.bold)
                        .foregroundColor(
                            Color(
                                red: 251 / 255,
                                green: 175 / 255,
                                blue: 23 / 255
                            )
                        )
                        + Text("SAMPAH LENYAP.\nDAN ITU,\nKARENA KAMU!")
                        .font(.custom("PaperInko", size: 28))
                        .fontWeight(.black)
                        .foregroundColor(.black))
                        .multilineTextAlignment(.center)

                    Text(
                        "KALAU SEMUA ORANG KAYAK KAMU,\nBUMI BISA LEGA NAPASNYA!"
                    )
                    .font(.custom("PaperInko", size: 14))
                    .multilineTextAlignment(.center)
                    .foregroundColor(
                        Color(red: 51 / 255, green: 178 / 255, blue: 199 / 255)
                    )
                }
                .frame(width: geo.size.width, height: geo.size.height * 1.1)

                VStack {
                    HStack(spacing: 8) {
                        Button(action: onReplay) {
                            Image("replay")
                                .resizable()
                                .frame(width: 88, height: 88)
                        }

                        Button(action: onHome) {
                            Image("home")
                                .resizable()
                                .frame(width: 88, height: 88)
                        }
                    }
                }
                .padding(.top, buttonTopPadding)
                .frame(width: geo.size.width)
            }
        }
        .padding(.horizontal, 16)
        .ignoresSafeArea(.all)
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
