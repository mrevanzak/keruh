//
//  Catcher.swift
//  keruh
//
//  Created by Farrell Matthew Lim on 14/07/25.
//

import SpriteKit

class Catcher: BaseGameObject {
    private let shapeNode: SKShapeNode

    static let size = CGSize(width: 80, height: 20)

    init() {
        self.shapeNode = SKShapeNode(
            rectOf: Catcher.size,
        )
        super.init(size: Catcher.size)
        node.addChild(shapeNode)
    }

    override func setup() {
        shapeNode.fillColor = GameColors.catcher
        shapeNode.strokeColor = GameColors.catcherStroke
        shapeNode.lineWidth = 2

        // Physics
        shapeNode.physicsBody = SKPhysicsBody(rectangleOf: size)
        shapeNode.physicsBody?.isDynamic = false
        shapeNode.physicsBody?.categoryBitMask = PhysicsCategory.catcher
        shapeNode.physicsBody?.contactTestBitMask =
            PhysicsCategory.fallingObject
        shapeNode.physicsBody?.collisionBitMask = 0
    }

    func moveTo(x: CGFloat, constrainedTo bounds: CGSize) {
        let constrainedX = max(
            (Catcher.size.width / 2),
            min(bounds.width - (Catcher.size.width / 2), x)
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
