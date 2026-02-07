//
//  GameCenterHelper.swift
//  BounceBall
//
//  Helper for Game Center Player ID retrieval
//

import Foundation
import GameKit

class GameCenterHelper {
    static let shared = GameCenterHelper()
    
    private(set) var playerId: String = ""
    private(set) var isAuthenticated: Bool = false
    
    private init() {
        // Use device UUID as fallback until Game Center authenticates
        playerId = getDeviceIdentifier()
    }
    
    /// Authenticate with Game Center and retrieve player ID
    func authenticate(completion: ((Bool) -> Void)? = nil) {
        let localPlayer = GKLocalPlayer.local
        
        localPlayer.authenticateHandler = { [weak self] viewController, error in
            guard let self = self else { return }
            
            if let error = error {
                print("GameCenterHelper: Authentication error - \(error.localizedDescription)")
                // Keep using device UUID
                completion?(false)
                return
            }
            
            if let viewController = viewController {
                // Present the Game Center login/permission UI
                print("GameCenterHelper: Presenting Game Center login UI")
                DispatchQueue.main.async {
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
                        rootVC.present(viewController, animated: true)
                    }
                }
                // Handler will be called again after user action
                return
            }
            
            if localPlayer.isAuthenticated {
                // Successfully authenticated
                let pid = localPlayer.gamePlayerID
                let alias = localPlayer.alias
                
                print("GameCenterHelper: Auth Success. Alias: \(alias), ID: '\(pid)'")
                
                if !pid.isEmpty {
                    self.playerId = pid
                    self.isAuthenticated = true
                    completion?(true)
                } else {
                    print("GameCenterHelper: Authenticated but ID is EMPTY. Using fallback.")
                    // Try to fetch specific identity if needed (iOS 13+ has teamPlayerID)
                    print("GameCenterHelper: Team ID: \(localPlayer.teamPlayerID)")
                    
                    if !localPlayer.teamPlayerID.isEmpty {
                         self.playerId = localPlayer.teamPlayerID
                         self.isAuthenticated = true
                         completion?(true)
                    } else {
                        completion?(false)
                    }
                }
            } else {
                print("GameCenterHelper: Not authenticated, using device ID")
                completion?(false)
            }
        }
    }
    
    /// Get device identifier as fallback
    private func getDeviceIdentifier() -> String {
        if let uuid = UIDevice.current.identifierForVendor?.uuidString {
            return "device_\(uuid)"
        }
        // Last resort fallback
        return "unknown_\(UUID().uuidString)"
    }
    
    /// Get current player ID (Game Center or device fallback)
    func getCurrentPlayerId() -> String {
        return playerId
    }
}
