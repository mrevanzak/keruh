import SwiftUI

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
    VStack(spacing: 20) {
        ForEach(TutorialStep.allCases, id: \.self) { step in
            HStack {
                TutorialStepIcon(step: step)
                Text(step.title)
                    .font(.headline)
                Spacer()
            }
            .padding()
        }
    }
    .padding()
}
