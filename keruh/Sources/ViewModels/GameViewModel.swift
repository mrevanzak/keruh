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
    static let catcherBottomOffset: CGFloat = 100
    static let speedIncreaseInterval = 5
    static let speedMultiplier: TimeInterval = 0.9
    static let minimumSpawnInterval: TimeInterval = 0.5
    static let defaultSpawnInterval: TimeInterval = 2.0
    static let initialHealth = 3
    static let initialScore = 0
    static let uiPadding: CGFloat = 36
    static let labelSpacing: CGFloat = 35
    static let offScreenBuffer: CGFloat = -100.0
    static let doublePointDuration: TimeInterval = 10.0
    static let slowMotionFallSpeedMultiplier: Double = 0.5
    static let slowMotionSpawnMultiplier: Double = 1.5
    static let slowMotionDuration: TimeInterval = 10.0
}

struct GameState {
    var score: Int = GameConfiguration.initialScore
    var health: Int = GameConfiguration.initialHealth
    var gameSpeed: TimeInterval = GameConfiguration.defaultSpawnInterval
    var playState: GamePlayState = .menu
}

enum GamePlayState {
    case menu
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

struct SceneNode {
    let sky: SKSpriteNode
    let river: SKSpriteNode
    let leftIsland: SKSpriteNode
    let rightIsland: SKSpriteNode
    let clouds: SKSpriteNode
    let waves: SKSpriteNode
}

class GameViewModel: ObservableObject {
    @Published var gameState = GameState()
    @Published var fallingObjects: [FallingObjectData] = []
    @Published var scoreText: String =
        "Score: \(GameConfiguration.initialScore)"
    @Published var healthText: String =
        "Health: \(GameConfiguration.initialHealth)"

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
    private var doublePointTimer: Timer?
    private var slowMotionTimer: Timer?
    private var originalGameSpeed: TimeInterval = GameConfiguration.defaultSpawnInterval

    var sceneNodes = SceneNode(
        sky: SKSpriteNode(imageNamed: "langit"),
        river: SKSpriteNode(imageNamed: "bg_sungai"),
        leftIsland: SKSpriteNode(imageNamed: "pulau_kiri"),
        rightIsland: SKSpriteNode(imageNamed: "pulau_kanan"),
        clouds: SKSpriteNode(imageNamed: "awan"),
        waves: SKSpriteNode(imageNamed: "ombak")
    )

    init() {
        self.catcher = Catcher()
        setupBindings()
        setupCatcher()
    }

    deinit {
        stopAllTimers()
    }

    func setupScene() {
        // Sky and River Background
        let skyHeight = screenSize.height * 0.35
        let riverHeight = screenSize.height * 0.65
        let horizonY = screenSize.height * 0.65

        sceneNodes.sky.anchorPoint = CGPoint(x: 0.5, y: 0)
        sceneNodes.sky.position = CGPoint(x: screenSize.width / 2, y: horizonY)
        sceneNodes.sky.size = CGSize(width: screenSize.width, height: skyHeight)
        sceneNodes.sky.zPosition = -10
        sceneNodes.sky.alpha = 0

        sceneNodes.river.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        sceneNodes.river.position = CGPoint(
            x: screenSize.width / 2,
            y: horizonY
        )
        sceneNodes.river.size = CGSize(
            width: screenSize.width,
            height: riverHeight
        )
        sceneNodes.river.zPosition = -8
        sceneNodes.river.alpha = 0

        // Islands
        sceneNodes.leftIsland.anchorPoint = CGPoint(x: 1.0, y: 0.0)
        sceneNodes.leftIsland.size = CGSize(
            width: screenSize.width * 0.65,
            height: screenSize.height * 0.8
        )
        let islandYPosition = screenSize.height * 0.05
        sceneNodes.leftIsland.position = CGPoint(
            x: -sceneNodes.leftIsland.size.width,
            y: islandYPosition
        )
        sceneNodes.leftIsland.zPosition = 10

        sceneNodes.rightIsland.anchorPoint = CGPoint(x: 0.1, y: 0.0)
        sceneNodes.rightIsland.size = CGSize(
            width: screenSize.width * 0.65,
            height: screenSize.height * 0.8
        )
        sceneNodes.rightIsland.position = CGPoint(
            x: screenSize.width + sceneNodes.rightIsland.size.width,
            y: islandYPosition
        )
        sceneNodes.rightIsland.zPosition = 10

        // Clouds
        sceneNodes.clouds.anchorPoint = CGPoint(x: 0.5, y: 0)
        sceneNodes.clouds.size = CGSize(
            width: screenSize.width * 1.2,
            height: screenSize.height * 0.25
        )
        sceneNodes.clouds.position = CGPoint(
            x: screenSize.width / 2,
            y: horizonY - 50
        )
        sceneNodes.clouds.zPosition = -9
        sceneNodes.clouds.alpha = 0

        // Waves
        sceneNodes.waves.anchorPoint = CGPoint(x: 0.55, y: 1.0)
        sceneNodes.waves.position = CGPoint(
            x: screenSize.width / 2,
            y: horizonY
        )
        sceneNodes.waves.size = CGSize(
            width: screenSize.width * 1.8,
            height: riverHeight * 1.5
        )
        sceneNodes.waves.zPosition = -5
        sceneNodes.waves.alpha = 0

        // Animations
        let skyAndRiver = SKAction.sequence([
            .wait(forDuration: 0.5), .fadeIn(withDuration: 1.0),
        ])
        sceneNodes.sky.run(skyAndRiver)
        sceneNodes.river.run(skyAndRiver)

        let wave = SKAction.sequence([
            .wait(forDuration: 0.8), .fadeIn(withDuration: 0.6),
        ])
        sceneNodes.waves.run(wave)

        let cloud = SKAction.sequence([
            .wait(forDuration: 1.5),
            .fadeIn(withDuration: 0.2),
            .moveBy(x: 0, y: 60, duration: 0.6),
        ])
        sceneNodes.clouds.run(cloud)

        let islandLeft = SKAction.sequence([
            .wait(forDuration: 0.1),
            .move(
                to: CGPoint(
                    x: sceneNodes.leftIsland.size.width / 2,
                    y: islandYPosition
                ),
                duration: 0.8
            ),
        ])
        islandLeft.timingMode = .easeOut
        sceneNodes.leftIsland.run(islandLeft)

        let islandRight = SKAction.sequence([
            .wait(forDuration: 0.1),
            .move(
                to: CGPoint(
                    x: screenSize.width
                        - (sceneNodes.rightIsland.size.width / 2),
                    y: islandYPosition
                ),
                duration: 0.8
            ),
        ])
        islandRight.timingMode = .easeOut
        sceneNodes.rightIsland.run(islandRight)
    }

    private func setupCatcher() {
        catcher.setup()
    }

    private func spawnCatcher() {
        // Position the catcher
        let catcherPosition = CGPoint(
            x: screenSize.width / 2,
            y: GameConfiguration.catcherBottomOffset
        )
        catcher.node.position = catcherPosition

        let transition = SKAction.fadeIn(withDuration: 0.5)
        catcher.node.run(transition)
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
    }

    func getCatcherNode() -> SKNode {
        return catcher.node
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

    func startGameplay() {
        gameState.playState = .playing

        spawnCatcher()
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
        let objectSize = objectType.getSize()
        let halfWidth = objectSize.width / 2
        let randomX = CGFloat.random(
            in: halfWidth...(screenSize.width - halfWidth)
        )

        let startPosition = CGPoint(
            x: randomX,
            y: screenSize.height * 0.7
        )
        
        let adjustedFallSpeed = (slowMotionTimer != nil)
            ? objectType.fallSpeed * GameConfiguration.slowMotionFallSpeedMultiplier
            : objectType.fallSpeed

        let fallingObjectData = FallingObjectData(
            type: objectType,
            position: startPosition,
            targetY: -objectSize.height,
            fallDuration: objectType.fallSpeed
        )

        let fallingObjectNode = FallingObject(type: objectType)
        fallingObjectNode.setup()

        fallingObjectNodes[fallingObjectData.id] = fallingObjectNode
        newFallingObjectNodes.append(fallingObjectNode)
        fallingObjects.append(fallingObjectData)

        animateFallingObject(fallingObjectData)
    }

    private func animateFallingObject(_ object: FallingObjectData) {
        guard let fallingObjectNode = fallingObjectNodes[object.id] else {
            return
        }

        fallingObjectNode.startFallingWithTypeSpeed(
            from: object.position,
            to: object.targetY,
            initialScale: 0.6,
            finalScale: 1.0
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
        guard
            let index = fallingObjects.firstIndex(where: { $0.id == objectId })
        else { return }

        let object = fallingObjects[index]
        fallingObjects.remove(at: index)

        updateScoreAndHealth(for: object)
        cleanupFallingObject(objectId)
        provideCatcherFeedback()
        checkForSpeedIncrease()
    }

    private func updateScoreAndHealth(for object: FallingObjectData) {
        switch object.type.assetName {
        case "heart":
            addHealth()
        case "star":
            activateDoublePoint()
        default:
            if object.type.isCollectible {
                let multiplier = (doublePointTimer != nil) ? 2 : 1
                gameState.score += object.type.points * multiplier
            } else {
                decreaseHealth()
            }
        }
    }

    private func handleObjectMissed(_ objectId: UUID) {
        if let index = fallingObjects.firstIndex(where: { $0.id == objectId }) {
            let fallingObject = fallingObjects[index]
            fallingObjects.remove(at: index)

            if fallingObject.type.isCollectible == true {
                decreaseHealth()
            }
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
            gameState.gameSpeed > GameConfiguration.minimumSpawnInterval
        else { return }

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
            let startData = touchStartData
        else { return }

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

            let topCatchZone = CGRect(
                x: catcherFrame.minX,
                y: catcherFrame.maxY - 30,
                width: catcherFrame.width,
                height: 30
            )

            if topCatchZone.intersects(objectFrame) {
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
            data.type.assetName == type.assetName
                ? fallingObjectNodes[data.id] : nil
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

    //power up
    private func addHealth(_ amount: Int = 1) {
        let maxHealth = 5
        if gameState.health < maxHealth {
            gameState.health = min(gameState.health + amount, maxHealth)
        } else {
            print("Health max")
        }
    }

    private func activateDoublePoint() {
        doublePointTimer?.invalidate()

        doublePointTimer = Timer.scheduledTimer(
            withTimeInterval: GameConfiguration.doublePointDuration,
            repeats: false
        ) { [weak self] _ in
            self?.doublePointTimer = nil
            print("Double Point expired")
        }

        print("Double Point activated")
    }
    
    func activateSlowMotion() {
            if slowMotionTimer != nil {
                slowMotionTimer?.invalidate()
                slowMotionTimer = Timer.scheduledTimer(
                    withTimeInterval: GameConfiguration.slowMotionDuration,
                    repeats: false
                ) { [weak self] _ in
                    guard let self = self else { return }
                    self.gameState.gameSpeed = self.originalGameSpeed
                    self.slowMotionTimer = nil
                    print("Slow Motion expired")
                }
                print("Slow Motion extended")
                return
            }

            print("Slow Motion activated")
            originalGameSpeed = gameState.gameSpeed
            gameState.gameSpeed *= GameConfiguration.slowMotionSpawnMultiplier

            for (index, object) in fallingObjects.enumerated() {
                let objectId = object.id
                guard let node = fallingObjectNodes[objectId] else { continue }

                let currentY = node.node.position.y
                let remainingDistance = abs(currentY - GameConfiguration.offScreenBuffer)
                let newFallSpeed = object.type.fallSpeed * GameConfiguration.slowMotionFallSpeedMultiplier
                let newDuration = TimeInterval(remainingDistance / newFallSpeed)

                node.node.removeAllActions()
                node.node.run(SKAction.moveTo(y: GameConfiguration.offScreenBuffer, duration: newDuration)) { [weak self] in
                    self?.handleObjectMissed(objectId)
                }
            }

            slowMotionTimer = Timer.scheduledTimer(
                withTimeInterval: GameConfiguration.slowMotionDuration,
                repeats: false
            ) { [weak self] _ in
                guard let self = self else { return }
                self.gameState.gameSpeed = self.originalGameSpeed
                self.slowMotionTimer = nil
                print("Slow Motion expired")
            }
        }
}
