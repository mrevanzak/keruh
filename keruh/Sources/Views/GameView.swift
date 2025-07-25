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
                    Color.black.opacity(0.6).ignoresSafeArea().transition(
                        .opacity
                    )

                    SettingsView(
                        title: "Paused",
                        showActionButtons: true,
                        onContinue: { viewModel.resumeGame() },
                        onReplay: { viewModel.resetGame() },
                        onHome: {
                            viewModel.resetToMenu()
                            currentScreen = .game
                        },
                        showCloseButton: false,
                        onClose: {}
                    )
                    .transition(.scale.combined(with: .opacity))
                }

            case .gameOver:
                ZStack {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                        .transition(.opacity)

                    GameOverView(
                        score: viewModel.gameState.score,
                        onReplay: { viewModel.resetGame() },
                        onHome: {
                            viewModel.resetToMenu()
                            currentScreen = .game
                        }
                    )
                    .transition(.scale.combined(with: .opacity))
                }
                .onAppear {
                    AudioManager.shared.playGameOverSFX()
                    GameCenterManager.shared.submitScore(
                        viewModel.gameState.score
                    )
                }
            case .settings:
                ZStack {
                    Color.black.opacity(0.6).ignoresSafeArea().transition(
                        .opacity
                    )

                    SettingsView(
                        title: "",
                        showActionButtons: false,
                        onContinue: {},
                        onReplay: {},
                        onHome: {},
                        showCloseButton: true,
                        onClose: {
                            viewModel.resetToMenu()
                            currentScreen = .game
                        }
                    )
                    .transition(.scale.combined(with: .opacity))
                }

            case .leaderboard:
                LeaderboardPopUpView(
                    onClose: {
                        viewModel.resetToMenu()
                        currentScreen = .game
                    }
                )
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
    @ObservedObject var tutorialManager: TutorialManager
    @ObservedObject var viewModel: GameViewModel

    @State private var showPlayText = false

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
                    Button {
                        viewModel.gameState.playState = .leaderboard
                    } label: {
                        MenuButton(icon: "medal.fill", size: 50, padding: 10)
                    }
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
            }
            .padding(.trailing, 20)
            .padding(.top, 20)
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
            .font(.paperInko(size: 80))
            .fontWeight(.bold)
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
    private let animatedText = Array("Ketuk untuk bermain")

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<animatedText.count, id: \.self) { index in
                Text(String(animatedText[index]))
                    .font(.figtree(size: 16))
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

                    if viewModel.shieldTimeRemaining > 0 {
                        PowerUpTimerView(
                            iconName: "icon_active power up_slow down",
                            progress: viewModel.shieldTimeRemaining
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
        GameOverlayContentView(
            titleImage: "title_gameover",
            mainContent: {
                VStack(spacing: 16) {
                    (Text("\(score) G\n")
                        .font(.paperInko(size: 36))
                        .fontWeight(.bold)
                        .foregroundColor(
                            Color(
                                red: 51 / 255,
                                green: 178 / 255,
                                blue: 199 / 255
                            )
                        )
                        + Text("SAMPAH LENYAP.\nDAN ITU,\nKARENA KAMU!")
                        .font(.paperInko(size: 28))
                        .fontWeight(.black)
                        .foregroundColor(.black))
                        .multilineTextAlignment(.center)

                    Text(
                        "KALAU SEMUA ORANG KAYAK KAMU,\nBUMI BISA LEGA NAPASNYA!"
                    )
                    .font(.paperInko(size: 14))
                    .multilineTextAlignment(.center)
                    .foregroundColor(
                        Color(red: 51 / 255, green: 178 / 255, blue: 199 / 255)
                    )
                }
            },
            actionContent: {
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
                }
            }
        )
    }
}

// MARK: - Game Stats View
private struct GameStatsView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ZStack {
                Image("icon_score view")
                    .resizable()
                    .scaledToFit()

                HStack {
                    Text("Berat")
                        .font(.paperInko(size: 18))
                        .foregroundColor(
                            Color(
                                red: 199 / 255,
                                green: 255 / 255,
                                blue: 255 / 255
                            )
                        )
                        .shadow(
                            color: .black.opacity(0.4),
                            radius: 2,
                            x: 1,
                            y: 1
                        )

                    Text("\(viewModel.scoreText) g")
                        .font(.paperInko(size: 24))
                        .foregroundColor(.white)
                        .shadow(
                            color: .black.opacity(0.4),
                            radius: 2,
                            x: 1,
                            y: 1
                        )
                        .padding(.leading, 8)
                    Spacer()
                }
                .padding(.top, 8)
                .padding(.leading, 48)
                .padding(.trailing, 18)
            }.frame(maxWidth: 250)

            HStack(spacing: 2) {
                let red = viewModel.healthText - viewModel.extraLive
                ForEach(0..<red, id: \.self) { _ in
                    Image("icon_live")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                        .transition(.scale)
                }
                ForEach(0..<viewModel.extraLive, id: \.self) { _ in
                    Image("power_extralive")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                        .transition(.scale)
                }
            }
        }
        .animation(.spring(), value: viewModel.healthText)
    }
}

// MARK: - Settings View
private struct SettingsView: View {
    let title: String
    let showActionButtons: Bool
    let onContinue: () -> Void
    let onReplay: () -> Void
    let onHome: () -> Void
    let showCloseButton: Bool
    let onClose: () -> Void

    @ObservedObject var settings = SettingsManager.shared

    var body: some View {
        GameOverlayContentView(
            showCloseButton: showCloseButton,
            onClose: onClose,
            titleImage: "title_\(title.lowercased())",
            mainContent: {
                GeometryReader { geo in
                    let isLargeScreen = geo.size.width > 800
                    let scaleFactor = isLargeScreen ? 1.2 : 1.0
                    let fontSize = 25 * scaleFactor
                    let gridSpacing = 12 * scaleFactor

                    VStack(spacing: 20 * scaleFactor) {
                        Text(title)
                            .font(.paperInko(size: 48))
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .padding(.bottom)

                        Grid(
                            horizontalSpacing: gridSpacing,
                            verticalSpacing: gridSpacing
                        ) {
                            GridRow {
                                Text("Musik")
                                    .gridColumnAlignment(.leading)
                                    .font(
                                        .paperInko(size: fontSize)
                                    )
                                    .lineLimit(1)
                                    .fixedSize(
                                        horizontal: true,
                                        vertical: false
                                    )
                                    .foregroundColor(.black)
                                Toggle(
                                    "",
                                    isOn: $settings.bgmEnabled
                                )
                                .labelsHidden()
                                .toggleStyle(
                                    WhiteBlueToggleStyle(
                                        scaleFactor: scaleFactor
                                    )
                                )
                            }
                            GridRow {
                                Text("SFX")
                                    .font(
                                        .paperInko(size: fontSize)
                                    )
                                    .lineLimit(1)
                                    .fixedSize(
                                        horizontal: true,
                                        vertical: false
                                    )
                                    .foregroundColor(.black)
                                Toggle(
                                    "",
                                    isOn: $settings.soundEnabled
                                )
                                .labelsHidden()
                                .toggleStyle(
                                    WhiteBlueToggleStyle(
                                        scaleFactor: scaleFactor
                                    )
                                )
                            }
                            GridRow {
                                Text("Getar")
                                    .font(
                                        .paperInko(size: fontSize)
                                    )
                                    .lineLimit(1)
                                    .fixedSize(
                                        horizontal: true,
                                        vertical: false
                                    )
                                    .foregroundColor(.black)
                                Toggle(
                                    "",
                                    isOn: $settings.hapticsEnabled
                                )
                                .labelsHidden()
                                .toggleStyle(
                                    WhiteBlueToggleStyle(
                                        scaleFactor: scaleFactor
                                    )
                                )
                            }
                        }
                        .padding(.horizontal, 30 * scaleFactor)
                    }
                    .frame(height: geo.size.height)
                }
            },
            actionContent: {
                GeometryReader { geo in
                    let isLargeScreen = geo.size.width > 800
                    let scaleFactor = isLargeScreen ? 1.2 : 1.0

                    if showActionButtons {
                        HStack(spacing: 25 * scaleFactor) {
                            Spacer()
                            Button(action: onReplay) {
                                MenuButton(
                                    icon: "arrow.counterclockwise",
                                    size: 50 * scaleFactor,
                                    padding: 10 * scaleFactor
                                )
                            }
                            Button(action: onContinue) {
                                MenuButton(
                                    icon: "play.fill",
                                    size: 50 * scaleFactor,
                                    padding: 13 * scaleFactor
                                )
                            }
                            Button(action: onHome) {
                                MenuButton(
                                    icon: "house.fill",
                                    size: 50 * scaleFactor,
                                    padding: 10 * scaleFactor
                                )
                            }
                            Spacer()
                        }

                    } else {
                        Spacer().frame(height: 60)
                    }
                }
                .frame(height: 60)
            }
        )
    }
}

struct WhiteBlueToggleStyle: ToggleStyle {
    let scaleFactor: CGFloat

    init(scaleFactor: CGFloat = 1.0) {
        self.scaleFactor = scaleFactor
    }

    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label

            Spacer()

            ZStack {
                // Background track
                RoundedRectangle(cornerRadius: 16 * scaleFactor)
                    .fill(
                        configuration.isOn
                            ? Color.white : Color.white.opacity(0.3)
                    )
                    .frame(width: 50 * scaleFactor, height: 30 * scaleFactor)

                // Circle knob
                Circle()
                    .fill(
                        configuration.isOn ? Color.toggleBlue : Color.gray
                    )
                    .frame(width: 24 * scaleFactor, height: 24 * scaleFactor)
                    .offset(
                        x: configuration.isOn
                            ? 10 * scaleFactor : -10 * scaleFactor
                    )
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
                currentScreen: .constant(.game),
                namespace: namespace
            )
        }
    }

    return MenuPreview()
}
