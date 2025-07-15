//
//  GameSceneView.swift
//  keruh
//
//  Created by Farrell Matthew Lim on 14/07/25.
//

import SpriteKit
import SwiftUI

class GameScene: SKScene {
    var viewModel: GameViewModel?

    override func didMove(to view: SKView) {
        guard let viewModel = viewModel else { return }
        viewModel.setupGame(
            screenSize: size,
            safeAreaInsets: view.safeAreaInsets
        )

        // Add game nodes to the scene
        addChild(viewModel.getCatcherNode())

        // Add any initial falling objects
        for node in viewModel.getNewFallingObjectNodes() {
            addChild(node.node)
        }
    }

    override func update(_ currentTime: TimeInterval) {
        viewModel?.checkCollisions()
        
        // Add new falling objects that were spawned since last update
        guard let viewModel = viewModel else { return }
        for node in viewModel.getNewFallingObjectNodes() {
            addChild(node.node)
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location = touches.first?.location(in: self) else { return }
        viewModel?.touchesBegan(at: location)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location = touches.first?.location(in: self) else { return }
        viewModel?.touchesMoved(to: location)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        viewModel?.touchesEnded()
    }

    override func touchesCancelled(
        _ touches: Set<UITouch>,
        with event: UIEvent?
    ) {
        viewModel?.touchesCancelled()
    }
}

struct GameSceneView: UIViewRepresentable {
    let viewModel: GameViewModel

    func makeUIView(context: Context) -> SKView {
        let skView = SKView()
        skView.backgroundColor = .clear
        skView.allowsTransparency = true

        let scene = GameScene()
        scene.size = UIScreen.main.bounds.size
        scene.scaleMode = .aspectFill
        scene.viewModel = viewModel

        skView.presentScene(scene)
        return skView
    }

    func updateUIView(_ uiView: SKView, context: Context) {
        // optional: update scene data if needed
    }
}
