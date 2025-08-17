import Foundation
import SpriteKit

// MARK: - ゲーム設定定数
struct GameConstants {
    // 画面サイズ
    static let screenWidth: CGFloat = 1024
    static let screenHeight: CGFloat = 768
    
    // フレームレート
    static let targetFPS: Double = 60.0
    static let frameInterval: TimeInterval = 1.0 / targetFPS
    
    // プレイヤー設定
    static let playerSpeed: CGFloat = 200.0
    static let playerSize: CGSize = CGSize(width: 32, height: 32)
    static let playerMaxHealth: Int = 3
    static let playerInvincibilityDuration: TimeInterval = 2.0
    
    // お札設定
    static let ofudaSpeed: CGFloat = 300.0
    static let ofudaMaxCount: Int = 4
    static let ofudaSize: CGSize = CGSize(width: 16, height: 24)
    static let ofudaCooldown: TimeInterval = 0.15
    static let ofudaLifetime: TimeInterval = 2.0
    
    // 御祓い棒設定
    static let oharaiRange: CGFloat = 48.0
    static let oharaiDuration: TimeInterval = 0.3
    static let oharaiCooldown: TimeInterval = 0.5
    
    // 水晶玉設定
    static let crystalBallDuration: TimeInterval = 6.0
    static let crystalBallWarningDuration: TimeInterval = 3.0
    
    // 敵設定
    static let enemyBaseSpeed: CGFloat = 80.0
    static let enemySpawnInterval: TimeInterval = 2.0
    static let enemyMaxCount: Int = 20
    
    // アイテム設定
    static let itemLifetime: TimeInterval = 10.0
    static let itemSize: CGSize = CGSize(width: 24, height: 24)
    
    // エフェクト設定
    static let explosionDuration: TimeInterval = 0.5
    static let sparkleLifetime: TimeInterval = 1.0
}

// MARK: - カラー定数
struct GameColors {
    // UI色
    static let healthRed = SKColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)
    static let scoreWhite = SKColor.white
    static let menuBackground = SKColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 1.0)
    
    // ゲーム内色
    static let playerWhite = SKColor.white
    static let ofudaYellow = SKColor(red: 1.0, green: 0.9, blue: 0.3, alpha: 1.0)
    static let oharaiPurple = SKColor(red: 0.6, green: 0.3, blue: 0.9, alpha: 1.0)
    
    // パワーアップ色
    static let powerOrange = SKColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 1.0)  // 橙色の力玉
    static let powerBlue = SKColor(red: 0.2, green: 0.5, blue: 1.0, alpha: 1.0)    // 青色の力玉
    static let powerGreen = SKColor(red: 0.2, green: 0.8, blue: 0.3, alpha: 1.0)   // 緑色の力玉
    
    // 敵色
    static let enemyRed = SKColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0)
    static let enemyPurple = SKColor(red: 0.5, green: 0.2, blue: 0.8, alpha: 1.0)
    static let enemyGreen = SKColor(red: 0.3, green: 0.7, blue: 0.3, alpha: 1.0)
    static let enemyBlue = SKColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0)
}

// MARK: - レイヤー定数（Z位置）
struct GameLayers {
    static let background: CGFloat = 0
    static let backgroundDecoration: CGFloat = 10
    static let items: CGFloat = 20
    static let enemies: CGFloat = 30
    static let enemyProjectiles: CGFloat = 35
    static let player: CGFloat = 40
    static let playerProjectiles: CGFloat = 45
    static let effects: CGFloat = 50
    static let ui: CGFloat = 100
}

// MARK: - 衝突カテゴリ
struct CollisionCategory {
    static let none: UInt32 = 0
    static let player: UInt32 = 1 << 0      // 1
    static let enemy: UInt32 = 1 << 1       // 2
    static let ofuda: UInt32 = 1 << 2       // 4
    static let enemyBullet: UInt32 = 1 << 3 // 8
    static let item: UInt32 = 1 << 4        // 16
    static let oharai: UInt32 = 1 << 5      // 32
    static let boundary: UInt32 = 1 << 6    // 64
}

// MARK: - アニメーション定数
struct AnimationKeys {
    static let playerWalk = "playerWalk"
    static let playerIdle = "playerIdle"
    static let playerDamage = "playerDamage"
    static let enemyMove = "enemyMove"
    static let enemyAttack = "enemyAttack"
    static let itemSparkle = "itemSparkle"
    static let explosion = "explosion"
    static let ofudaFly = "ofudaFly"
}

// MARK: - サウンド定数
struct SoundNames {
    // BGM
    static let menuBGM = "menu_bgm"
    static let stage1BGM = "stage1_bgm"
    static let stage2BGM = "stage2_bgm"
    static let bossBGM = "boss_bgm"
    
    // 効果音
    static let ofudaShoot = "ofuda_shoot"
    static let oharaiSwing = "oharai_swing"
    static let enemyHit = "enemy_hit"
    static let enemyDestroy = "enemy_destroy"
    static let playerDamage = "player_damage"
    static let itemGet = "item_get"
    static let powerUp = "power_up"
    static let crystalBall = "crystal_ball"
    static let stageCleared = "stage_cleared"
    static let gameOver = "game_over"
}

// MARK: - ゲーム設定
struct GameSettings {
    // 難易度設定
    enum Difficulty {
        case easy, normal, hard
        
        var enemySpeedMultiplier: CGFloat {
            switch self {
            case .easy: return 0.8
            case .normal: return 1.0
            case .hard: return 1.3
            }
        }
        
        var enemyHealthMultiplier: Int {
            switch self {
            case .easy: return 1
            case .normal: return 1
            case .hard: return 2
            }
        }
        
        var itemDropRate: CGFloat {
            switch self {
            case .easy: return 0.4
            case .normal: return 0.25
            case .hard: return 0.15
            }
        }
    }
    
    static var currentDifficulty: Difficulty = .normal
    static var soundEnabled: Bool = true
    static var musicEnabled: Bool = true
    static var showDebugInfo: Bool = false
}

// MARK: - ユーティリティ関数
extension GameConstants {
    // 画面境界チェック
    static func isWithinBounds(_ position: CGPoint, margin: CGFloat = 0) -> Bool {
        return position.x >= -margin &&
               position.x <= screenWidth + margin &&
               position.y >= -margin &&
               position.y <= screenHeight + margin
    }
    
    // 距離計算
    static func distance(from point1: CGPoint, to point2: CGPoint) -> CGFloat {
        let dx = point2.x - point1.x
        let dy = point2.y - point1.y
        return sqrt(dx * dx + dy * dy)
    }
    
    // ランダム位置生成
    static func randomPosition(inRect rect: CGRect) -> CGPoint {
        return CGPoint(
            x: rect.minX + CGFloat.random(in: 0...rect.width),
            y: rect.minY + CGFloat.random(in: 0...rect.height)
        )
    }
    
    // ベクトル正規化
    static func normalizeVector(_ vector: CGVector) -> CGVector {
        let length = sqrt(vector.dx * vector.dx + vector.dy * vector.dy)
        guard length > 0 else { return CGVector.zero }
        return CGVector(dx: vector.dx / length, dy: vector.dy / length)
    }
}
