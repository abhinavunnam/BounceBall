
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
    private var logoNode: SKShapeNode?
    
    // MARK: - Scene Lifecycle
    override func didMove(to view: SKView) {
        setupScene()
        createLogo()
        createTitle()
        createStartButton()
        animateEntrance()
    }
    
    // MARK: - Setup Methods
    private func setupScene() {
        // Gradient background
        backgroundColor = SKColor(red: 0.95, green: 0.85, blue: 0.90, alpha: 1.0)
    }
    
    private func createLogo() {
        // Create a simple logo using shapes (you can replace with image later)
        logoNode = SKShapeNode()
        logoNode?.position = CGPoint(x: frame.midX, y: frame.height * 0.65)
        
        guard let logoNode = logoNode else { return }
        
        // Create a heart shape for "Angry Wife" theme
        let heartPath = createHeartPath(size: 80)
        let heart = SKShapeNode(path: heartPath)
        heart.fillColor = .red
        heart.strokeColor = .darkGray
        heart.lineWidth = 3
        heart.setScale(0)
        logoNode.addChild(heart)
        
        // Add angry eyebrows
        let leftBrow = SKShapeNode(rectOf: CGSize(width: 20, height: 4), cornerRadius: 2)
        leftBrow.fillColor = .black
        leftBrow.position = CGPoint(x: -15, y: 10)
        leftBrow.zRotation = .pi / 6
        logoNode.addChild(leftBrow)
        
        let rightBrow = SKShapeNode(rectOf: CGSize(width: 20, height: 4), cornerRadius: 2)
        rightBrow.fillColor = .black
        rightBrow.position = CGPoint(x: 15, y: 10)
        rightBrow.zRotation = -.pi / 6
        logoNode.addChild(rightBrow)
        
        addChild(logoNode)
    }
    
    private func createHeartPath(size: CGFloat) -> CGPath {
        let path = UIBezierPath()
        let width = size
        let height = size
        
        path.move(to: CGPoint(x: 0, y: -height * 0.3))
        
        // Left curve
        path.addCurve(
            to: CGPoint(x: -width * 0.5, y: height * 0.1),
            controlPoint1: CGPoint(x: -width * 0.3, y: -height * 0.5),
            controlPoint2: CGPoint(x: -width * 0.6, y: -height * 0.1)
        )
        
        // Bottom left
        path.addCurve(
            to: CGPoint(x: 0, y: height * 0.5),
            controlPoint1: CGPoint(x: -width * 0.5, y: height * 0.3),
            controlPoint2: CGPoint(x: -width * 0.2, y: height * 0.5)
        )
        
        // Bottom right
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: height * 0.1),
            controlPoint1: CGPoint(x: width * 0.2, y: height * 0.5),
            controlPoint2: CGPoint(x: width * 0.5, y: height * 0.3)
        )
        
        // Right curve
        path.addCurve(
            to: CGPoint(x: 0, y: -height * 0.3),
            controlPoint1: CGPoint(x: width * 0.6, y: -height * 0.1),
            controlPoint2: CGPoint(x: width * 0.3, y: -height * 0.5)
        )
        
        path.close()
        return path.cgPath
    }
    
    private func createTitle() {
        // Main title
        titleLabel = SKLabelNode(fontNamed: "Arial-BoldMT")
        titleLabel?.text = "BOUNCE BALL"
        titleLabel?.fontSize = 48
        titleLabel?.fontColor = .darkGray
        titleLabel?.position = CGPoint(x: frame.midX, y: frame.height * 0.45)
        titleLabel?.alpha = 0
        
        if let titleLabel = titleLabel {
            addChild(titleLabel)
        }
        
        // Subtitle
        subtitleLabel = SKLabelNode(fontNamed: "Arial")
        subtitleLabel?.text = "BasketBall Challenge"
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
        startButton?.fillColor = SKColor(red: 1.0, green: 0.3, blue: 0.5, alpha: 1.0)
        startButton?.strokeColor = .white
        startButton?.lineWidth = 3
        startButton?.position = CGPoint(x: frame.midX, y: frame.height * 0.25)
        startButton?.name = "startButton"
        startButton?.alpha = 0
        
        // Button label
        startButtonLabel = SKLabelNode(fontNamed: "Arial-BoldMT")
        startButtonLabel?.text = "START GAME"
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
        // Animate logo
        if let logoNode = logoNode, let heart = logoNode.children.first {
            let scaleUp = SKAction.scale(to: 1.0, duration: 0.5)
            scaleUp.timingMode = .easeOut
            heart.run(scaleUp)
        }
        
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
                SKAction.scale(to: 1.05, duration: 0.5),
                SKAction.scale(to: 1.0, duration: 0.5)
            ]))
        ]))
    }
    
    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)
        
        for node in touchedNodes {
            if node.name == "startButton" {
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.transitionToGame()
        }
    }
    
    private func transitionToGame() {
        let gameScene = GameScene(size: self.size)
        gameScene.scaleMode = .aspectFill
        
        let transition = SKTransition.fade(withDuration: 1.0)
        self.view?.presentScene(gameScene, transition: transition)
    }
}