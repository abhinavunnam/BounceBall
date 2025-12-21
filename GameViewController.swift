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
import GameKit // Import GameKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Authenticate Game Center Player
        authenticateLocalPlayer()

        if let view = self.view as! SKView? {
            view.isUserInteractionEnabled = true

            // Create the scene with the view's bounds
            let scene = MenuScene(size: view.bounds.size)

            scene.scaleMode = .aspectFill

            // Present the scene
            view.presentScene(scene)

            // Debug options (optional - remove for production)
            view.ignoresSiblingOrder = true
            view.showsFPS = false
            view.showsNodeCount = false
            // view.showsPhysics = true // Commented out to remove physics outlines
        }
    }
    
    func authenticateLocalPlayer() {
        let localPlayer = GKLocalPlayer.local
        localPlayer.authenticateHandler = { viewController, error in
            if let vc = viewController {
                self.present(vc, animated: true)
            } else if localPlayer.isAuthenticated {
                print("Game Center: Authenticated successfully!")
            } else {
                print("Game Center: Authentication failed - \(String(describing: error?.localizedDescription))")
            }
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
