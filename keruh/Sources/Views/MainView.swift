//
//  ContentView.swift
//  keruh
//
//  Created by Elizabeth Celine Liong on 14/07/25.
//

import SwiftUI

enum ScreenState {
    case splash
    case menu
}

struct MainView: View {
    @StateObject private var leaderboardViewModel = LeaderboardViewModel()

    @State private var currentScreen: ScreenState = .splash

    @Namespace private var heroAnimation

    var body: some View {
        ZStack {
            Color(red: 38 / 255, green: 175 / 255, blue: 225 / 255)
                .ignoresSafeArea()

            switch currentScreen {
            case .splash:
                SplashScreenView(namespace: heroAnimation)
            case .menu:
                GameView(
                    currentScreen: $currentScreen,
                    namespace: heroAnimation
                )
            }
        }
        .onAppear {
            leaderboardViewModel.authenticate()
            AudioManager.shared.playBackgroundMusic()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.spring(response: 1.0, dampingFraction: 0.9)) {
                    currentScreen = .menu
                }
            }
        }
    }
}

#Preview {
    MainView()
}
