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
    var playState: GamePlayState = .playing
}

enum GamePlayState {
    case playing
    case paused
    case gameOver
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
    @Published var scoreText: String = "Score: \(GameConfiguration.initialScore)"
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
            .map(\.gameSpeed)
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.updateSpawning()
            }
            .store(in: &cancellables)
    }

    func setupGame(screenSize: CGSize, safeAreaInsets: UIEdgeInsets) {
        self.screenSize = screenSize
        self.safeAreaInsets = safeAreaInsets
        
        let catcherPosition = CGPoint(
            x: screenSize.width / 2,
            y: GameConfiguration.catcherBottomOffset
        )
        catcher.node.position = catcherPosition
        
        startGameplay()
    }

    func getCatcherNode() -> SKNode {
        catcher.node
    }

    func getFallingObjectNodes() -> [FallingObject] {
        Array(fallingObjectNodes.values)
    }

    func getNewFallingObjectNodes() -> [FallingObject] {
        let newNodes = newFallingObjectNodes
        newFallingObjectNodes.removeAll()
        return newNodes
    }

    func getAllActiveNodes() -> [SKNode] {
        var nodes: [SKNode] = [catcher.node]
        nodes.append(contentsOf: fallingObjectNodes.values.map(\.node))
        return nodes
    }

    private func startGameplay() {
        guard gameState.playState == .playing else { return }
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
        guard gameState.playState == .playing else { return }

        let objectType = FallingObjectType.random()
        let objectSize = objectType.size
        let halfWidth = objectSize.width / 2
        let randomX = CGFloat.random(in: halfWidth...(screenSize.width - halfWidth))

        let startPosition = CGPoint(
            x: randomX,
            y: screenSize.height + objectSize.height
        )
        
        let fallingObjectData = FallingObjectData(
            type: objectType,
            position: startPosition,
            targetY: -objectSize.height,
            fallDuration: TimeInterval.random(in: GameConfiguration.fallDurationRange)
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

        scheduleObjectCleanup(for: object)
    }

    private func scheduleObjectCleanup(for object: FallingObjectData) {
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
        guard let index = fallingObjects.firstIndex(where: { $0.id == objectId }) else { return }
        
        let object = fallingObjects[index]
        fallingObjects.remove(at: index)

        updateScoreAndHealth(for: object)
        cleanupFallingObject(objectId)
        provideCatcherFeedback()
        checkForSpeedIncrease()
    }

    private func updateScoreAndHealth(for object: FallingObjectData) {
        if object.type.isCollectible {
            gameState.score += object.type.points
        } else {
            decreaseHealth()
        }
    }

    private func handleObjectMissed(_ objectId: UUID) {
        if let index = fallingObjects.firstIndex(where: { $0.id == objectId }) {
            fallingObjects.remove(at: index)
            decreaseHealth()
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

    private func decreaseHealth() {
        gameState.health -= 1
        if gameState.health == 0 {
            gameOver()
        }
    }

    private func checkForSpeedIncrease() {
        guard gameState.score % GameConfiguration.speedIncreaseInterval == 0,
              gameState.gameSpeed > GameConfiguration.minimumSpawnInterval else { return }
        
        gameState.gameSpeed *= GameConfiguration.speedMultiplier
    }

    private func updateSpawning() {
        guard gameState.playState == .playing else { return }
        startSpawningObjects()
    }

    func touchesBegan(at location: CGPoint) {
        guard gameState.playState == .playing else { return }

        catcher.moveTo(x: location.x, constrainedTo: screenSize)

        touchState = .dragging
        touchStartData = TouchStartData(
            touchPosition: location,
            catcherPosition: catcher.node.position
        )
    }

    func touchesMoved(to location: CGPoint) {
        guard touchState == .dragging,
              let startData = touchStartData else { return }

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
        gameState.playState = .paused
        stopAllTimers()
        
        fallingObjectNodes.values.forEach { $0.node.isPaused = true }
    }

    func resumeGame() {
        gameState.playState = .playing
        
        fallingObjectNodes.values.forEach { $0.node.isPaused = false }
        startGameplay()
    }

    func resetGame() {
        gameState = GameState()
        fallingObjects.removeAll()
        
        cleanupAllObjects()
        resetCatcherPosition()
        startGameplay()
    }
    
    private func gameOver() {
        gameState.playState = .gameOver
        
        fallingObjects.removeAll()
        cleanupAllObjects()
        stopAllTimers()
    }

    private func cleanupAllObjects() {
        fallingObjectNodes.values.forEach { $0.node.removeFromParent() }
        fallingObjectNodes.removeAll()
    }

    private func resetCatcherPosition() {
        catcher.node.position = CGPoint(
            x: screenSize.width / 2,
            y: GameConfiguration.catcherBottomOffset
        )
    }

    func checkCollisions() {
        let catcherFrame = createCatcherFrame()
        
        for (objectId, fallingObject) in fallingObjectNodes {
            let objectFrame = createObjectFrame(for: fallingObject)
            
            if catcherFrame.intersects(objectFrame) {
                handleObjectCaught(objectId)
            }
        }
        
        cleanupOffScreenObjects()
    }

    private func createCatcherFrame() -> CGRect {
        CGRect(
            origin: CGPoint(
                x: catcher.node.position.x - Catcher.size.width / 2,
                y: catcher.node.position.y - Catcher.size.height / 2
            ),
            size: Catcher.size
        )
    }

    private func createObjectFrame(for fallingObject: FallingObject) -> CGRect {
        CGRect(
            x: fallingObject.node.position.x - fallingObject.size.width / 2,
            y: fallingObject.node.position.y - fallingObject.size.height / 2,
            width: fallingObject.size.width,
            height: fallingObject.size.height
        )
    }

    private func cleanupOffScreenObjects() {
        let offScreenObjects = fallingObjectNodes.filter { _, fallingObject in
            fallingObject.node.position.y < GameConfiguration.offScreenBuffer
        }
        
        offScreenObjects.forEach { objectId, _ in
            cleanupFallingObject(objectId)
        }
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

    func getFallingObjectsCount() -> Int {
        fallingObjectNodes.count
    }

    func getFallingObjectsByType(_ type: FallingObjectType) -> [FallingObject] {
        fallingObjects.compactMap { data in
            data.type.assetName == type.assetName ? fallingObjectNodes[data.id] : nil
        }
    }

    func getObjectPosition(for objectId: UUID) -> CGPoint? {
        fallingObjectNodes[objectId]?.node.position
    }

    func updateObjectPosition(for objectId: UUID, to position: CGPoint) {
        fallingObjectNodes[objectId]?.node.position = position
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
