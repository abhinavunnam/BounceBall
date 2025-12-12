// ==========================================
// BOUNCE BALL GAME - Complete Game Scene Code
// ==========================================
//
// INSTRUCTIONS:
// 1. Open Xcode
// 2. File → New → Project → iOS → Game
// 3. Product Name: BounceBallGame
// 4. Game Technology: SpriteKit
// 5. Save it anywhere
// 6. Replace the generated GameScene.swift with this code
// 7. Run!
//
// ==========================================

import SpriteKit
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
    private var score = 0
    private var isLaunched = false
    private var isResetting = false
    
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
        createLauncher()
        createBall()
        createPlatform()
        createBasket()
        createWalls()
        createScoreLabel()
        createFireButton()
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

    private func createLauncher() {
        // Launcher using "canon" asset
        launcher = SKSpriteNode(imageNamed: "canon")
        // Position at bottom left
        launcher?.position = CGPoint(x: 50, y: frame.height * 0.2)
        // Scale down if necessary, though SKTexture usually handles it.
        // Assuming canon needs to be roughly same size as before or appropriate for the asset.
        // Let's set a size to ensure it's not huge, or we can trust the asset size.
        // Let's start with a reasonable size similar to previous box
        launcher?.size = CGSize(width: 80, height: 80)

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
        // Set explicit size to prevent oversized sprites
        let ballSize = CGSize(width: 40, height: 40)
        ball = SKSpriteNode(texture: ballTexture, size: ballSize)
        
        // Ensure proper rendering without artifacts
        ball?.texture?.filteringMode = .linear

        guard let ball = ball else { return }

        // Ball starts on the launcher
        // Ball starts (hidden/inside) at the launcher center
        ball.position = CGPoint(x: 50, y: frame.height * 0.2)

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
        platform = SKSpriteNode(texture: platformTexture, size: CGSize(width: 100, height: 40))
        platform?.position = CGPoint(x: frame.midX, y: frame.height * 0.5)

        guard let platform = platform else { return }

        // Physics setup
        platform.physicsBody = SKPhysicsBody(rectangleOf: platform.size)
        platform.physicsBody?.isDynamic = false
        platform.physicsBody?.categoryBitMask = PhysicsCategory.platform
        platform.physicsBody?.restitution = 0.9 // Very bouncy

        addChild(platform)
    }

    private func createBasket() {
        // Basket using "net" asset
        basket = SKSpriteNode(imageNamed: "net")
        
        // Position at top right
        basket?.position = CGPoint(x: frame.width - 100, y: frame.height * 0.8)
        
        // Size adjustment
        basket?.size = CGSize(width: 100, height: 100)
        
        // Make translucent so we can see the ball inside
        basket?.alpha = 0.8

        guard let basket = basket else { return }

        // REMOVED: texture-based physics body which blocked the ball
        // basket.physicsBody = SKPhysicsBody(texture: basket.texture!, size: basket.size)
        // basket.physicsBody?.isDynamic = false
        // basket.physicsBody?.categoryBitMask = PhysicsCategory.wall 
        
        // INSTEAD: Create invisible collision bodies for the rim
        
        // Left Rim
        let leftRim = SKSpriteNode(color: .clear, size: CGSize(width: 10, height: 10))
        // Position relative to basket center - adjust based on visual "net" asset
        leftRim.position = CGPoint(x: -35, y: 30) 
        leftRim.physicsBody = SKPhysicsBody(circleOfRadius: 5)
        leftRim.physicsBody?.isDynamic = false
        leftRim.physicsBody?.categoryBitMask = PhysicsCategory.wall
        basket.addChild(leftRim)
        
        // Right Rim
        let rightRim = SKSpriteNode(color: .clear, size: CGSize(width: 10, height: 10))
        rightRim.position = CGPoint(x: 35, y: 30)
        rightRim.physicsBody = SKPhysicsBody(circleOfRadius: 5)
        rightRim.physicsBody?.isDynamic = false
        rightRim.physicsBody?.categoryBitMask = PhysicsCategory.wall
        basket.addChild(rightRim)

        // Add a sensor for scoring
        // Positioned lower so the ball has to fall completely in
        let goalSensor = SKSpriteNode(color: .clear, size: CGSize(width: basket.size.width * 0.4, height: 5))
        goalSensor.position = CGPoint(x: 0, y: -basket.size.height * 0.2) // 40% down from center
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
        // Create Background
        let scoreBoardWidth: CGFloat = 120 // Reduced from 160
        let scoreBoardHeight: CGFloat = 50 // Reduced from 80
        scoreBoard = SKShapeNode(rectOf: CGSize(width: scoreBoardWidth, height: scoreBoardHeight), cornerRadius: 10)
        scoreBoard?.fillColor = .black
        scoreBoard?.strokeColor = .white
        scoreBoard?.lineWidth = 2
        scoreBoard?.position = CGPoint(x: frame.midX, y: frame.height - 100)
        scoreBoard?.zPosition = 100 // Ensure it's on top

        guard let scoreBoard = scoreBoard else { return }

        // Create "SCORE" Title Node
        let titleLabel = SKLabelNode(fontNamed: "Arial-BoldMT")
        titleLabel.text = "SCORE"
        titleLabel.fontSize = 20
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: -15, y: 0) // Top half
        titleLabel.verticalAlignmentMode = .center
        scoreBoard.addChild(titleLabel)

        // Create Dynamic Score Value Node
        scoreLabel = SKLabelNode(fontNamed: "Arial-BoldMT")
        scoreLabel?.text = "\(score)"
        scoreLabel?.fontSize = 20 // Reduced size
        scoreLabel?.fontColor = .white
        scoreLabel?.position = CGPoint(x: 40, y: 0) // Bottom half
        scoreLabel?.verticalAlignmentMode = .center
        scoreBoard.addChild(scoreLabel!)

        addChild(scoreBoard)
    }

    private func createFireButton() {
        let btnWidth: CGFloat = 120
        let btnHeight: CGFloat = 50
        fireButton = SKShapeNode(rectOf: CGSize(width: btnWidth, height: btnHeight), cornerRadius: 10)
        fireButton?.fillColor = .black
        fireButton?.strokeColor = .white
        fireButton?.lineWidth = 2
        // Position Bottom Center: frame.midX
        fireButton?.position = CGPoint(x: frame.midX, y: 80)
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

    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
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
                    // Cannon size is 80x80, so half is 40. Barrel tip is roughly 40 units out.
                    let offsetDistance: CGFloat = 50.0 
                    let offsetX = cos(angle) * offsetDistance
                    let offsetY = sin(angle) * offsetDistance
                    
                    // Move ball to muzzle tip
                    ball.position = CGPoint(x: launcher.position.x + offsetX, y: launcher.position.y + offsetY)
                    
                    // Impulse magnitude
                    let power: CGFloat = 80.0
                    
                    let impulse = CGVector(dx: cos(angle) * power, dy: sin(angle) * power)
                    ball.physicsBody?.applyImpulse(impulse)
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
                scoreLabel?.text = "\(score)"
                print("SCORE UPDATED: \(score)")
                
                // Allow ball to fall to ground to trigger reset
                // Reset logic is handled by floor collision checks
            } else {
                print("IGNORED SCORE: Ball velocity dy is \(ballBody.velocity.dy) (moving up)")
            }
        }

        if collision == PhysicsCategory.ball | PhysicsCategory.platform {
            // Ball hit platform - can add bounce effect or particles
        }

        if collision == PhysicsCategory.ball | PhysicsCategory.wall {
            let contactPoint = contact.contactPoint
            if contactPoint.y < frame.height * 0.05 {
                resetLevel()
            }
        }
    }

    // MARK: - Game Logic
    private func resetLevel() {
    // Remove old ball
    ball?.removeFromParent()
    
    // Create new ball
    isLaunched = false
    isResetting = false
    createBall()
}

    // MARK: - Update
    override func update(_ currentTime: TimeInterval) {
    // Reset if ball is launched and has stopped moving or went off screen
    if isLaunched, let ball = ball, !isResetting {
        let velocity = ball.physicsBody?.velocity ?? CGVector.zero
        let speed = sqrt(velocity.dx * velocity.dx + velocity.dy * velocity.dy)
        
        // If ball is barely moving or off screen, reset
        if speed < 5 || ball.position.y < -100 {
            isResetting = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.resetLevel()
            }
        }
    }
}
}
