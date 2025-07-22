//
//  SettingsManager.swift
//  keruh
//
//  Created by Farrell Matthew Lim on 22/07/25.
//

import Foundation

final class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let bgm = "bgmEnabled"
        static let sound = "soundEnabled"
        static let haptics = "hapticsEnabled"
    }
    
    @Published var bgmEnabled: Bool {
        didSet { defaults.set(bgmEnabled, forKey: Keys.bgm) }
    }

    @Published var soundEnabled: Bool {
        didSet { defaults.set(soundEnabled, forKey: Keys.sound) }
    }
    
    @Published var hapticsEnabled: Bool {
        didSet { defaults.set(hapticsEnabled, forKey: Keys.haptics) }
    }

    init() {
        bgmEnabled = defaults.object(forKey: Keys.bgm) as? Bool ?? true
        soundEnabled = defaults.object(forKey: Keys.sound) as? Bool ?? true
        hapticsEnabled = defaults.object(forKey: Keys.haptics) as? Bool ?? true
    }
}
