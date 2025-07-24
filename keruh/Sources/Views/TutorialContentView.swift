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
                    "Langkah \(tutorialManager.currentStep.rawValue + 1) dari \(TutorialStep.allCases.count)"
                )
                .font(.caption)
                .foregroundColor(.secondary)
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
            // Icon
            TutorialStepIcon(step: step)
            
            VStack(spacing: 8){
                // Title
                Text(step.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                // Description
                Text(step.description)
                    .font(.body)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                    .lineLimit(nil)
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
                    .frame(width: 60, height: 80)
                    .offset(x: characterPosition)
                    .onAppear {
                        startMovementDemo()
                    }

                Spacer()
            }
            .frame(height: 100)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
            )

            Text("Seret ke kiri dan kanan untuk bergerak")
                .font(.caption2)
                .foregroundColor(.blue)
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
