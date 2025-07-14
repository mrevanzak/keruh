//
//  GameView.swift
//  keruh
//
//  Created by Revanza Kurniawan on 11/07/25.
//

import SpriteKit
import SwiftUI

// MARK: - SwiftUI Wrapper
struct GameSceneView: UIViewRepresentable {
  let scene: SKScene

  func makeUIView(context: Context) -> SKView {
    let view = SKView()
    view.backgroundColor = .clear
    view.allowsTransparency = true
    view.presentScene(scene)
    return view
  }

  func updateUIView(_ uiView: SKView, context: Context) {
    // Update if needed
  }
}

struct GameView: View {
  var body: some View {
    GeometryReader { geometry in
      let gameScene = GameScene()

      GameSceneView(scene: gameScene)
        .ignoresSafeArea()
        .onAppear {
          gameScene.size = geometry.size
          gameScene.scaleMode = .aspectFill
          gameScene.setSafeAreaInsets(
            UIEdgeInsets(
              top: geometry.safeAreaInsets.top,
              left: geometry.safeAreaInsets.leading,
              bottom: geometry.safeAreaInsets.bottom,
              right: geometry.safeAreaInsets.trailing
            )
          )
        }
        .onChange(of: geometry.size) { _, newSize in
          gameScene.size = newSize
        }
    }
  }
}

#Preview {
  GameView()
}
