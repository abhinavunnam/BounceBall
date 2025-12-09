// ==========================================
// GAME VIEW CONTROLLER
// ==========================================
//
// Replace the GameViewController.swift in your Xcode project with this code
//
// ==========================================

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        if let view = self.view as! SKView? {
            view.isUserInteractionEnabled = true

            // Create the scene with the view's bounds
            let scene = MenuScene(size: view.bounds.size)

            scene.scaleMode = .aspectFill

            // Present the scene
            view.presentScene(scene)

            // Debug options (optional - remove for production)
            view.ignoresSiblingOrder = true
            view.showsFPS = true
            view.showsNodeCount = true
            view.showsPhysics = true // Shows physics bodies
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
