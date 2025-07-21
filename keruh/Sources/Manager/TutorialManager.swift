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
      return "Move Your Character"
    case .catching:
      return "Catch Clean Items"
    case .avoidHarmful:
      return "Avoid Harmful Trash"
    case .powerUps:
      return "Collect Power-Ups"
    case .scoring:
      return "Score Points"
    case .completed:
      return "Tutorial Complete!"
    }
  }

  var description: String {
    switch self {
    case .movement:
      return "Tap and drag to move your character left and right"
    case .catching:
      return
        "Catch falling bottles, cans, and plastic bags to clean the river"
    case .avoidHarmful:
      return "Avoid catching tires - they will damage your health!"
    case .powerUps:
      return
        "Collect hearts for health, coins for double points, and clocks for slow motion"
    case .scoring:
      return
        "Different items give different points. Try to get a high score!"
    case .completed:
      return "You're ready to save the river! Good luck!"
    }
  }

  var buttonText: String {
    switch self {
    case .completed:
      return "Start Playing!"
    default:
      return "Next"
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

      if nextStep == .completed {
        completeTutorial()
      }
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
