//
//  GameConfiguration.swift
//  keruh
//
//  Created by Farrell Matthew Lim on 14/07/25.
//

import GameplayKit
import SpriteKit
import SwiftUI

struct PhysicsCategory {
    static let catcher: UInt32 = 0x1 << 0
    static let fallingObject: UInt32 = 0x1 << 1
}
