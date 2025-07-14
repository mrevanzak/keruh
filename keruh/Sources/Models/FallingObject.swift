//
//  FallingObject.swift
//  keruh
//
//  Created by Farrell Matthew Lim on 14/07/25.
//

import SpriteKit

struct FallingObjectType {
    let assetName: String
    let size: CGSize
    let points: Int
    let fallSpeed: CGFloat
    let rarity: Float
    let isSpecial: Bool
    let isCollectible: Bool

    static let apple = FallingObjectType(
        assetName: "apple",
        size: CGSize(width: 35, height: 35),
        points: 10,
        fallSpeed: 100,
        rarity: 0.4,
        isSpecial: false,
        isCollectible: true
    )

    static let banana = FallingObjectType(
        assetName: "banana",
        size: CGSize(width: 25, height: 40),
        points: 15,
        fallSpeed: 120,
        rarity: 0.3,
        isSpecial: false,
        isCollectible: true
    )

    static let cherry = FallingObjectType(
        assetName: "cherry",
        size: CGSize(width: 20, height: 20),
        points: 20,
        fallSpeed: 80,
        rarity: 0.25,
        isSpecial: false,
        isCollectible: true
    )

    static let diamond = FallingObjectType(
        assetName: "diamond",
        size: CGSize(width: 30, height: 30),
        points: 50,
        fallSpeed: 60,
        rarity: 0.05,
        isSpecial: false,
        isCollectible: true
    )

    static let allTypes = [apple, banana, cherry, diamond]

    static func random() -> FallingObjectType {
        let randomValue = Float.random(in: 0...1)
        var cumulativeWeight: Float = 0

        for type in allTypes {
            cumulativeWeight += type.rarity
            if randomValue <= cumulativeWeight {
                return type
            }
        }

        return apple
    }
}

class FallingObject: BaseGameObject {
    private let spriteNode: SKSpriteNode
    private let objectType: FallingObjectType

    init(type: FallingObjectType) {
        self.objectType = type
        self.spriteNode = SKSpriteNode()
        super.init(size: type.size)
        node.addChild(spriteNode)
    }

    override func setup() {
        // Load custom asset texture
        spriteNode.texture = loadTexture(named: objectType.assetName)
        spriteNode.size = size

        spriteNode.physicsBody = SKPhysicsBody(rectangleOf: size)
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
        onComplete: @escaping () -> Void
    ) {
        node.position = position

        // Calculate duration based on distance and fall speed
        let distance = abs(position.y - targetY)
        let duration = TimeInterval(distance / objectType.fallSpeed)

        let fallAction = SKAction.moveTo(y: targetY, duration: duration)
        let completeAction = SKAction.run(onComplete)
        let sequence = SKAction.sequence([fallAction, completeAction])

        node.run(sequence)
    }
}
