//
//  GameViewControllerWrapper.swift
//  keruh
//
//  Created by Richie Reuben Hermanto on 11/07/25.
//

import SwiftUI
import UIKit

struct GameViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> LeaderboardController {
        return LeaderboardController()
    }

    func updateUIViewController(_ uiViewController: LeaderboardController, context: Context) {
        // Tidak perlu implementasi tambahan untuk sekarang
    }
}
