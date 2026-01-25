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
            
            if viewController != nil {
                // Game Center login UI would be shown - we skip for analytics
                print("GameCenterHelper: Login UI required but skipping for analytics")
                completion?(false)
                return
            }
            
            if localPlayer.isAuthenticated {
                // Successfully authenticated - use Game Center player ID
                self.playerId = localPlayer.gamePlayerID
                self.isAuthenticated = true
                print("GameCenterHelper: Authenticated with player ID: \(self.playerId)")
                completion?(true)
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
