//
//  AudioManager.swift
//  keruh
//
//  Created by Elizabeth Celine Liong on 22/07/25.
//

import AVFoundation

class AudioManager {
    static let shared = AudioManager()
    private var player: AVAudioPlayer?

    private init() {}
    
    func playBackgroundMusic() {
        playMusic(named: "BGM.mp3", withExtension: "mp3")
    }
    
    private func playMusic(named name: String, withExtension ext: String) {
        guard let path = Bundle.main.path(forResource: name, ofType: nil) else {
            print("Sound file \(name).\(ext) not found.")
            return
        }

        let url = URL(fileURLWithPath: path)

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.play()
            player?.volume = 0.2
            player?.numberOfLoops = -1
        } catch {
            print("Failed to play sound: \(error.localizedDescription)")
        }
    }

    func stopSound() {
        player?.stop()
        player = nil
    }
}
