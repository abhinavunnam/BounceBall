
import SpriteKit

class LevelSelectScene: SKScene {
    
    // MARK: - Properties
    private let levelsPerRow = 3
    // Removed fixed properties to calculate dynamically in createLevelGrid
    
    override func didMove(to view: SKView) {
        backgroundColor = .white
        
        createTitle()
        createLevelGrid()
        createBackButton()
    }
    
    // MARK: - UI Configuration
    private func createTitle() {
        let titleLabel = SKLabelNode(fontNamed: "Arial-BoldMT")
        titleLabel.text = "SELECT LEVEL"
        titleLabel.fontSize = 32
        titleLabel.fontColor = .black
        titleLabel.position = CGPoint(x: frame.midX, y: frame.height * 0.85)
        addChild(titleLabel)
    }
    
    private func createLevelGrid() {
        let totalLevels = LevelData.levels.count
        let highestUnlocked = GameData.shared.highestUnlockedLevelIndex
        
        // Dynamic Columns: 4 for iPad (wider aspect ratio), 3 for iPhone
        // iPad is 4:3 (~1.33), iPhone is 19.5:9 (~2.16 height/width or ~0.46 width/height)
        // If width/height > 0.6 (wider screen), use 4 columns
        let aspectRatio = frame.width / frame.height
        let levelsPerRow = aspectRatio > 0.6 ? 4 : 3
        
        // Calculate Rows needed
        let rows = Int(ceil(Double(totalLevels) / Double(levelsPerRow)))
        
        // SAFETY BOUNDS
        // Title is at 0.85, Back Button at 0.15.
        // Safe area: 0.80 down to 0.20
        let topY = frame.height * 0.75
        let bottomY = frame.height * 0.25
        let availableHeight = topY - bottomY
        let availableWidth = frame.width * 0.85 // 85% width
        
        // Spacing
        let spacingX = frame.width * 0.02
        let spacingY = frame.height * 0.02
        
        // Calculate Max Possible Button Size
        // 1. Based on Width
        let widthForButtons = availableWidth - (spacingX * CGFloat(levelsPerRow - 1))
        let maxButtonWidth = widthForButtons / CGFloat(levelsPerRow)
        
        // 2. Based on Height
        let heightForButtons = availableHeight - (spacingY * CGFloat(rows - 1))
        let maxButtonHeight = heightForButtons / CGFloat(rows)
        
        // Use the smaller dimension to ensure it fits both ways (keep square)
        let buttonSide = min(maxButtonWidth, maxButtonHeight)
        let buttonSize = CGSize(width: buttonSide, height: buttonSide)
        
        // Center the grid explicitly
        let totalGridWidth = (buttonSide * CGFloat(levelsPerRow)) + (spacingX * CGFloat(levelsPerRow - 1))
        let totalGridHeight = (buttonSide * CGFloat(rows)) + (spacingY * CGFloat(rows - 1))
        
        let startX = frame.midX - (totalGridWidth / 2) + (buttonSide / 2)
        let startY = frame.midY + (totalGridHeight / 2) - (buttonSide / 2) // Centered vertically
        
        for i in 0..<totalLevels {
            let column = i % levelsPerRow
            let row = i / levelsPerRow
            
            let x = startX + CGFloat(column) * (buttonSide + spacingX)
            let y = startY - CGFloat(row) * (buttonSide + spacingY)
            
            let levelIndex = i
            let isUnlocked = levelIndex <= highestUnlocked
            
            createLevelButton(index: levelIndex, x: x, y: y, isUnlocked: isUnlocked, size: buttonSize)
        }
    }
    
    private func createLevelButton(index: Int, x: CGFloat, y: CGFloat, isUnlocked: Bool, size: CGSize) {
        let button = SKShapeNode(rectOf: size, cornerRadius: 15)
        button.position = CGPoint(x: x, y: y)
        button.lineWidth = 2
        button.name = "Level_\(index)"
        
        if isUnlocked {
            button.fillColor = .white
            button.strokeColor = .black
        } else {
            button.fillColor = UIColor(white: 0.9, alpha: 1.0) // Light Grey
            button.strokeColor = .lightGray
        }
        
        addChild(button)
        
        // Label
        let label = SKLabelNode(fontNamed: "Arial-BoldMT")
        label.text = "\(index + 1)"
        label.fontSize = 32
        label.fontColor = isUnlocked ? .black : .gray
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.name = "Level_\(index)" // Give label same name for easier touch handling
        button.addChild(label)
        
        // Lock Icon (Simple representation if locked)
        if !isUnlocked {
            // Optional: Draw a small lock? For now color distinction is enough.
        }
    }
    
    private func createBackButton() {
        let backButton = SKLabelNode(fontNamed: "Arial")
        backButton.text = "BACK"
        backButton.fontSize = 20
        backButton.fontColor = .darkGray
        backButton.position = CGPoint(x: frame.midX, y: frame.height * 0.15)
        backButton.name = "backButton"
        addChild(backButton)
    }
    
    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)
        
        for node in touchedNodes {
            if let name = node.name {
                if name == "backButton" {
                    transitionToMenu()
                    return
                }
                
                if name.starts(with: "Level_") {
                    let parts = name.split(separator: "_")
                    if parts.count == 2, let index = Int(parts[1]) {
                        // Check lock again just in case
                        if index <= GameData.shared.highestUnlockedLevelIndex {
                            transitionToGame(levelIndex: index)
                        } else {
                            // Locked animation (shake)?
                            let moveRight = SKAction.moveBy(x: 5, y: 0, duration: 0.05)
                            let moveLeft = SKAction.moveBy(x: -5, y: 0, duration: 0.05)
                            node.run(SKAction.sequence([moveRight, moveLeft, moveLeft, moveRight]))
                        }
                    }
                    return
                }
            }
        }
    }
    
    // MARK: - Navigation
    private func transitionToMenu() {
        let menuScene = MenuScene(size: size)
        menuScene.scaleMode = .aspectFill
        view?.presentScene(menuScene, transition: SKTransition.moveIn(with: .left, duration: 0.3))
    }
    
    private func transitionToGame(levelIndex: Int) {
        let gameScene = GameScene(size: size)
        gameScene.scaleMode = .aspectFill
        gameScene.startingLevelIndex = levelIndex // Need to ensure GameScene respects this
        view?.presentScene(gameScene, transition: SKTransition.doorway(withDuration: 0.5))
    }
}
