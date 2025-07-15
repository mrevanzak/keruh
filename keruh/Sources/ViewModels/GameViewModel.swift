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

private enum GameConfiguration {
    static let catcherBottomOffset: CGFloat = 60

    static let fallDurationRange: ClosedRange<TimeInterval> = 3.0...5.0
    static let speedIncreaseInterval = 5
    static let speedMultiplier: TimeInterval = 0.9
    static let minimumSpawnInterval: TimeInterval = 0.5
    static let defaultSpawnInterval: TimeInterval = 2.0

    static let initialHealth = 3
    static let initialScore = 0

    static let uiPadding: CGFloat = 36
    static let labelSpacing: CGFloat = 35

    static let offScreenBuffer: CGFloat = -100.0
}

struct GameState {
    var score: Int = GameConfiguration.initialScore
    var health: Int = GameConfiguration.initialHealth
    var gameSpeed: TimeInterval = GameConfiguration.defaultSpawnInterval
    var isPlaying: Bool = true
    var isPaused: Bool = false
    var isGameOver: Bool = false
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
    @Published var healthText: String = "Health: \(GameConfiguration.initialHealth)"

    private(set) var catcher: Catcher
    private var fallingObjectNodes: [UUID: FallingObject] = [:]
    private var newFallingObjectNodes: [FallingObject] = []

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
        $gameState
            .map { "Score: \($0.score)" }
            .assign(to: \.scoreText, on: self)
            .store(in: &cancellables)

        $gameState
            .map { "Health: \($0.health)" }
            .assign(to: \.healthText, on: self)
            .store(in: &cancellables)

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
        let randomX = CGFloat.random(in: halfWidth...(screenSize.width - halfWidth))

        let startPosition = CGPoint(
            x: randomX,
            y: screenSize.height + objectSize.height
        )
        let targetY = -objectSize.height
        let fallDuration = TimeInterval.random(in: GameConfiguration.fallDurationRange)

        let fallingObjectData = FallingObjectData(
            type: objectType,
            position: startPosition,
            targetY: targetY,
            fallDuration: fallDuration
        )

        let fallingObjectNode = FallingObject(type: objectType)
        fallingObjectNode.setup()
        fallingObjectNodes[fallingObjectData.id] = fallingObjectNode
        newFallingObjectNodes.append(fallingObjectNode)
        fallingObjects.append(fallingObjectData)

        animateFallingObject(fallingObjectData)
    }

    private func animateFallingObject(_ object: FallingObjectData) {
        guard let fallingObjectNode = fallingObjectNodes[object.id] else { return }

        fallingObjectNode.startFallingWithTypeSpeed(
            from: object.position,
            to: object.targetY
        ) { [weak self] in
            self?.handleObjectMissed(object.id)
        }

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
        if let index = fallingObjects.firstIndex(where: { $0.id == objectId }) {
            let object = fallingObjects[index]
            fallingObjects.remove(at: index)

            if object.type.isCollectible {
                gameState.score += object.type.points
            } else {
                gameState.health -= 1
            }

            cleanupFallingObject(objectId)
            provideCatcherFeedback()
            checkForSpeedIncrease()
        }
    }

    private func handleObjectMissed(_ objectId: UUID) {
        if let index = fallingObjects.firstIndex(where: { $0.id == objectId }) {
            fallingObjects.remove(at: index)
            gameState.health -= 1
        }

        cleanupFallingObject(objectId)
    }

    private func cleanupFallingObject(_ objectId: UUID) {
        fallingObjectNodes[objectId]?.node.removeFromParent()
        fallingObjectNodes.removeValue(forKey: objectId)

        objectTimers[objectId]?.invalidate()
        objectTimers.removeValue(forKey: objectId)
    }

    private func provideCatcherFeedback() {
        #if os(iOS)
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        #endif
    }

    private func checkForSpeedIncrease() {
        guard gameState.score % GameConfiguration.speedIncreaseInterval == 0,
              gameState.gameSpeed > GameConfiguration.minimumSpawnInterval else { return }

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
            origin: CGPoint(
                x: catcherPosition.x - Catcher.size.width / 2,
                y: catcherPosition.y - Catcher.size.height / 2
            ),
            size: Catcher.size
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
        guard touchState == .dragging, let startData = touchStartData else { return }

        let deltaX = location.x - startData.touchPosition.x
        let newX = startData.catcherPosition.x + deltaX

        catcher.moveTo(x: newX, constrainedTo: screenSize)
    }

    func touchesEnded() { endTouch() }
    func touchesCancelled() { endTouch() }

    private func endTouch() {
        touchState = .idle
        touchStartData = nil
    }

    func pauseGame() {
        gameState.isPaused = true
        gameState.isPlaying = false
        stopAllTimers()

        fallingObjectNodes.values.forEach { $0.node.isPaused = true }
    }

    func resumeGame() {
        gameState.isPaused = false
        gameState.isPlaying = true

        fallingObjectNodes.values.forEach { $0.node.isPaused = false }
        startGameplay()
    }

    func resetGame() {
        gameState = GameState()
        fallingObjects.removeAll()

        fallingObjectNodes.values.forEach { $0.node.removeFromParent() }
        fallingObjectNodes.removeAll()
        stopAllTimers()

        catcher.node.position = CGPoint(
            x: screenSize.width / 2,
            y: GameConfiguration.catcherBottomOffset
        )

        startGameplay()
    }

    func checkCollisions() {
        let catcherFrame = CGRect(
            origin: CGPoint(
                x: catcher.node.position.x - Catcher.size.width / 2,
                y: catcher.node.position.y - Catcher.size.height / 2
            ),
            size: Catcher.size
        )

        for (objectId, fallingObject) in fallingObjectNodes {
            let objectFrame = CGRect(
                x: fallingObject.node.position.x - fallingObject.size.width / 2,
                y: fallingObject.node.position.y - fallingObject.size.height / 2,
                width: fallingObject.size.width,
                height: fallingObject.size.height
            )

            if catcherFrame.intersects(objectFrame) {
                handleObjectCaught(objectId)
            }
        }

        cleanupOffScreenObjects()
    }

    private func cleanupOffScreenObjects() {
        let offScreenY = GameConfiguration.offScreenBuffer
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
        return CGPoint(x: GameConfiguration.uiPadding, y: screenSize.height - safeAreaTop)
    }

    func getMissedPosition() -> CGPoint {
        let safeAreaTop = safeAreaInsets.top + GameConfiguration.uiPadding
        return CGPoint(
            x: GameConfiguration.uiPadding,
            y: screenSize.height - safeAreaTop - GameConfiguration.labelSpacing
        )
    }
}

