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
    case game
}

struct MainView: View {
    @State private var currentScreen: ScreenState = .splash
    
    @Namespace private var heroAnimation
    
    @State private var menuScene: MenuScene = {
        let scene = MenuScene()
        scene.size = UIScreen.main.bounds.size
        scene.scaleMode = .aspectFill
        return scene
    }()

    var body: some View {
        ZStack {
            switch currentScreen {
            case .splash:
                SplashScreenView(namespace: heroAnimation)
            case .menu:
                MenuView(currentScreen: $currentScreen, scene: menuScene, namespace: heroAnimation)
            case .game:
                GameView()
            }
        }
        .onAppear {
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
