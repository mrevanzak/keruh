//
//  GameViewController.swift
//  keruh
//
//  Created by Revanza Kurniawan on 10/07/25.
//

import GameplayKit
import SpriteKit
import UIKit

final class GameViewController: UIViewController {

  // MARK: - Properties

  private weak var gameScene: GameScene?

  private var skView: SKView? {
    return view as? SKView
  }

  // MARK: - Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()
    setupGameView()
    createAndPresentScene()
  }

  override func viewSafeAreaInsetsDidChange() {
    super.viewSafeAreaInsetsDidChange()
    updateGameSceneSafeArea()
  }

  override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    return UIDevice.current.userInterfaceIdiom == .phone ? .allButUpsideDown : .all
  }

  override var prefersStatusBarHidden: Bool {
    return true
  }

  // MARK: - Private Methods

  private func setupGameView() {
    guard let skView = skView else {
      assertionFailure("Expected SKView but got \(type(of: view))")
      return
    }

    skView.ignoresSiblingOrder = true

    #if DEBUG
      skView.showsFPS = true
      skView.showsNodeCount = true
    #endif
  }

  private func createAndPresentScene() {
    guard let skView = skView else { return }

    let scene = GameScene()
    scene.size = skView.bounds.size
    scene.scaleMode = .aspectFill

    gameScene = scene
    skView.presentScene(scene)
  }

  private func updateGameSceneSafeArea() {
    let safeAreaInsets = view.safeAreaInsets

    #if DEBUG
      print("Safe area insets updated: \(safeAreaInsets)")
    #endif

    gameScene?.setSafeAreaInsets(safeAreaInsets)
  }
}
