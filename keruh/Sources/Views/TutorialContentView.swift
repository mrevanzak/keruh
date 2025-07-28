import SwiftUI

struct TutorialContentView: View {
    @ObservedObject var tutorialManager: TutorialManager

    var body: some View {
        VStack {
            Spacer()

            // Tutorial card
            VStack(spacing: 20) {
                // Progress bar
                TutorialProgressView(tutorialManager: tutorialManager)

                // Content based on step
                TutorialStepContent(step: tutorialManager.currentStep)

                // Navigation buttons
                TutorialNavigationButtons(tutorialManager: tutorialManager)
            }
            .padding(24)
            .background(
                Color(.systemBackground)
                    .opacity(0.95),
                in: RoundedRectangle(cornerRadius: 20)
            )
            .padding(.horizontal, 20)
            .animation(
                .easeInOut(duration: 0.4),
                value: tutorialManager.currentStep
            )
        }
    }
}

struct TutorialProgressView: View {
    @ObservedObject var tutorialManager: TutorialManager

    var body: some View {
        VStack(spacing: 8) {
            ProgressView(value: tutorialManager.progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .scaleEffect(y: 2.0)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.tertiary)
                        .frame(height: 6)
                )

            HStack {
                Text(
                    "\(tutorialManager.currentStep.rawValue + 1)/\(TutorialStep.allCases.count)"
                )
                .font(.figtree(size: 14))
                Spacer()
            }
        }
    }
}

struct TutorialNavigationButtons: View {
    @ObservedObject var tutorialManager: TutorialManager

    var body: some View {
        HStack(spacing: 12) {
            Button("Lewati") {
                tutorialManager.skipTutorial()
            }
            .foregroundColor(.gray)

            Spacer()

            Button(tutorialManager.currentStep.buttonText) {
                tutorialManager.nextStep()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

struct TutorialStepContent: View {
    let step: TutorialStep

    var body: some View {
        VStack(spacing: 16) {
            if step != .movement {
                Text(step.title)
                    .font(.figtree(size: 24))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            } else {
                Image("icon_arrow")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 150)
                    .padding(.vertical, 12)
            }

            // Step-specific content
            Group {
                switch step {
                case .catching:
                    TutorialItemsSection(
                        items: FallingObjectType.collectibles,
                        animateItems: true
                    )
                case .avoidHarmful:
                    TutorialItemsSection(
                        items: FallingObjectType.harmful,
                        animateItems: true
                    )
                case .powerUps:
                    TutorialItemsSection(
                        items: FallingObjectType.powerUps,
                        animateItems: true
                    )
                case .movement:
                    MovementDemoView()
                default:
                    EmptyView()
                }
            }

            if step != .completed {

                VStack(spacing: 8) {
                    // title for movement
                    if step == .movement {
                        Text(step.title)
                            .font(.figtree(size: 24))
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                    }

                    // Description
                    Text(step.description)
                        .font(.figtree(size: 16))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                        .lineLimit(nil)
                }.padding(.vertical, 8)
            } else {
                Image("bg_game_over")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200)
            }
        }
    }
}

struct MovementDemoView: View {
    @State private var characterPosition: CGFloat = 0
    @State private var isAnimationActive = false

    var body: some View {
        VStack(spacing: 12) {
            // Demo area
            HStack {
                Spacer()

                Image("lutfi")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100)
                    .offset(x: characterPosition)
                    .onAppear {
                        startMovementDemo()
                    }

                Spacer()
            }
            .frame(height: 150)
        }
    }

    private func startMovementDemo() {
        withAnimation(
            .easeInOut(duration: 1.5).repeatForever(autoreverses: true)
        ) {
            characterPosition = isAnimationActive ? -30 : 30
            isAnimationActive.toggle()
        }
    }
}

#Preview {
    struct TutorialContentPreview: View {
        @StateObject private var tutorialManager = TutorialManager()

        var body: some View {
            ZStack {
                Color.gray.opacity(0.2).ignoresSafeArea()

                TutorialContentView(tutorialManager: tutorialManager)
                    .onAppear {
                        tutorialManager.startTutorial()
                    }
            }
        }
    }

    return TutorialContentPreview()
}
