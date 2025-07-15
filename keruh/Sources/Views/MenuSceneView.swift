//
//  MenuSceneView.swift
//  keruh
//
//  Created by Elizabeth Celine Liong on 14/07/25.
//

import SpriteKit

class MenuScene: SKScene {

    private var skyNode: SKSpriteNode!
    private var riverBgNode: SKSpriteNode!
    private var waterNode: SKSpriteNode!
    private var leftIslandNode: SKSpriteNode!
    private var rightIslandNode: SKSpriteNode!
    private var cloudsNode: SKSpriteNode!
    private var wavesNode: SKSpriteNode!

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.5, green: 0.8, blue: 0.95, alpha: 1.0)
    }

    func buildAndAnimateMenu() {
        guard scene != nil else { return }

        // Sky and River Background
        let skyHeight = size.height * 0.35
        let riverHeight = size.height * 0.65
        let horizonY = size.height * 0.65

        skyNode = SKSpriteNode(imageNamed: "langit")
        skyNode.anchorPoint = CGPoint(x: 0.5, y: 0)
        skyNode.position = CGPoint(x: size.width / 2, y: horizonY)
        skyNode.size = CGSize(width: size.width, height: skyHeight)
        skyNode.zPosition = -10
        skyNode.alpha = 0
        addChild(skyNode)

        riverBgNode = SKSpriteNode(imageNamed: "bg_sungai")
        riverBgNode.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        riverBgNode.position = CGPoint(x: size.width / 2, y: horizonY)
        riverBgNode.size = CGSize(width: size.width, height: riverHeight)
        riverBgNode.zPosition = -8
        riverBgNode.alpha = 0
        addChild(riverBgNode)

        // Islands
        leftIslandNode = SKSpriteNode(imageNamed: "pulau_kiri")
        leftIslandNode.anchorPoint = CGPoint(x: 1.0, y: 0.0)
        leftIslandNode.size = CGSize(
            width: size.width * 0.65,
            height: size.height * 0.8
        )
        let islandYPosition = size.height * 0.05
        leftIslandNode.position = CGPoint(
            x: -leftIslandNode.size.width,
            y: islandYPosition
        )
        leftIslandNode.zPosition = 10
        addChild(leftIslandNode)

        rightIslandNode = SKSpriteNode(imageNamed: "pulau_kanan")
        rightIslandNode.anchorPoint = CGPoint(x: 0.1, y: 0.0)
        rightIslandNode.size = CGSize(
            width: size.width * 0.65,
            height: size.height * 0.8
        )
        rightIslandNode.position = CGPoint(
            x: size.width + rightIslandNode.size.width,
            y: islandYPosition
        )
        rightIslandNode.zPosition = 10
        addChild(rightIslandNode)

        // Clouds
        cloudsNode = SKSpriteNode(imageNamed: "awan")
        cloudsNode.anchorPoint = CGPoint(x: 0.5, y: 0)
        cloudsNode.size = CGSize(
            width: size.width * 1.1,
            height: size.height * 0.25
        )
        cloudsNode.position = CGPoint(x: size.width / 2, y: horizonY + 10)
        cloudsNode.zPosition = -8
        cloudsNode.alpha = 0
        addChild(cloudsNode)

        // Waves
        wavesNode = SKSpriteNode(imageNamed: "ombak")
        wavesNode.anchorPoint = CGPoint(x: 0.55, y: 1.0)
        wavesNode.position = CGPoint(x: size.width / 2, y: horizonY)
        wavesNode.size = CGSize(width: size.width * 1.8, height: riverHeight * 1.5)
        wavesNode.zPosition = -5
        wavesNode.alpha = 0
        addChild(wavesNode)

        // Animations
        let fadeInBackground = SKAction.fadeIn(withDuration: 0.5)
        skyNode.run(fadeInBackground)
        riverBgNode.run(fadeInBackground)
        
        let waitAndFadeIn = SKAction.sequence([
            .wait(forDuration: 0.8), .fadeIn(withDuration: 0.6),
        ])
        cloudsNode.run(waitAndFadeIn)
        wavesNode.run(waitAndFadeIn)

        let waitAndMoveLeft = SKAction.sequence([
            .wait(forDuration: 0.3),
            .move(
                to: CGPoint(
                    x: leftIslandNode.size.width / 2,
                    y: islandYPosition
                ),
                duration: 1.0
            ),
        ])
        waitAndMoveLeft.timingMode = .easeOut
        leftIslandNode.run(waitAndMoveLeft)

        let waitAndMoveRight = SKAction.sequence([
            .wait(forDuration: 0.3),
            .move(
                to: CGPoint(
                    x: size.width - (rightIslandNode.size.width / 2),
                    y: islandYPosition
                ),
                duration: 1.0
            ),
        ])
        waitAndMoveRight.timingMode = .easeOut
        rightIslandNode.run(waitAndMoveRight)
    }
}
