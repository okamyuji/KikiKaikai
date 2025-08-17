import SpriteKit
import Foundation

// MARK: - Enemy プロトコル
protocol Enemy: SKNode {
    var health: Int { get set }
    var maxHealth: Int { get }
    var scoreValue: Int { get }
    var gameManager: GameManager { get }
    var velocity: CGVector { get set }
    
    func takeDamage(_ damage: Int)
    func update(_ deltaTime: TimeInterval)
    func performAttack()
}

// MARK: - 基底Enemyクラス
class BaseEnemy: SKSpriteNode, Enemy {
    var health: Int
    var maxHealth: Int
    var scoreValue: Int
    var gameManager: GameManager
    
    // 移動関連
    var velocity = CGVector.zero
    var targetPosition: CGPoint?
    internal var lastAttackTime: TimeInterval = 0
    internal var attackCooldown: TimeInterval = 2.0
    var isStopped: Bool = false
    
    // アニメーション関連
    private var isFlashing = false
    
    init(gameManager: GameManager, health: Int, scoreValue: Int, color: SKColor, size: CGSize) {
        self.gameManager = gameManager
        self.health = health
        self.maxHealth = health
        self.scoreValue = scoreValue
        
        super.init(texture: nil, color: color, size: size)
        
        setupEnemy()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupEnemy() {
        name = "enemy"
        zPosition = GameLayers.enemies
        
        setupPhysics(
            category: CollisionCategory.enemy,
            contact: CollisionCategory.player | CollisionCategory.ofuda | CollisionCategory.oharai,
            collision: CollisionCategory.boundary
        )
        
        // 基本的な敵の見た目
        addEnemyVisuals()
        startIdleAnimation()
    }
    
    func addEnemyVisuals() {
        // 継承先でオーバーライド
    }
    
    func startIdleAnimation() {
        let idleAction = SKAction.sequence([
            SKAction.scale(to: 1.05, duration: 1.0),
            SKAction.scale(to: 0.95, duration: 1.0)
        ])
        let idleRepeat = SKAction.repeatForever(idleAction)
        run(idleRepeat, withKey: AnimationKeys.enemyMove)
    }
    
    func takeDamage(_ damage: Int) {
        health -= damage
        
        // ダメージエフェクト
        flashDamage()
        
        if health <= 0 {
            destroy()
        }
    }
    
    private func flashDamage() {
        guard !isFlashing else { return }
        isFlashing = true
        
        let originalColor = color
        let flashAction = SKAction.sequence([
            SKAction.colorize(with: .red, colorBlendFactor: 0.8, duration: 0.1),
            SKAction.colorize(with: originalColor, colorBlendFactor: 1.0, duration: 0.1),
            SKAction.run { [weak self] in
                self?.isFlashing = false
            }
        ])
        run(flashAction)
    }
    
    private func destroy() {
        // スコア加算
        gameManager.enemyKilled(scoreValue: scoreValue)
        
        // 破壊エフェクト
        createDestroyEffect()
        
        // アイテムドロップ判定
        dropItem()
        
        // 敵を削除
        removeFromParent()
    }
    
    private func createDestroyEffect() {
        guard let scene = scene else { return }
        
        // 爆発エフェクト
        let explosion = SKSpriteNode(color: .orange, size: CGSize(width: size.width * 2, height: size.height * 2))
        explosion.position = position
        explosion.zPosition = GameLayers.effects
        scene.addChild(explosion)
        
        let explosionAction = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.5, duration: 0.3),
                SKAction.fadeOut(withDuration: 0.3)
            ]),
            SKAction.removeFromParent()
        ])
        explosion.run(explosionAction)
        
        // パーティクル効果
        createParticles()
    }
    
    private func createParticles() {
        guard let scene = scene else { return }
        
        for _ in 0..<5 {
            let particle = SKSpriteNode(color: color, size: CGSize(width: 4, height: 4))
            particle.position = position
            particle.zPosition = GameLayers.effects
            scene.addChild(particle)
            
            let randomDirection = CGVector(
                dx: CGFloat.random(in: -1...1),
                dy: CGFloat.random(in: -1...1)
            ).normalized
            
            let particleAction = SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(
                        x: randomDirection.dx * 50,
                        y: randomDirection.dy * 50,
                        duration: 0.5
                    ),
                    SKAction.fadeOut(withDuration: 0.5)
                ]),
                SKAction.removeFromParent()
            ])
            particle.run(particleAction)
        }
    }
    
    private func dropItem() {
        // アイテムドロップ率
        let dropRate = GameSettings.currentDifficulty.itemDropRate
        guard CGFloat.random(in: 0...1) < dropRate else { return }
        
        // ランダムなアイテムタイプ
        let itemTypes: [ItemType] = [.coin, .health, .crystalBall, .powerUp(.damage), .powerUp(.speed), .powerUp(.pierce)]
        guard let itemType = itemTypes.randomElement else { return }
        
        let item = Item(type: itemType)
        item.position = position
        scene?.addChild(item)
    }
    
    func update(_ deltaTime: TimeInterval) {
        // 基本的な更新処理（継承先でオーバーライド）
        updateMovement(deltaTime)
        
        // 画面外チェック
        if !isOnScreen {
            removeFromParent()
        }
    }
    
    func updateMovement(_ deltaTime: TimeInterval) {
        position = position + CGPoint(x: velocity.dx * CGFloat(deltaTime), y: velocity.dy * CGFloat(deltaTime))
    }
    
    func performAttack() {
        // 基本的な攻撃処理（継承先でオーバーライド）
    }
    
    func canAttack(currentTime: TimeInterval) -> Bool {
        return currentTime - lastAttackTime >= attackCooldown
    }
    
    func markAttackTime(_ time: TimeInterval) {
        lastAttackTime = time
    }
}

// MARK: - 人魂（Hitodama）
class Hitodama: BaseEnemy {
    private var formationPosition: CGPoint?
    private var formationOffset: CGVector?
    
    init(gameManager: GameManager) {
        super.init(
            gameManager: gameManager,
            health: 1,
            scoreValue: 100,
            color: GameColors.enemyPurple,
            size: CGSize(width: 24, height: 24)
        )
        
        setupHitodama()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupHitodama() {
        name = "hitodama"
        attackCooldown = 3.0
    }
    
    override func addEnemyVisuals() {
        // 人魂の見た目（青白い炎）
        let flame = SKSpriteNode(color: .cyan, size: CGSize(width: 20, height: 20))
        flame.zPosition = 1
        addChild(flame)
        
        // 尻尾効果
        let tail = SKSpriteNode(color: .blue, size: CGSize(width: 8, height: 16))
        tail.position = CGPoint(x: 0, y: -12)
        tail.zPosition = 0
        addChild(tail)
        
        // 揺らめきアニメーション
        let flickerAction = SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.3),
            SKAction.scale(to: 0.9, duration: 0.3)
        ])
        let flickerRepeat = SKAction.repeatForever(flickerAction)
        flame.run(flickerRepeat)
    }
    
    override func update(_ deltaTime: TimeInterval) {
        super.update(deltaTime)
        
        // プレイヤーを追跡
        if let scene = scene,
           let player = scene.childNode(withName: "player") as? Player {
            let direction = position.direction(to: player.position)
            velocity = direction * GameConstants.enemyBaseSpeed * 0.8
        }
        
        // 攻撃チェック
        if canAttack(currentTime: CACurrentMediaTime()) {
            performAttack()
        }
    }
    
    override func performAttack() {
        guard let scene = scene,
              let player = scene.childNode(withName: "player") as? Player else { return }
        
        markAttackTime(CACurrentMediaTime())
        
        // プレイヤーに向けて弾を発射
        let bullet = EnemyBullet(type: .fireball)
        bullet.position = position
        
        let direction = position.direction(to: player.position)
        bullet.launch(direction: direction)
        
        scene.addChild(bullet)
    }
}

// MARK: - 化け提灯（BakeChouchin）
class BakeChouchin: BaseEnemy {
    private var shootAndRunPattern = false
    private var hasShot = false
    
    init(gameManager: GameManager) {
        super.init(
            gameManager: gameManager,
            health: 2,
            scoreValue: 150,
            color: GameColors.enemyRed,
            size: CGSize(width: 28, height: 32)
        )
        
        setupBakeChouchin()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupBakeChouchin() {
        name = "bakechouchin"
        shootAndRunPattern = true
        attackCooldown = 2.5
    }
    
    override func addEnemyVisuals() {
        // 提灯の本体（赤）
        let lanternBody = SKSpriteNode(color: GameColors.enemyRed, size: CGSize(width: 24, height: 28))
        lanternBody.zPosition = 1
        addChild(lanternBody)
        
        // 提灯の枠（黒）
        let frame = SKShapeNode(rect: CGRect(x: -12, y: -14, width: 24, height: 28))
        frame.strokeColor = .black
        frame.lineWidth = 2
        frame.fillColor = .clear
        frame.zPosition = 2
        addChild(frame)
        
        // 火（オレンジ）
        let fire = SKSpriteNode(color: .orange, size: CGSize(width: 8, height: 12))
        fire.position = CGPoint(x: 0, y: 2)
        fire.zPosition = 3
        addChild(fire)
        
        // 火の揺らめき
        let fireAction = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.2),
            SKAction.scale(to: 0.8, duration: 0.2)
        ])
        let fireRepeat = SKAction.repeatForever(fireAction)
        fire.run(fireRepeat)
    }
    
    override func update(_ deltaTime: TimeInterval) {
        super.update(deltaTime)
        
        if shootAndRunPattern && !hasShot {
            // 一回攻撃してから逃げる
            if canAttack(currentTime: CACurrentMediaTime()) {
                performAttack()
                hasShot = true
                
                // 逃走開始
                velocity = CGVector(dx: CGFloat.random(in: -100...100), dy: -GameConstants.enemyBaseSpeed * 1.5)
            }
        } else if !shootAndRunPattern {
            // 通常の移動パターン
            velocity = CGVector(dx: 0, dy: -GameConstants.enemyBaseSpeed * 0.6)
        }
    }
    
    override func performAttack() {
        guard let scene = scene else { return }
        
        markAttackTime(CACurrentMediaTime())
        
        // 火の玉を発射
        let bullet = EnemyBullet(type: .fireball)
        bullet.position = position
        
        // 下向きに発射
        bullet.launch(direction: CGVector(dx: 0, dy: -1))
        
        scene.addChild(bullet)
    }
}

// MARK: - ろくろ首（Rokurokubi）
class Rokurokubi: BaseEnemy {
    private var chargeDirection: CGVector?
    private var isCharging = false
    
    init(gameManager: GameManager) {
        super.init(
            gameManager: gameManager,
            health: 3,
            scoreValue: 200,
            color: GameColors.enemyGreen,
            size: CGSize(width: 32, height: 32)
        )
        
        setupRokurokubi()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupRokurokubi() {
        name = "rokurokubi"
        attackCooldown = 4.0
    }
    
    override func addEnemyVisuals() {
        // 体（緑）
        let body = SKSpriteNode(color: GameColors.enemyGreen, size: CGSize(width: 24, height: 20))
        body.position = CGPoint(x: 0, y: -6)
        body.zPosition = 1
        addChild(body)
        
        // 首（薄緑）
        let neck = SKSpriteNode(color: .green, size: CGSize(width: 8, height: 16))
        neck.position = CGPoint(x: 0, y: 4)
        neck.zPosition = 1
        addChild(neck)
        
        // 頭（緑）
        let head = SKSpriteNode(color: GameColors.enemyGreen, size: CGSize(width: 16, height: 16))
        head.position = CGPoint(x: 0, y: 12)
        head.zPosition = 2
        addChild(head)
        
        // 首伸縮アニメーション
        let stretchAction = SKAction.sequence([
            SKAction.scaleY(to: 1.5, duration: 0.5),
            SKAction.scaleY(to: 1.0, duration: 0.5)
        ])
        let stretchRepeat = SKAction.repeatForever(stretchAction)
        neck.run(stretchRepeat)
    }
    
    override func update(_ deltaTime: TimeInterval) {
        super.update(deltaTime)
        
        if !isCharging {
            // プレイヤーに向かってチャージ準備
            if let scene = scene,
               let player = scene.childNode(withName: "player") as? Player {
                chargeDirection = position.direction(to: player.position)
                startCharge()
            }
        }
    }
    
    private func startCharge() {
        isCharging = true
        
        // チャージエフェクト
        let chargeEffect = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.3),
            SKAction.scale(to: 0.8, duration: 0.1),
            SKAction.run { [weak self] in
                self?.executeCharge()
            }
        ])
        run(chargeEffect)
    }
    
    private func executeCharge() {
        guard let direction = chargeDirection else { return }
        
        velocity = direction * GameConstants.enemyBaseSpeed * 2.0
        
        // チャージ時間制限
        let chargeAction = SKAction.sequence([
            SKAction.wait(forDuration: 2.0),
            SKAction.run { [weak self] in
                self?.stopCharge()
            }
        ])
        run(chargeAction, withKey: "charge")
    }
    
    private func stopCharge() {
        isCharging = false
        velocity = CGVector.zero
        removeAction(forKey: "charge")
    }
    
    override func performAttack() {
        // ろくろ首は体当たりが主攻撃
    }
}

// MARK: - 留無留（Rumuru）
class Rumuru: BaseEnemy {
    private var attachedToPlayer = false
    private var attachmentTimer: Timer?
    
    init(gameManager: GameManager) {
        super.init(
            gameManager: gameManager,
            health: 1,
            scoreValue: 300,
            color: .purple,
            size: CGSize(width: 20, height: 20)
        )
        
        setupRumuru()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupRumuru() {
        name = "rumuru"
        attackCooldown = 1.5
    }
    
    override func addEnemyVisuals() {
        // 小さな紫の球体
        let sphere = SKShapeNode(circleOfRadius: 10)
        sphere.fillColor = .purple
        sphere.strokeColor = .magenta
        sphere.lineWidth = 1
        sphere.zPosition = 1
        addChild(sphere)
        
        // 浮遊エフェクト
        let floatAction = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 5, duration: 0.8),
            SKAction.moveBy(x: 0, y: -5, duration: 0.8)
        ])
        let floatRepeat = SKAction.repeatForever(floatAction)
        run(floatRepeat)
    }
    
    override func update(_ deltaTime: TimeInterval) {
        if !attachedToPlayer {
            super.update(deltaTime)
            
            // プレイヤーに近づく
            if let scene = scene,
               let player = scene.childNode(withName: "player") as? Player {
                let direction = position.direction(to: player.position)
                velocity = direction * GameConstants.enemyBaseSpeed * 1.5
                
                // プレイヤーに接触したら取り憑く
                let distance = position.distance(to: player.position)
                if distance < 30 {
                    attachToPlayer(player)
                }
            }
        }
    }
    
    private func attachToPlayer(_ player: Player) {
        attachedToPlayer = true
        velocity = CGVector.zero
        
        // プレイヤーの子ノードになる
        removeFromParent()
        player.addChild(self)
        position = CGPoint(x: 0, y: 20) // プレイヤーの頭上
        
        // 一定時間後にダメージを与えて消える
        attachmentTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self, weak player] _ in
            player?.takeDamage(1)
            self?.removeFromParent()
        }
        
        // 御祓い棒で弾き飛ばされる可能性
    }
    
    func detachFromPlayer() {
        attachmentTimer?.invalidate()
        attachmentTimer = nil
        attachedToPlayer = false
        
        // 親から離れる
        if let parent = parent {
            let worldPosition = parent.convert(position, to: scene!)
            removeFromParent()
            scene?.addChild(self)
            position = worldPosition
        }
        
        // 逃走
        velocity = CGVector(dx: CGFloat.random(in: -200...200), dy: 200)
    }
    
    override func performAttack() {
        // 取り憑き中はダメージを与える（attachToPlayerで処理）
    }
}

// MARK: - 敵の弾丸
class EnemyBullet: SKSpriteNode {
    enum BulletType {
        case fireball
        case energy
        case shard
        
        var color: SKColor {
            switch self {
            case .fireball: return .orange
            case .energy: return .cyan
            case .shard: return .gray
            }
        }
        
        var size: CGSize {
            switch self {
            case .fireball: return CGSize(width: 12, height: 12)
            case .energy: return CGSize(width: 8, height: 16)
            case .shard: return CGSize(width: 6, height: 6)
            }
        }
        
        var speed: CGFloat {
            switch self {
            case .fireball: return 150
            case .energy: return 200
            case .shard: return 100
            }
        }
    }
    
    private let bulletType: BulletType
    private var direction = CGVector.zero
    
    init(type: BulletType) {
        self.bulletType = type
        
        super.init(texture: nil, color: type.color, size: type.size)
        
        setupBullet()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupBullet() {
        name = "enemyBullet"
        zPosition = GameLayers.enemyProjectiles
        
        setupPhysics(
            category: CollisionCategory.enemyBullet,
            contact: CollisionCategory.player | CollisionCategory.boundary,
            collision: CollisionCategory.none
        )
        
        // 弾の見た目
        switch bulletType {
        case .fireball:
            let fire = SKShapeNode(circleOfRadius: 6)
            fire.fillColor = .orange
            fire.strokeColor = .red
            fire.lineWidth = 1
            addChild(fire)
            
        case .energy:
            let energy = SKSpriteNode(color: .cyan, size: bulletType.size)
            addChild(energy)
            
        case .shard:
            let shard = SKSpriteNode(color: .gray, size: bulletType.size)
            addChild(shard)
        }
        
        // 自動削除
        let removeAction = SKAction.sequence([
            SKAction.wait(forDuration: 5.0),
            SKAction.removeFromParent()
        ])
        run(removeAction, withKey: "autoRemove")
    }
    
    func launch(direction: CGVector) {
        self.direction = direction.normalized
        
        physicsBody?.velocity = CGVector(
            dx: self.direction.dx * bulletType.speed,
            dy: self.direction.dy * bulletType.speed
        )
        
        // 回転エフェクト
        if bulletType == .fireball {
            let rotateAction = SKAction.rotate(byAngle: CGFloat.pi * 2, duration: 1.0)
            let rotateRepeat = SKAction.repeatForever(rotateAction)
            run(rotateRepeat)
        }
    }
    
    func hitPlayer() {
        // プレイヤーにダメージを与えて弾を削除
        removeFromParent()
    }
}
