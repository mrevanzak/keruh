//
//  GameOverlayContentView.swift
//  keruh
//
//  Created by Curosr on 23/07/25.
//

import SwiftUI

struct GameOverlayContentView<
    MainContent: View,
    ActionContent: View
>: View {
    let mainContent: MainContent
    let actionContent: ActionContent
    let onClose: (() -> Void)?
    let showCloseButton: Bool

    init(
        showCloseButton: Bool = false,
        onClose: (() -> Void)? = nil,
        titleImage: String,
        @ViewBuilder mainContent: () -> MainContent,
        @ViewBuilder actionContent: () -> ActionContent
    ) {
        self.showCloseButton = showCloseButton
        self.onClose = onClose
        self.mainContent = mainContent()
        self.actionContent = actionContent()
    }

    var body: some View {
        VStack {
            GeometryReader { outerGeo in
                let isLargeScreen = outerGeo.size.width > 800
                let maxImageWidth =
                    isLargeScreen ? min(outerGeo.size.width * 0.5, 700) : 350
                let scaleFactor = isLargeScreen ? 1.2 : 1.0

                Image("bg_game_over")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: maxImageWidth)
                    .frame(
                        width: outerGeo.size.width,
                        height: outerGeo.size.height
                    )
                    .overlay {
                        // Main Content Area
                        VStack {
                            mainContent
                        }
                        .frame(maxWidth: maxImageWidth * 0.7)
                        .padding(.top, maxImageWidth * 0.25)

                        ZStack {
                            // Close button (when enabled)
                            if showCloseButton, let onClose = onClose {
                                HStack {
                                    Button(action: onClose) {
                                        MenuButton(
                                            icon: "xmark",
                                            size: 35 * scaleFactor,
                                            padding: 6 * scaleFactor
                                        )
                                    }
                                }
                                .padding(.bottom, outerGeo.size.height * 0.5)
                                .padding(.leading, outerGeo.size.width * 0.8)
                            }

                            // Action Content
                            VStack {
                                actionContent
                            }
                            .padding(.top, outerGeo.size.height * 0.6)
                        }
                    }
            }
        }
        .padding(.horizontal, 16)
        .ignoresSafeArea(.all)
    }
}

struct MenuButton: View {
    let icon: String
    let size: CGFloat
    let padding: CGFloat

    var body: some View {
        ZStack {
            Image("icon_kotak")
                .resizable()
                .scaledToFill()
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .padding(padding)
                .foregroundStyle(Color.white)
        }
        .frame(width: size, height: size)
    }
}
