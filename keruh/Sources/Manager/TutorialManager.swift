import Combine
import SwiftUI

enum TutorialStep: Int, CaseIterable {
    case movement = 0
    case catching = 1
    case avoidHarmful = 2
    case powerUps = 3
    case completed = 4

    var title: String {
        switch self {
        case .movement:
            return "Kontrol karakter"
        case .catching:
            return "Pungut sampah-sampahnya!"
        case .avoidHarmful:
            return "Hindari makhluk hidup yang tinggal di sungai!"
        case .powerUps:
            return "Ambil power up untuk jadi tak terkalahkan!"
        case .completed:
            return "Kumpulkan sampah sebanyak-banyaknya!"
        }
    }

    var description: String {
        switch self {
        case .movement:
            return
                "Tekan dan geser karakter ke kanan atau kiri untuk menangkap sampah!"
        case .catching:
            return
                "Tiap jenis sampah punya poinnya sendiri-sendiri. Kumpulkan sebanyak mungkin dan raih skor tertinggi sekarang!"
        case .avoidHarmful:
            return "Hati-hati jika tertangkap maka nyawamu akan dikurangi!"
        case .powerUps:
            return
                "Langsung aktif saat kamu ambil!"
        case .completed:
            return ""
        }
    }

    var buttonText: String {
        switch self {
        case .completed:
            return "Main sekarang!"
        default:
            return "Lanjut"
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
