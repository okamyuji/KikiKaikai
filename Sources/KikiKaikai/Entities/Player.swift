import SpriteKit
import Foundation

class Player: SKSpriteNode {
    // プレイヤー状態
    private var gameManager: GameManager
    private var lastOfudaTime: TimeInterval = 0
    private var lastOharaiTime: TimeInterval = 0
    private var isInvincible: Bool = false
    private var invincibilityTimer: Timer?
    
    // 移動状態
    private var velocity = CGVector.zero
    private var targetVelocity = CGVector.zero
    private let acceleration: CGFloat = 800
    private let deceleration: CGFloat = 600
    
    // アニメーション状態
    private var currentDirection: Direction = .down
    private var isMoving = false
    
    enum Direction: CaseIterable {
        case up, down, left, right, upLeft, upRight, downLeft, downRight
        
        var vector: CGVector {
            switch self {
            case .up: return CGVector(dx: 0, dy: 1)
            case .down: return CGVector(dx: 0, dy: -1)
            case .left: return CGVector(dx: -1, dy: 0)
            case .right: return CGVector(dx: 1, dy: 0)
            case .upLeft: return CGVector(dx: -0.707, dy: 0.707)
            case .upRight: return CGVector(dx: 0.707, dy: 0.707)
            case .downLeft: return CGVector(dx: -0.707, dy: -0.707)
            case .downRight: return CGVector(dx: 0.707, dy: -0.707)
            }
        }
    }
    
    init(gameManager: GameManager) {
        self.gameManager = gameManager
        
        // プレイヤーのスプライトを作成（仮の四角形）
        let texture = SKTexture()
        super.init(texture: texture, color: GameColors.playerWhite, size: GameConstants.playerSize)
        
        setupPlayer()
        setupPhysics()
        setupAnimations()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupPlayer() {
        name = "player"
        zPosition = GameLayers.player
        
        // 初期位置を画面中央下部に設定
        position = CGPoint(
            x: GameConstants.screenWidth / 2,
            y: GameConstants.screenHeight / 4
        )
        
        // 巫女装束をイメージした見た目
        addPlayerVisuals()
    }
    
    private func addPlayerVisuals() {
        // メインボディ（白い着物）
        let body = SKSpriteNode(color: .white, size: CGSize(width: 24, height: 28))
        body.position = CGPoint(x: 0, y: -2)
        body.zPosition = 1
        addChild(body)
        
        // 袴（赤い下半身）
        let hakama = SKSpriteNode(color: GameColors.healthRed, size: CGSize(width: 20, height: 12))
        hakama.position = CGPoint(x: 0, y: -10)
        hakama.zPosition = 2
        addChild(hakama)
        
        // 髪（黒）
        let hair = SKSpriteNode(color: .black, size: CGSize(width: 16, height: 12))
        hair.position = CGPoint(x: 0, y: 8)
        hair.zPosition = 2
        addChild(hair)
        
        // リボン（赤）
        let ribbon = SKSpriteNode(color: GameColors.healthRed, size: CGSize(width: 12, height: 4))
        ribbon.position = CGPoint(x: 0, y: 12)
        ribbon.zPosition = 3
        addChild(ribbon)
    }
    
    private func setupPhysics() {
        setupPhysics(
            category: CollisionCategory.player,
            contact: CollisionCategory.enemy | CollisionCategory.enemyBullet | CollisionCategory.item,
            collision: CollisionCategory.boundary
        )
    }
    
    private func setupAnimations() {
        // アイドルアニメーション
        let idleAction = SKAction.sequence([
            SKAction.scale(to: 1.0, duration: 1.0),
            SKAction.scale(to: 0.98, duration: 1.0)
        ])
        let idleRepeat = SKAction.repeatForever(idleAction)
        run(idleRepeat, withKey: AnimationKeys.playerIdle)
    }
    
    // MARK: - 移動制御
    
    func setMovement(direction: CGVector) {
        targetVelocity = direction * GameConstants.playerSpeed
        isMoving = targetVelocity.length > 0
        
        if isMoving {
            updateDirection(direction)
            startWalkAnimation()
        } else {
            stopWalkAnimation()
        }
    }
    
    private func updateDirection(_ direction: CGVector) {
        // 8方向の移動方向を決定
        let directions: [Direction] = [
            .right, .upRight, .up, .upLeft,
            .left, .downLeft, .down, .downRight
        ]
        
        let angle = atan2(direction.dy, direction.dx).normalizedAngle
        let sectionAngle = 2 * CGFloat.pi / CGFloat(directions.count)
        let section = Int((angle + sectionAngle / 2) / sectionAngle) % directions.count
        
        currentDirection = directions[section]
    }
    
    private func startWalkAnimation() {
        removeAction(forKey: AnimationKeys.playerWalk)
        
        let walkAction = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 2, duration: 0.2),
            SKAction.moveBy(x: 0, y: -2, duration: 0.2)
        ])
        let walkRepeat = SKAction.repeatForever(walkAction)
        run(walkRepeat, withKey: AnimationKeys.playerWalk)
    }
    
    private func stopWalkAnimation() {
        removeAction(forKey: AnimationKeys.playerWalk)
    }
    
    func update(_ deltaTime: TimeInterval) {
        updateMovement(deltaTime)
        constrainToScreen()
    }
    
    private func updateMovement(_ deltaTime: TimeInterval) {
        // 滑らかな加速・減速
        let deltaVelocity = targetVelocity - velocity
        let accelerationRate = isMoving ? acceleration : deceleration
        let maxDelta = accelerationRate * CGFloat(deltaTime)
        
        if deltaVelocity.length <= maxDelta {
            velocity = targetVelocity
        } else {
            velocity = velocity + deltaVelocity.normalized * maxDelta
        }
        
        // 位置更新
        position = position + CGPoint(x: velocity.dx * CGFloat(deltaTime), y: velocity.dy * CGFloat(deltaTime))
    }
    
    private func constrainToScreen() {
        let margin: CGFloat = size.width / 2
        position = position.clamped(to: CGRect(
            x: margin,
            y: margin,
            width: GameConstants.screenWidth - margin * 2,
            height: GameConstants.screenHeight - margin * 2
        ))
    }
    
    // MARK: - 攻撃システム
    
    func shootOfuda(currentTime: TimeInterval) -> Ofuda? {
        guard currentTime - lastOfudaTime >= GameConstants.ofudaCooldown else { return nil }
        
        // 現在画面内のお札数をチェック
        guard let scene = scene,
              scene.children.filter({ $0 is Ofuda }).count < GameConstants.ofudaMaxCount else { return nil }
        
        lastOfudaTime = currentTime
        
        // お札作成
        let ofuda = Ofuda(gameManager: gameManager)
        
        // 発射方向（現在の移動方向、または上方向）
        let shootDirection = isMoving ? currentDirection.vector : CGVector(dx: 0, dy: 1)
        ofuda.launch(from: position, direction: shootDirection)
        
        return ofuda
    }
    
    func useOharaiStick(currentTime: TimeInterval) -> OharaiStick? {
        guard currentTime - lastOharaiTime >= GameConstants.oharaiCooldown else { return nil }
        
        lastOharaiTime = currentTime
        
        // 御祓い棒作成
        let oharai = OharaiStick(gameManager: gameManager)
        oharai.activate(at: position, direction: currentDirection.vector)
        
        return oharai
    }
    
    func useCrystalBall() -> Bool {
        return gameManager.useCrystalBall()
    }
    
    // MARK: - ダメージ・回復システム
    
    func takeDamage(_ damage: Int = 1) {
        guard !isInvincible else { return }
        
        gameManager.takeDamage(damage)
        startInvincibility()
        playDamageAnimation()
        
        // ゲームオーバーチェック
        if gameManager.currentHealth <= 0 {
            playDeathAnimation()
        }
    }
    
    private func startInvincibility() {
        isInvincible = true
        
        // 点滅エフェクト
        let blinkAction = SKAction.blink(times: 6, duration: GameConstants.playerInvincibilityDuration)
        run(blinkAction, withKey: AnimationKeys.playerDamage)
        
        // 無敵時間終了
        invincibilityTimer = Timer.scheduledTimer(withTimeInterval: GameConstants.playerInvincibilityDuration, repeats: false) { [weak self] _ in
            self?.endInvincibility()
        }
    }
    
    private func endInvincibility() {
        isInvincible = false
        removeAction(forKey: AnimationKeys.playerDamage)
        alpha = 1.0
        invincibilityTimer?.invalidate()
        invincibilityTimer = nil
    }
    
    private func playDamageAnimation() {
        let damageAction = SKAction.sequence([
            SKAction.shake(intensity: 5, duration: 0.2),
            SKAction.moveBy(x: 0, y: 0, duration: 0) // 位置リセット
        ])
        run(damageAction)
    }
    
    private func playDeathAnimation() {
        removeAllActions()
        
        let deathAction = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.5, duration: 0.5),
                SKAction.fadeOut(withDuration: 0.5)
            ]),
            SKAction.run { [weak self] in
                self?.gameManager.gameOver()
            }
        ])
        run(deathAction)
    }
    
    // MARK: - アイテム取得
    
    func collectItem(_ item: Item) {
        gameManager.collectItem(item.itemType)
        
        // アイテム取得エフェクト
        let collectEffect = SKSpriteNode(color: .yellow, size: CGSize(width: 32, height: 32))
        collectEffect.position = item.position
        collectEffect.zPosition = GameLayers.effects
        scene?.addChild(collectEffect)
        
        let effectAction = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 2.0, duration: 0.3),
                SKAction.fadeOut(withDuration: 0.3)
            ]),
            SKAction.removeFromParent()
        ])
        collectEffect.run(effectAction)
    }
    
    // MARK: - ユーティリティ
    
    var isAlive: Bool {
        return gameManager.currentHealth > 0
    }
    
    func reset() {
        position = CGPoint(x: GameConstants.screenWidth / 2, y: GameConstants.screenHeight / 4)
        velocity = CGVector.zero
        targetVelocity = CGVector.zero
        endInvincibility()
        alpha = 1.0
        removeAllActions()
        setupAnimations()
    }
}

// MARK: - お札クラス
class Ofuda: SKSpriteNode {
    private let gameManager: GameManager
    private var direction = CGVector.zero
    private let projectileSpeed: CGFloat
    private let damage: Int
    private let canPierce: Bool
    private var pierceCount = 0
    private let maxPierce = 3
    
    init(gameManager: GameManager) {
        self.gameManager = gameManager
        self.projectileSpeed = gameManager.getOfudaSpeed()
        self.damage = gameManager.getOfudaDamage()
        self.canPierce = gameManager.getOfudaPierce()
        
        super.init(texture: nil, color: GameColors.ofudaYellow, size: GameConstants.ofudaSize)
        
        setupOfuda()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupOfuda() {
        name = "ofuda"
        zPosition = GameLayers.playerProjectiles
        
        setupPhysics(
            category: CollisionCategory.ofuda,
            contact: CollisionCategory.enemy | CollisionCategory.boundary,
            collision: CollisionCategory.none
        )
        
        // お札の見た目（縦長の黄色い矩形）
        let paper = SKSpriteNode(color: .white, size: CGSize(width: 12, height: 20))
        paper.zPosition = 1
        addChild(paper)
        
        let text = SKSpriteNode(color: .black, size: CGSize(width: 8, height: 12))
        text.zPosition = 2
        addChild(text)
        
        // 回転アニメーション
        let rotateAction = SKAction.rotate(byAngle: CGFloat.pi * 2, duration: 1.0)
        let rotateRepeat = SKAction.repeatForever(rotateAction)
        run(rotateRepeat, withKey: AnimationKeys.ofudaFly)
    }
    
    func launch(from startPosition: CGPoint, direction: CGVector) {
        position = startPosition
        self.direction = direction.normalized
        
        // 物理的な移動
        physicsBody?.velocity = CGVector(
            dx: self.direction.dx * projectileSpeed,
            dy: self.direction.dy * projectileSpeed
        )
        
        // 一定時間後に自動削除
        let removeAction = SKAction.sequence([
            SKAction.wait(forDuration: GameConstants.ofudaLifetime),
            SKAction.removeFromParent()
        ])
        run(removeAction, withKey: "autoRemove")
    }
    
    func hitEnemy(_ enemy: Enemy) {
        // ダメージを与える
        enemy.takeDamage(damage)
        
        // エフェクト
        createHitEffect()
        
        // 貫通チェック
        if canPierce && pierceCount < maxPierce {
            pierceCount += 1
            // 貫通時のエフェクト
            flash()
        } else {
            // 破壊
            removeFromParent()
        }
    }
    
    private func createHitEffect() {
        let effect = SKSpriteNode(color: .yellow, size: CGSize(width: 16, height: 16))
        effect.position = position
        effect.zPosition = GameLayers.effects
        scene?.addChild(effect)
        
        let effectAction = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 2.0, duration: 0.2),
                SKAction.fadeOut(withDuration: 0.2)
            ]),
            SKAction.removeFromParent()
        ])
        effect.run(effectAction)
    }
    
    private func flash() {
        let flashAction = SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.1),
            SKAction.fadeIn(withDuration: 0.1)
        ])
        run(flashAction)
    }
}

// MARK: - 御祓い棒クラス
class OharaiStick: SKSpriteNode {
    private let gameManager: GameManager
    private let damage = 2 // 御祓い棒はお札より威力が高い
    
    init(gameManager: GameManager) {
        self.gameManager = gameManager
        
        super.init(texture: nil, color: GameColors.oharaiPurple, size: CGSize(width: GameConstants.oharaiRange, height: GameConstants.oharaiRange))
        
        setupOharai()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupOharai() {
        name = "oharai"
        zPosition = GameLayers.playerProjectiles
        alpha = 0.6
        
        setupPhysics(
            category: CollisionCategory.oharai,
            contact: CollisionCategory.enemy,
            collision: CollisionCategory.none
        )
        
        // 円形の範囲攻撃エフェクト
        let circle = SKShapeNode(circleOfRadius: GameConstants.oharaiRange / 2)
        circle.strokeColor = GameColors.oharaiPurple
        circle.lineWidth = 3
        circle.fillColor = GameColors.oharaiPurple.withAlphaComponent(0.3)
        addChild(circle)
    }
    
    func activate(at position: CGPoint, direction: CGVector) {
        self.position = position
        
        let activateAction = SKAction.sequence([
            SKAction.scale(to: 1.0, duration: 0.1),
            SKAction.wait(forDuration: GameConstants.oharaiDuration - 0.2),
            SKAction.group([
                SKAction.scale(to: 1.2, duration: 0.1),
                SKAction.fadeOut(withDuration: 0.1)
            ]),
            SKAction.removeFromParent()
        ])
        
        // 初期スケールを0.1に設定
        setScale(0.1)
        
        run(activateAction)
        
        // 範囲内の敵にダメージ
        dealDamageToEnemiesInRange()
    }
    
    private func dealDamageToEnemiesInRange() {
        guard let scene = scene else { return }
        
        let enemies = scene.children.compactMap { $0 as? Enemy }
        for enemy in enemies {
            let distance = position.distance(to: enemy.position)
            if distance <= GameConstants.oharaiRange / 2 {
                enemy.takeDamage(damage)
                
                // 敵をノックバック
                let knockbackDirection = position.direction(to: enemy.position)
                let knockback = SKAction.moveBy(
                    x: knockbackDirection.dx * 30,
                    y: knockbackDirection.dy * 30,
                    duration: 0.2
                )
                enemy.run(knockback)
            }
        }
    }
}
