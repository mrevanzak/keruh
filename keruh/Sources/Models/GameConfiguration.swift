//
//  GameConfiguration.swift
//  keruh
//
//  Created by Farrell Matthew Lim on 14/07/25.
//

import GameplayKit
import SpriteKit
import SwiftUI

enum GameConfiguration {
    static let catcherBottomOffset: CGFloat = 60
    static let fallingObjectRadius: CGFloat = 15
    static let fallingObjectSize: CGSize = CGSize(width: 10, height: 10)
    static let initialSpawnInterval: TimeInterval = 2.0
    static let fallDurationRange: ClosedRange<TimeInterval> = 3.0...5.0
    static let speedIncreaseInterval = 5
    static let speedMultiplier: TimeInterval = 0.9
    static let minimumSpawnInterval: TimeInterval = 0.5

    static let uiPadding: CGFloat = 36
    static let labelSpacing: CGFloat = 35
    static let fontSize: CGFloat = 24

    static let catcherScaleAnimation: CGFloat = 1.2
    static let animationDuration: TimeInterval = 0.1
}

enum GameColors {
    static let background = SKColor.systemBlue
    static let catcher = SKColor.systemGreen
    static let catcherStroke = SKColor.green
    static let scoreText = SKColor.white
    static let missedText = SKColor.red
    static let fallingObjects: [SKColor] = [
        .systemRed, .systemYellow, .systemOrange, .systemPurple,
    ]
}

struct PhysicsCategory {
    static let catcher: UInt32 = 0x1 << 0
    static let fallingObject: UInt32 = 0x1 << 1
}
