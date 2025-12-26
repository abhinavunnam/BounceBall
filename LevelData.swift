
import Foundation
import CoreGraphics

struct LevelConfiguration {
    let levelNumber: Int
    /// Normalized position (0.0-1.0) for the basket center.
    /// x: 0 is left, 1 is right. y: 0 is bottom, 1 is top.
    let basketPosition: CGPoint 
    
    /// Normalized position (0.0-1.0) for the platform center.
    let platformPosition: CGPoint
    
    /// Whether the platform moves back and forth.
    let isPlatformMoving: Bool
    
    /// Speed of platform movement.
    let platformMoveSpeed: CGFloat
    
    /// Score required to complete this level.
    let targetScore: Int
}

struct LevelData {
    static let levels: [LevelConfiguration] = [
        // Level 1: Intro - Right Basket, Center Platform
        LevelConfiguration(
            levelNumber: 1,
            basketPosition: CGPoint(x: 0.85, y: 0.8), // Top Right
            platformPosition: CGPoint(x: 0.5, y: 0.5), // Center
            isPlatformMoving: false,
            platformMoveSpeed: 0,
            targetScore: 1
        ),
        
        // Level 2: Left Side - Basket Left, Platform Right
        LevelConfiguration(
            levelNumber: 2,
            basketPosition: CGPoint(x: 0.75, y: 0.5), // Top Left
            platformPosition: CGPoint(x: 0.5, y: 0.75), // Low Right
            isPlatformMoving: false,
            platformMoveSpeed: 0,
            targetScore: 1
        ),
        
        // Level 3: Height Challenge - High Center Basket, Low Platform
        LevelConfiguration(
            levelNumber: 3,
            basketPosition: CGPoint(x: 0.5, y: 0.5), // High Center
            platformPosition: CGPoint(x: 0.5, y: 0.75), // Low Center
            isPlatformMoving: false,
            platformMoveSpeed: 0,
            targetScore: 1
        ),
        
        // Level 4: Moving Target - Standard layout but platform moves
        LevelConfiguration(
            levelNumber: 4,
            basketPosition: CGPoint(x: 0.8, y: 0.8),
            platformPosition: CGPoint(x: 0.5, y: 0.5),
            isPlatformMoving: true,
            platformMoveSpeed: 2.0, // Moderate speed
            targetScore: 1
        ),
        
        // Level 5: Expert - Tricky shot with Fast Moving Platform
        LevelConfiguration(
            levelNumber: 5,
            basketPosition: CGPoint(x: 0.5, y: 0.5), // High Left
            platformPosition: CGPoint(x: 0.6, y: 0.75), // Mid Right
            isPlatformMoving: true,
            platformMoveSpeed: 3.5, // Fast
            targetScore: 1
        ),

        // Level 6: Speed Demon - Fast moving platform
        LevelConfiguration(
            levelNumber: 6,
            basketPosition: CGPoint(x: 0.85, y: 0.7),
            platformPosition: CGPoint(x: 0.5, y: 0.4),
            isPlatformMoving: true,
            platformMoveSpeed: 5.0, // Very Fast
            targetScore: 1
        ),

        // Level 7: The Squeeze - Basket tucked in corner
        LevelConfiguration(
            levelNumber: 7,
            basketPosition: CGPoint(x: 0.9, y: 0.6), // Top right corner
            platformPosition: CGPoint(x: 0.5, y: 0.6),
            isPlatformMoving: false,
            platformMoveSpeed: 0,
            targetScore: 1
        ),

        // Level 8: Rhythm - Moderate speed, trickier angle
        LevelConfiguration(
            levelNumber: 8,
            basketPosition: CGPoint(x: 0.2, y: 0.5), // Low Left
            platformPosition: CGPoint(x: 0.6, y: 0.6), // Low Right
            isPlatformMoving: true,
            platformMoveSpeed: 3.0,
            targetScore: 1
        ),

        // Level 9: Long Shot - Cross map
        LevelConfiguration(
            levelNumber: 9,
            basketPosition: CGPoint(x: 0.8, y: 0.3), // Top Right
            platformPosition: CGPoint(x: 0.5, y: 0.5), // Low Left
            isPlatformMoving: false,
            platformMoveSpeed: 6,
            targetScore: 1
        ),

        // Level 10: The Masterpiece - Fast platform, awkward angle
        LevelConfiguration(
            levelNumber: 10,
            basketPosition: CGPoint(x: 0.5, y: 0.5), // Top Center
            platformPosition: CGPoint(x: 0.5, y: 0.7), // Center
            isPlatformMoving: true,
            platformMoveSpeed: 6.0, // Maximum speed
            targetScore: 1
        )
    ]
}
