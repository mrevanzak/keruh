import SwiftUI

struct TutorialOverlayView: View {
    @ObservedObject var tutorialManager: TutorialManager

    var body: some View {
        ZStack {
            if tutorialManager.isShowingTutorial {
                // Semi-transparent background
                Color.black.opacity(0.8)
                    .ignoresSafeArea()
                    .transition(.opacity)

                // Tutorial content
                TutorialContentView(tutorialManager: tutorialManager)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .bottom).combined(
                                with: .opacity
                            ),
                            removal: .move(edge: .bottom).combined(
                                with: .opacity
                            )
                        )
                    )
            }
        }
        .animation(
            .easeInOut(duration: 0.3),
            value: tutorialManager.isShowingTutorial
        )
    }
}

struct TutorialStepIcon: View {
    let step: TutorialStep

    var body: some View {
        Group {
            switch step {
            case .movement:
                Image(systemName: "arrow.left.and.right")
                    .foregroundColor(.green)
            case .catching:
                Image(systemName: "hand.raised.fill")
                    .foregroundColor(.orange)
            case .avoidHarmful:
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
            case .powerUps:
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
            case .scoring:
                Image(systemName: "trophy.fill")
                    .foregroundColor(.purple)
            case .completed:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .font(.system(size: 40))
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.3), value: step)
    }
}

#Preview {
    struct TutorialPreview: View {
        @StateObject private var tutorialManager = TutorialManager()

        var body: some View {
            ZStack {
                Color.blue.ignoresSafeArea()

                VStack {
                    Text("Game Background")
                        .font(.title)
                        .foregroundColor(.white)

                    Spacer()

                    Button("Show Tutorial") {
                        tutorialManager.startTutorial()
                    }
                    .buttonStyle(.borderedProminent)
                }

                TutorialOverlayView(tutorialManager: tutorialManager)
            }
        }
    }

    return TutorialPreview()
}
