//
//  MenuScene.swift
//  BounceBallGame
//
//  Menu/Launch Screen
//

import SpriteKit

class MenuScene: SKScene {
    
    // MARK: - Properties
    private var titleLabel: SKLabelNode?
    private var subtitleLabel: SKLabelNode?
    private var startButton: SKShapeNode?
    private var startButtonLabel: SKLabelNode?
    
    // MARK: - Scene Lifecycle
    override func didMove(to view: SKView) {
        print("--- APP LAUNCHED: MenuScene Loaded ---")
        setupScene()
        createLogoElements()
        createTitle()
        createStartButton()
        animateEntrance()
    }
    
    // MARK: - Setup Methods
    private func setupScene() {
        // White background to match GameScene
        backgroundColor = .white
    }
    
    private func createLogoElements() {
        // Decorative Ball
        let ball = SKSpriteNode(imageNamed: "ball")
        ball.size = CGSize(width: 60, height: 60)
        ball.position = CGPoint(x: frame.midX - 40, y: frame.height * 0.65)
        ball.zRotation = .pi / 4
        ball.name = "logoBall"
        addChild(ball)
        
        // Decorative Net
        let net = SKSpriteNode(imageNamed: "net")
        net.size = CGSize(width: 80, height: 80)
        net.position = CGPoint(x: frame.midX + 40, y: frame.height * 0.6)
        net.alpha = 0.8
        net.zRotation = -0.1
        net.name = "logoNet"
        addChild(net)
        
        // Add a "bouncing" animation to the ball
        let moveUp = SKAction.moveBy(x: 0, y: 20, duration: 0.8)
        moveUp.timingMode = .easeOut
        let moveDown = SKAction.moveBy(x: 0, y: -20, duration: 0.6)
        moveDown.timingMode = .easeIn
        let bounce = SKAction.sequence([moveUp, moveDown])
        ball.run(SKAction.repeatForever(bounce))
    }
    
    private func createTitle() {
        // Main title
        titleLabel = SKLabelNode(fontNamed: "Arial-BoldMT")
        titleLabel?.text = "BOUNCE BALL"
        titleLabel?.fontSize = 48
        titleLabel?.fontColor = .black
        titleLabel?.position = CGPoint(x: frame.midX, y: frame.height * 0.45)
        titleLabel?.alpha = 0
        
        if let titleLabel = titleLabel {
            addChild(titleLabel)
        }
        
        // Subtitle
        subtitleLabel = SKLabelNode(fontNamed: "Arial")
        subtitleLabel?.text = "Basketball Challenge"
        subtitleLabel?.fontSize = 20
        subtitleLabel?.fontColor = .gray
        subtitleLabel?.position = CGPoint(x: frame.midX, y: frame.height * 0.40)
        subtitleLabel?.alpha = 0
        
        if let subtitleLabel = subtitleLabel {
            addChild(subtitleLabel)
        }
    }
    
    private func createStartButton() {
        // Button background
        let buttonWidth: CGFloat = 200
        let buttonHeight: CGFloat = 60
        
        startButton = SKShapeNode(rectOf: CGSize(width: buttonWidth, height: buttonHeight), cornerRadius: 15)
        startButton?.fillColor = .black
        startButton?.strokeColor = .black
        startButton?.lineWidth = 3
        startButton?.position = CGPoint(x: frame.midX, y: frame.height * 0.25)
        startButton?.name = "startButton"
        startButton?.alpha = 0
        
        // Button label
        startButtonLabel = SKLabelNode(fontNamed: "Arial-BoldMT")
        
        let highestLevel = GameData.shared.highestUnlockedLevelIndex
        let buttonText = highestLevel > 0 ? "CONTINUE" : "START GAME"
        
        startButtonLabel?.text = buttonText
        startButtonLabel?.fontSize = 24
        startButtonLabel?.fontColor = .white
        startButtonLabel?.verticalAlignmentMode = .center
        startButtonLabel?.name = "startButton"
        
        if let startButton = startButton, let startButtonLabel = startButtonLabel {
            startButton.addChild(startButtonLabel)
            addChild(startButton)
        }
    }
    
    private func animateEntrance() {
        // Animate title
        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        titleLabel?.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.3),
            fadeIn
        ]))
        
        subtitleLabel?.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            fadeIn
        ]))
        
        // Animate button with pulse
        startButton?.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.7),
            fadeIn,
            SKAction.repeatForever(SKAction.sequence([
                SKAction.scale(to: 1.05, duration: 0.8),
                SKAction.scale(to: 1.0, duration: 0.8)
            ]))
        ]))
    }
    
    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)
        
        for node in touchedNodes {
            // Check button or label
            if node.name == "startButton" || node.parent?.name == "startButton" {
                startButtonTapped()
                break
            }
        }
    }
    
    private func startButtonTapped() {
        // Button press animation
        let scaleDown = SKAction.scale(to: 0.95, duration: 0.1)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.1)
        startButton?.run(SKAction.sequence([scaleDown, scaleUp]))
        
        // Transition to game scene
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.transitionToGame()
        }
    }
    
    private func transitionToGame() {
        let gameScene = GameScene(size: self.size)
        gameScene.scaleMode = .aspectFill
        
        // Load the highest unlocked level
        gameScene.startingLevelIndex = GameData.shared.highestUnlockedLevelIndex
        
        let transition = SKTransition.fade(with: .white, duration: 1.0)
        self.view?.presentScene(gameScene, transition: transition)
    }
}