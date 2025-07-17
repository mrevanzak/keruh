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
        backgroundColor = SKColor(
            red: 38 / 255,
            green: 175 / 255,
            blue: 225 / 255,
            alpha: 1.0
        )
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
            width: size.width * 1.2,
            height: size.height * 0.25
        )
        cloudsNode.position = CGPoint(x: size.width / 2, y: horizonY - 50)
        cloudsNode.zPosition = -9
        cloudsNode.alpha = 0
        addChild(cloudsNode)

        // Waves
        wavesNode = SKSpriteNode(imageNamed: "ombak")
        wavesNode.anchorPoint = CGPoint(x: 0.55, y: 1.0)
        wavesNode.position = CGPoint(x: size.width / 2, y: horizonY)
        wavesNode.size = CGSize(
            width: size.width * 1.8,
            height: riverHeight * 1.5
        )
        wavesNode.zPosition = -5
        wavesNode.alpha = 0
        addChild(wavesNode)

        // Animations
        let skyAndRiver = SKAction.sequence([
            .wait(forDuration: 0.5), .fadeIn(withDuration: 1.0),
        ])
        skyNode.run(skyAndRiver)
        riverBgNode.run(skyAndRiver)

        let wave = SKAction.sequence([
            .wait(forDuration: 0.8), .fadeIn(withDuration: 0.6),
        ])
        wavesNode.run(wave)
        
        let cloud = SKAction.sequence([
            .wait(forDuration: 1.5),
            .fadeIn(withDuration: 0.2),
            .moveBy(x: 0, y: 60, duration: 0.6),
        ])
        cloudsNode.run(cloud)

        let islandLeft = SKAction.sequence([
            .wait(forDuration: 0.1),
            .move(
                to: CGPoint(
                    x: leftIslandNode.size.width / 2,
                    y: islandYPosition
                ),
                duration: 0.8
            ),
        ])
        islandLeft.timingMode = .easeOut
        leftIslandNode.run(islandLeft)

        let islandRight = SKAction.sequence([
            .wait(forDuration: 0.1),
            .move(
                to: CGPoint(
                    x: size.width - (rightIslandNode.size.width / 2),
                    y: islandYPosition
                ),
                duration: 0.8
            ),
        ])
        islandRight.timingMode = .easeOut
        rightIslandNode.run(islandRight)
    }
}
