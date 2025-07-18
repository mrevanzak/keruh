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
            switch currentScreen {
            case .splash:
                SplashScreenView(namespace: heroAnimation)
            case .menu:
                GameView(currentScreen: $currentScreen, namespace: heroAnimation)
            }
        }
        .onAppear {
            leaderboardViewModel.authenticate()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.spring(response: 1.0, dampingFraction: 0.8)) {
                    currentScreen = .menu
                }
            }
        }
    }
}

#Preview {
    MainView()
}
