//
//  FallingObject.swift
//  keruh
//
//  Created by Farrell Matthew Lim on 14/07/25.
//

import SpriteKit

struct FallingObjectType {
    let assetName: String
    private let size: CGSize?
    let points: Int
    let fallSpeed: CGFloat
    let rarity: Float
    let isSpecial: Bool
    let isCollectible: Bool

    // Default size for falling objects
    static let defaultSize = CGSize(width: 48, height: 48)

    init(
        assetName: String,
        size: CGSize? = nil,
        points: Int,
        fallSpeed: CGFloat,
        rarity: Float,
        isSpecial: Bool,
        isCollectible: Bool
    ) {
        self.assetName = assetName
        self.size = size
        self.points = points
        self.fallSpeed = fallSpeed
        self.rarity = rarity
        self.isSpecial = isSpecial
        self.isCollectible = isCollectible
    }

    // Helper method to get the actual size to use
    func getSize() -> CGSize {
        return size ?? FallingObjectType.defaultSize
    }

    static let tire = FallingObjectType(
        assetName: "collect_ban",
        size: CGSize(width: 90, height: 90),
        points: 10,
        fallSpeed: 100,
        rarity: 0.1,
        isSpecial: false,
        isCollectible: true
    )

    static let bottle = FallingObjectType(
        assetName: "collect_botol",
        points: 15,
        fallSpeed: 120,
        rarity: 0.1,
        isSpecial: false,
        isCollectible: true
    )

    static let ciki = FallingObjectType(
        assetName: "collect_ciki",
        points: 20,
        fallSpeed: 80,
        rarity: 0.1,
        isSpecial: false,
        isCollectible: true
    )

    static let can = FallingObjectType(
        assetName: "collect_kaleng",
        points: 50,
        fallSpeed: 60,
        rarity: 0.1,
        isSpecial: false,
        isCollectible: true
    )

    static let plasticBag = FallingObjectType(
        assetName: "collect_kresek",
        points: 50,
        fallSpeed: 60,
        rarity: 0.1,
        isSpecial: false,
        isCollectible: true
    )

    static let sandal = FallingObjectType(
        assetName: "collect_sandal",
        points: 50,
        fallSpeed: 60,
        rarity: 0.1,
        isSpecial: false,
        isCollectible: true
    )

    static let diaper = FallingObjectType(
        assetName: "collect_popmie",
        points: 50,
        fallSpeed: 60,
        rarity: 0.1,
        isSpecial: false,
        isCollectible: true
    )

    //power up
    static let heart = FallingObjectType(
        assetName: "power_extralive",
        size: CGSize(width: 30, height: 30),
        points: 0,
        fallSpeed: 90,
        rarity: 0.05,
        isSpecial: true,
        isCollectible: true
    )

    static let coin = FallingObjectType(
        assetName: "power_doublepoint",
        size: CGSize(width: 30, height: 30),
        points: 0,
        fallSpeed: 90,
        rarity: 0.05,
        isSpecial: true,
        isCollectible: true
    )

    static let clock = FallingObjectType(
        assetName: "power_slowdown",
        size: CGSize(width: 30, height: 30),
        points: 0,
        fallSpeed: 90,
        rarity: 0.05,
        isSpecial: true,
        isCollectible: true
    )

    static let allTypes = [
        tire, ciki, bottle, can, plasticBag, heart, coin, clock,
    ]

    static func random() -> FallingObjectType {
        let randomValue = Float.random(in: 0...1)
        var cumulativeWeight: Float = 0

        for type in allTypes {
            cumulativeWeight += type.rarity
            if randomValue <= cumulativeWeight {
                return type
            }
        }

        return bottle 
    }
}

class FallingObject: BaseGameObject {
    private let spriteNode: SKSpriteNode
    private let objectType: FallingObjectType

    init(type: FallingObjectType) {
        self.objectType = type
        self.spriteNode = SKSpriteNode()
        super.init(size: type.getSize())
        node.addChild(spriteNode)
    }

    override func setup() {
        // Load custom asset texture
        spriteNode.texture = loadTexture(named: objectType.assetName)
        spriteNode.size = objectType.getSize()

        spriteNode.physicsBody = SKPhysicsBody(
            rectangleOf: objectType.getSize()
        )
        spriteNode.physicsBody?.isDynamic = true
        spriteNode.physicsBody?.categoryBitMask = PhysicsCategory.fallingObject
        spriteNode.physicsBody?.contactTestBitMask = PhysicsCategory.catcher
        spriteNode.physicsBody?.collisionBitMask = 0
        spriteNode.physicsBody?.affectedByGravity = false
    }

    private func loadTexture(named name: String) -> SKTexture? {
        // Load texture from bundle
        if let image = UIImage(named: name) {
            return SKTexture(image: image)
        }
        return nil
    }

    func startFalling(
        from position: CGPoint,
        to targetY: CGFloat,
        duration: TimeInterval,
        onComplete: @escaping () -> Void
    ) {
        node.position = position

        let fallAction = SKAction.moveTo(y: targetY, duration: duration)
        let completeAction = SKAction.run(onComplete)
        let sequence = SKAction.sequence([fallAction, completeAction])

        node.run(sequence)
    }

    // Additional methods to leverage the struct properties
    func getPoints() -> Int {
        return objectType.points
    }

    func getFallSpeed() -> CGFloat {
        return objectType.fallSpeed
    }

    func isSpecialObject() -> Bool {
        return objectType.isSpecial
    }

    func startFallingWithTypeSpeed(
        from position: CGPoint,
        to targetY: CGFloat,
        duration: TimeInterval,
        initialScale: CGFloat = 1.0,
        finalScale: CGFloat = 1.0,
        onComplete: @escaping () -> Void
    ) {
        node.position = position
        node.setScale(initialScale)
        
//        // Calculate duration based on distance and fall speed
//        let distance = abs(position.y - targetY)
//        let duration = TimeInterval(distance / objectType.fallSpeed)

        let fallAction = SKAction.moveTo(y: targetY, duration: duration)
        let scaleAction = SKAction.scale(to: finalScale, duration: duration)
        let completeAction = SKAction.run(onComplete)

        let simultaneousActions = SKAction.group([fallAction, scaleAction])
        let sequence = SKAction.sequence([simultaneousActions, completeAction])

        node.run(sequence)
    }
}

struct FallingObjectData {
    let id: UUID = UUID()
    let type: FallingObjectType
    var position: CGPoint
    let targetY: CGFloat
    let fallDuration: TimeInterval
    var isActive: Bool = true
}

extension FallingObject {
    func startFallingWithPerspective(
        from startPosition: CGPoint,
        to endPosition: CGPoint,
        initialScale: CGFloat,
        finalScale: CGFloat,
        duration: TimeInterval,
        completion: @escaping () -> Void
    ) {
        node.position = startPosition
        node.setScale(initialScale)

        let moveAction = SKAction.move(to: endPosition, duration: duration)
        let scaleAction = SKAction.scale(to: finalScale, duration: duration)

        moveAction.timingMode = .easeOut
        scaleAction.timingMode = .easeOut

        let combinedAction = SKAction.group([moveAction, scaleAction])
        let sequenceAction = SKAction.sequence([
            combinedAction,
            SKAction.run(completion),
        ])

        node.run(sequenceAction)
    }
}
