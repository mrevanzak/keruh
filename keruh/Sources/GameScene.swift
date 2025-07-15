//
//  GameScene.swift
//  keruh
//
//  Created by Revanza Kurniawan on 10/07/25.
//

import GameplayKit
import SpriteKit
import SwiftUI


private enum GameConfiguration {
    static let catcherSize = CGSize(width: 80, height: 20)
    static let catcherCornerRadius: CGFloat = 8
    static let catcherBottomOffset: CGFloat = 60
    static let catcherHalfWidth: CGFloat = 40

    static let fallingObjectSize = CGSize(width: 30, height: 30)
    static let initialSpawnInterval: TimeInterval = 2.5
    static let fallDurationRange: ClosedRange<TimeInterval> = 3.0...5.0
    static let speedIncreaseInterval = 5
    static let speedMultiplier: TimeInterval = 0.9
    static let minimumSpawnInterval: TimeInterval = 0.8

    static let uiPadding: CGFloat = 36
    static let labelSpacing: CGFloat = 35
    static let fontSize: CGFloat = 24
    
    static let leftRightSafeArea: CGFloat = 30

    static let catcherScaleAnimation: CGFloat = 1.2
    static let animationDuration: TimeInterval = 0.1

    static let maxHealth = 3
    static let redItemSpawnChance: Double = 0.3
    
    static let numberOfTracks = 5
    static let trackMargin: CGFloat = 70
    
    static let speedIncreaseTimer: TimeInterval = 0.2
    static let spawnIntervalDecrease: TimeInterval = 0.1
    static let fallSpeedIncrease: TimeInterval = 0.03
    static let minimumFallDuration: TimeInterval = 0.5
    static let initialFallDuration: TimeInterval = 4.0
    static let sequentialSpawnDelay: TimeInterval = 0.3
}

private enum GameColors {
    static let background = SKColor.systemBlue
    static let catcher = SKColor.systemGreen
    static let catcherStroke = SKColor.green
    static let scoreText = SKColor.white
    static let missedText = SKColor.black
    static let healthText = SKColor.yellow
    static let trackLine = SKColor.white.withAlphaComponent(0.3)
    static let doublePointItem = SKColor.systemYellow
    static let addHealthItem = SKColor.systemPink
    static let slowMotionItem = SKColor.systemBlue

    static let goodItem = SKColor.systemGreen
    static let badItem = SKColor.black
}

private struct PhysicsCategory {
    static let catcher: UInt32 = 0x1 << 0
    static let goodItem: UInt32 = 0x1 << 1
    static let badItem: UInt32 = 0x1 << 2
    static let doublePointItem: UInt32 = 0x1 << 3
    static let addHealthItem: UInt32 = 0x1 << 4
    static let slowMotionItem: UInt32 = 0x1 << 5
}

private enum ItemType {
    case good
    case bad
    case doublePoint
    case addHealth
    case slowMotion
    
    var imageNames: [String] {
        switch self {
        case .good:
            return ["collectable", "collectable_can"] // ← Tambahkan nama-nama image kamu di sini
        case .bad:
            return ["non_collectable"]
        default:
            return [imageName] // default image untuk selain good
        }
    }

    var imageName: String {
        switch self {
        case .good:
            return imageNames.randomElement() ?? "collectable"
        case .bad:
            return imageNames.randomElement() ?? "fish"
        case .doublePoint: return "double_point"
        case .addHealth: return "xtra_life"
        case .slowMotion: return "slow_down"
        }
    }
    
    // Fallback colors if images are not available
    var fallbackColor: SKColor {
        switch self {
        case .good: return GameColors.goodItem
        case .bad: return GameColors.badItem
        case .doublePoint: return GameColors.doublePointItem
        case .addHealth: return SKColor.systemPink
        case .slowMotion: return GameColors.slowMotionItem
        }
    }

    var physicsCategory: UInt32 {
        switch self {
        case .good: return PhysicsCategory.goodItem
        case .bad: return PhysicsCategory.badItem
        case .doublePoint: return PhysicsCategory.doublePointItem
        case .addHealth: return PhysicsCategory.addHealthItem
        case .slowMotion: return PhysicsCategory.slowMotionItem
        }
    }
}


final class GameScene: SKScene {

    var entities = [GKEntity]()
    var graphs = [String: GKGraph]()
    
    private var doublePointOverlay: SKSpriteNode?

    private var gameState: GameState = .playing
    private var safeAreaInsets: UIEdgeInsets = .zero
    
    private var isDoublePointActive = false
    private var doublePointTimer: Timer?
    
    private var isSlowMotionActive = false
    private var slowMotionTimer: Timer?
    private var slowMotionOverlay: SKSpriteNode?

    // Game Elements
    private var catcher: SKShapeNode!
    private var scoreLabel: SKLabelNode!
    private var missedLabel: SKLabelNode!
    private var healthLabel: SKLabelNode!
    private var trackLines: [SKShapeNode] = []

    // Track System
    private var trackPositions: [CGFloat] = []

    // Game State
    private var score = 0 {
        didSet { updateScoreDisplay() }
    }

    private var missed = 0 {
        didSet { updateMissedDisplay() }
    }

    private var health = GameConfiguration.maxHealth {
        didSet {
            updateHealthDisplay()
            if health <= 0 {
                gameOver()
            }
        }
    }

    private var gameSpeed: TimeInterval = GameConfiguration.initialSpawnInterval
    {
        didSet { updateSpawning() }
    }

    private var currentSpawnInterval: TimeInterval = GameConfiguration.initialSpawnInterval
    private var currentFallDuration: TimeInterval = GameConfiguration.initialFallDuration
    private var gameStartTime: TimeInterval = 0
    private var lastSpeedUpdateTime: TimeInterval = 0

    private var isSpawningSequence = false
    private var activeItems: Set<SKSpriteNode> = [] // Changed from SKShapeNode to SKSpriteNode
    private var lastSpawnTime: TimeInterval = 0

    // Touch Handling
    private var touchState: TouchState = .idle
    private var touchStartData: TouchStartData?


    override func didMove(to view: SKView) {
        if let window = view.window {
            safeAreaInsets = window.safeAreaInsets
        }

        setupGame()
    }
}

private enum GameState {
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


extension GameScene {

    fileprivate func setupGame() {
        setupScene()
        setupTracks()
        setupCatcher()
        setupUI()
        startGameplay()
        initializeSpeedLogic()
    }

    fileprivate func setupScene() {
        backgroundColor = GameColors.background
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = .zero
    }

    fileprivate func setupTracks() {
        let availableWidth = size.width - (GameConfiguration.trackMargin * 2)
        let trackSpacing = availableWidth / CGFloat(GameConfiguration.numberOfTracks - 1)
        
        trackPositions = []
        trackLines = []
        
        for i in 0..<GameConfiguration.numberOfTracks {
            let xPosition = GameConfiguration.trackMargin + (CGFloat(i) * trackSpacing)
            trackPositions.append(xPosition)
            
            let trackLine = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: xPosition, y: 0))
            path.addLine(to: CGPoint(x: xPosition, y: size.height))
            trackLine.path = path
            trackLine.strokeColor = GameColors.trackLine
            trackLine.lineWidth = 1
            trackLine.alpha = 0.5
            trackLine.zPosition = -1
            
            addChild(trackLine)
            trackLines.append(trackLine)
        }
    }

    fileprivate func setupCatcher() {
        catcher = createCatcher()
        addChild(catcher)
    }

    fileprivate func createCatcher() -> SKShapeNode {
        let catcherNode = SKShapeNode(
            rectOf: GameConfiguration.catcherSize,
            cornerRadius: GameConfiguration.catcherCornerRadius
        )

        catcherNode.fillColor = GameColors.catcher
        catcherNode.strokeColor = GameColors.catcherStroke
        catcherNode.lineWidth = 2
        catcherNode.position = CGPoint(
            x: size.width / 2, y: GameConfiguration.catcherBottomOffset)

        catcherNode.physicsBody = SKPhysicsBody(
            rectangleOf: GameConfiguration.catcherSize)
        catcherNode.physicsBody?.isDynamic = false
        catcherNode.physicsBody?.categoryBitMask = PhysicsCategory.catcher
        catcherNode.physicsBody?.contactTestBitMask =
            PhysicsCategory.goodItem | PhysicsCategory.badItem
        catcherNode.physicsBody?.collisionBitMask = 0

        return catcherNode
    }

    fileprivate func setupUI() {
        scoreLabel = createLabel(text: "Score: 0", color: GameColors.scoreText)
        missedLabel = createLabel(
            text: "Missed: 0", color: GameColors.missedText)
        healthLabel = createLabel(
            text: "Health: \(health)", color: GameColors.healthText)

        addChild(scoreLabel)
        addChild(missedLabel)
        addChild(healthLabel)

        updateUIPositions()
    }

    fileprivate func createLabel(text: String, color: SKColor) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: "Arial-BoldMT")
        label.fontSize = GameConfiguration.fontSize
        label.fontColor = color
        label.text = text
        label.horizontalAlignmentMode = .left
        return label
    }

    fileprivate func startGameplay() {
        guard gameState == .playing else { return }
        startSpawningObjects()
    }

    fileprivate func initializeSpeedLogic() {
        gameStartTime = CACurrentMediaTime()
        lastSpeedUpdateTime = gameStartTime
        lastSpawnTime = gameStartTime
        currentSpawnInterval = GameConfiguration.initialSpawnInterval
        currentFallDuration = GameConfiguration.initialFallDuration
        
        startSpeedIncreaseTimer()
    }

    fileprivate func startSpeedIncreaseTimer() {
        removeAction(forKey: "speedIncrease")
        
        let speedUpdate = SKAction.run { [weak self] in
            self?.updateGameSpeed()
        }
        let wait = SKAction.wait(forDuration: GameConfiguration.speedIncreaseTimer)
        let sequence = SKAction.sequence([speedUpdate, wait])
        let repeatAction = SKAction.repeatForever(sequence)
        
        run(repeatAction, withKey: "speedIncrease")
    }

    fileprivate func updateGameSpeed() {
        guard gameState == .playing else { return }
        
        let currentTime = CACurrentMediaTime()
        let timeSinceStart = currentTime - gameStartTime
        
        currentSpawnInterval = max(
            GameConfiguration.minimumSpawnInterval,
            GameConfiguration.initialSpawnInterval - (timeSinceStart * GameConfiguration.spawnIntervalDecrease)
        )
        
        currentFallDuration = max(
            GameConfiguration.minimumFallDuration,
            GameConfiguration.initialFallDuration - (timeSinceStart * GameConfiguration.fallSpeedIncrease)
        )
        
        gameSpeed = currentSpawnInterval
        
        lastSpeedUpdateTime = currentTime
    }
}


extension GameScene {

    fileprivate func startSpawningObjects() {
        removeAction(forKey: "spawning")
        
        let spawn = SKAction.run { [weak self] in
            self?.checkAndSpawnNextItem()
        }
        let wait = SKAction.wait(forDuration: 0.1)
        let sequence = SKAction.sequence([spawn, wait])
        let repeatAction = SKAction.repeatForever(sequence)

        run(repeatAction, withKey: "spawning")
    }

    fileprivate func checkAndSpawnNextItem() {
        guard gameState == .playing else { return }

        let currentTime = CACurrentMediaTime()

        if currentTime - lastSpawnTime >= currentSpawnInterval {
            let batchCount = isSlowMotionActive ? 1 : Int.random(in: 2...3)
            spawnObjectBatch(count: batchCount)
            lastSpawnTime = currentTime
        }
    }

    fileprivate func spawnFallingObject() {
        guard gameState == .playing else { return }
        guard activeItems.count < 10 else { return }

        let chance = Double.random(in: 0...1)
        let itemType: ItemType
        
        if chance < 0.025 && score > 200 && health < 5 {
            itemType = .addHealth
        } else if chance < 0.05 && score > 200 {
            itemType = .doublePoint
        } else if chance < 0.07 && score > 500 {
            itemType = .slowMotion
        } else if chance < GameConfiguration.redItemSpawnChance {
            itemType = .bad
        } else {
            itemType = .good
        }

        let fallingObject = createFallingObject(type: itemType)
        activeItems.insert(fallingObject)
        addChild(fallingObject)
        animateFallingObject(fallingObject, type: itemType)
    }

    fileprivate func createFallingObject(type: ItemType) -> SKSpriteNode {
        let object: SKSpriteNode
        
        // Try to create sprite with image, fallback to colored sprite if image not found
        if UIImage(named: type.imageName) != nil {
            let texture = SKTexture(imageNamed: type.imageName)
            object = SKSpriteNode(texture: texture)
            object.size = GameConfiguration.fallingObjectSize
        } else {
            // Fallback
            object = SKSpriteNode(color: type.fallbackColor, size: GameConfiguration.fallingObjectSize)
        }

        // Choose random track
        let randomTrackIndex = Int.random(in: 0..<trackPositions.count)
        let xPosition = trackPositions[randomTrackIndex]
        
        object.position = CGPoint(
            x: xPosition,
            y: size.height + GameConfiguration.fallingObjectSize.height/2
        )

        // Physics - using circular physics body for better collision detection
        let radius = min(GameConfiguration.fallingObjectSize.width, GameConfiguration.fallingObjectSize.height) / 2
        object.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        object.physicsBody?.isDynamic = true
        object.physicsBody?.categoryBitMask = type.physicsCategory
        object.physicsBody?.contactTestBitMask = PhysicsCategory.catcher
        object.physicsBody?.collisionBitMask = 0
        object.physicsBody?.affectedByGravity = false

        return object
    }

    fileprivate func animateFallingObject(_ object: SKSpriteNode, type: ItemType) {
        let fallAction = SKAction.moveTo(
            y: -GameConfiguration.fallingObjectSize.height,
            duration: currentFallDuration
        )

        let missedAction = SKAction.run { [weak self] in
            self?.handleObjectMissed(type: type)
        }
        let cleanupAction = SKAction.run { [weak self] in
            self?.activeItems.remove(object)
        }
        let removeAction = SKAction.removeFromParent()

        let sequence = SKAction.sequence([
            fallAction, missedAction, cleanupAction, removeAction,
        ])
        object.run(sequence)

        object.speed = isSlowMotionActive ? 0.4 : 1.0
    }

    fileprivate func handleGoodItemCaught(_ object: SKSpriteNode) {
        let earnedScore = isDoublePointActive ? 200 : 100
        score += earnedScore

        activeItems.remove(object)
        object.removeFromParent()

        provideCatcherFeedback(positive: true)
        checkForSpeedIncrease()
    }

    fileprivate func showPowerUpFlash(color: SKColor) {
        doublePointOverlay?.removeFromParent()

        let flashOverlay = SKSpriteNode(color: color, size: size)
        flashOverlay.alpha = 0.4
        flashOverlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        flashOverlay.zPosition = 99

        addChild(flashOverlay)
        doublePointOverlay = flashOverlay
    }
    
    fileprivate func removeDoublePointOverlay() {
        doublePointOverlay?.removeFromParent()
        doublePointOverlay = nil
    }
    
    fileprivate func handleDoublePointItemCaught(_ object: SKSpriteNode) {
        activeItems.remove(object)
        object.removeFromParent()

        isDoublePointActive = true
        showPowerUpFlash(color: GameColors.doublePointItem)

        doublePointTimer?.invalidate()

        doublePointTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] _ in
            self?.isDoublePointActive = false
            self?.removeDoublePointOverlay()
        }
    }

    fileprivate func handleBadItemCaught(_ object: SKSpriteNode) {
        health -= 1
        activeItems.remove(object)
        object.removeFromParent()

        provideCatcherFeedback(positive: false)
        showHealthLostFeedback()
    }

    fileprivate func handleSlowMotionItemCaught(_ object: SKSpriteNode) {
        activeItems.remove(object)
        object.removeFromParent()

        isSlowMotionActive = true
        showSlowMotionOverlay()
        
        let previousSpawnInterval = currentSpawnInterval
        currentSpawnInterval *= 2.0
        updateSpawning()

        applySlowMotionToActiveItems()

        slowMotionTimer?.invalidate()

        slowMotionTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] _ in
            self?.isSlowMotionActive = false
            self?.resetSpeedForActiveItems()
            self?.removeSlowMotionOverlay()
        }
    }

    fileprivate func showSlowMotionOverlay() {
        slowMotionOverlay?.removeFromParent()

        let overlay = SKSpriteNode(color: GameColors.slowMotionItem, size: size)
        overlay.alpha = 0.3
        overlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.zPosition = 99

        addChild(overlay)
        slowMotionOverlay = overlay
    }
    
    fileprivate func applySlowMotionToActiveItems() {
        for node in activeItems {
            node.speed = 0.4
        }
    }
    
    fileprivate func resetSpeedForActiveItems() {
        for node in activeItems {
            node.speed = 1.0
        }
    }

    fileprivate func removeSlowMotionOverlay() {
        slowMotionOverlay?.removeFromParent()
        slowMotionOverlay = nil
    }
    
    fileprivate func handleAddHealthItemCaught(_ object: SKSpriteNode) {
        if health < 5 {
            health += 1
            showPowerUpFlash(color: GameColors.addHealthItem)
            
            run(SKAction.sequence([
                SKAction.wait(forDuration: 1.0),
                SKAction.run { [weak self] in self?.removeDoublePointOverlay() }
            ]))
        }

        activeItems.remove(object)
        object.removeFromParent()
    }

    fileprivate func handleObjectMissed(type: ItemType) {
        switch type {
        case .good:
            health -= 1
            missed += 1
            showHealthLostFeedback()
        case .bad:
            break
        case .doublePoint:
            break
        case .addHealth:
            break
        case .slowMotion:
            break
        }
    }

    fileprivate func provideCatcherFeedback(positive: Bool) {
        let targetScale: CGFloat =
            positive ? GameConfiguration.catcherScaleAnimation : 0.8
        let scaleUp = SKAction.scale(
            to: targetScale, duration: GameConfiguration.animationDuration)
        let scaleDown = SKAction.scale(
            to: 1.0, duration: GameConfiguration.animationDuration)
        let sequence = SKAction.sequence([scaleUp, scaleDown])

        catcher.run(sequence)

        if !positive {
            let originalColor = catcher.fillColor
            let redColor = SKAction.colorize(
                with: .red, colorBlendFactor: 0.5, duration: 0.2)
            let resetColor = SKAction.colorize(
                with: originalColor, colorBlendFactor: 1.0, duration: 0.2)
            let colorSequence = SKAction.sequence([redColor, resetColor])
            catcher.run(colorSequence)
        }
    }

    fileprivate func showHealthLostFeedback() {
        let scaleUp = SKAction.scale(to: 1.3, duration: 0.1)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
        let sequence = SKAction.sequence([scaleUp, scaleDown])

        healthLabel.run(sequence)

        let flashOverlay = SKSpriteNode(color: .red, size: size)
        flashOverlay.alpha = 0.3
        flashOverlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        flashOverlay.zPosition = 100

        addChild(flashOverlay)

        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        let remove = SKAction.removeFromParent()
        let flashSequence = SKAction.sequence([fadeOut, remove])

        flashOverlay.run(flashSequence)
    }

    fileprivate func checkForSpeedIncrease() {
        guard score % GameConfiguration.speedIncreaseInterval == 2,
            gameSpeed > GameConfiguration.minimumSpawnInterval
        else { return }

        gameSpeed *= GameConfiguration.speedMultiplier
    }

    fileprivate func spawnObjectBatch(count: Int) {
        guard gameState == .playing else { return }

        for i in 0..<count {
            let delay = Double(i) * GameConfiguration.sequentialSpawnDelay
            let spawnAction = SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.run { [weak self] in
                    self?.spawnFallingObject()
                    self?.lastSpawnTime = CACurrentMediaTime()
                }
            ])
            run(spawnAction)
        }
    }
    
    fileprivate func updateSpawning() {
        guard gameState == .playing else { return }
        startSpawningObjects()
    }

    fileprivate func updateScoreDisplay() {
        scoreLabel.text = "Score: \(score)"
    }

    fileprivate func updateMissedDisplay() {
        missedLabel.text = "Missed: \(missed)"
    }

    fileprivate func updateHealthDisplay() {
        healthLabel.text = "Health: \(health)"
    }

    fileprivate func gameOver() {
        gameState = .gameOver
        removeAction(forKey: "spawning")
        removeAction(forKey: "speedIncrease")

        activeItems.removeAll()

        enumerateChildNodes(withName: "*") { node, _ in
            if let spriteNode = node as? SKSpriteNode,
                spriteNode != self.catcher,
                spriteNode.physicsBody?.categoryBitMask == PhysicsCategory.goodItem
               || spriteNode.physicsBody?.categoryBitMask == PhysicsCategory.badItem
               || spriteNode.physicsBody?.categoryBitMask == PhysicsCategory.doublePointItem
               || spriteNode.physicsBody?.categoryBitMask == PhysicsCategory.addHealthItem
               || spriteNode.physicsBody?.categoryBitMask == PhysicsCategory.slowMotionItem

            {
                spriteNode.removeFromParent()
            }
        }

        showGameOverScreen()
    }

    fileprivate func showGameOverScreen() {
        let gameOverLabel = SKLabelNode(fontNamed: "Arial-BoldMT")
        gameOverLabel.fontSize = 48
        gameOverLabel.fontColor = .white
        gameOverLabel.text = "GAME OVER"
        gameOverLabel.position = CGPoint(
            x: size.width / 2, y: size.height / 2 + 50)
        gameOverLabel.zPosition = 200

        let finalScoreLabel = SKLabelNode(fontNamed: "Arial-BoldMT")
        finalScoreLabel.fontSize = 24
        finalScoreLabel.fontColor = .white
        finalScoreLabel.text = "Final Score: \(score)"
        finalScoreLabel.position = CGPoint(
            x: size.width / 2, y: size.height / 2)
        finalScoreLabel.zPosition = 200

        let restartLabel = SKLabelNode(fontNamed: "Arial-BoldMT")
        restartLabel.fontSize = 20
        restartLabel.fontColor = .yellow
        restartLabel.text = "Tap to Restart"
        restartLabel.position = CGPoint(
            x: size.width / 2, y: size.height / 2 - 50)
        restartLabel.zPosition = 200

        addChild(gameOverLabel)
        addChild(finalScoreLabel)
        addChild(restartLabel)

        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        gameOverLabel.alpha = 0
        finalScoreLabel.alpha = 0
        restartLabel.alpha = 0

        gameOverLabel.run(fadeIn)
        finalScoreLabel.run(fadeIn)
        restartLabel.run(fadeIn)
    }

    fileprivate func restartGame() {
        score = 0
        missed = 0
        health = GameConfiguration.maxHealth
        gameSpeed = GameConfiguration.initialSpawnInterval
        gameState = .playing
        
        isDoublePointActive = false
        doublePointTimer?.invalidate()

        currentSpawnInterval = GameConfiguration.initialSpawnInterval
        currentFallDuration = GameConfiguration.initialFallDuration
        
        activeItems.removeAll()
        lastSpawnTime = 0
        
        doublePointOverlay?.removeFromParent()
        doublePointOverlay = nil

        removeAllChildren()

        setupGame()
    }
}

extension GameScene {

    func setSafeAreaInsets(_ insets: UIEdgeInsets) {
        safeAreaInsets = insets
        updateUIPositions()
    }

    func updateUIPositions() {
        let safeAreaTop = safeAreaInsets.top + GameConfiguration.uiPadding
        let safeAreaLeft = GameConfiguration.leftRightSafeArea + GameConfiguration.uiPadding

        scoreLabel.position = CGPoint(
            x: safeAreaLeft,
            y: size.height - safeAreaTop
        )

        missedLabel.position = CGPoint(
            x: safeAreaLeft,
            y: size.height - safeAreaTop - GameConfiguration.labelSpacing
        )

        healthLabel.position = CGPoint(
            x: safeAreaLeft,
            y: size.height - safeAreaTop - (GameConfiguration.labelSpacing * 2)
        )
    }
}

extension GameScene {

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }

        if gameState == .gameOver {
            restartGame()
            return
        }

        guard gameState == .playing else { return }

        let location = touch.location(in: self)

        if catcher.contains(location) {
            touchState = .dragging
            touchStartData = TouchStartData(
                touchPosition: location,
                catcherPosition: catcher.position
            )
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard touchState == .dragging,
            let touch = touches.first,
            let startData = touchStartData,
            gameState == .playing
        else { return }

        let currentLocation = touch.location(in: self)
        let deltaX = currentLocation.x - startData.touchPosition.x
        let newX = startData.catcherPosition.x + deltaX

        let leftBound = GameConfiguration.catcherHalfWidth
        let rightBound = size.width - GameConfiguration.catcherHalfWidth
        let constrainedX = max(leftBound, min(rightBound, newX))

        catcher.position.x = constrainedX
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        endTouch()
    }

    override func touchesCancelled(
        _ touches: Set<UITouch>, with event: UIEvent?
    ) {
        endTouch()
    }

    private func endTouch() {
        touchState = .idle
        touchStartData = nil
    }
}

extension GameScene: SKPhysicsContactDelegate {

    func didBegin(_ contact: SKPhysicsContact) {
        let (catcherBody, itemBody) = identifyContactBodies(contact)

        guard let itemNode = itemBody?.node as? SKSpriteNode else { return }

        if itemBody?.categoryBitMask == PhysicsCategory.goodItem {
            handleGoodItemCaught(itemNode)
        } else if itemBody?.categoryBitMask == PhysicsCategory.badItem {
            handleBadItemCaught(itemNode)
        } else if itemBody?.categoryBitMask == PhysicsCategory.doublePointItem {
            handleDoublePointItemCaught(itemNode)
        }else if itemBody?.categoryBitMask == PhysicsCategory.addHealthItem {
            handleAddHealthItemCaught(itemNode)
        }else if itemBody?.categoryBitMask == PhysicsCategory.slowMotionItem {
            handleSlowMotionItemCaught(itemNode)
        }


    }

    private func identifyContactBodies(_ contact: SKPhysicsContact) -> (
        SKPhysicsBody?, SKPhysicsBody?
    ) {
        let bodyA = contact.bodyA
        let bodyB = contact.bodyB

        if bodyA.categoryBitMask == PhysicsCategory.catcher {
            return (bodyA, bodyB)
        } else if bodyB.categoryBitMask == PhysicsCategory.catcher {
            return (bodyB, bodyA)
        }

        return (nil, nil)
    }
}
