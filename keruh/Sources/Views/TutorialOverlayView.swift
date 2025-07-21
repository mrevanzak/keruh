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

#Preview {
    struct TutorialOverlayPreview: View {
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

    return TutorialOverlayPreview()
}
