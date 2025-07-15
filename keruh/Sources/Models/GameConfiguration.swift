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
    static let fallDurationRange: ClosedRange<TimeInterval> = 3.0...5.0
    static let speedIncreaseInterval = 5
    static let speedMultiplier: TimeInterval = 0.9
    static let minimumSpawnInterval: TimeInterval = 0.5

    static let uiPadding: CGFloat = 36
    static let labelSpacing: CGFloat = 35
}

struct PhysicsCategory {
    static let catcher: UInt32 = 0x1 << 0
    static let fallingObject: UInt32 = 0x1 << 1
}
