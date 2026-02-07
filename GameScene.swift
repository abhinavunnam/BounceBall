//
//  GameScene.swift
//  BounceBallGame
//
//  Main Gameplay Scene
//

import SpriteKit
import GameplayKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {

    // MARK: - Properties
    private var ball: SKSpriteNode?
    private var basket: SKSpriteNode?
    private var platform: SKSpriteNode?
    private var launcher: SKSpriteNode?
    private var scoreLabel: SKLabelNode?
    private var scoreBoard: SKShapeNode?
    private var fireButton: SKShapeNode?
    private var backButton: SKLabelNode?
    private var score = 0
    private var isLaunched = false
    private var isResetting = false
    
    // Analytics: track attempts per level
    private var currentLevelAttempts = 0
    
    // Level Properties
    var startingLevelIndex = 0 // Public property to set start level
    private var currentLevelIndex = 0
    private var currentLevelConfig: LevelConfiguration?
    private var levelLabel: SKLabelNode?
    
    // Platform Movement
    private var platformDirection: CGFloat = 1.0 // 1 for right, -1 for left
    
    // Audio Actions
    private let fireSoundAction = SKAction.playSoundFileNamed("fire.mp3", waitForCompletion: false)
    private let bounceSoundAction = SKAction.playSoundFileNamed("bounce.mp3", waitForCompletion: false)
    private let scoreSoundAction = SKAction.playSoundFileNamed("score.mp3", waitForCompletion: false)
    
    // Correction for visual asset rotation (Asset points slightly Up/Left, so we subtract to aligning Right)
    // Adjust this if the cannon still looks off.
    private let cannonVisualCorrection: CGFloat = .pi / 8 // Approx 22.5 degrees

    // Physics categories for collision detection
    // Memory efficient way to handle collision tracking
    struct PhysicsCategory {
        static let ball: UInt32 = 0x1 << 0
        static let wall: UInt32 = 0x1 << 1
        static let basket: UInt32 = 0x1 << 2
        static let platform: UInt32 = 0x1 << 3
        static let launcher: UInt32 = 0x1 << 4
    }

    // MARK: - Scene Lifecycle
    override func didMove(to view: SKView) {
        setupPhysics()

        setupScene()
        setupScene()
        // Sound actions are preloaded as properties
        
        createWalls()
        
        // UI Elements
        createScoreLabel()
        createFireButton()
        createBackButton()
        createLevelLabel()
        
        // Initial Game Objects (Created once, repositioned per level)
        createLauncher()
        createPlatform()
        createBasket()
        createBall()
        
        // Load First Level
        loadLevel(index: startingLevelIndex)
    }

    // MARK: - Setup Methods
    private func setupPhysics() {
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        physicsWorld.contactDelegate = self
    }

    private func setupScene() {
        backgroundColor = .white
        scaleMode = .aspectFill
    }

    // Scaling Helper that Caps at 1.5x to prevent huge objects on iPad
    var gameScale: CGFloat {
        return min(frame.width / 390.0, 1.5)
    }

    private func createLauncher() {
        // Launcher using "canon" asset
        launcher = SKSpriteNode(imageNamed: "canon")
        // Position at bottom left (15% width check is okay for position, but maybe size separate)
        launcher?.position = CGPoint(x: frame.width * 0.15, y: frame.height * 0.2)
        
        // Scale size using gameScale instead of raw width percentage
        // Base size on iPhone was approx 80 (width * 0.2 of 390 is ~78)
        let size = 80.0 * gameScale
        launcher?.size = CGSize(width: size, height: size)

        guard let launcher = launcher else { return }

        // Physics setup
        // Use texture physics for more accurate hit detection if it's not a box
        launcher.physicsBody = SKPhysicsBody(texture: launcher.texture!, size: launcher.size)
        launcher.physicsBody?.isDynamic = false
        launcher.physicsBody?.categoryBitMask = PhysicsCategory.launcher
        launcher.physicsBody?.collisionBitMask = PhysicsCategory.ball
        launcher.physicsBody?.restitution = 0.5 
        launcher.physicsBody?.friction = 0.2

        addChild(launcher)
    }

    private func createBall() {
        let ballTexture = SKTexture(imageNamed: "ball")
        // Use gameScale. Base radius approx 40 (width * 0.1 of 390 -> 39)
        let ballRadius = 40.0 * gameScale
        let ballSize = CGSize(width: ballRadius, height: ballRadius)
        ball = SKSpriteNode(texture: ballTexture, size: ballSize)
        
        // Ensure proper rendering without artifacts
        ball?.texture?.filteringMode = .linear

        guard let ball = ball else { return }

        // Ball starts on the launcher
        // Position ball at the muzzle tip based on initial cannon rotation (0 + correction)
        let initialAngle = (launcher?.zRotation ?? 0) + cannonVisualCorrection
        
        // Scale offset distance using gameScale
        let offsetDistance: CGFloat = 50.0 * gameScale
        
        let lp = launcher?.position ?? CGPoint(x: 50, y: frame.height * 0.2)
        let bx = lp.x + cos(initialAngle) * offsetDistance
        let by = lp.y + sin(initialAngle) * offsetDistance
        ball.position = CGPoint(x: bx, y: by)

        // Physics setup - use circular body matching the visual size
        ball.physicsBody = SKPhysicsBody(circleOfRadius: ballSize.width / 2)
        ball.physicsBody?.isDynamic = false // Static until launched
        ball.physicsBody?.categoryBitMask = PhysicsCategory.ball
        ball.physicsBody?.contactTestBitMask = PhysicsCategory.basket | PhysicsCategory.platform | PhysicsCategory.wall | PhysicsCategory.launcher
        ball.physicsBody?.collisionBitMask = PhysicsCategory.wall | PhysicsCategory.platform // REMOVED .basket and .launcher so it launches smoothly
        ball.physicsBody?.restitution = 0.7 // Bounciness
        ball.physicsBody?.friction = 0.2
        ball.physicsBody?.linearDamping = 0.1
        ball.physicsBody?.allowsRotation = true

        addChild(ball)
    }

    private func createPlatform() {
        // Platform in the middle between launcher and basket, using image asset "platform"
        let platformTexture = SKTexture(imageNamed: "platform")
        // Set explicit size to prevent oversized sprites
        // Use gameScale. Base size approx 100x40
        let pWidth = 100.0 * gameScale
        let pHeight = 40.0 * gameScale
        platform = SKSpriteNode(texture: platformTexture, size: CGSize(width: pWidth, height: pHeight))
        platform?.position = CGPoint(x: frame.midX, y: frame.height * 0.5)

        guard let platform = platform else { return }

        // Physics setup
        platform.physicsBody = SKPhysicsBody(rectangleOf: platform.size)
        platform.physicsBody?.isDynamic = false
        platform.physicsBody?.categoryBitMask = PhysicsCategory.platform
        platform.physicsBody?.restitution = 0.9 // Very bouncy

        addChild(platform)
    }
    
    // Create Level Label
    private func createLevelLabel() {
        levelLabel = SKLabelNode(fontNamed: "Arial-BoldMT")
        levelLabel?.text = "LEVEL 1"
        levelLabel?.fontSize = 20
        levelLabel?.fontColor = .black
        // Position top left, moved down slightly
        levelLabel?.horizontalAlignmentMode = .left
        levelLabel?.position = CGPoint(x: frame.width * 0.05, y: frame.height * 0.9) // Top left with 5% margin
        addChild(levelLabel!)
    }
    
    // Load a specific level
    private func loadLevel(index: Int) {
        // Validation
        guard index < LevelData.levels.count else {
            print("GAME COMPLETED!")
            levelLabel?.text = "YOU WIN!"
            return
        }
        
        currentLevelIndex = index
        let config = LevelData.levels[index]
        currentLevelConfig = config
        
        // Update UI
        levelLabel?.text = "LEVEL \(config.levelNumber)"
        
        // Reset Score for the level (or keep cumulative? Let's reset for "Target Score")
        score = 0
        scoreLabel?.text = "0 / \(config.targetScore)"
        
        // Analytics: Reset attempts and track level started
        currentLevelAttempts = 1
        AnalyticsService.shared.trackLevelStarted(levelIndex: index)
        
        // Reposition Basket
        if let basket = basket {
            let cx = frame.width * config.basketPosition.x
            let cy = frame.height * config.basketPosition.y
            
            // Animate to new position
            let move = SKAction.move(to: CGPoint(x: cx, y: cy), duration: 0.5)
            basket.run(move)
        }
        
        // Reposition Platform
        if let platform = platform {
            let px = frame.width * config.platformPosition.x
            let py = frame.height * config.platformPosition.y
            
            let move = SKAction.move(to: CGPoint(x: px, y: py), duration: 0.5)
            platform.run(move)
        }
        
        // Reset Ball
        resetBall()
    }
        
    private func createBasket() {
        // Basket using "net" asset
        basket = SKSpriteNode(imageNamed: "net")
        
        // Position at top right
        basket?.position = CGPoint(x: frame.width * 0.85, y: frame.height * 0.8)
        
        // Size adjustment using gameScale
        // Base size on iPhone was approx 100 (width * 0.25 of 390 is ~97)
        let bSize = 100.0 * gameScale
        basket?.size = CGSize(width: bSize, height: bSize)
        
        // Make translucent so we can see the ball inside
        basket?.alpha = 0.8 // More translucent
        basket?.zPosition = 10 // Ensure it renders ON TOP of the ball

        guard let basket = basket else { return }

        // INSTEAD: Create invisible collision bodies for the rim
        // Calculate offsets based on actual basket size
        let halfWidth = basket.size.width / 2
        let rimOffset = halfWidth * 0.7 // 70% from center
        let rimY = basket.size.height * 0.3 // 30% up from center
        
        // Left Rim
        let leftRim = SKSpriteNode(color: .clear, size: CGSize(width: 10, height: 10))
        leftRim.position = CGPoint(x: -rimOffset, y: rimY)
        leftRim.physicsBody = SKPhysicsBody(circleOfRadius: 5) // Small collision point
        leftRim.physicsBody?.isDynamic = false
        leftRim.physicsBody?.categoryBitMask = PhysicsCategory.wall
        basket.addChild(leftRim)
        
        // Right Rim
        let rightRim = SKSpriteNode(color: .clear, size: CGSize(width: 10, height: 10))
        rightRim.position = CGPoint(x: rimOffset, y: rimY)
        rightRim.physicsBody = SKPhysicsBody(circleOfRadius: 5)
        rightRim.physicsBody?.isDynamic = false
        rightRim.physicsBody?.categoryBitMask = PhysicsCategory.wall
        basket.addChild(rightRim)
        
        // Net Funnel Walls (to make ball bounce inside)
        // Adjust these relative to size
        let netHeight = basket.size.height * 0.6
        let netX = halfWidth * 0.85 // Slightly wider than rims to form funnel
        
        // Left Net Wall (Angled)
        let leftNetSize = CGSize(width: 8, height: netHeight)
        let leftNet = SKSpriteNode(color: .clear, size: leftNetSize)
        leftNet.position = CGPoint(x: -netX, y: -5)
        leftNet.zRotation = 0.3 
        leftNet.physicsBody = SKPhysicsBody(rectangleOf: leftNetSize)
        leftNet.physicsBody?.isDynamic = false
        leftNet.physicsBody?.categoryBitMask = PhysicsCategory.wall
        basket.addChild(leftNet)
        
        // Right Net Wall (Angled)
        let rightNetSize = CGSize(width: 8, height: netHeight)
        let rightNet = SKSpriteNode(color: .clear, size: rightNetSize)
        rightNet.position = CGPoint(x: netX, y: -5)
        rightNet.zRotation = -0.3 
        rightNet.physicsBody = SKPhysicsBody(rectangleOf: rightNetSize)
        rightNet.physicsBody?.isDynamic = false
        rightNet.physicsBody?.categoryBitMask = PhysicsCategory.wall
        basket.addChild(rightNet)

        // Add a sensor for scoring
        // Positioned lower so the ball has to fall completely in
        let goalSensor = SKSpriteNode(color: .clear, size: CGSize(width: basket.size.width * 0.4, height: 5))
        goalSensor.position = CGPoint(x: 0, y: -basket.size.height * 0.2) // 20% down from center
        goalSensor.physicsBody = SKPhysicsBody(rectangleOf: goalSensor.size)
        goalSensor.physicsBody?.isDynamic = false
        goalSensor.physicsBody?.categoryBitMask = PhysicsCategory.basket
        goalSensor.physicsBody?.contactTestBitMask = PhysicsCategory.ball
        goalSensor.physicsBody?.collisionBitMask = 0 // Sensor only
        
        basket.addChild(goalSensor)

        addChild(basket)
    }

    private func createWalls() {
        let wallThickness: CGFloat = 10

        // Bottom wall
        let bottomWall = SKSpriteNode(color: .black, size: CGSize(width: frame.width, height: wallThickness))
        bottomWall.position = CGPoint(x: frame.midX, y: wallThickness / 2)
        bottomWall.physicsBody = SKPhysicsBody(rectangleOf: bottomWall.size)
        bottomWall.physicsBody?.isDynamic = false
        bottomWall.physicsBody?.categoryBitMask = PhysicsCategory.wall
        addChild(bottomWall)

        // Top wall
        let topWall = SKSpriteNode(color: .black, size: CGSize(width: frame.width, height: wallThickness))
        topWall.position = CGPoint(x: frame.midX, y: frame.height - wallThickness / 2)
        topWall.physicsBody = SKPhysicsBody(rectangleOf: topWall.size)
        topWall.physicsBody?.isDynamic = false
        topWall.physicsBody?.categoryBitMask = PhysicsCategory.wall
        addChild(topWall)

        // Left wall
        let leftWall = SKSpriteNode(color: .black, size: CGSize(width: wallThickness, height: frame.height))
        leftWall.position = CGPoint(x: wallThickness / 2, y: frame.midY)
        leftWall.physicsBody = SKPhysicsBody(rectangleOf: leftWall.size)
        leftWall.physicsBody?.isDynamic = false
        leftWall.physicsBody?.categoryBitMask = PhysicsCategory.wall
        addChild(leftWall)

        // Right wall
        let rightWall = SKSpriteNode(color: .black, size: CGSize(width: wallThickness, height: frame.height))
        rightWall.position = CGPoint(x: frame.width - wallThickness / 2, y: frame.midY)
        rightWall.physicsBody = SKPhysicsBody(rectangleOf: rightWall.size)
        rightWall.physicsBody?.isDynamic = false
        rightWall.physicsBody?.categoryBitMask = PhysicsCategory.wall
        addChild(rightWall)
    }

    // Use a container for the scoreboard

    private func createScoreLabel() {
        // Create Background - Expanded to provide more space
        let scoreBoardWidth: CGFloat = 160.0 * gameScale
        let scoreBoardHeight: CGFloat = 50.0 * gameScale
        scoreBoard = SKShapeNode(rectOf: CGSize(width: scoreBoardWidth, height: scoreBoardHeight), cornerRadius: 10 * gameScale)
        scoreBoard?.fillColor = .black
        scoreBoard?.strokeColor = .white
        scoreBoard?.lineWidth = 2 * gameScale
        scoreBoard?.position = CGPoint(x: frame.midX, y: frame.height - (100 * gameScale))
        scoreBoard?.zPosition = 100 

        guard let scoreBoard = scoreBoard else { return }

        // Create "SCORE" Title Node
        let titleLabel = SKLabelNode(fontNamed: "Arial-BoldMT")
        titleLabel.text = "SCORE"
        titleLabel.fontSize = 20 * gameScale
        titleLabel.fontColor = .white
        titleLabel.horizontalAlignmentMode = .left // Align left
        titleLabel.position = CGPoint(x: -scoreBoardWidth/2 + (15 * gameScale), y: -7 * gameScale) 
        scoreBoard.addChild(titleLabel)

        // Create Dynamic Score Value Node
        scoreLabel = SKLabelNode(fontNamed: "Arial-BoldMT")
        if let config = currentLevelConfig {
            scoreLabel?.text = "\(score)/\(config.targetScore)"
        } else {
             scoreLabel?.text = "0/0"
        }
        scoreLabel?.fontSize = 20 * gameScale
        scoreLabel?.fontColor = .white
        
        // Move "0/t" to the right for space
        scoreLabel?.horizontalAlignmentMode = .right 
        scoreLabel?.position = CGPoint(x: scoreBoardWidth/2 - (15 * gameScale), y: -7 * gameScale)
        
        scoreBoard.addChild(scoreLabel!)

        addChild(scoreBoard)
    }

    private func createFireButton() {
        let btnWidth: CGFloat = frame.width * 0.3
        let btnHeight: CGFloat = 50
        fireButton = SKShapeNode(rectOf: CGSize(width: btnWidth, height: btnHeight), cornerRadius: 10)
        fireButton?.fillColor = .black
        fireButton?.strokeColor = .white
        fireButton?.lineWidth = 2
        // Position Bottom Center: frame.midX
        fireButton?.position = CGPoint(x: frame.midX, y: frame.height * 0.1)
        fireButton?.zPosition = 100
        
        guard let fireButton = fireButton else { return }
        
        let label = SKLabelNode(fontNamed: "Arial-BoldMT")
        label.text = "FIRE"
        label.fontSize = 20
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        fireButton.addChild(label)
        
        addChild(fireButton)
    }
    
    private func createBackButton() {
        backButton = SKLabelNode(fontNamed: "Arial-BoldMT")
        backButton?.text = "← BACK"
        backButton?.fontSize = 20
        backButton?.fontColor = .black
        backButton?.position = CGPoint(x: frame.width * 0.95, y: frame.height * 0.90)
        backButton?.horizontalAlignmentMode = .right
        backButton?.name = "backButton"
        backButton?.zPosition = 100
        
        if let backButton = backButton {
            addChild(backButton)
        }
    }

    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Check if back button is pressed
        if let backButton = backButton, backButton.contains(location) {
            transitionToLevelSelect()
            return
        }
        
        // Check if fire button is pressed
        if let fireButton = fireButton, fireButton.contains(location) {
            // FIRE LOGIC
             if let ball = ball, !isLaunched {
                // Launch the ball
                ball.physicsBody?.isDynamic = true
                isLaunched = true

                // Calculate launch vector based on CURRENT angle of launcher
                if let launcher = launcher {
                    // Use the rotation of the launcher but ADD back the correction to get the TRUE physics angle
                    // Physics Angle = Visual Rotation + Correction
                    let angle = launcher.zRotation + cannonVisualCorrection
                    
                    // Offset to spawn ball at muzzle (length of cannon barrel)
                    // Cannon size is 80x80 (scaled), so barrel tip distance must scale.
                    // Scale offset distance based on gameScale
                    let offsetDistance: CGFloat = 50.0 * gameScale
                    
                    let offsetX = cos(angle) * offsetDistance
                    let offsetY = sin(angle) * offsetDistance
                    
                    // Move ball to muzzle tip
                    ball.position = CGPoint(x: launcher.position.x + offsetX, y: launcher.position.y + offsetY)
                    
                    // Impulse magnitude
                    let basePower: CGFloat = 80.0
                    
                    // SCALING FIX FOR IPAD:
                    // Ball Radius scales with Width (Width * 0.1). Mass scales with Area (Radius^2) -> Width^2.
                    // To keep trajectory similar under constant gravity, Velocity must scale with sqrt(Scale).
                    // Impulse = Mass * Velocity.
                    // Mass ~ Scale^2. Velocity ~ Scale^0.5.
                    // Impulse ~ Scale^2.5.
                    
                    // Use gameScale here
                    let power = basePower * pow(gameScale, 2.5)
                    
                    let impulse = CGVector(dx: cos(angle) * power, dy: sin(angle) * power)
                    ball.physicsBody?.applyImpulse(impulse)
                    
                    // Play Fire Sound
                    run(fireSoundAction)
                }
            }
        } else {
            // AIMING LOGIC
            rotateCannon(to: location)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Only aim if NOT touching the button (simple check, though touchesMoved usually tracks the same touch)
        // Ideally we check if the touch started on button, but separating regions is often enough.
        if let fireButton = fireButton, !fireButton.contains(location) {
             rotateCannon(to: location)
        }
    }
    
    private func rotateCannon(to location: CGPoint) {
        guard let launcher = launcher else { return }
        
        let dx = location.x - launcher.position.x
        let dy = location.y - launcher.position.y
        let angle = atan2(dy, dx)
        
        // SpriteKit rotation is in radians.
        // Assuming the cannon sprite points RIGHT by default:
        // We SUBTRACT the correction because the asset is intrinsicly rotated "Positive" (CCW).
        launcher.zRotation = angle - cannonVisualCorrection
        
        // Update ball position to follow muzzle if not yet launched
        if let ball = ball, !isLaunched {
            // Re-calculate physics angle for position
            let physicsAngle = angle // This is the raw angle from atan2, which IS the physical angle
            
            // Cannon size is 80x80, so half is 40. Barrel tip is roughly 40 units out + margin = 50 (scaled)
            let offsetDistance: CGFloat = 50.0 * gameScale
            
            let offsetX = cos(physicsAngle) * offsetDistance
            let offsetY = sin(physicsAngle) * offsetDistance
            
            ball.position = CGPoint(x: launcher.position.x + offsetX, y: launcher.position.y + offsetY)
            // Sync rotation too if desired, though ball is round
            ball.zRotation = physicsAngle
        }
    }

    // MARK: - Physics Contact Delegate
    func didBegin(_ contact: SKPhysicsContact) {
        let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask

        if collision == PhysicsCategory.ball | PhysicsCategory.basket {
            // Check if ball is moving downwards to count as a score
            // We need to access the ball's physics body. 
            // Since we don't know if bodyA or bodyB is the ball, we check both or just use the `ball` property if reliable.
            // Safer to check the contact bodies directly.
            
            let ballBody = (contact.bodyA.categoryBitMask == PhysicsCategory.ball) ? contact.bodyA : contact.bodyB
            
            if let velocity = ballBody.velocity as CGVector?, velocity.dy < 0 {
                 print("SCORING: Ball velocity dy is \(velocity.dy) (negative, so valid)")
                // Ball scored in basket!
                score += 1
                
                // Play Score Sound
                run(scoreSoundAction)
                
                // Show progress
                if let config = currentLevelConfig {
                     scoreLabel?.text = "\(score) / \(config.targetScore)"
                     
                     // Check Level Completion
                     if score >= config.targetScore {
                         print("LEVEL COMPLETE!")
                         
                         // Analytics: Track level completed
                         AnalyticsService.shared.trackLevelCompleted(levelIndex: self.currentLevelIndex, attempts: self.currentLevelAttempts)
                         
                         // Save Progress
                         GameData.shared.unlockNextLevel(currentLevelIndex: self.currentLevelIndex)
                         
                         // Transition to Level Complete Screen
                         DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                             self.goToLevelComplete()
                         }
                         return // Skip reset logic
                     }
                } else {
                    scoreLabel?.text = "\(score)"
                }
                
                print("SCORE UPDATED: \(score)")
                
                // Allow ball to fall to ground to trigger reset
                // Reset logic is handled by floor collision checks
            } else {
                print("IGNORED SCORE: Ball velocity dy is \(ballBody.velocity.dy) (moving up)")
            }
        }

        if collision == PhysicsCategory.ball | PhysicsCategory.platform {
            // Ball hit platform - can add bounce effect or particles
            // Play Bounce Sound
            run(bounceSoundAction)
        }

        if collision == PhysicsCategory.ball | PhysicsCategory.wall {
            let contactPoint = contact.contactPoint
            if contactPoint.y < frame.height * 0.05 {
                // Analytics: Track failed attempt (ball hit bottom)
                AnalyticsService.shared.trackLevelFailed(levelIndex: currentLevelIndex, attempts: currentLevelAttempts)
                currentLevelAttempts += 1
                
                resetBall()
            }
        }
    }

    // MARK: - Game Logic
    private func resetBall() {
        // Remove old ball
        ball?.removeFromParent()
        
        // Create new ball
        isLaunched = false
        isResetting = false
        createBall()
    }

    // MARK: - Update
    override func update(_ currentTime: TimeInterval) {
        // Platform Movement Logic
        if let config = currentLevelConfig, config.isPlatformMoving, let platform = platform {
            // Simple horizontal movement logic
            // If moving, we update x position by speed * direction
            
            
            // Scaling Helper
            // Reference width is based on iPhone 12/13/14 (approx 390 pts)
            let referenceWidth: CGFloat = 390.0
            let scaleFactor = frame.width / referenceWidth
            
            // Scale speed linearly to keep relative screen traversal time consistent
            // Speed (pts/sec) * Scale = New Speed
            let speed = config.platformMoveSpeed * scaleFactor
            
            var newX = platform.position.x + (speed * platformDirection)
            
            // Bounds check (Keep within screen with some margin)
            // Use dynamic margin based on actual platform size + wall thickness (10)
            let margin: CGFloat = (platform.size.width / 2) + 10.0
            if newX > frame.width - margin {
                newX = frame.width - margin
                platformDirection = -1 // Reverse
            } else if newX < margin {
                newX = margin
                platformDirection = 1 // Reverse
            }
            
            platform.position = CGPoint(x: newX, y: platform.position.y)
        }
    
        // Reset if ball is launched and has stopped moving or went off screen
        if isLaunched, let ball = ball, !isResetting {
            let velocity = ball.physicsBody?.velocity ?? CGVector.zero
            let speed = sqrt(velocity.dx * velocity.dx + velocity.dy * velocity.dy)
            
            // If ball is barely moving or off screen, reset
            if speed < 5 || ball.position.y < -100 {
                isResetting = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.resetBall()
                }
            }
        }
    }

    
    
    // setupSounds() removed - using SKAction instead
    
    
    private func goToLevelComplete() {
        let completeScene = LevelCompleteScene(size: self.size)
        completeScene.scaleMode = .aspectFill
        completeScene.nextLevelIndex = currentLevelIndex + 1
        
        let transition = SKTransition.crossFade(withDuration: 0.5)
        view?.presentScene(completeScene, transition: transition)
    }
    
    private func transitionToLevelSelect() {
        let levelSelectScene = LevelSelectScene(size: self.size)
        levelSelectScene.scaleMode = .aspectFill
        
        let transition = SKTransition.moveIn(with: .left, duration: 0.3)
        view?.presentScene(levelSelectScene, transition: transition)
    }
}
