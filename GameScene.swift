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
    private var score = 0
    private var isLaunched = false
    private var isResetting = false

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
        // Launcher at bottom left
        launcher = SKSpriteNode(color: .black, size: CGSize(width: 60, height: 60))
        launcher?.position = CGPoint(x: 50, y: frame.height * 0.2)

        // Create gradient texture
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(origin: .zero, size: size)
        gradientLayer.colors = [
            UIColor(red: 0.6, green: 0.3, blue: 0.1, alpha: 1.0).cgColor,
            UIColor(red: 0.8, green: 0.5, blue: 0.2, alpha: 1.0).cgColor,
            UIColor(red: 0.6, green: 0.3, blue: 0.1, alpha: 1.0).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        
        // Create a texture from the gradient
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            gradientLayer.render(in: ctx.cgContext)
        }
        let texture = SKTexture(image: image)
        let launcherBase = SKSpriteNode(texture: texture, size: size)
        launcherBase.position = CGPoint(x: 0, y: -25) // Position at bottom of launcher
        
        // Add shadow
        launcherBase.shadowCastBitMask = 1
        launcherBase.lightingBitMask = 1

        launcher?.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 60, height: 60))
        launcher?.physicsBody?.isDynamic = false
        launcher?.physicsBody?.categoryBitMask = PhysicsCategory.launcher
        launcher?.physicsBody?.collisionBitMask = PhysicsCategory.ball
        launcher?.physicsBody?.restitution = 1.2 // Make it bouncy like the platform
        launcher?.physicsBody?.friction = 0.2

        if let launcher = launcher {
            addChild(launcher)
        }
    }

    private func createBall() {
        let ballTexture = SKTexture(imageNamed: "ball")
        let ballSize = CGSize(width: 40, height: 40)
        ball = SKSpriteNode(texture: ballTexture, size: ballSize)

        guard let ball = ball else { return }

        // Ball starts on the launcher
        ball.position = CGPoint(x: 50, y: frame.height * 0.2 + 50)

        // Physics setup
        ball.physicsBody = SKPhysicsBody(circleOfRadius: ballSize.width / 2)
        ball.physicsBody?.isDynamic = false // Static until launched
        ball.physicsBody?.categoryBitMask = PhysicsCategory.ball
        ball.physicsBody?.contactTestBitMask = PhysicsCategory.basket | PhysicsCategory.platform | PhysicsCategory.wall | PhysicsCategory.launcher
        ball.physicsBody?.collisionBitMask = PhysicsCategory.wall | PhysicsCategory.platform | PhysicsCategory.basket | PhysicsCategory.launcher
        ball.physicsBody?.restitution = 0.7 // Bounciness
        ball.physicsBody?.friction = 0.2
        ball.physicsBody?.linearDamping = 0.1
        ball.physicsBody?.allowsRotation = true

        addChild(ball)
    }

    private func createPlatform() {
        // Platform in the middle between launcher and basket
        platform = SKSpriteNode(color: .black, size: CGSize(width: 100, height: 20))
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
        // Basket at top right - realistic basket design
        let basketWidth: CGFloat = 70
        let basketHeight: CGFloat = 80
        let rimThickness: CGFloat = 8
        let wallThickness: CGFloat = 6

        basket = SKSpriteNode()
        basket?.position = CGPoint(x: frame.width - 100, y: frame.height * 0.8)

        guard let basket = basket else { return }

        // Top rim (wider opening)
        let topRim = SKSpriteNode(color: .black, size: CGSize(width: basketWidth, height: rimThickness))
        topRim.position = CGPoint(x: 0, y: basketHeight/2)
        topRim.physicsBody = SKPhysicsBody(rectangleOf: topRim.size)
        topRim.physicsBody?.isDynamic = false
        topRim.physicsBody?.categoryBitMask = PhysicsCategory.wall
        basket.addChild(topRim)

        // Left curved wall (angled inward)
        let leftWallPath = UIBezierPath()
        leftWallPath.move(to: CGPoint(x: 0, y: 0))
        leftWallPath.addCurve(
            to: CGPoint(x: -basketWidth/4, y: basketHeight/2),
            controlPoint1: CGPoint(x: -wallThickness, y: basketHeight/4),
            controlPoint2: CGPoint(x: -basketWidth/3, y: basketHeight/2)
        )
        let leftWall = SKShapeNode(path: leftWallPath.cgPath)
        leftWall.strokeColor = .black
        leftWall.lineWidth = wallThickness
        leftWall.fillColor = .clear
        leftWall.position = CGPoint(x: -basketWidth/2, y: -basketHeight/2)
        leftWall.physicsBody = SKPhysicsBody(edgeLoopFrom: leftWallPath.cgPath)
        leftWall.physicsBody?.isDynamic = false
        leftWall.physicsBody?.categoryBitMask = PhysicsCategory.wall
        basket.addChild(leftWall)

        // Right curved wall (angled inward)
        let rightWallPath = UIBezierPath()
        rightWallPath.move(to: CGPoint(x: 0, y: 0))
        rightWallPath.addCurve(
            to: CGPoint(x: basketWidth/4, y: basketHeight/2),
            controlPoint1: CGPoint(x: wallThickness, y: basketHeight/4),
            controlPoint2: CGPoint(x: basketWidth/3, y: basketHeight/2)
        )
        let rightWall = SKShapeNode(path: rightWallPath.cgPath)
        rightWall.strokeColor = .black
        rightWall.lineWidth = wallThickness
        rightWall.fillColor = .clear
        rightWall.position = CGPoint(x: basketWidth/2, y: -basketHeight/2)
        rightWall.physicsBody = SKPhysicsBody(edgeLoopFrom: rightWallPath.cgPath)
        rightWall.physicsBody?.isDynamic = false
        rightWall.physicsBody?.categoryBitMask = PhysicsCategory.wall
        basket.addChild(rightWall)

        // Bottom net (goal zone)
        let netWidth: CGFloat = basketWidth/2
        let bottom = SKSpriteNode(color: .black, size: CGSize(width: netWidth, height: rimThickness))
        bottom.position = CGPoint(x: 0, y: -basketHeight/2)
        bottom.physicsBody = SKPhysicsBody(rectangleOf: bottom.size)
        bottom.physicsBody?.isDynamic = false
        bottom.physicsBody?.categoryBitMask = PhysicsCategory.basket
        basket.addChild(bottom)

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

    // This is the score label & {metadata etc}
    private func createScoreLabel() {
        scoreLabel = SKLabelNode(fontNamed: "Arial")
        scoreLabel?.fontSize = 36
        scoreLabel?.fontColor = .black
        scoreLabel?.position = CGPoint(x: frame.midX, y: frame.height - 100)
        scoreLabel?.text = "Score: \(score)"

        if let scoreLabel = scoreLabel {
            addChild(scoreLabel)
        }
    }

    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        if let ball = ball, !isLaunched {
            // Launch the ball
            ball.physicsBody?.isDynamic = true
            isLaunched = true

            // Calculate launch direction (upward and to the right toward basket)
            let dx = location.x - ball.position.x
            let dy = location.y - ball.position.y
            let impulse = CGVector(dx: dx * 0.3, dy: dy * 0.3)
            ball.physicsBody?.applyImpulse(impulse)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Can be used for trajectory preview
    }

    // MARK: - Physics Contact Delegate
    func didBegin(_ contact: SKPhysicsContact) {
        let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask

        if collision == PhysicsCategory.ball | PhysicsCategory.basket {
            // Ball scored in basket!
            score += 1
            scoreLabel?.text = "Score: \(score)"

            // Reset level
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.resetLevel()
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
