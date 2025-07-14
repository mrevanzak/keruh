//
//  GameObject.swift
//  keruh
//
//  Created by Farrell Matthew Lim on 14/07/25.
//

import SpriteKit

protocol GameObject {
    var node: SKNode { get }
    var size: CGSize { get }
    func setup()
    func update(deltaTime: TimeInterval)
}

class BaseGameObject: GameObject {
    let node: SKNode
    let size: CGSize

    init(size: CGSize) {
        self.size = size
        self.node = SKNode()
        setup()
    }

    func setup() {
        // Override in subclasses
    }

    func update(deltaTime: TimeInterval) {
        // Override in subclasses
    }
}
