//
//  Catcher.swift
//  keruh
//
//  Created by Farrell Matthew Lim on 14/07/25.
//

import SpriteKit

class Catcher: BaseGameObject {
    private let spriteNode: SKSpriteNode

    static let size = CGSize(width: 98, height: 150)

    init() {
        self.spriteNode = SKSpriteNode(
            texture: nil,
            color: .clear,
            size: Catcher.size
        )
        super.init(size: Catcher.size)
        node.addChild(spriteNode)
        node.alpha = 0
    }

    override func setup() {
        // Load texture from assets
        spriteNode.texture = SKTexture(imageNamed: "lutfi")
        spriteNode.size = Catcher.size
        spriteNode.zPosition = 1

        // Setup physics
        spriteNode.physicsBody = SKPhysicsBody(rectangleOf: Catcher.size)
        spriteNode.physicsBody?.isDynamic = false
        spriteNode.physicsBody?.categoryBitMask = PhysicsCategory.catcher
        spriteNode.physicsBody?.contactTestBitMask =
            PhysicsCategory.fallingObject
        spriteNode.physicsBody?.collisionBitMask = 0
    }

    func moveTo(x: CGFloat, constrainedTo bounds: CGSize) {
        let constrainedX = max(
            Catcher.size.width / 2,
            min(bounds.width - Catcher.size.width / 2, x)
        )
        node.position.x = constrainedX
    }

    //    func animateCatch() {
    //        let scaleUp = SKAction.scale(
    //            to: GameConfiguration.catcherScaleAnimation,
    //            duration: GameConfiguration.animationDuration
    //        )
    //        let scaleDown = SKAction.scale(
    //            to: 1.0,
    //            duration: GameConfiguration.animationDuration
    //        )
    //        let sequence = SKAction.sequence([scaleUp, scaleDown])
    //        node.run(sequence)
    //    }
}
