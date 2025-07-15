//
//  MenuView.swift
//  keruh
//
//  Created by Elizabeth Celine Liong on 14/07/25.
//

import SpriteKit
import SwiftUI

struct MenuView: View {
    @Binding var currentScreen: ScreenState

    let scene: MenuScene
    let namespace: Namespace.ID

    @State private var showPlayText = false

    private let animatedText = Array("Tap to Play")

    var body: some View {
        ZStack {
            SpriteView(scene: scene)
                .ignoresSafeArea()
                .transition(.opacity)

            VStack {
                Text("KERUH")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(.white)
                    .fixedSize()
                    .matchedGeometryEffect(id: "title", in: namespace)

                Spacer()

                HStack(spacing: 0) {
                    ForEach(0..<animatedText.count, id: \.self) { index in
                        Text(String(self.animatedText[index]))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .offset(y: showPlayText ? 0 : 20)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.5)
                                    .delay(Double(index) * 0.05),
                                value: showPlayText
                            )
                    }
                }
                .opacity(showPlayText ? 1 : 0)
            }
            .padding(.vertical, 72)
        }
        .ignoresSafeArea()
        .onTapGesture {
            currentScreen = .game
        }
        .onAppear(perform: setupAnimations)
    }

    private func setupAnimations() {
        scene.buildAndAnimateMenu()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation {
                showPlayText = true
            }
        }
    }
}

#Preview {
    struct MenuPreview: View {
        @Namespace private var namespace
        let previewScene: MenuScene = {
            let scene = MenuScene()
            scene.size = UIScreen.main.bounds.size
            scene.scaleMode = .aspectFill
            return scene
        }()
        var body: some View {
            MenuView(
                currentScreen: .constant(.menu),
                scene: previewScene,
                namespace: namespace
            )
        }
    }
    return MenuPreview()
}
