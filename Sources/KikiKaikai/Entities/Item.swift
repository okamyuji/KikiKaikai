import SpriteKit
import Foundation

class Item: SKSpriteNode {
    let itemType: ItemType
    private var sparkleTimer: Timer?
    private var lifetimeTimer: Timer?
    
    init(type: ItemType) {
        self.itemType = type
        
        let config = ItemConfiguration.getConfig(for: type)
        super.init(texture: nil, color: config.color, size: config.size)
        
        setupItem(config: config)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupItem(config: ItemConfiguration) {
        name = "item"
        zPosition = GameLayers.items
        
        setupPhysics(
            category: CollisionCategory.item,
            contact: CollisionCategory.player,
            collision: CollisionCategory.none,
            isDynamic: false
        )
        
        // アイテムの見た目を作成
        createVisuals(config: config)
        
        // スパークルエフェクト開始
        startSparkleEffect()
        
        // 浮遊エフェクト
        startFloatingEffect()
        
        // ライフタイマー開始
        startLifetimeTimer()
    }
    
    private func createVisuals(config: ItemConfiguration) {
        switch itemType {
        case .health:
            createHealthVisuals()
        case .crystalBall:
            createCrystalBallVisuals()
        case .powerUp(let type):
            createPowerUpVisuals(type: type)
        case .coin:
            createCoinVisuals()
        }
    }
    
    private func createHealthVisuals() {
        // ハート型（簡易版）
        let heart = SKSpriteNode(color: GameColors.healthRed, size: CGSize(width: 20, height: 18))
        heart.zPosition = 1
        addChild(heart)
        
        // ハートの光沢
        let shine = SKSpriteNode(color: .white, size: CGSize(width: 6, height: 6))
        shine.position = CGPoint(x: -4, y: 4)
        shine.alpha = 0.8
        shine.zPosition = 2
        addChild(shine)
        
        // 脈動エフェクト
        let pulseAction = SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.8),
            SKAction.scale(to: 0.9, duration: 0.8)
        ])
        let pulseRepeat = SKAction.repeatForever(pulseAction)
        run(pulseRepeat, withKey: "pulse")
    }
    
    private func createCrystalBallVisuals() {
        // 水晶玉本体
        let crystal = SKShapeNode(circleOfRadius: 12)
        crystal.fillColor = GameColors.powerBlue
        crystal.strokeColor = .white
        crystal.lineWidth = 2
        crystal.alpha = 0.8
        crystal.zPosition = 1
        addChild(crystal)
        
        // 内部の光
        let innerLight = SKShapeNode(circleOfRadius: 8)
        innerLight.fillColor = .cyan
        innerLight.alpha = 0.6
        innerLight.zPosition = 2
        addChild(innerLight)
        
        // 回転エフェクト
        let rotateAction = SKAction.rotate(byAngle: CGFloat.pi * 2, duration: 3.0)
        let rotateRepeat = SKAction.repeatForever(rotateAction)
        innerLight.run(rotateRepeat)
        
        // 光の点滅
        let blinkAction = SKAction.sequence([
            SKAction.fadeIn(withDuration: 1.0),
            SKAction.fadeOut(withDuration: 1.0)
        ])
        let blinkRepeat = SKAction.repeatForever(blinkAction)
        innerLight.run(blinkRepeat, withKey: "blink")
    }
    
    private func createPowerUpVisuals(type: PowerType) {
        let powerColor: SKColor
        let symbol: String
        
        switch type {
        case .damage:
            powerColor = GameColors.powerOrange
            symbol = "⚡" // 攻撃力
        case .speed:
            powerColor = GameColors.powerBlue
            symbol = "→" // 速度
        case .pierce:
            powerColor = GameColors.powerGreen
            symbol = "◆" // 貫通
        }
        
        // 力玉本体
        let orb = SKShapeNode(circleOfRadius: 10)
        orb.fillColor = powerColor
        orb.strokeColor = .white
        orb.lineWidth = 1
        orb.zPosition = 1
        addChild(orb)
        
        // シンボル（簡易版）
        let symbolNode = SKSpriteNode(color: .white, size: CGSize(width: 8, height: 8))
        symbolNode.zPosition = 2
        addChild(symbolNode)
        
        // オーラエフェクト
        let aura = SKShapeNode(circleOfRadius: 15)
        aura.strokeColor = powerColor
        aura.lineWidth = 1
        aura.fillColor = .clear
        aura.alpha = 0.5
        aura.zPosition = 0
        addChild(aura)
        
        // オーラアニメーション
        let auraAction = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 1.0),
            SKAction.scale(to: 0.8, duration: 1.0)
        ])
        let auraRepeat = SKAction.repeatForever(auraAction)
        aura.run(auraRepeat)
    }
    
    private func createCoinVisuals() {
        // コイン本体
        let coin = SKShapeNode(circleOfRadius: 8)
        coin.fillColor = .yellow
        coin.strokeColor = .orange
        coin.lineWidth = 1
        coin.zPosition = 1
        addChild(coin)
        
        // コインの模様
        let pattern = SKSpriteNode(color: .orange, size: CGSize(width: 8, height: 2))
        pattern.zPosition = 2
        addChild(pattern)
        
        let pattern2 = SKSpriteNode(color: .orange, size: CGSize(width: 2, height: 8))
        pattern2.zPosition = 2
        addChild(pattern2)
        
        // 回転エフェクト
        let spinAction = SKAction.rotate(byAngle: CGFloat.pi * 2, duration: 2.0)
        let spinRepeat = SKAction.repeatForever(spinAction)
        run(spinRepeat, withKey: "spin")
    }
    
    private func startSparkleEffect() {
        sparkleTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.createSparkle()
        }
    }
    
    private func createSparkle() {
        guard let scene = scene else { return }
        
        let sparkle = SKSpriteNode(color: .white, size: CGSize(width: 4, height: 4))
        
        // ランダムな位置（アイテム周辺）
        let randomOffset = CGPoint(
            x: CGFloat.random(in: -20...20),
            y: CGFloat.random(in: -20...20)
        )
        sparkle.position = position + randomOffset
        sparkle.zPosition = GameLayers.effects
        scene.addChild(sparkle)
        
        // スパークルアニメーション
        let sparkleAction = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 2.0, duration: GameConstants.sparkleLifetime),
                SKAction.fadeOut(withDuration: GameConstants.sparkleLifetime)
            ]),
            SKAction.removeFromParent()
        ])
        sparkle.run(sparkleAction)
    }
    
    private func startFloatingEffect() {
        let floatAction = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 8, duration: 2.0),
            SKAction.moveBy(x: 0, y: -8, duration: 2.0)
        ])
        let floatRepeat = SKAction.repeatForever(floatAction)
        run(floatRepeat, withKey: "float")
    }
    
    private func startLifetimeTimer() {
        lifetimeTimer = Timer.scheduledTimer(withTimeInterval: GameConstants.itemLifetime, repeats: false) { [weak self] _ in
            self?.expire()
        }
    }
    
    private func expire() {
        // 点滅してから消える
        let blinkAction = SKAction.blink(times: 6, duration: 1.0)
        let expireSequence = SKAction.sequence([
            blinkAction,
            SKAction.removeFromParent()
        ])
        run(expireSequence)
    }
    
    func collect() {
        // タイマーを停止
        sparkleTimer?.invalidate()
        lifetimeTimer?.invalidate()
        
        // 収集エフェクト
        let collectAction = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.5, duration: 0.2),
                SKAction.fadeOut(withDuration: 0.2)
            ]),
            SKAction.removeFromParent()
        ])
        run(collectAction)
        
        // 収集時のパーティクル
        createCollectParticles()
    }
    
    private func createCollectParticles() {
        guard let scene = scene else { return }
        
        for _ in 0..<8 {
            let particle = SKSpriteNode(color: color, size: CGSize(width: 3, height: 3))
            particle.position = position
            particle.zPosition = GameLayers.effects
            scene.addChild(particle)
            
            let angle = CGFloat.random(in: 0...(2 * CGFloat.pi))
            let distance: CGFloat = 30
            let targetPosition = CGPoint(
                x: position.x + cos(angle) * distance,
                y: position.y + sin(angle) * distance
            )
            
            let particleAction = SKAction.sequence([
                SKAction.group([
                    SKAction.move(to: targetPosition, duration: 0.5),
                    SKAction.fadeOut(withDuration: 0.5)
                ]),
                SKAction.removeFromParent()
            ])
            particle.run(particleAction)
        }
    }
    
    deinit {
        sparkleTimer?.invalidate()
        lifetimeTimer?.invalidate()
    }
}

// MARK: - アイテム設定
struct ItemConfiguration {
    let color: SKColor
    let size: CGSize
    let scoreValue: Int
    
    static func getConfig(for itemType: ItemType) -> ItemConfiguration {
        switch itemType {
        case .health:
            return ItemConfiguration(
                color: GameColors.healthRed,
                size: GameConstants.itemSize,
                scoreValue: 100
            )
            
        case .crystalBall:
            return ItemConfiguration(
                color: GameColors.powerBlue,
                size: GameConstants.itemSize,
                scoreValue: 200
            )
            
        case .powerUp(.damage):
            return ItemConfiguration(
                color: GameColors.powerOrange,
                size: GameConstants.itemSize,
                scoreValue: 300
            )
            
        case .powerUp(.speed):
            return ItemConfiguration(
                color: GameColors.powerBlue,
                size: GameConstants.itemSize,
                scoreValue: 300
            )
            
        case .powerUp(.pierce):
            return ItemConfiguration(
                color: GameColors.powerGreen,
                size: GameConstants.itemSize,
                scoreValue: 300
            )
            
        case .coin:
            return ItemConfiguration(
                color: .yellow,
                size: CGSize(width: 16, height: 16),
                scoreValue: 50
            )
        }
    }
}

// MARK: - アイテムスポナー
class ItemSpawner {
    private weak var scene: SKScene?
    private var spawnTimer: Timer?
    
    init(scene: SKScene) {
        self.scene = scene
    }
    
    func startSpawning() {
        spawnTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.spawnRandomItem()
        }
    }
    
    func stopSpawning() {
        spawnTimer?.invalidate()
        spawnTimer = nil
    }
    
    private func spawnRandomItem() {
        guard let scene = scene else { return }
        
        // ランダムなアイテムタイプ（重み付き）
        let weightedItems: [(ItemType, Int)] = [
            (.coin, 50),
            (.health, 15),
            (.crystalBall, 10),
            (.powerUp(.damage), 8),
            (.powerUp(.speed), 8),
            (.powerUp(.pierce), 9)
        ]
        
        let totalWeight = weightedItems.reduce(0) { $0 + $1.1 }
        let randomValue = Int.random(in: 0..<totalWeight)
        
        var currentWeight = 0
        var selectedType: ItemType = .coin
        
        for (itemType, weight) in weightedItems {
            currentWeight += weight
            if randomValue < currentWeight {
                selectedType = itemType
                break
            }
        }
        
        // ランダムな位置にスポーン
        let spawnArea = CGRect(
            x: 50,
            y: 50,
            width: GameConstants.screenWidth - 100,
            height: GameConstants.screenHeight - 100
        )
        
        let item = Item(type: selectedType)
        item.position = GameConstants.randomPosition(inRect: spawnArea)
        scene.addChild(item)
    }
    
    deinit {
        stopSpawning()
    }
}

// MARK: - 特殊アイテム
class SpecialItem: Item {
    enum SpecialType {
        case invincibility    // 無敵
        case rapidFire       // 連射
        case shield          // シールド
        case magnetism       // 磁力（アイテム吸引）
        
        var duration: TimeInterval {
            switch self {
            case .invincibility: return 5.0
            case .rapidFire: return 8.0
            case .shield: return 10.0
            case .magnetism: return 15.0
            }
        }
        
        var color: SKColor {
            switch self {
            case .invincibility: return SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0) // ゴールド色
            case .rapidFire: return .orange
            case .shield: return .blue
            case .magnetism: return .purple
            }
        }
    }
    
    let specialType: SpecialType
    
    init(type: SpecialType) {
        self.specialType = type
        super.init(type: .coin) // 基底クラスのイニシャライザを呼ぶ
        
        // 特殊アイテムの見た目に変更
        setupSpecialVisuals()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSpecialVisuals() {
        removeAllChildren()
        color = specialType.color
        
        // 特殊エフェクト
        let aura = SKShapeNode(circleOfRadius: 20)
        aura.strokeColor = specialType.color
        aura.lineWidth = 2
        aura.fillColor = .clear
        aura.alpha = 0.3
        aura.zPosition = 0
        addChild(aura)
        
        // オーラパルス
        let pulseAction = SKAction.sequence([
            SKAction.scale(to: 1.3, duration: 0.5),
            SKAction.scale(to: 0.7, duration: 0.5)
        ])
        let pulseRepeat = SKAction.repeatForever(pulseAction)
        aura.run(pulseRepeat)
        
        // 本体
        let core = SKShapeNode(circleOfRadius: 12)
        core.fillColor = specialType.color
        core.strokeColor = .white
        core.lineWidth = 2
        core.zPosition = 1
        addChild(core)
    }
    
    func applyEffect(to player: Player, gameManager: GameManager) {
        switch specialType {
        case .invincibility:
            // 無敵効果の実装
            break
        case .rapidFire:
            // 連射効果の実装
            break
        case .shield:
            // シールド効果の実装
            break
        case .magnetism:
            // 磁力効果の実装
            break
        }
    }
}
