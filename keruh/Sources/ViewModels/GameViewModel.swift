//
//  GameViewModel.swift
//  keruh
//
//  Created by Farrell Matthew Lim on 14/07/25.
//

import Combine
import Foundation
import SpriteKit
import SwiftUI

struct GameState {
    var score: Int = 0
    var missed: Int = 0
    var gameSpeed: TimeInterval = 2.0
    var isPlaying: Bool = true
    var isPaused: Bool = false
    var isGameOver: Bool = false
}

struct FallingObjectData {
    let id: UUID = UUID()
    let type: FallingObjectType
    var position: CGPoint
    let targetY: CGFloat
    let fallDuration: TimeInterval
    var isActive: Bool = true
}

private enum TouchState {
    case idle
    case dragging
}

private struct TouchStartData {
    let touchPosition: CGPoint
    let catcherPosition: CGPoint
}

class GameViewModel: ObservableObject {
    @Published var gameState = GameState()
    @Published var fallingObjects: [FallingObjectData] = []
    @Published var scoreText: String = "Score: 0"
    @Published var missedText: String = "Missed: 0"

    // Game objects managed by ViewModel
    private(set) var catcher: Catcher
    private var fallingObjectNodes: [UUID: FallingObject] = [:]
    private var newFallingObjectNodes: [FallingObject] = []  // Queue for scene addition

    private var cancellables = Set<AnyCancellable>()
    private var spawnTimer: Timer?
    private var objectTimers: [UUID: Timer] = [:]
    private var screenSize: CGSize = .zero
    private var safeAreaInsets: UIEdgeInsets = .zero

    private var touchState: TouchState = .idle
    private var touchStartData: TouchStartData?

    init() {
        self.catcher = Catcher()
        setupBindings()
        setupCatcher()
    }

    deinit {
        stopAllTimers()
    }

    private func setupCatcher() {
        catcher.setup()
    }

    func getCatcherNode() -> SKNode {
        return catcher.node
    }

    func getFallingObjectNodes() -> [FallingObject] {
        return Array(fallingObjectNodes.values)
    }

    func getNewFallingObjectNodes() -> [FallingObject] {
        let newNodes = newFallingObjectNodes
        newFallingObjectNodes.removeAll()
        return newNodes
    }

    func getAllActiveNodes() -> [SKNode] {
        var nodes: [SKNode] = [catcher.node]
        nodes.append(contentsOf: fallingObjectNodes.values.map { $0.node })
        return nodes
    }

    private func setupBindings() {
        // Update text when score changes
        $gameState
            .map { "Score: \($0.score)" }
            .assign(to: \.scoreText, on: self)
            .store(in: &cancellables)

        // Update text when missed changes
        $gameState
            .map { "Missed: \($0.missed)" }
            .assign(to: \.missedText, on: self)
            .store(in: &cancellables)

        // Update spawning when game speed changes
        $gameState
            .map { $0.gameSpeed }
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.updateSpawning()
            }
            .store(in: &cancellables)
    }

    func setupGame(screenSize: CGSize, safeAreaInsets: UIEdgeInsets) {
        self.screenSize = screenSize
        self.safeAreaInsets = safeAreaInsets

        // Initialize catcher position
        let catcherY = GameConfiguration.catcherBottomOffset
        let catcherX = screenSize.width / 2

        catcher.node.position = CGPoint(x: catcherX, y: catcherY)

        startGameplay()
    }

    private func startGameplay() {
        guard gameState.isPlaying else { return }
        startSpawningObjects()
    }

    private func startSpawningObjects() {
        stopSpawnTimer()

        spawnTimer = Timer.scheduledTimer(
            withTimeInterval: gameState.gameSpeed,
            repeats: true
        ) { [weak self] _ in
            self?.spawnFallingObject()
        }
    }

    private func spawnFallingObject() {
        guard gameState.isPlaying else { return }

        let objectType = FallingObjectType.random()
        let objectSize = objectType.size
        let halfWidth = objectSize.width / 2
        let randomX = CGFloat.random(
            in: halfWidth...(screenSize.width - halfWidth)
        )
        let startPosition = CGPoint(
            x: randomX,
            y: screenSize.height + objectSize.height
        )
        let targetY = -objectSize.height
        let fallDuration = TimeInterval.random(
            in: GameConfiguration.fallDurationRange
        )

        let fallingObjectData = FallingObjectData(
            type: objectType,
            position: startPosition,
            targetY: targetY,
            fallDuration: fallDuration
        )

        // Create the actual SpriteKit object
        let fallingObjectNode = FallingObject(type: objectType)
        fallingObjectNode.setup()
        fallingObjectNodes[fallingObjectData.id] = fallingObjectNode

        // Add to queue for scene addition
        newFallingObjectNodes.append(fallingObjectNode)

        fallingObjects.append(fallingObjectData)
        animateFallingObject(fallingObjectData)
    }

    private func animateFallingObject(_ object: FallingObjectData) {
        guard let fallingObjectNode = fallingObjectNodes[object.id] else {
            return
        }

        // Start the falling animation using the object's specific fall speed
        fallingObjectNode.startFallingWithTypeSpeed(
            from: object.position,
            to: object.targetY
        ) { [weak self] in
            self?.handleObjectMissed(object.id)
        }

        // Set up timer for cleanup (backup) - slightly longer than expected duration
        let distance = abs(object.position.y - object.targetY)
        let expectedDuration = TimeInterval(distance / object.type.fallSpeed)
        let timer = Timer.scheduledTimer(
            withTimeInterval: expectedDuration + 1.0,
            repeats: false
        ) { [weak self] _ in
            self?.cleanupFallingObject(object.id)
        }

        objectTimers[object.id] = timer
    }

    func handleObjectCaught(_ objectId: UUID) {
        // Remove from falling objects data
        if let index = fallingObjects.firstIndex(where: { $0.id == objectId }) {
            let object = fallingObjects[index]
            fallingObjects.remove(at: index)

            // Add score based on object type
            gameState.score += object.type.points

            // Clean up the SpriteKit node
            cleanupFallingObject(objectId)

            provideCatcherFeedback()
            checkForSpeedIncrease()
        }
    }

    private func handleObjectMissed(_ objectId: UUID) {
        // Remove from falling objects data
        if let index = fallingObjects.firstIndex(where: { $0.id == objectId }) {
            fallingObjects.remove(at: index)
            gameState.missed += 1
        }

        // Clean up the SpriteKit node
        cleanupFallingObject(objectId)
    }

    private func cleanupFallingObject(_ objectId: UUID) {
        // Remove from scene
        fallingObjectNodes[objectId]?.node.removeFromParent()
        fallingObjectNodes.removeValue(forKey: objectId)

        // Cancel timer
        objectTimers[objectId]?.invalidate()
        objectTimers.removeValue(forKey: objectId)
    }

    private func provideCatcherFeedback() {
        // Animate the catcher
        // catcher.animateCatch()

        // Optional: Add haptic feedback
        #if os(iOS)
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        #endif
    }

    private func checkForSpeedIncrease() {
        guard gameState.score % GameConfiguration.speedIncreaseInterval == 0,
            gameState.gameSpeed > GameConfiguration.minimumSpawnInterval
        else { return }

        gameState.gameSpeed *= GameConfiguration.speedMultiplier
    }

    private func updateSpawning() {
        guard gameState.isPlaying else { return }
        startSpawningObjects()
    }

    func touchesBegan(at location: CGPoint) {
        guard gameState.isPlaying else { return }

        let catcherPosition = catcher.node.position
        let catcherFrame = CGRect(
            x: catcherPosition.x - Catcher.size.width / 2,
            y: catcherPosition.y - Catcher.size.height / 2,
            width: Catcher.size.width,
            height: Catcher.size.height
        )

        if catcherFrame.contains(location) {
            touchState = .dragging
            touchStartData = TouchStartData(
                touchPosition: location,
                catcherPosition: catcherPosition
            )
        }
    }

    func touchesMoved(to location: CGPoint) {
        guard touchState == .dragging,
            let startData = touchStartData
        else { return }

        let deltaX = location.x - startData.touchPosition.x
        let newX = startData.catcherPosition.x + deltaX

        // Move the catcher (it handles its own constraints)
        catcher.moveTo(x: newX, constrainedTo: screenSize)
    }

    func touchesEnded() {
        endTouch()
    }

    func touchesCancelled() {
        endTouch()
    }

    private func endTouch() {
        touchState = .idle
        touchStartData = nil
    }

    func pauseGame() {
        gameState.isPaused = true
        gameState.isPlaying = false
        stopAllTimers()

        // Pause all falling object animations
        fallingObjectNodes.values.forEach { fallingObject in
            fallingObject.node.isPaused = true
        }
    }

    func resumeGame() {
        gameState.isPaused = false
        gameState.isPlaying = true

        // Resume all falling object animations
        fallingObjectNodes.values.forEach { fallingObject in
            fallingObject.node.isPaused = false
        }

        startGameplay()
    }

    func resetGame() {
        gameState = GameState()

        // Clean up all falling objects
        fallingObjects.removeAll()
        fallingObjectNodes.values.forEach { $0.node.removeFromParent() }
        fallingObjectNodes.removeAll()

        stopAllTimers()

        // Reset catcher position
        let catcherY = GameConfiguration.catcherBottomOffset
        let catcherX = screenSize.width / 2
        catcher.node.position = CGPoint(x: catcherX, y: catcherY)

        startGameplay()
    }

    func checkCollisions() {
        let catcherFrame = CGRect(
            x: catcher.node.position.x - Catcher.size.width / 2,
            y: catcher.node.position.y - Catcher.size.height / 2,
            width: Catcher.size.width,
            height: Catcher.size.height
        )

        for (objectId, fallingObject) in fallingObjectNodes {
            let objectFrame = CGRect(
                x: fallingObject.node.position.x - fallingObject.size.width / 2,
                y: fallingObject.node.position.y - fallingObject.size.height
                    / 2,
                width: fallingObject.size.width,
                height: fallingObject.size.height
            )

            if catcherFrame.intersects(objectFrame) {
                handleObjectCaught(objectId)
            }
        }

        // Clean up objects that have fallen off screen
        cleanupOffScreenObjects()
    }

    private func cleanupOffScreenObjects() {
        let offScreenY = -100.0  // Buffer below screen

        let offScreenObjects = fallingObjectNodes.filter { _, fallingObject in
            fallingObject.node.position.y < offScreenY
        }

        for (objectId, _) in offScreenObjects {
            cleanupFallingObject(objectId)
        }
    }

    func getFallingObjectsCount() -> Int {
        return fallingObjectNodes.count
    }

    func getFallingObjectsByType(_ type: FallingObjectType) -> [FallingObject] {
        return fallingObjects.compactMap { data in
            if data.type.assetName == type.assetName {
                return fallingObjectNodes[data.id]
            }
            return nil
        }
    }

    func getObjectPosition(for objectId: UUID) -> CGPoint? {
        return fallingObjectNodes[objectId]?.node.position
    }

    func updateObjectPosition(for objectId: UUID, to position: CGPoint) {
        fallingObjectNodes[objectId]?.node.position = position
    }

    private func stopAllTimers() {
        stopSpawnTimer()
        objectTimers.values.forEach { $0.invalidate() }
        objectTimers.removeAll()
    }

    private func stopSpawnTimer() {
        spawnTimer?.invalidate()
        spawnTimer = nil
    }

    func getScorePosition() -> CGPoint {
        let safeAreaTop = safeAreaInsets.top + GameConfiguration.uiPadding
        return CGPoint(
            x: GameConfiguration.uiPadding,
            y: screenSize.height - safeAreaTop
        )
    }

    func getMissedPosition() -> CGPoint {
        let safeAreaTop = safeAreaInsets.top + GameConfiguration.uiPadding
        return CGPoint(
            x: GameConfiguration.uiPadding,
            y: screenSize.height - safeAreaTop - GameConfiguration.labelSpacing
        )
    }
}
