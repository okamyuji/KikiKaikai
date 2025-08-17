import SpriteKit
import Foundation

class ScoreDisplay {
    
    // MARK: - スコアポップアップ作成
    
    static func createScorePopup(points: Int, at position: CGPoint, scene: SKScene) {
        let scoreLabel = SKLabelNode(text: "+\(points)")
        scoreLabel.fontName = "AvenirNext-Bold"
        scoreLabel.fontSize = 16
        scoreLabel.fontColor = GameColors.scoreWhite
        scoreLabel.position = position
        scoreLabel.zPosition = GameLayers.ui
        
        scene.addChild(scoreLabel)
        
        // アニメーション
        let moveUp = SKAction.moveBy(x: 0, y: 30, duration: 1.0)
        let fadeOut = SKAction.fadeOut(withDuration: 1.0)
        let scale = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ])
        
        let group = SKAction.group([moveUp, fadeOut])
        let sequence = SKAction.sequence([
            scale,
            group,
            SKAction.removeFromParent()
        ])
        
        scoreLabel.run(sequence)
    }
    
    static func createBonusPopup(points: Int, reason: String, at position: CGPoint, scene: SKScene) {
        let bonusLabel = SKLabelNode(text: "\(reason)\n+\(points)")
        bonusLabel.fontName = "AvenirNext-Bold"
        bonusLabel.fontSize = 14
        bonusLabel.fontColor = GameColors.powerOrange
        bonusLabel.position = position
        bonusLabel.zPosition = GameLayers.ui + 1
        bonusLabel.numberOfLines = 2
        
        scene.addChild(bonusLabel)
        
        // 派手なアニメーション
        let moveUp = SKAction.moveBy(x: 0, y: 50, duration: 1.5)
        let fadeOut = SKAction.fadeOut(withDuration: 1.5)
        let scale = SKAction.sequence([
            SKAction.scale(to: 1.5, duration: 0.2),
            SKAction.scale(to: 1.0, duration: 0.2)
        ])
        let glow = createGlowEffect()
        
        bonusLabel.addChild(glow)
        
        let group = SKAction.group([moveUp, fadeOut])
        let sequence = SKAction.sequence([
            scale,
            group,
            SKAction.removeFromParent()
        ])
        
        bonusLabel.run(sequence)
    }
    
    static func createComboPopup(combo: Int, at position: CGPoint, scene: SKScene) {
        let comboLabel = SKLabelNode(text: "\(combo) COMBO!")
        comboLabel.fontName = "AvenirNext-Heavy"
        comboLabel.fontSize = 20
        comboLabel.fontColor = GameColors.powerBlue
        comboLabel.position = position
        comboLabel.zPosition = GameLayers.ui + 2
        
        scene.addChild(comboLabel)
        
        // コンボアニメーション
        let bounce = SKAction.sequence([
            SKAction.scale(to: 1.3, duration: 0.1),
            SKAction.scale(to: 1.1, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ])
        
        let moveUp = SKAction.moveBy(x: 0, y: 40, duration: 1.2)
        let fadeOut = SKAction.fadeOut(withDuration: 1.2)
        
        let group = SKAction.group([moveUp, fadeOut])
        let sequence = SKAction.sequence([
            bounce,
            group,
            SKAction.removeFromParent()
        ])
        
        comboLabel.run(sequence)
        
        // パーティクル効果
        addComboParticles(at: position, scene: scene)
    }
    
    static func createMilestonePopup(milestone: Int, at position: CGPoint, scene: SKScene) {
        let milestoneLabel = SKLabelNode(text: "MILESTONE!\n\(milestone) PTS")
        milestoneLabel.fontName = "AvenirNext-Heavy"
        milestoneLabel.fontSize = 24
        milestoneLabel.fontColor = GameColors.powerGreen
        milestoneLabel.position = position
        milestoneLabel.zPosition = GameLayers.ui + 3
        milestoneLabel.numberOfLines = 2
        
        scene.addChild(milestoneLabel)
        
        // マイルストーンアニメーション
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.5, duration: 0.3),
            SKAction.scale(to: 1.2, duration: 0.2),
            SKAction.scale(to: 1.0, duration: 0.3)
        ])
        
        let stay = SKAction.wait(forDuration: 1.0)
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        
        let sequence = SKAction.sequence([
            pulse,
            stay,
            fadeOut,
            SKAction.removeFromParent()
        ])
        
        milestoneLabel.run(sequence)
        
        // 画面エフェクト
        createScreenFlash(color: GameColors.powerGreen, scene: scene)
    }
    
    // MARK: - エフェクト作成
    
    private static func createGlowEffect() -> SKNode {
        let glow = SKSpriteNode(color: GameColors.powerOrange, size: CGSize(width: 100, height: 30))
        glow.alpha = 0.3
        glow.zPosition = -1
        
        let glowAnimation = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.6, duration: 0.5),
            SKAction.fadeAlpha(to: 0.1, duration: 0.5)
        ])
        glow.run(SKAction.repeatForever(glowAnimation))
        
        return glow
    }
    
    private static func addComboParticles(at position: CGPoint, scene: SKScene) {
        for _ in 0..<8 {
            let particle = SKSpriteNode(color: GameColors.powerBlue, size: CGSize(width: 4, height: 4))
            particle.position = position
            particle.zPosition = GameLayers.effects
            scene.addChild(particle)
            
            let randomAngle = CGFloat.random(in: 0...(CGFloat.pi * 2))
            let randomDistance = CGFloat.random(in: 30...60)
            let targetPosition = CGPoint(
                x: position.x + cos(randomAngle) * randomDistance,
                y: position.y + sin(randomAngle) * randomDistance
            )
            
            let moveAction = SKAction.move(to: targetPosition, duration: 0.8)
            let fadeAction = SKAction.fadeOut(withDuration: 0.8)
            let group = SKAction.group([moveAction, fadeAction])
            let sequence = SKAction.sequence([group, SKAction.removeFromParent()])
            
            particle.run(sequence)
        }
    }
    
    private static func createScreenFlash(color: SKColor, scene: SKScene) {
        let flash = SKSpriteNode(color: color, size: scene.size)
        flash.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        flash.alpha = 0.0
        flash.zPosition = GameLayers.effects + 10
        scene.addChild(flash)
        
        let flashAction = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.1),
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ])
        flash.run(flashAction)
    }
}

// MARK: - HUD管理
class HUDDisplay {
    private var scene: SKScene
    private var hudContainer: SKNode
    
    // UI要素
    private var scoreLabel: SKLabelNode
    private var healthBars: [SKSpriteNode] = []
    private var crystalBallIcons: [SKSpriteNode] = []
    private var comboLabel: SKLabelNode
    private var timeLabel: SKLabelNode
    
    init(scene: SKScene) {
        self.scene = scene
        self.hudContainer = SKNode()
        
        // ラベル初期化
        self.scoreLabel = SKLabelNode(text: "SCORE: 0")
        self.comboLabel = SKLabelNode(text: "")
        self.timeLabel = SKLabelNode(text: "TIME: 00:00")
        
        setupHUD()
    }
    
    private func setupHUD() {
        hudContainer.zPosition = GameLayers.ui
        scene.addChild(hudContainer)
        
        // スコア表示
        scoreLabel.fontName = "AvenirNext-Bold"
        scoreLabel.fontSize = 24
        scoreLabel.fontColor = GameColors.scoreWhite
        scoreLabel.position = CGPoint(x: 20, y: scene.size.height - 40)
        scoreLabel.horizontalAlignmentMode = .left
        hudContainer.addChild(scoreLabel)
        
        // ヘルス表示
        setupHealthDisplay()
        
        // 水晶玉表示
        setupCrystalBallDisplay()
        
        // コンボ表示
        comboLabel.fontName = "AvenirNext-Bold"
        comboLabel.fontSize = 16
        comboLabel.fontColor = GameColors.powerBlue
        comboLabel.position = CGPoint(x: scene.size.width / 2, y: scene.size.height - 40)
        comboLabel.horizontalAlignmentMode = .center
        hudContainer.addChild(comboLabel)
        
        // タイム表示
        timeLabel.fontName = "AvenirNext-Medium"
        timeLabel.fontSize = 16
        timeLabel.fontColor = GameColors.scoreWhite
        timeLabel.position = CGPoint(x: scene.size.width - 20, y: scene.size.height - 40)
        timeLabel.horizontalAlignmentMode = .right
        hudContainer.addChild(timeLabel)
    }
    
    private func setupHealthDisplay() {
        let startX: CGFloat = 20
        let startY: CGFloat = scene.size.height - 80
        
        for i in 0..<GameConstants.playerMaxHealth {
            let healthBar = SKSpriteNode(color: GameColors.healthRed, size: CGSize(width: 30, height: 10))
            healthBar.position = CGPoint(x: startX + CGFloat(i) * 35, y: startY)
            healthBars.append(healthBar)
            hudContainer.addChild(healthBar)
        }
    }
    
    private func setupCrystalBallDisplay() {
        let startX: CGFloat = 20
        let startY: CGFloat = scene.size.height - 110
        
        for i in 0..<2 { // 初期水晶玉数
            let crystalIcon = SKSpriteNode(color: GameColors.powerBlue, size: CGSize(width: 20, height: 20))
            crystalIcon.position = CGPoint(x: startX + CGFloat(i) * 25, y: startY)
            crystalBallIcons.append(crystalIcon)
            hudContainer.addChild(crystalIcon)
        }
    }
    
    // MARK: - HUD更新
    
    func updateScore(_ score: Int) {
        scoreLabel.text = "SCORE: \(score)"
    }
    
    func updateHealth(_ health: Int) {
        for (index, healthBar) in healthBars.enumerated() {
            healthBar.isHidden = index >= health
        }
    }
    
    func updateCrystalBalls(_ count: Int) {
        for (index, crystalIcon) in crystalBallIcons.enumerated() {
            crystalIcon.isHidden = index >= count
        }
    }
    
    func updateCombo(_ combo: Int) {
        if combo > 1 {
            comboLabel.text = "\(combo) COMBO"
            comboLabel.isHidden = false
        } else {
            comboLabel.isHidden = true
        }
    }
    
    func updateTime(_ time: TimeInterval) {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        timeLabel.text = String(format: "TIME: %02d:%02d", minutes, seconds)
    }
    
    func showPowerUpIndicator(_ powerType: String) {
        let indicator = SKLabelNode(text: "\(powerType) POWER UP!")
        indicator.fontName = "AvenirNext-Bold"
        indicator.fontSize = 18
        indicator.fontColor = GameColors.powerOrange
        indicator.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2 + 50)
        indicator.horizontalAlignmentMode = .center
        indicator.zPosition = GameLayers.ui + 5
        hudContainer.addChild(indicator)
        
        let showAction = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.2),
            SKAction.scale(to: 1.0, duration: 0.2),
            SKAction.wait(forDuration: 1.0),
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ])
        indicator.run(showAction)
    }
    
    func hide() {
        hudContainer.isHidden = true
    }
    
    func show() {
        hudContainer.isHidden = false
    }
}
