//
//  GameSceneView.swift
//  keruh
//
//  Created by Farrell Matthew Lim on 14/07/25.
//

import SpriteKit
import SwiftUI

class GameScene: SKScene, SKPhysicsContactDelegate {
    var viewModel: GameViewModel?

    // Debug visualization
    var debugShapes: [SKShapeNode] = []
    var showDebugPhysics = false  // Toggle this for debugging

    override func didMove(to view: SKView) {
        guard let viewModel = viewModel else { return }
        viewModel.setupGame(
            screenSize: size,
            safeAreaInsets: view.safeAreaInsets
        )

        backgroundColor = SKColor(
            red: 38 / 255,
            green: 175 / 255,
            blue: 225 / 255,
            alpha: 1.0
        )

        // Set up physics world and contact delegate
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)  // No gravity since we control movement

        // Add scene nodes to the scene
        addChild(viewModel.sceneNodes.sky)
        addChild(viewModel.sceneNodes.river)
        addChild(viewModel.sceneNodes.leftIsland)
        addChild(viewModel.sceneNodes.rightIsland)
        addChild(viewModel.sceneNodes.clouds)
        addChild(viewModel.sceneNodes.waves)

        // Add game nodes to the scene
        addChild(viewModel.getCatcherNode())

        // Add any initial falling objects
        addNewFallingObjects()

        // Enable physics debug view (remove in production)
        if showDebugPhysics {
            view.showsPhysics = true
            view.showsFPS = true
            view.showsNodeCount = true
        }
    }

    // MARK: - Physics Contact Delegate
    func didBegin(_ contact: SKPhysicsContact) {
        let firstBody = contact.bodyA
        let secondBody = contact.bodyB

        var catcherBody: SKPhysicsBody?
        var objectBody: SKPhysicsBody?

        if firstBody.categoryBitMask == PhysicsCategory.catcher {
            catcherBody = firstBody
            objectBody = secondBody
        } else if secondBody.categoryBitMask == PhysicsCategory.catcher {
            catcherBody = secondBody
            objectBody = firstBody
        }

        guard catcherBody != nil, let objectNode = objectBody?.node else {
            return
        }

        // Find the falling object ID and handle the catch
        if let objectId = viewModel?.getObjectId(for: objectNode) {
            viewModel?.handleObjectCaught(objectId)
        }
    }

    // MARK: - Debug Visualization
    func drawDebugCollisionZones() {
        // Clear previous debug shapes
        debugShapes.forEach { $0.removeFromParent() }
        debugShapes.removeAll()

        guard let viewModel = viewModel, showDebugPhysics else { return }

        // Draw catcher collision zone
        let catcherFrame = createDebugCatcherFrame()
        let catcherDebugShape = SKShapeNode(rect: catcherFrame)
        catcherDebugShape.strokeColor = .green
        catcherDebugShape.fillColor = .green.withAlphaComponent(0.3)
        catcherDebugShape.lineWidth = 2
        catcherDebugShape.zPosition = 1000
        addChild(catcherDebugShape)
        debugShapes.append(catcherDebugShape)

        // Draw the actual collision zone used in manual detection
        let manualCatchZone = createManualCatchZone()
        let manualZoneShape = SKShapeNode(rect: manualCatchZone)
        manualZoneShape.strokeColor = .red
        manualZoneShape.fillColor = .red.withAlphaComponent(0.3)
        manualZoneShape.lineWidth = 2
        manualZoneShape.zPosition = 1001
        addChild(manualZoneShape)
        debugShapes.append(manualZoneShape)

        // Draw falling object frames
        for fallingObject in viewModel.getFallingObjectNodes() {
            let objectFrame = CGRect(
                x: fallingObject.node.position.x - fallingObject.size.width / 2,
                y: fallingObject.node.position.y - fallingObject.size.height
                    / 2,
                width: fallingObject.size.width,
                height: fallingObject.size.height
            )
            let objectShape = SKShapeNode(rect: objectFrame)
            objectShape.strokeColor = .blue
            objectShape.fillColor = .blue.withAlphaComponent(0.2)
            objectShape.lineWidth = 1
            objectShape.zPosition = 999
            addChild(objectShape)
            debugShapes.append(objectShape)
        }
    }

    private func createDebugCatcherFrame() -> CGRect {
        guard let viewModel = viewModel else { return .zero }
        let catcherNode = viewModel.getCatcherNode()

        return CGRect(
            origin: CGPoint(
                x: catcherNode.position.x - Catcher.size.width / 2,
                y: catcherNode.position.y - Catcher.size.height / 2
            ),
            size: Catcher.size
        )
    }

    private func createManualCatchZone() -> CGRect {
        guard let viewModel = viewModel else { return .zero }
        let catcherFrame = createDebugCatcherFrame()

        return CGRect(
            x: catcherFrame.minX,
            y: catcherFrame.maxY - 80,
            width: catcherFrame.width - 50,  // This is the problematic calculation
            height: 10
        )
    }

    override func update(_ currentTime: TimeInterval) {
        viewModel?.checkCollisions()

        // Add new falling objects that were spawned since last update
        addNewFallingObjects()

        // Update debug visualization
        if showDebugPhysics {
            drawDebugCollisionZones()
        }
    }

    private func addNewFallingObjects() {
        guard let viewModel = viewModel else { return }
        for node in viewModel.getNewFallingObjectNodes() {
            addChild(node.node)
        }
    }

    private func getFirstTouchLocation(from touches: Set<UITouch>) -> CGPoint? {
        return touches.first?.location(in: self)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location = getFirstTouchLocation(from: touches) else {
            return
        }
        viewModel?.touchesBegan(at: location)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location = getFirstTouchLocation(from: touches) else {
            return
        }
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
        scene.backgroundColor = .clear

        skView.presentScene(scene)
        return skView
    }

    func updateUIView(_ uiView: SKView, context: Context) {
        // optional: update scene data if needed
    }
}
