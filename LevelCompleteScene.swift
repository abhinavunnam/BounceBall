
import SpriteKit

class LevelCompleteScene: SKScene {
    
    // MARK: - Properties
    var nextLevelIndex: Int = 0
    
    private var titleLabel: SKLabelNode?
    private var nextButton: SKShapeNode?
    
    // MARK: - Scene Lifecycle
    override func didMove(to view: SKView) {
        backgroundColor = .white
        createContent()
        animateEntrance()
    }
    
    private func createContent() {
        // decorative elements
        let star = SKSpriteNode(imageNamed: "ball") // Reuse ball as decor
        star.position = CGPoint(x: frame.midX, y: frame.height * 0.7)
        star.size = CGSize(width: 80, height: 80)
        star.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi, duration: 2.0)))
        addChild(star)
        
        // Title
        titleLabel = SKLabelNode(fontNamed: "Arial-BoldMT")
        
        let isLastLevel = nextLevelIndex >= LevelData.levels.count
        titleLabel?.text = isLastLevel ? "GAME COMPLETED!" : "LEVEL COMPLETE!"
        
        titleLabel?.fontSize = 40
        titleLabel?.fontColor = .black
        titleLabel?.position = CGPoint(x: frame.midX, y: frame.height * 0.55)
        titleLabel?.alpha = 0
        addChild(titleLabel!)
        
        // Next Button
        let btnWidth: CGFloat = 220
        let btnHeight: CGFloat = 60
        nextButton = SKShapeNode(rectOf: CGSize(width: btnWidth, height: btnHeight), cornerRadius: 15)
        nextButton?.fillColor = .black
        nextButton?.strokeColor = .black
        nextButton?.position = CGPoint(x: frame.midX, y: frame.height * 0.35)
        nextButton?.name = "nextButton"
        nextButton?.alpha = 0
        
        let btnLabel = SKLabelNode(fontNamed: "Arial-BoldMT")
        btnLabel.text = isLastLevel ? "MAIN MENU" : "NEXT LEVEL"
        btnLabel.fontSize = 24
        btnLabel.fontColor = .white
        btnLabel.verticalAlignmentMode = .center
        btnLabel.name = "nextButton" // Hit test name
        
        nextButton?.addChild(btnLabel)
        addChild(nextButton!)
    }
    
    private func animateEntrance() {
        titleLabel?.run(SKAction.fadeIn(withDuration: 0.5))
        
        nextButton?.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.3),
            SKAction.fadeIn(withDuration: 0.5),
            SKAction.scale(to: 1.1, duration: 0.2),
            SKAction.scale(to: 1.0, duration: 0.1)
        ]))
    }
    
    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)
        
        for node in touchedNodes {
            if node.name == "nextButton" || node.parent?.name == "nextButton" {
                handleNextButton()
                break
            }
        }
    }
    
    private func handleNextButton() {
        // Animation
        nextButton?.run(SKAction.sequence([
            SKAction.scale(to: 0.9, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ]))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.transitionToNext()
        }
    }
    
    private func transitionToNext() {
        // Check if we have levels left
        if nextLevelIndex < LevelData.levels.count {
            // Go to Next Level GameScene
            let gameScene = GameScene(size: self.size)
            gameScene.scaleMode = .aspectFill
            gameScene.startingLevelIndex = nextLevelIndex // Pass new index
            
            let transition = SKTransition.moveIn(with: .right, duration: 0.5)
            self.view?.presentScene(gameScene, transition: transition)
        } else {
            // Return to Main Menu
            let menuScene = MenuScene(size: self.size)
            menuScene.scaleMode = .aspectFill
            
            let transition = SKTransition.crossFade(withDuration: 0.5)
            self.view?.presentScene(menuScene, transition: transition)
        }
    }
}
