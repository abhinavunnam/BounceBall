
import Foundation

class GameData {
    static let shared = GameData()
    
    private let keyHighestLevelUnlocked = "highestLevelUnlocked"
    private let keyHasShownTutorial = "hasShownTutorial"
    
    // Track whether tutorial has been shown (defaults to false for new players)
    var hasShownTutorial: Bool {
        get {
            return UserDefaults.standard.bool(forKey: keyHasShownTutorial)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keyHasShownTutorial)
        }
    }
    
    // Default to Level 1 unlocked (index 0)
    var highestUnlockedLevelIndex: Int {
        get {
            // Default is 0 if not key exists
            return UserDefaults.standard.integer(forKey: keyHighestLevelUnlocked)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keyHighestLevelUnlocked)
        }
    }
    
    func unlockNextLevel(currentLevelIndex: Int) {
        let nextIndex = currentLevelIndex + 1
        // Only update if we actually unlocked a NEW level (don't downgrade if replaying)
        if nextIndex > highestUnlockedLevelIndex {
            highestUnlockedLevelIndex = nextIndex
            print("GameData: Unlocked Level Index \(nextIndex)")
        }
    }
    
    func resetProgress() {
        highestUnlockedLevelIndex = 0
    }
}
