
import Foundation

class GameData {
    static let shared = GameData()
    
    private let keyHighestLevelUntructed = "highestLevelUnlocked"
    
    // Default to Level 1 unlocked (index 0)
    var highestUnlockedLevelIndex: Int {
        get {
            // Default is 0 if not key exists
            return UserDefaults.standard.integer(forKey: keyHighestLevelUntructed)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keyHighestLevelUntructed)
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
