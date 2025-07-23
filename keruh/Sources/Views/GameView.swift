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
                    viewModel: viewModel,
                    namespace: namespace,
                )
            case .playing:
                GameOverlayView(
                    viewModel: viewModel,
                    tutorialManager: tutorialManager
                )

            case .paused:
                ZStack {
                    GameOverlayView(
                        viewModel: viewModel,
                        tutorialManager: tutorialManager
                    )

                    PauseView(
                        onContinue: {
                            viewModel.resumeGame()
                        },
                        onReplay: {
                            viewModel.resetGame()
                        }
                    )
                }

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
            case .settings:
                ZStack {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                        .transition(.opacity)

                    SettingsView(
                        onReplay: {
                            viewModel.resetGame()
                        },
                        onHome: {
                            viewModel.resetToMenu()
                            currentScreen = .menu
                        },
                        onPlay: {
                            viewModel.resumeGame()
                        },
                        viewModel: viewModel
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            }

            TutorialOverlayView(tutorialManager: tutorialManager)
        }
        .onTapGesture {
            if viewModel.gameState.playState == .menu {
                viewModel.startGameplay()
            }
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
    @ObservedObject var viewModel: GameViewModel

    let namespace: Namespace.ID

    var body: some View {
        ZStack {
            VStack {
                Spacer()

                // Title
                GameTitleView(namespace: namespace)

                // Animated Play Text
                AnimatedPlayText(isVisible: showPlayText)
            }
            .padding(.vertical, 72)
            .onAppear {
                setupPlayTextAnimation()
            }
        }
        VStack {
            HStack {
                Spacer()
                VStack {
                    MenuButton(icon: "medal.fill", size: 50, padding: 10)
                    Button {
                        viewModel.gameState.playState = .settings
                    } label: {
                        MenuButton(
                            icon: "gearshape.fill",
                            size: 50,
                            padding: 10
                        )
                    }
                    Button {
                        tutorialManager.startTutorial()
                    } label: {
                        MenuButton(
                            icon: "questionmark.circle.fill",
                            size: 50,
                            padding: 10
                        )
                    }
                }
            }.padding(.trailing, 20)
            Spacer()
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

// MARK: - Power-Up Timer View
private struct PowerUpTimerView: View {
    let iconName: String
    let progress: Double

    var body: some View {
        ZStack {
            Image(iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .shadow(color: .black.opacity(0.6), radius: 5, x: 8, y: 0)

            Circle()
                .trim(from: 0.0, to: CGFloat(progress))
                .stroke(
                    Color.white,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear, value: progress)
                .frame(width: 38, height: 38)

        }
        .frame(width: 50, height: 50)
    }
}

// MARK: - Game Overlay View
private struct GameOverlayView: View {
    @ObservedObject var viewModel: GameViewModel
    @ObservedObject var tutorialManager: TutorialManager

    var body: some View {
        VStack {
            HStack(alignment: .top) {
                GameStatsView(viewModel: viewModel)
                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    Button(action: viewModel.pauseGame) {
                        MenuButton(
                            icon: "pause.fill",
                            size: 50,
                            padding: 12
                        )
                    }

                    if viewModel.doublePointTimeRemaining > 0 {
                        PowerUpTimerView(
                            iconName: "icon_active power up_double point",
                            progress: viewModel.doublePointTimeRemaining
                        )
                        .transition(.scale.combined(with: .opacity))
                    }

                    if viewModel.slowMotionTimeRemaining > 0 {
                        PowerUpTimerView(
                            iconName: "icon_active power up_slow down",
                            progress: viewModel.slowMotionTimeRemaining
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 20)
            Spacer()
        }
        .animation(
            .spring(response: 0.4, dampingFraction: 0.8),
            value: viewModel.doublePointTimeRemaining > 0
        )
        .animation(
            .spring(response: 0.4, dampingFraction: 0.8),
            value: viewModel.slowMotionTimeRemaining > 0
        )
    }
}

// MARK: - Game Over View
private struct GameOverView: View {
    let score: Int
    let onReplay: () -> Void
    let onHome: () -> Void

    var body: some View {
        ZStack {
            Image("bg_game_over")
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
                            Image("icon_replay")
                                .resizable()
                                .frame(width: 88, height: 88)
                        }

                        Button(action: onHome) {
                            Image("icon_home")
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
    }
}

private struct MenuButton: View {
    let icon: String
    let size: CGFloat
    let padding: CGFloat

    var body: some View {
        ZStack {
            Image("icon_kotak")
                .resizable()
                .scaledToFill()
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .padding(padding)
                .foregroundStyle(Color.white)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Settings View
private struct SettingsView: View {
    let onReplay: () -> Void
    let onHome: () -> Void
    let onPlay: () -> Void
    @ObservedObject var viewModel: GameViewModel
    @ObservedObject var settings = SettingsManager.shared

    var body: some View {
        ZStack {
            Image("bg_game_over")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 480)

            GeometryReader { geo in
                let imageHeight = geo.size.height
                let buttonTopPadding = imageHeight * 0.77
                let buttonBottomPadding = imageHeight * 0.17

                Grid(horizontalSpacing: 16, verticalSpacing: 16) {
                    GridRow {
                        Text("Musik")
                            .gridColumnAlignment(.leading)
                            .font(.custom("PaperInko", size: 28))
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                        Toggle("", isOn: $settings.bgmEnabled).labelsHidden()
                    }
                    GridRow {
                        Text("SFX")
                            .font(.custom("PaperInko", size: 28))
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                        Toggle("", isOn: $settings.soundEnabled).labelsHidden()
                    }
                    GridRow {
                        Text("Getar")
                            .font(.custom("PaperInko", size: 28))
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                        Toggle("", isOn: $settings.hapticsEnabled)
                            .labelsHidden()
                    }
                }
                .frame(width: geo.size.width / 2).labelsHidden()
                .toggleStyle(WhiteBlueToggleStyle())
                .frame(width: geo.size.width, height: geo.size.height * 1.1)

                VStack {
                    HStack(spacing: 0) {
                        Spacer()
                        Button(action: onHome) {
                            MenuButton(
                                icon: "xmark",
                                size: 50,
                                padding: 10
                            )
                        }
                    }
                }
                .padding(.top, buttonBottomPadding)
                .padding(.horizontal, 10)
                .frame(width: geo.size.width)

                if viewModel.gameState.playState == .playing {
                    VStack {
                        HStack(spacing: 8) {
                            Button(action: onReplay) {
                                MenuButton(
                                    icon: "arrow.counterclockwise",
                                    size: 70,
                                    padding: 10
                                )
                            }

                            Button(action: onHome) {
                                MenuButton(
                                    icon: "house.fill",
                                    size: 70,
                                    padding: 10
                                )
                            }

                            Button(action: onPlay) {
                                MenuButton(
                                    icon: "play.fill",
                                    size: 70,
                                    padding: 15
                                )
                            }
                        }
                    }
                    .padding(.top, buttonTopPadding)
                    .frame(width: geo.size.width)
                }
            }
        }
        .padding(.horizontal, 16)
        .ignoresSafeArea(.all)
    }
}

// MARK: - Pause View
private struct PauseView: View {
    let onContinue: () -> Void
    let onReplay: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .transition(.opacity)

            VStack(spacing: 25) {
                Text("Paused")
                    .font(.custom("PaperInko", size: 48))
                    .foregroundColor(.white)

                HStack(spacing: 30) {
                    Button(action: onReplay) {
                        MenuButton(
                            icon: "arrow.counterclockwise",
                            size: 64,
                            padding: 14
                        )
                    }

                    Button(action: onContinue) {
                        MenuButton(
                            icon: "play.fill",
                            size: 64,
                            padding: 14
                        )
                    }
                }
            }
        }
    }
}

struct WhiteBlueToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label

            Spacer()

            ZStack {
                // Background track
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        configuration.isOn
                            ? Color.white : Color.white.opacity(0.3)
                    )
                    .frame(width: 50, height: 30)

                // Circle knob
                Circle()
                    .fill(
                        configuration.isOn ? Color.toggleBlue : Color.gray
                    )
                    .frame(width: 24, height: 24)
                    .offset(x: configuration.isOn ? 10 : -10)
                    .animation(
                        .easeInOut(duration: 0.2),
                        value: configuration.isOn
                    )
            }
            .onTapGesture {
                configuration.isOn.toggle()
            }
        }
    }
}

extension Color {
    static let toggleBlue = Color(
        red: 0.21568627450980393,
        green: 0.6941176470588235,
        blue: 0.7803921568627451
    )
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
