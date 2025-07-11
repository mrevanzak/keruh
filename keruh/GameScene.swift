//
//  GameScene.swift
//  keruh
//
//  Created by Revanza Kurniawan on 10/07/25.
//

import GameplayKit
import SpriteKit

// MARK: - Game Configuration

private enum GameConfiguration {
  static let catcherSize = CGSize(width: 80, height: 20)
  static let catcherCornerRadius: CGFloat = 8
  static let catcherBottomOffset: CGFloat = 60
  static let catcherHalfWidth: CGFloat = 40

  static let fallingObjectRadius: CGFloat = 15
  static let initialSpawnInterval: TimeInterval = 2.0
  static let fallDurationRange: ClosedRange<TimeInterval> = 3.0...5.0
  static let speedIncreaseInterval = 5
  static let speedMultiplier: TimeInterval = 0.9
  static let minimumSpawnInterval: TimeInterval = 0.5

  static let uiPadding: CGFloat = 20
  static let labelSpacing: CGFloat = 35
  static let fontSize: CGFloat = 24

  static let catcherScaleAnimation: CGFloat = 1.2
  static let animationDuration: TimeInterval = 0.1
}

private enum GameColors {
  static let background = SKColor.systemBlue
  static let catcher = SKColor.systemGreen
  static let catcherStroke = SKColor.green
  static let scoreText = SKColor.white
  static let missedText = SKColor.red
  static let fallingObjects: [SKColor] = [.systemRed, .systemYellow, .systemOrange, .systemPurple]
}

private struct PhysicsCategory {
  static let catcher: UInt32 = 0x1 << 0
  static let fallingObject: UInt32 = 0x1 << 1
}

// MARK: - GameScene

final class GameScene: SKScene {

  // MARK: - GameplayKit Compatibility
  var entities = [GKEntity]()
  var graphs = [String: GKGraph]()

  // MARK: - Private Properties
  private var gameState: GameState = .playing
  private var safeAreaInsets: UIEdgeInsets = .zero

  // Game Elements
  private var catcher: SKShapeNode!
  private var scoreLabel: SKLabelNode!
  private var missedLabel: SKLabelNode!

  // Game State
  private var score = 0 {
    didSet { updateScoreDisplay() }
  }

  private var missed = 0 {
    didSet { updateMissedDisplay() }
  }

  private var gameSpeed: TimeInterval = GameConfiguration.initialSpawnInterval {
    didSet { updateSpawning() }
  }

  // Touch Handling
  private var touchState: TouchState = .idle
  private var touchStartData: TouchStartData?

  // MARK: - Lifecycle

  override func didMove(to view: SKView) {
    setupGame()
  }
}

// MARK: - Game State

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

// MARK: - Setup

extension GameScene {

  fileprivate func setupGame() {
    setupScene()
    setupCatcher()
    setupUI()
    startGameplay()
  }

  fileprivate func setupScene() {
    backgroundColor = GameColors.background
    physicsWorld.contactDelegate = self
    physicsWorld.gravity = .zero
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
    catcherNode.position = CGPoint(x: size.width / 2, y: GameConfiguration.catcherBottomOffset)

    // Physics
    catcherNode.physicsBody = SKPhysicsBody(rectangleOf: GameConfiguration.catcherSize)
    catcherNode.physicsBody?.isDynamic = false
    catcherNode.physicsBody?.categoryBitMask = PhysicsCategory.catcher
    catcherNode.physicsBody?.contactTestBitMask = PhysicsCategory.fallingObject
    catcherNode.physicsBody?.collisionBitMask = 0

    return catcherNode
  }

  fileprivate func setupUI() {
    scoreLabel = createLabel(text: "Score: 0", color: GameColors.scoreText)
    missedLabel = createLabel(text: "Missed: 0", color: GameColors.missedText)

    addChild(scoreLabel)
    addChild(missedLabel)

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
}

// MARK: - Game Logic

extension GameScene {

  fileprivate func startSpawningObjects() {
    removeAction(forKey: "spawning")

    let spawn = SKAction.run { [weak self] in
      self?.spawnFallingObject()
    }
    let wait = SKAction.wait(forDuration: gameSpeed)
    let sequence = SKAction.sequence([spawn, wait])
    let repeatAction = SKAction.repeatForever(sequence)

    run(repeatAction, withKey: "spawning")
  }

  fileprivate func spawnFallingObject() {
    guard gameState == .playing else { return }

    let fallingObject = createFallingObject()
    addChild(fallingObject)
    animateFallingObject(fallingObject)
  }

  fileprivate func createFallingObject() -> SKShapeNode {
    let radius = GameConfiguration.fallingObjectRadius
    let object = SKShapeNode(circleOfRadius: radius)

    // Appearance
    object.fillColor = GameColors.fallingObjects.randomElement() ?? GameColors.fallingObjects[0]
    object.strokeColor = .black
    object.lineWidth = 1

    // Position
    let randomX = CGFloat.random(in: radius...(size.width - radius))
    object.position = CGPoint(x: randomX, y: size.height + radius)

    // Physics
    object.physicsBody = SKPhysicsBody(circleOfRadius: radius)
    object.physicsBody?.isDynamic = true
    object.physicsBody?.categoryBitMask = PhysicsCategory.fallingObject
    object.physicsBody?.contactTestBitMask = PhysicsCategory.catcher
    object.physicsBody?.collisionBitMask = 0
    object.physicsBody?.affectedByGravity = false

    return object
  }

  fileprivate func animateFallingObject(_ object: SKShapeNode) {
    let fallDuration = TimeInterval.random(in: GameConfiguration.fallDurationRange)
    let fallAction = SKAction.moveTo(
      y: -GameConfiguration.fallingObjectRadius, duration: fallDuration)
    let missedAction = SKAction.run { [weak self] in
      self?.handleObjectMissed()
    }
    let removeAction = SKAction.removeFromParent()

    let sequence = SKAction.sequence([fallAction, missedAction, removeAction])
    object.run(sequence)
  }

  fileprivate func handleObjectCaught(_ object: SKShapeNode) {
    score += 1
    object.removeFromParent()

    provideCatcherFeedback()
    checkForSpeedIncrease()
  }

  fileprivate func handleObjectMissed() {
    missed += 1
  }

  fileprivate func provideCatcherFeedback() {
    let scaleUp = SKAction.scale(
      to: GameConfiguration.catcherScaleAnimation, duration: GameConfiguration.animationDuration)
    let scaleDown = SKAction.scale(to: 1.0, duration: GameConfiguration.animationDuration)
    let sequence = SKAction.sequence([scaleUp, scaleDown])

    catcher.run(sequence)
  }

  fileprivate func checkForSpeedIncrease() {
    guard score % GameConfiguration.speedIncreaseInterval == 0,
      gameSpeed > GameConfiguration.minimumSpawnInterval
    else { return }

    gameSpeed *= GameConfiguration.speedMultiplier
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
}

// MARK: - UI Management

extension GameScene {

  func setSafeAreaInsets(_ insets: UIEdgeInsets) {
    safeAreaInsets = insets
    updateUIPositions()
  }

  func updateUIPositions() {
    let safeAreaTop = safeAreaInsets.top + GameConfiguration.uiPadding

    scoreLabel.position = CGPoint(
      x: GameConfiguration.uiPadding,
      y: size.height - safeAreaTop
    )

    missedLabel.position = CGPoint(
      x: GameConfiguration.uiPadding,
      y: size.height - safeAreaTop - GameConfiguration.labelSpacing
    )
  }
}

// MARK: - Touch Handling

extension GameScene {

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let touch = touches.first,
      gameState == .playing
    else { return }

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
      let startData = touchStartData
    else { return }

    let currentLocation = touch.location(in: self)
    let deltaX = currentLocation.x - startData.touchPosition.x
    let newX = startData.catcherPosition.x + deltaX

    // Constrain to screen bounds
    let constrainedX = max(
      GameConfiguration.catcherHalfWidth,
      min(size.width - GameConfiguration.catcherHalfWidth, newX)
    )

    catcher.position.x = constrainedX
  }

  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    endTouch()
  }

  override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    endTouch()
  }

  private func endTouch() {
    touchState = .idle
    touchStartData = nil
  }
}

// MARK: - Physics Contact Delegate

extension GameScene: SKPhysicsContactDelegate {

  func didBegin(_ contact: SKPhysicsContact) {
    let (catcherBody, fallingObjectBody) = identifyContactBodies(contact)

    guard let fallingObject = fallingObjectBody?.node as? SKShapeNode else { return }

    handleObjectCaught(fallingObject)
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
