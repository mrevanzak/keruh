import Combine
import SwiftUI

enum TutorialStep: Int, CaseIterable {
    case movement = 0
    case catching = 1
    case avoidHarmful = 2
    case powerUps = 3
    case scoring = 4
    case completed = 5

    var title: String {
        switch self {
        case .movement:
            return "Gerakkan Karakter"
        case .catching:
            return "Ambil sampah"
        case .avoidHarmful:
            return "Hindari makhluk hidup"
        case .powerUps:
            return "Ambil power-up"
        case .scoring:
            return "Dapatkan poin"
        case .completed:
            return "Selamat! Kamu siap bermain!"
        }
    }

    var description: String {
        switch self {
        case .movement:
            return "Sentuh dan seret untuk bergerak ke kiri dan kanan"
        case .catching:
            return
                "Tangkap sampah yang jatuh untuk membersihkan sungai"
        case .avoidHarmful:
            return "Mereka tidak merusak sungai"
        case .powerUps:
            return
                "Ambil jantung untuk menambah nyawa, koin untuk poin ganda, dan jam untuk mengurangi kecepatan"
        case .scoring:
            return
                "Berbagai barang memberikan poin yang berbeda. Coba dapatkan skor tinggi!"
        case .completed:
            return "Kamu siap menyelamatkan sungai! Semoga beruntung!"
        }
    }

    var buttonText: String {
        switch self {
        case .completed:
            return "Main"
        default:
            return "Selanjutnya"
        }
    }
}

class TutorialManager: ObservableObject {
    @Published var isShowingTutorial = false
    @Published var currentStep: TutorialStep = .movement

    private let userDefaults = UserDefaults.standard
    private let hasSeenTutorialKey = "hasSeenTutorial"
    private var completionCallback: (() -> Void)?

    func shouldShowTutorial() -> Bool {
        // Check if user has seen tutorial before
        let hasSeenTutorial = userDefaults.bool(forKey: hasSeenTutorialKey)
        return !hasSeenTutorial
    }

    func startTutorial() {
        // Don't start if already showing
        guard !isShowingTutorial else { return }

        currentStep = .movement
        isShowingTutorial = true
    }

    func nextStep() {
        let nextStepValue = currentStep.rawValue + 1

        if let nextStep = TutorialStep(rawValue: nextStepValue) {
            currentStep = nextStep
            return
        }

        if currentStep == .completed {
            completeTutorial()
        }
    }

    func onCompleted(completion: @escaping () -> Void) {
        completionCallback = completion
    }

    func skipTutorial() {
        completeTutorial()
    }

    private func completeTutorial() {
        userDefaults.set(true, forKey: hasSeenTutorialKey)
        isShowingTutorial = false

        // Call completion callback if set
        completionCallback?()
        completionCallback = nil
    }

    func resetTutorial() {
        userDefaults.set(false, forKey: hasSeenTutorialKey)
        currentStep = .movement
        completionCallback = nil
    }

    func forceStartTutorial() {
        // Force start tutorial even if already seen
        currentStep = .movement
        isShowingTutorial = true
    }

    var progress: Double {
        return Double(currentStep.rawValue)
            / Double(TutorialStep.allCases.count - 1)
    }
}
