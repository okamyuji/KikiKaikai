import SpriteKit
import Foundation

class CollisionSystem: NSObject, SKPhysicsContactDelegate {
    weak var scene: GameScene?
    private var gameManager: GameManager
    
    init(scene: GameScene, gameManager: GameManager) {
        self.scene = scene
        self.gameManager = gameManager
        super.init()
        
        // 物理世界の衝突デリゲートを設定
        scene.physicsWorld.contactDelegate = self
        scene.physicsWorld.gravity = CGVector.zero
    }
    
    // MARK: - SKPhysicsContactDelegate
    
    func didBegin(_ contact: SKPhysicsContact) {
        let contactA = contact.bodyA
        let contactB = contact.bodyB
        
        // 衝突対象を特定
        let collision = identifyCollision(bodyA: contactA, bodyB: contactB)
        
        switch collision {
        case .playerEnemy(let player, let enemy):
            handlePlayerEnemyCollision(player: player, enemy: enemy)
            
        case .playerEnemyBullet(let player, let bullet):
            handlePlayerEnemyBulletCollision(player: player, bullet: bullet)
            
        case .playerItem(let player, let item):
            handlePlayerItemCollision(player: player, item: item)
            
        case .ofudaEnemy(let ofuda, let enemy):
            handleOfudaEnemyCollision(ofuda: ofuda, enemy: enemy)
            
        case .oharaiEnemy(let oharai, let enemy):
            handleOharaiEnemyCollision(oharai: oharai, enemy: enemy)
            
        case .projectileBoundary(let projectile):
            handleProjectileBoundaryCollision(projectile: projectile)
            
        case .entityBoundary(let entity):
            handleEntityBoundaryCollision(entity: entity)
            
        case .unknown:
            // 未知の衝突は無視
            break
        }
    }
    
    // MARK: - 衝突タイプの識別
    
    enum CollisionType {
        case playerEnemy(Player, BaseEnemy)
        case playerEnemyBullet(Player, EnemyBullet)
        case playerItem(Player, Item)
        case ofudaEnemy(Ofuda, BaseEnemy)
        case oharaiEnemy(OharaiStick, BaseEnemy)
        case projectileBoundary(SKNode)
        case entityBoundary(SKNode)
        case unknown
    }
    
    private func identifyCollision(bodyA: SKPhysicsBody, bodyB: SKPhysicsBody) -> CollisionType {
        guard let nodeA = bodyA.node, let nodeB = bodyB.node else {
            return .unknown
        }
        
        let categoryA = bodyA.categoryBitMask
        let categoryB = bodyB.categoryBitMask
        
        // プレイヤーと敵の衝突
        if isCollision(categoryA, categoryB, CollisionCategory.player, CollisionCategory.enemy) {
            if let player = getNode(nodeA, nodeB, Player.self),
               let enemy = getNode(nodeA, nodeB, BaseEnemy.self) {
                return .playerEnemy(player, enemy)
            }
        }
        
        // プレイヤーと敵弾の衝突
        if isCollision(categoryA, categoryB, CollisionCategory.player, CollisionCategory.enemyBullet) {
            if let player = getNode(nodeA, nodeB, Player.self),
               let bullet = getNode(nodeA, nodeB, EnemyBullet.self) {
                return .playerEnemyBullet(player, bullet)
            }
        }
        
        // プレイヤーとアイテムの衝突
        if isCollision(categoryA, categoryB, CollisionCategory.player, CollisionCategory.item) {
            if let player = getNode(nodeA, nodeB, Player.self),
               let item = getNode(nodeA, nodeB, Item.self) {
                return .playerItem(player, item)
            }
        }
        
        // お札と敵の衝突
        if isCollision(categoryA, categoryB, CollisionCategory.ofuda, CollisionCategory.enemy) {
            if let ofuda = getNode(nodeA, nodeB, Ofuda.self),
               let enemy = getNode(nodeA, nodeB, BaseEnemy.self) {
                return .ofudaEnemy(ofuda, enemy)
            }
        }
        
        // 御祓い棒と敵の衝突
        if isCollision(categoryA, categoryB, CollisionCategory.oharai, CollisionCategory.enemy) {
            if let oharai = getNode(nodeA, nodeB, OharaiStick.self),
               let enemy = getNode(nodeA, nodeB, BaseEnemy.self) {
                return .oharaiEnemy(oharai, enemy)
            }
        }
        
        // 弾丸と境界の衝突
        if isBoundaryCollision(categoryA, categoryB) {
            if isProjectile(categoryA) {
                return .projectileBoundary(nodeA)
            } else if isProjectile(categoryB) {
                return .projectileBoundary(nodeB)
            }
        }
        
        // エンティティと境界の衝突
        if isBoundaryCollision(categoryA, categoryB) {
            if categoryA == CollisionCategory.boundary {
                return .entityBoundary(nodeB)
            } else {
                return .entityBoundary(nodeA)
            }
        }
        
        return .unknown
    }
    
    // MARK: - ヘルパーメソッド
    
    private func isCollision(_ catA: UInt32, _ catB: UInt32, _ cat1: UInt32, _ cat2: UInt32) -> Bool {
        return (catA == cat1 && catB == cat2) || (catA == cat2 && catB == cat1)
    }
    
    private func isBoundaryCollision(_ catA: UInt32, _ catB: UInt32) -> Bool {
        return catA == CollisionCategory.boundary || catB == CollisionCategory.boundary
    }
    
    private func isProjectile(_ category: UInt32) -> Bool {
        return category == CollisionCategory.ofuda || 
               category == CollisionCategory.enemyBullet ||
               category == CollisionCategory.oharai
    }
    
    private func getNode<T: SKNode>(_ nodeA: SKNode, _ nodeB: SKNode, _ type: T.Type) -> T? {
        if let node = nodeA as? T {
            return node
        } else if let node = nodeB as? T {
            return node
        }
        return nil
    }
    
    // MARK: - 衝突処理メソッド
    
    private func handlePlayerEnemyCollision(player: Player, enemy: BaseEnemy) {
        // プレイヤーがダメージを受ける
        player.takeDamage()
        
        // 衝突エフェクト
        createCollisionEffect(at: player.position, type: .playerDamage)
        
        // 敵の反応（特定の敵タイプの場合）
        if enemy is Rumuru {
            // 留無留は取り憑く
            return
        }
        
        // 通常の敵は接触時にノックバック
        let knockbackDirection = enemy.position.direction(to: player.position)
        let knockbackAction = SKAction.moveBy(
            x: knockbackDirection.dx * 20,
            y: knockbackDirection.dy * 20,
            duration: 0.2
        )
        enemy.run(knockbackAction)
    }
    
    private func handlePlayerEnemyBulletCollision(player: Player, bullet: EnemyBullet) {
        // プレイヤーがダメージを受ける
        player.takeDamage()
        
        // 弾を削除
        bullet.hitPlayer()
        
        // 衝突エフェクト
        createCollisionEffect(at: bullet.position, type: .bulletHit)
    }
    
    private func handlePlayerItemCollision(player: Player, item: Item) {
        // アイテムを取得
        player.collectItem(item)
        
        // アイテムを削除
        item.collect()
        
        // 取得エフェクト
        createCollisionEffect(at: item.position, type: .itemCollect)
    }
    
    private func handleOfudaEnemyCollision(ofuda: Ofuda, enemy: BaseEnemy) {
        // 敵にダメージを与える
        ofuda.hitEnemy(enemy)
        
        // 衝突エフェクト
        createCollisionEffect(at: ofuda.position, type: .ofudaHit)
    }
    
    private func handleOharaiEnemyCollision(oharai: OharaiStick, enemy: BaseEnemy) {
        // 御祓い棒の範囲攻撃は別途処理されるので、ここでは特別な処理なし
        
        // 特殊な敵（留無留）の場合は弾き飛ばし
        if let rumuru = enemy as? Rumuru {
            rumuru.detachFromPlayer()
        }
    }
    
    private func handleProjectileBoundaryCollision(projectile: SKNode) {
        // 弾丸が画面外に出た場合は削除
        projectile.removeFromParent()
    }
    
    private func handleEntityBoundaryCollision(entity: SKNode) {
        // エンティティが境界に触れた場合の処理
        if let enemy = entity as? BaseEnemy {
            // 敵が画面外に出そうになったら反転
            if entity.position.x <= 0 || entity.position.x >= GameConstants.screenWidth {
                enemy.velocity.dx *= -1
            }
            if entity.position.y <= 0 || entity.position.y >= GameConstants.screenHeight {
                enemy.velocity.dy *= -1
            }
        }
    }
    
    // MARK: - エフェクト生成
    
    enum EffectType {
        case playerDamage
        case bulletHit
        case itemCollect
        case ofudaHit
        case explosion
    }
    
    private func createCollisionEffect(at position: CGPoint, type: EffectType) {
        guard let scene = scene else { return }
        
        let effect: SKNode
        
        switch type {
        case .playerDamage:
            effect = createPlayerDamageEffect()
        case .bulletHit:
            effect = createBulletHitEffect()
        case .itemCollect:
            effect = createItemCollectEffect()
        case .ofudaHit:
            effect = createOfudaHitEffect()
        case .explosion:
            effect = createExplosionEffect()
        }
        
        effect.position = position
        effect.zPosition = GameLayers.effects
        scene.addChild(effect)
    }
    
    private func createPlayerDamageEffect() -> SKNode {
        let effect = SKNode()
        
        // 赤い衝撃波
        for i in 0..<8 {
            let spark = SKSpriteNode(color: .red, size: CGSize(width: 4, height: 12))
            spark.zRotation = CGFloat(i) * (CGFloat.pi / 4)
            effect.addChild(spark)
            
            let sparkAction = SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: 0, y: 20, duration: 0.3),
                    SKAction.fadeOut(withDuration: 0.3)
                ]),
                SKAction.removeFromParent()
            ])
            spark.run(sparkAction)
        }
        
        // 全体削除
        let removeAction = SKAction.sequence([
            SKAction.wait(forDuration: 0.4),
            SKAction.removeFromParent()
        ])
        effect.run(removeAction)
        
        return effect
    }
    
    private func createBulletHitEffect() -> SKNode {
        let effect = SKSpriteNode(color: .orange, size: CGSize(width: 24, height: 24))
        
        let effectAction = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.5, duration: 0.2),
                SKAction.fadeOut(withDuration: 0.2)
            ]),
            SKAction.removeFromParent()
        ])
        effect.run(effectAction)
        
        return effect
    }
    
    private func createItemCollectEffect() -> SKNode {
        let effect = SKNode()
        
        // 黄色い光の粒子
        for _ in 0..<12 {
            let particle = SKSpriteNode(color: .yellow, size: CGSize(width: 3, height: 3))
            let angle = CGFloat.random(in: 0...(2 * CGFloat.pi))
            let distance: CGFloat = 40
            
            particle.position = CGPoint(
                x: cos(angle) * distance,
                y: sin(angle) * distance
            )
            effect.addChild(particle)
            
            let particleAction = SKAction.sequence([
                SKAction.group([
                    SKAction.move(to: CGPoint.zero, duration: 0.4),
                    SKAction.fadeOut(withDuration: 0.4)
                ]),
                SKAction.removeFromParent()
            ])
            particle.run(particleAction)
        }
        
        let removeAction = SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.removeFromParent()
        ])
        effect.run(removeAction)
        
        return effect
    }
    
    private func createOfudaHitEffect() -> SKNode {
        let effect = SKSpriteNode(color: .yellow, size: CGSize(width: 16, height: 16))
        
        let effectAction = SKAction.sequence([
            SKAction.scale(to: 2.0, duration: 0.1),
            SKAction.group([
                SKAction.scale(to: 0.5, duration: 0.2),
                SKAction.fadeOut(withDuration: 0.2)
            ]),
            SKAction.removeFromParent()
        ])
        effect.run(effectAction)
        
        return effect
    }
    
    private func createExplosionEffect() -> SKNode {
        let effect = SKNode()
        
        // 中心の爆発
        let center = SKSpriteNode(color: .orange, size: CGSize(width: 32, height: 32))
        effect.addChild(center)
        
        let centerAction = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 2.0, duration: 0.3),
                SKAction.fadeOut(withDuration: 0.3)
            ]),
            SKAction.removeFromParent()
        ])
        center.run(centerAction)
        
        // 放射状の火花
        for i in 0..<16 {
            let spark = SKSpriteNode(color: .red, size: CGSize(width: 3, height: 8))
            let angle = CGFloat(i) * (CGFloat.pi / 8)
            spark.zRotation = angle
            effect.addChild(spark)
            
            let sparkAction = SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(
                        x: cos(angle) * 50,
                        y: sin(angle) * 50,
                        duration: 0.4
                    ),
                    SKAction.fadeOut(withDuration: 0.4)
                ]),
                SKAction.removeFromParent()
            ])
            spark.run(sparkAction)
        }
        
        let removeAction = SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.removeFromParent()
        ])
        effect.run(removeAction)
        
        return effect
    }
    
    // MARK: - デバッグ機能
    
    #if DEBUG
    func showCollisionBoxes(_ show: Bool) {
        guard let scene = scene else { return }
        
        if show {
            // すべてのノードの当たり判定を可視化
            scene.enumerateChildNodes(withName: "//*") { node, _ in
                if node.physicsBody != nil {
                    node.showBoundingBox()
                }
            }
        } else {
            // 当たり判定の可視化を非表示
            scene.enumerateChildNodes(withName: "//*") { node, _ in
                node.hideBoundingBox()
            }
        }
    }
    
    func logCollision(_ contact: SKPhysicsContact) {
        let categoryA = contact.bodyA.categoryBitMask
        let categoryB = contact.bodyB.categoryBitMask
        let nodeA = contact.bodyA.node?.name ?? "unknown"
        let nodeB = contact.bodyB.node?.name ?? "unknown"
        
        print("衝突検出: \(nodeA) (category: \(categoryA)) <-> \(nodeB) (category: \(categoryB))")
    }
    #endif
}

// MARK: - 衝突検出ユーティリティ
extension CollisionSystem {
    
    // 円形の衝突判定
    static func circleCollision(pos1: CGPoint, radius1: CGFloat, pos2: CGPoint, radius2: CGFloat) -> Bool {
        let distance = pos1.distance(to: pos2)
        return distance <= (radius1 + radius2)
    }
    
    // 矩形の衝突判定
    static func rectCollision(rect1: CGRect, rect2: CGRect) -> Bool {
        return rect1.intersects(rect2)
    }
    
    // 点と円の衝突判定
    static func pointInCircle(point: CGPoint, center: CGPoint, radius: CGFloat) -> Bool {
        return point.distance(to: center) <= radius
    }
    
    // 点と矩形の衝突判定
    static func pointInRect(point: CGPoint, rect: CGRect) -> Bool {
        return rect.contains(point)
    }
}
