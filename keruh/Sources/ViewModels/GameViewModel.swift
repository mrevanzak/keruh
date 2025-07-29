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
    static let speedMultiplier: TimeInterval = 0.96
    static let minimumSpawnInterval: TimeInterval = 0.5
    static let defaultSpawnInterval: TimeInterval = 2.0
    static let initialHealth = 3
    static let initialScore = 0
    static let uiPadding: CGFloat = 36
    static let labelSpacing: CGFloat = 35
    static let offScreenBuffer: CGFloat = -100.0
    static let doublePointDuration: TimeInterval = 10.0
    static let shieldDuration: TimeInterval = 10.0
    static let slowMotionFallSpeedMultiplier: Double = 0.5
    static let slowMotionSpawnMultiplier: Double = 3
    static let slowMotionDuration: TimeInterval = 10.0
    static let minimumGameSpeedThreshold: TimeInterval = 0.4
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
    case settings
    case leaderboard
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
    @Published var scoreText: Int = GameConfiguration.initialScore
    @Published var healthText: Int = GameConfiguration.initialHealth
    @Published var doublePointTimeRemaining: Double = 0.0
    @Published var shieldTimeRemaining: Double = 0.0
    @Published var slowMotionTimeRemaining: Double = 0.0
    @Published var extraLive: Int = 0
    @Published var userHighScore: Int = 0
    @Published var isNewHighScore: Bool = false

    private(set) var catcher: Catcher
    private var fallingObjectNodes: [UUID: FallingObject] = [:]
    private var newFallingObjectNodes: [FallingObject] = []
    private var cancellables = Set<AnyCancellable>()
    private var spawnTimer: Timer?
    private var objectTimers: [UUID: Timer] = [:]
    private var missTimers: [UUID: Timer] = [:]
    private var screenSize: CGSize = .zero
    private var safeAreaInsets: UIEdgeInsets = .zero
    private var touchState: TouchState = .idle
    private var touchStartData: TouchStartData?
    private var doublePointTimer: Timer?
    private var shieldTimer: Timer?
    private var slowMotionTimer: Timer?
    private var originalGameSpeed: TimeInterval = GameConfiguration
        .defaultSpawnInterval

    private var uiUpdateTimer: Timer?
    private var pausedMissTimers: [UUID: TimeInterval] = [:]
    private var pausedDoublePointTime: TimeInterval?
    private var pausedSlowMotionTime: TimeInterval?
    private var pausedShieldTime: TimeInterval?

    // Store clamped island positions for spawn calculations
    private var riverLeftBound: CGFloat = 0
    private var riverRightBound: CGFloat = 0

    private var spawnLanes: [CGFloat] = []
    private var lastLaneIndex: Int?

    // Callback for tutorial trigger
    var onCatcherSpawned: (() -> Void)?

    private var latestXDrop: CGFloat?
    #if os(iOS)
        private let hapticQueue = DispatchQueue(
            label: "haptic.feedback",
            qos: .userInitiated
        )
        private var impactFeedback: UIImpactFeedbackGenerator?
        private var hardImpactFeedback: UIImpactFeedbackGenerator?
    #endif

    var sceneNodes = SceneNode(
        sky: SKSpriteNode(imageNamed: "bg_langit"),
        river: SKSpriteNode(imageNamed: "bg_sungai"),
        leftIsland: SKSpriteNode(imageNamed: "pulau_kiri"),
        rightIsland: SKSpriteNode(imageNamed: "pulau_kanan"),
        clouds: SKSpriteNode(imageNamed: "awan"),
        waves: SKSpriteNode(imageNamed: "ombak1_1")
    )

    init() {
        self.catcher = Catcher()
        setupBindings()
        setupCatcher()
        startUIUpdater()
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

        // Islands with clamping for larger screens
        let islandYPosition = screenSize.height * 0.01

        // Configure left island
        sceneNodes.leftIsland.anchorPoint = CGPoint(x: 1.0, y: 0.0)
        sceneNodes.leftIsland.size = CGSize(
            width: screenSize.width * 0.55,
            height: screenSize.height * 0.8
        )
        sceneNodes.leftIsland.position = CGPoint(
            x: -sceneNodes.leftIsland.size.width,
            y: islandYPosition
        )
        sceneNodes.leftIsland.zPosition = 10

        // Configure right island
        sceneNodes.rightIsland.anchorPoint = CGPoint(x: 0.0, y: 0.0)
        sceneNodes.rightIsland.size = CGSize(
            width: screenSize.width * 0.55,
            height: screenSize.height * 0.8
        )
        sceneNodes.rightIsland.position = CGPoint(
            x: screenSize.width + sceneNodes.rightIsland.size.width,
            y: islandYPosition
        )
        sceneNodes.rightIsland.zPosition = 10

        // Calculate clamped positions to prevent river from being too wide
        let maxRiverWidth: CGFloat = 120  // Maximum river width for larger screens
        let minIslandOverlap: CGFloat = 50  // Minimum island overlap into river

        let centerX = screenSize.width / 2
        let clampedLeftFinalX = max(
            centerX - maxRiverWidth / 2,
            minIslandOverlap
        )
        let clampedRightFinalX = min(
            centerX + maxRiverWidth / 2,
            screenSize.width - minIslandOverlap
        )

        // Store river bounds for spawn calculations
        riverLeftBound = clampedLeftFinalX
        riverRightBound = clampedRightFinalX

        let spawnWidth = riverRightBound - riverLeftBound
        let numberOfLanes = 5
        let laneWidth = spawnWidth / CGFloat(numberOfLanes)
        self.spawnLanes = (0..<numberOfLanes).map { i in
            let laneCenter = riverLeftBound + (laneWidth * (CGFloat(i) + 0.5))
            return laneCenter
        }

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
            width: screenSize.width * 2.2,
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

        let waveTextures = [
            SKTexture(imageNamed: "ombak 1_4"),
            SKTexture(imageNamed: "ombak 1_5"),
            SKTexture(imageNamed: "ombak 1_6"),
            SKTexture(imageNamed: "ombak 1_7"),
            SKTexture(imageNamed: "ombak 1_8"),
            SKTexture(imageNamed: "ombak 1_9"),
            SKTexture(imageNamed: "ombak 1_10"),
            SKTexture(imageNamed: "ombak 1_11"),
            SKTexture(imageNamed: "ombak 1_12"),
            SKTexture(imageNamed: "ombak 1_13"),
            SKTexture(imageNamed: "ombak 1_14"),
            SKTexture(imageNamed: "ombak 1_13"),
            SKTexture(imageNamed: "ombak 1_12"),
            SKTexture(imageNamed: "ombak 1_11"),
            SKTexture(imageNamed: "ombak 1_10"),
            SKTexture(imageNamed: "ombak 1_9"),
            SKTexture(imageNamed: "ombak 1_8"),
            SKTexture(imageNamed: "ombak 1_7"),
            SKTexture(imageNamed: "ombak 1_6"),
            SKTexture(imageNamed: "ombak 1_5"),
            
        ]

        let animateWavesAction = SKAction.animate(
            with: waveTextures,
            timePerFrame: 0.375
        )

        let loopWavesAction = SKAction.repeatForever(animateWavesAction)

        let fadeInAction = SKAction.sequence([
            .wait(forDuration: 0.8),
            .fadeIn(withDuration: 0.6),
        ])

        let waveAnimationGroup = SKAction.group([fadeInAction, loopWavesAction])

        sceneNodes.waves.run(waveAnimationGroup)

        let cloud = SKAction.sequence([
            .wait(forDuration: 1.5),
            .fadeAlpha(to: 0.3, duration: 1.0),
            .moveBy(x: 0, y: 30, duration: 0.6),
        ])
        sceneNodes.clouds.run(cloud)

        let islandLeft = SKAction.sequence([
            .wait(forDuration: 0.1),
            .move(
                to: CGPoint(
                    x: clampedLeftFinalX,
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
                    x: clampedRightFinalX,
                    y: islandYPosition
                ),
                duration: 0.8
            ),
        ])
        islandRight.timingMode = .easeOut
        sceneNodes.rightIsland.run(islandRight)

        preSpawnInitialObjects()
    }

    private func setupCatcher() {
        catcher.setup()
        #if os(iOS)
            hapticQueue.async {
                self.impactFeedback = UIImpactFeedbackGenerator(style: .light)
                self.hardImpactFeedback = UIImpactFeedbackGenerator(
                    style: .heavy
                )
                self.impactFeedback?.prepare()
                self.hardImpactFeedback?.prepare()
            }
        #endif
    }

    private func spawnCatcher() {
        catcher.node.alpha = 1
        // Position the catcher
        let catcherPosition = CGPoint(
            x: screenSize.width / 2,
            y: GameConfiguration.catcherBottomOffset
        )
        catcher.node.position = catcherPosition

        let transition = SKAction.fadeIn(withDuration: 0.5)
        catcher.node.run(transition) { [weak self] in
            // Trigger tutorial when catcher appears
            self?.onCatcherSpawned?()
        }
    }

    private func setupBindings() {
        $gameState
            .map { ($0.score) }
            .assign(to: \.scoreText, on: self)
            .store(in: &cancellables)

        $gameState
            .map { ($0.health) }
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

    func startGameplay(isResuming: Bool = false) {
        gameState.playState = .playing

        if !isResuming {
            startInitialObjectsFalling()
            spawnCatcher()
        }

        sceneNodes.clouds.run(SKAction.fadeAlpha(to: 1.0, duration: 0.5))

        startSpawningObjects()
    }

    private func startInitialObjectsFalling() {
        let initialFallSpeed: CGFloat = 60.0

        for objectData in fallingObjects {
            guard let fallingObjectNode = fallingObjectNodes[objectData.id]
            else { continue }

            fallingObjectNode.node.removeAllActions()
            fallingObjectNode.node.position = objectData.position
            fallingObjectNode.node.alpha = 1.0
            fallingObjectNode.node.setScale(0.4)
            fallingObjectNode.node.zRotation = 0

            let screenCenter = screenSize.width / 2
            let finalX: CGFloat
            if objectData.position.x < screenCenter {
                finalX =
                    objectData.position.x
                    - (screenCenter - objectData.position.x)
            } else {
                finalX =
                    objectData.position.x
                    + (objectData.position.x - screenCenter)
            }

            let finalPosition = CGPoint(x: finalX, y: objectData.targetY)

            let fallDistance = abs(
                fallingObjectNode.node.position.y - objectData.targetY
            )
            let actualDuration = TimeInterval(fallDistance / initialFallSpeed)

            let earlyMissTime = max(actualDuration - 1.2, 0.05)
            let missTimer = Timer.scheduledTimer(
                withTimeInterval: earlyMissTime,
                repeats: false
            ) { [weak self] _ in
                self?.handleObjectMissed(objectData.id)
            }
            missTimers[objectData.id] = missTimer

            fallingObjectNode.startFallingWithPerspective(
                from: fallingObjectNode.node.position,
                to: finalPosition,
                initialScale: fallingObjectNode.node.xScale,
                finalScale: 1.0,
                duration: actualDuration,
                completion: {}
            )

            scheduleObjectCleanup(for: objectData)
        }
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

    private func calculateSpawnX(for objectSize: CGSize) -> CGFloat {
        guard !spawnLanes.isEmpty else {
            let riverCenter = (riverLeftBound + riverRightBound) / 2
            return riverCenter
        }

        var newLaneIndex: Int

        if let lastIndex = lastLaneIndex, spawnLanes.count > 1 {
            repeat {
                newLaneIndex = Int.random(in: 0..<spawnLanes.count)
            } while newLaneIndex == lastIndex
        } else {
            newLaneIndex = Int.random(in: 0..<spawnLanes.count)
        }

        lastLaneIndex = newLaneIndex

        return spawnLanes[newLaneIndex]
    }

    private func preSpawnInitialObjects() {
        guard fallingObjectNodes.isEmpty else { return }

        let visualLayoutOrder: [FallingObjectType] = [
            .can, .diaper, .bottle, .tire, .sandal,
        ]
        let animationSequenceOrder: [FallingObjectType] = [
            .sandal, .tire, .bottle, .diaper, .can,
        ]
        let laneAssignments: [String: Int] = [
            "collect_sandal": 0, "collect_kaleng": 1, "collect_botol": 2,
            "collect_popmie": 3, "collect_ban": 4,
        ]

        guard spawnLanes.count >= visualLayoutOrder.count else { return }

        let screenCenterY = (screenSize.height / 2) - 50.0
        let verticalSpread: CGFloat = 90.0
        let topYBound = screenCenterY + verticalSpread
        let bottomYBound = screenCenterY - verticalSpread
        let spacing =
            (topYBound - bottomYBound) / CGFloat(visualLayoutOrder.count - 1)

        for (visualIndex, objectType) in visualLayoutOrder.enumerated() {
            let objectSize = objectType.getSize()
            guard let laneIndex = laneAssignments[objectType.assetName] else {
                continue
            }

            let xPosition = spawnLanes[laneIndex]
            let yPosition = topYBound - (CGFloat(visualIndex) * spacing)
            let finalPosition = CGPoint(x: xPosition, y: yPosition)

            let fallingObjectData = FallingObjectData(
                type: objectType,
                position: finalPosition,
                targetY: -objectSize.height,
                fallDuration: 50.0
            )

            let fallingObjectNode = FallingObject(type: objectType)
            fallingObjectNode.setup()

            fallingObjectNode.node.position = finalPosition
            fallingObjectNode.node.setScale(0)
            fallingObjectNode.node.alpha = 0

            if let animationIndex = animationSequenceOrder.firstIndex(
                of: objectType
            ) {
                let popInDuration: TimeInterval = 0.5
                let initialWait: TimeInterval = 0.8
                let waitDuration = initialWait + (Double(animationIndex) * 0.2)

                let waitAction = SKAction.wait(forDuration: waitDuration)

                let fadeInAction = SKAction.fadeIn(withDuration: 0.4)
                let scaleUpAction = SKAction.scale(
                    to: 0.4,
                    duration: popInDuration
                )
                scaleUpAction.timingMode = .easeOut

                let animationGroup = SKAction.group([
                    fadeInAction, scaleUpAction,
                ])
                let sequenceAction = SKAction.sequence([
                    waitAction, animationGroup,
                ])

                fallingObjectNode.node.run(sequenceAction)
            }

            fallingObjectNodes[fallingObjectData.id] = fallingObjectNode
            newFallingObjectNodes.append(fallingObjectNode)
            fallingObjects.append(fallingObjectData)
        }
    }

    private func spawnFallingObject() {
        guard gameState.playState == .playing else { return }

        let objectType = FallingObjectType.random(
            currentHealth: gameState.health
        )
        let objectSize = objectType.getSize()
        let randomX = calculateSpawnX(for: objectSize)

        let startPosition = CGPoint(x: randomX, y: screenSize.height * 0.65)

        let baseFallSpeed = objectType.fallSpeed
        let speedFactor =
            GameConfiguration.defaultSpawnInterval / gameState.gameSpeed

        let adjustedFallSpeed: CGFloat = {
            var speed = baseFallSpeed * CGFloat(speedFactor)
            if slowMotionTimer != nil {
                speed *= CGFloat(
                    GameConfiguration.slowMotionFallSpeedMultiplier
                )
            }
            return speed
        }()

        let fallDistance = abs(startPosition.y + objectSize.height)
        let fallDuration = TimeInterval(fallDistance / adjustedFallSpeed)

        let fallingObjectData = FallingObjectData(
            type: objectType,
            position: startPosition,
            targetY: -objectSize.height,
            fallDuration: fallDuration
        )

        let fallingObjectNode = FallingObject(type: objectType)
        fallingObjectNode.setup()

        fallingObjectNodes[fallingObjectData.id] = fallingObjectNode
        newFallingObjectNodes.append(fallingObjectNode)
        fallingObjects.append(fallingObjectData)

        animateFallingObjectSimplePerspectiveWithAdjustedSpeed(
            fallingObjectData,
            adjustedFallSpeed: adjustedFallSpeed
        )
    }

    private func animateFallingObjectSimplePerspectiveWithAdjustedSpeed(
        _ object: FallingObjectData,
        adjustedFallSpeed: CGFloat
    ) {
        guard let fallingObjectNode = fallingObjectNodes[object.id] else {
            return
        }

        let screenCenter = screenSize.width / 2
        let finalX: CGFloat
        if object.position.x < screenCenter {
            finalX = object.position.x - (screenCenter - object.position.x)
        } else {
            finalX = object.position.x + (object.position.x - screenCenter)
        }

        let finalPosition = CGPoint(x: finalX, y: object.targetY)
        let fallDistance = abs(object.position.y - object.targetY)
        let actualDuration = TimeInterval(fallDistance / adjustedFallSpeed)

        // Calculate miss timing more precisely
        // Miss should trigger when object reaches catch zone level, not before
        let catchZoneY =
            GameConfiguration.catcherBottomOffset + (Catcher.size.height / 2)
            - 20
        let distanceToMiss = abs(object.position.y - catchZoneY)
        let timeToMiss = TimeInterval(distanceToMiss / adjustedFallSpeed)

        // Set miss timer with proper timing
        let missTimer = Timer.scheduledTimer(
            withTimeInterval: timeToMiss,
            repeats: false
        ) { [weak self] timer in
            // Double-check timer is still valid before processing miss
            guard timer.isValid else { return }
            self?.handleObjectMissed(object.id)
        }
        missTimers[object.id] = missTimer

        // Start visual animation
        fallingObjectNode.startFallingWithPerspective(
            from: object.position,
            to: finalPosition,
            initialScale: 0.4,
            finalScale: 1.0,
            duration: actualDuration,
            completion: {}
        )

        scheduleObjectCleanup(for: object)
    }

    private func scheduleObjectCleanup(for object: FallingObjectData) {
        let timer = Timer.scheduledTimer(
            withTimeInterval: object.fallDuration + 1.0,
            repeats: false
        ) { [weak self] _ in
            self?.cleanupFallingObject(object.id)
        }

        objectTimers[object.id] = timer
    }

    func handleObjectCaught(_ objectId: UUID) {
        // CRITICAL: Stop the miss timer immediately to prevent race conditions
        if let missTimer = missTimers[objectId] {
            missTimer.invalidate()
            missTimers.removeValue(forKey: objectId)
        }

        // Stop cleanup timer to prevent premature removal
        if let cleanupTimer = objectTimers[objectId] {
            cleanupTimer.invalidate()
            objectTimers.removeValue(forKey: objectId)
        }

        guard
            let index = fallingObjects.firstIndex(where: { $0.id == objectId })
        else {
            return
        }

        let object = fallingObjects[index]
        fallingObjects.remove(at: index)

        updateScoreAndHealth(for: object)

        // Clean up immediately after catch
        cleanupFallingObject(objectId)
        provideCatcherFeedback()
        checkForSpeedIncrease()
    }

    private func updateScoreAndHealth(for object: FallingObjectData) {
        if SettingsManager.shared.soundEnabled {
            if object.type.isSpecial {
                let playSound = SKAction.playSoundFileNamed(
                    "power_up.mp3",
                    waitForCompletion: false
                )
                catcher.node.run(playSound)
            } else if object.type.isCollectible {
                let playSound = SKAction.playSoundFileNamed(
                    "correct.mp3",
                    waitForCompletion: false
                )
                catcher.node.run(playSound)
            } else {
                let playSound = SKAction.playSoundFileNamed(
                    "incorrect.mp3",
                    waitForCompletion: false
                )
                catcher.node.run(playSound)
            }
        }

        switch object.type.assetName {
        case "power_extralive":
            addHealth()
        case "power_doublepoint":
            activateDoublePoint()
        case "power_shield":
            activateShield()
        case "power_slowdown":
            activateShield()
        default:
            if object.type.isCollectible {
                let multiplier = (doublePointTimer != nil) ? 2 : 1
                gameState.score += object.type.points * multiplier
            } else {
                provideInvalidFeedback()
                decreaseHealth()
            }
        }
    }

    private func handleObjectMissed(_ objectId: UUID) {
        // Check if object still exists (might have been caught already)
        guard fallingObjectNodes[objectId] != nil else { return }

        // Remove miss timer since we're processing the miss
        missTimers.removeValue(forKey: objectId)

        if let index = fallingObjects.firstIndex(where: { $0.id == objectId }) {
            let fallingObject = fallingObjects[index]
            fallingObjects.remove(at: index)

            // Only penalize for missing collectible objects (not power-ups)
            if fallingObject.type.isCollectible && !fallingObject.type.isSpecial
            {
                if SettingsManager.shared.soundEnabled {
                    let playSound = SKAction.playSoundFileNamed(
                        "incorrect.mp3",
                        waitForCompletion: false
                    )
                    catcher.node.run(playSound)
                }

                provideInvalidFeedback()
                decreaseHealth()
            }
        }

        cleanupFallingObject(objectId)
    }

    private func cleanupFallingObject(_ objectId: UUID) {
        // Remove from visual scene
        fallingObjectNodes[objectId]?.node.removeFromParent()
        fallingObjectNodes.removeValue(forKey: objectId)

        // Clean up all associated timers
        objectTimers[objectId]?.invalidate()
        objectTimers.removeValue(forKey: objectId)

        missTimers[objectId]?.invalidate()
        missTimers.removeValue(forKey: objectId)

        // Remove from data array if still present
        if let index = fallingObjects.firstIndex(where: { $0.id == objectId }) {
            fallingObjects.remove(at: index)
        }
    }

    private func provideCatcherFeedback() {
        #if os(iOS)
            if SettingsManager.shared.hapticsEnabled {
                hapticQueue.async {
                    DispatchQueue.main.async {
                        self.impactFeedback?.impactOccurred()
                    }
                }
            }
        #endif
    }

    private func provideInvalidFeedback() {
        #if os(iOS)
            if SettingsManager.shared.hapticsEnabled {
                hapticQueue.async {
                    DispatchQueue.main.async {
                        self.hardImpactFeedback?.impactOccurred()
                    }
                }
            }
        #endif
    }

    private func decreaseHealth() {
        if shieldTimer == nil {
            gameState.health -= 1
            if extraLive > 0 {
                extraLive -= 1
            }
            if gameState.health == 0 {
                touchesEnded()
                gameOver()
            }
        }
    }

    private func checkForSpeedIncrease() {
        guard gameState.score % GameConfiguration.speedIncreaseInterval == 0
        else { return }
        let newSpeed = gameState.gameSpeed * GameConfiguration.speedMultiplier
        gameState.gameSpeed = max(newSpeed, GameConfiguration.minimumGameSpeedThreshold)
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

        catcher.node.isPaused = true
        fallingObjectNodes.values.forEach { $0.node.isPaused = true }

        stopSpawnTimer()
        objectTimers.values.forEach { $0.invalidate() }
        objectTimers.removeAll()

        pausedMissTimers.removeAll()
        for (id, timer) in missTimers {
            if timer.isValid {
                pausedMissTimers[id] = timer.fireDate.timeIntervalSinceNow
            }
            timer.invalidate()
        }
        missTimers.removeAll()

        uiUpdateTimer?.invalidate()

        if let timer = doublePointTimer, timer.isValid {
            pausedDoublePointTime = timer.fireDate.timeIntervalSinceNow
            timer.invalidate()
            doublePointTimer = nil
        }

        if let timer = shieldTimer, timer.isValid {
            pausedShieldTime = timer.fireDate.timeIntervalSinceNow
            timer.invalidate()
            shieldTimer = nil
        }

        if let timer = slowMotionTimer, timer.isValid {
            pausedSlowMotionTime = timer.fireDate.timeIntervalSinceNow
            timer.invalidate()
            slowMotionTimer = nil
        }
    }

    func resumeGame() {
        gameState.playState = .playing

        if let remainingTime = pausedDoublePointTime {
            doublePointTimer = Timer.scheduledTimer(
                withTimeInterval: remainingTime,
                repeats: false
            ) { [weak self] _ in
                self?.doublePointTimer = nil
            }
            pausedDoublePointTime = nil
        }

        if let remainingTime = pausedShieldTime {
            shieldTimer = Timer.scheduledTimer(
                withTimeInterval: remainingTime,
                repeats: false
            ) { [weak self] _ in
                self?.shieldTimer = nil
            }
            pausedShieldTime = nil
        }

        if let remainingTime = pausedSlowMotionTime {
            slowMotionTimer = Timer.scheduledTimer(
                withTimeInterval: remainingTime,
                repeats: false
            ) { [weak self] _ in
                guard let self = self else { return }
                self.gameState.gameSpeed = self.originalGameSpeed
                self.adjustFallingObjectSpeeds(multiplier: 1.0)
                self.slowMotionTimer = nil
            }
            pausedSlowMotionTime = nil
        }

        for (id, remainingTime) in pausedMissTimers {
            let timer = Timer.scheduledTimer(
                withTimeInterval: remainingTime,
                repeats: false
            ) { [weak self] _ in
                self?.handleObjectMissed(id)
            }
            missTimers[id] = timer
        }
        pausedMissTimers.removeAll()

        startUIUpdater()

        catcher.node.isPaused = false
        fallingObjectNodes.values.forEach { $0.node.isPaused = false }
        startGameplay(isResuming: true)
    }

    func resetGame() {
        gameState = GameState()

        stopAllTimers()
        doublePointTimeRemaining = 0.0
        shieldTimeRemaining = 0.0
        slowMotionTimeRemaining = 0.0

        startUIUpdater()
        fallingObjects.removeAll()

        cleanupAllObjects()
        resetCatcherPosition()
        startGameplay()
    }

    func resetToMenu() {
        stopAllTimers()
        doublePointTimeRemaining = 0.0
        shieldTimeRemaining = 0.0
        slowMotionTimeRemaining = 0.0

        startUIUpdater()
        cleanupAllObjects()
        resetCatcherPosition()

        sceneNodes.clouds.run(SKAction.fadeAlpha(to: 0.4, duration: 0.5))

        preSpawnInitialObjects()

        catcher.node.alpha = 0
        gameState = GameState()
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
        guard gameState.playState == .playing else { return }

        let catcherFrame = createCatcherFrame()

        for (objectId, fallingObject) in fallingObjectNodes {
            let objectFrame = createObjectFrame(for: fallingObject)

            // Create a more generous and symmetric catch zone
            let catchZoneWidth = Catcher.size.width * 0.9  // 90% of catcher width for better feel
            let catchZoneHeight: CGFloat = 25  // Slightly taller catch zone
            let catchZoneX = catcherFrame.midX - (catchZoneWidth / 2)  // Perfect centering
            let catchZoneY = catcherFrame.maxY - 40  // Adjusted for better visual alignment

            let topCatchZone = CGRect(
                x: catchZoneX,
                y: catchZoneY,
                width: catchZoneWidth,
                height: catchZoneHeight
            )

            // Check collision
            if topCatchZone.intersects(objectFrame) {
                // Immediately mark for catch to prevent double processing
                handleObjectCaught(objectId)
                break  // Process one catch per frame to avoid conflicts
            }
        }

        cleanupOffScreenObjects()
    }

    private func createCatcherFrame() -> CGRect {
        // Use the actual node position and ensure consistent anchor point calculation
        let position = catcher.node.position

        return CGRect(
            origin: CGPoint(
                x: position.x - Catcher.size.width / 2,
                y: position.y - Catcher.size.height / 2
            ),
            size: Catcher.size
        )
    }

    // Alternative: Use physics-based collision detection (recommended)
    func enablePhysicsCollisionDetection() {
        // This method shows how to switch to physics-based detection
        // You can call this instead of manual collision detection

        // The physics contact delegate in GameScene will handle collisions
        // This is more accurate and handles edge cases better
    }

    // Debug methods
    #if DEBUG
        func togglePhysicsDebug() {
            // This will be called from the game scene to toggle debug visualization
            print("Physics debug toggled")
        }

        func printCollisionDebugInfo() {
            print("=== COLLISION DEBUG INFO ===")
            print("Catcher position: \(catcher.node.position)")
            print("Catcher size: \(Catcher.size)")
            print("Screen size: \(screenSize)")
            print("Active falling objects: \(fallingObjectNodes.count)")

            for (id, object) in fallingObjectNodes {
                print(
                    "Object \(id): position \(object.node.position), size \(object.size)"
                )
            }
            print("============================")
        }
    #endif

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
        uiUpdateTimer?.invalidate()
        uiUpdateTimer = nil

        stopSpawnTimer()
        objectTimers.values.forEach { $0.invalidate() }
        objectTimers.removeAll()

        missTimers.values.forEach { $0.invalidate() }
        missTimers.removeAll()

        doublePointTimer?.invalidate()
        doublePointTimer = nil
        shieldTimer?.invalidate()
        shieldTimer = nil
        slowMotionTimer?.invalidate()
        slowMotionTimer = nil
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

    func getObjectId(for node: SKNode) -> UUID? {
        return fallingObjectNodes.first { $0.value.node == node }?.key
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

    private func startUIUpdater() {
        uiUpdateTimer?.invalidate()
        uiUpdateTimer = Timer.scheduledTimer(
            withTimeInterval: 0.05,
            repeats: true
        ) { [weak self] _ in
            self?.updatePowerUpTimers()
        }
    }

    private func updatePowerUpTimers() {
        // Double Point Timer
        if let timer = doublePointTimer, timer.isValid {
            let remaining = timer.fireDate.timeIntervalSinceNow
            doublePointTimeRemaining = max(
                0,
                remaining / GameConfiguration.doublePointDuration
            )
        } else if doublePointTimeRemaining != 0 {
            doublePointTimeRemaining = 0
        }

        // Shield Timer
        if let timer = shieldTimer, timer.isValid {
            let remaining = timer.fireDate.timeIntervalSinceNow
            shieldTimeRemaining = max(
                0,
                remaining / GameConfiguration.shieldDuration
            )
        } else if shieldTimeRemaining != 0 {
            shieldTimeRemaining = 0
        }

        // Slow Motion Timer
        if let timer = slowMotionTimer, timer.isValid {
            let remaining = timer.fireDate.timeIntervalSinceNow
            slowMotionTimeRemaining = max(
                0,
                remaining / GameConfiguration.slowMotionDuration
            )
        } else if slowMotionTimeRemaining != 0 {
            slowMotionTimeRemaining = 0
        }
    }

    //power up
    private func addHealth(_ amount: Int = 1) {
        let maxHealth = 5
        if gameState.health < maxHealth {
            gameState.health = min(gameState.health + amount, maxHealth)
            extraLive += 1
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
            print("[\(self?.currentTimestamp() ?? "")] Double Point expired")
        }
        print("[\(currentTimestamp())] Double Point activated")
    }

    private func activateShield() {
        shieldTimer?.invalidate()

        shieldTimer = Timer.scheduledTimer(
            withTimeInterval: GameConfiguration.shieldDuration,
            repeats: false
        ) { [weak self] _ in
            self?.shieldTimer = nil
            print("[\(self?.currentTimestamp() ?? "")] Shield expired")
        }
        print("[\(currentTimestamp())] Shield activated")
    }

    private func activateSlowMotion() {
        if let timer = slowMotionTimer {
            timer.invalidate()
            print("[\(currentTimestamp())] Slow Motion extended")
        } else {
            originalGameSpeed = gameState.gameSpeed
            gameState.gameSpeed *= GameConfiguration.slowMotionSpawnMultiplier
            adjustFallingObjectSpeeds(
                multiplier: GameConfiguration.slowMotionFallSpeedMultiplier
            )
            print("[\(currentTimestamp())] Slow Motion activated")
        }
        slowMotionTimer = Timer.scheduledTimer(
            withTimeInterval: GameConfiguration.slowMotionDuration,
            repeats: false
        ) { [weak self] _ in
            guard let self = self else { return }
            self.gameState.gameSpeed = self.originalGameSpeed
            self.adjustFallingObjectSpeeds(multiplier: 1.0)
            self.slowMotionTimer = nil
            print("[\(self.currentTimestamp())] Slow Motion ended")
        }
    }

    private func adjustFallingObjectSpeeds(multiplier: Double) {
        for (objectId, fallingObject) in fallingObjectNodes {
            let currentPos = fallingObject.node.position
            let targetY = -fallingObject.size.height

            let remainingDistance = abs(currentPos.y - targetY)
            let newDuration = TimeInterval(
                remainingDistance / (fallingObject.getFallSpeed() * multiplier)
            )

            fallingObject.node.removeAllActions()

            fallingObject.startFallingWithPerspective(
                from: currentPos,
                to: CGPoint(x: currentPos.x, y: targetY),
                initialScale: fallingObject.node.xScale,
                finalScale: 1.0,
                duration: newDuration
            ) { [weak self] in
                self?.handleObjectMissed(objectId)
            }
        }
    }

    //helper untuk debug
    private func currentTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: Date())
    }

    //highscore
    func checkIfNewHighScore() {
        if gameState.score > userHighScore {
            isNewHighScore = true
            userHighScore = gameState.score
        } else {
            isNewHighScore = false
        }
    }
    
    func fetchUserHighScore() {
        GameCenterManager.shared.getCurrentUserHighScore { [weak self] score in
            DispatchQueue.main.async {
                self?.userHighScore = score ?? 0
            }
        }
    }


}
