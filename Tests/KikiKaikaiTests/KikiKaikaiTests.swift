import XCTest
@testable import KikiKaikai

final class KikiKaikaiTests: XCTestCase {
    
    var gameManager: GameManager!
    var scoreSystem: ScoreSystem!
    
    override func setUp() {
        super.setUp()
        gameManager = GameManager()
        scoreSystem = ScoreSystem.shared
        scoreSystem.resetGame()
    }
    
    override func tearDown() {
        gameManager = nil
        super.tearDown()
    }
    
    // MARK: - GameManager Tests
    
    func testGameManagerInitialization() {
        XCTAssertEqual(gameManager.currentStage, 1)
        XCTAssertEqual(gameManager.score, 0)
        XCTAssertEqual(gameManager.currentHealth, gameManager.maxHealth)
        XCTAssertEqual(gameManager.crystalBalls, 2)
        XCTAssertEqual(gameManager.gameState, .menu)
    }
    
    func testStartNewGame() {
        gameManager.score = 1000
        gameManager.currentHealth = 1
        gameManager.startNewGame()
        
        XCTAssertEqual(gameManager.gameState, .playing)
        XCTAssertEqual(gameManager.score, 0)
        XCTAssertEqual(gameManager.currentHealth, gameManager.maxHealth)
        XCTAssertEqual(gameManager.currentStage, 1)
    }
    
    func testTakeDamage() {
        let initialHealth = gameManager.currentHealth
        gameManager.takeDamage(1)
        
        XCTAssertEqual(gameManager.currentHealth, initialHealth - 1)
    }
    
    func testGameOverWhenHealthZero() {
        gameManager.startNewGame()
        
        // 体力を0にする
        for _ in 0..<gameManager.maxHealth {
            gameManager.takeDamage(1)
        }
        
        XCTAssertEqual(gameManager.gameState, .gameOver)
        XCTAssertEqual(gameManager.currentHealth, 0)
    }
    
    func testHeal() {
        gameManager.takeDamage(2)
        let damagedHealth = gameManager.currentHealth
        
        gameManager.heal(1)
        XCTAssertEqual(gameManager.currentHealth, damagedHealth + 1)
        
        // 最大体力を超えないことを確認
        gameManager.heal(10)
        XCTAssertEqual(gameManager.currentHealth, gameManager.maxHealth)
    }
    
    func testCrystalBallUsage() {
        let initialCount = gameManager.crystalBalls
        
        let success = gameManager.useCrystalBall()
        XCTAssertTrue(success)
        XCTAssertEqual(gameManager.crystalBalls, initialCount - 1)
        
        // 0個の時は使用できない
        gameManager.crystalBalls = 0
        let failedAttempt = gameManager.useCrystalBall()
        XCTAssertFalse(failedAttempt)
    }
    
    func testPowerLevels() {
        XCTAssertEqual(gameManager.getPowerLevel(.damage), 0)
        XCTAssertEqual(gameManager.getPowerLevel(.speed), 0)
        XCTAssertEqual(gameManager.getPowerLevel(.pierce), 0)
        
        // パワーアップアイテム取得
        gameManager.collectItem(.powerUp(.damage))
        XCTAssertEqual(gameManager.getPowerLevel(.damage), 1)
        
        gameManager.collectItem(.powerUp(.speed))
        XCTAssertEqual(gameManager.getPowerLevel(.speed), 1)
        
        gameManager.collectItem(.powerUp(.pierce))
        XCTAssertEqual(gameManager.getPowerLevel(.pierce), 1)
    }
    
    func testOfudaStats() {
        // 初期値
        XCTAssertEqual(gameManager.getOfudaDamage(), 1)
        XCTAssertEqual(gameManager.getOfudaSpeed(), 300.0)
        XCTAssertFalse(gameManager.getOfudaPierce())
        
        // パワーアップ後
        gameManager.collectItem(.powerUp(.damage))
        XCTAssertEqual(gameManager.getOfudaDamage(), 2)
        
        gameManager.collectItem(.powerUp(.speed))
        XCTAssertEqual(gameManager.getOfudaSpeed(), 400.0)
        
        gameManager.collectItem(.powerUp(.pierce))
        gameManager.collectItem(.powerUp(.pierce))
        XCTAssertTrue(gameManager.getOfudaPierce())
    }
    
    // MARK: - ScoreSystem Tests
    
    func testScoreSystemInitialization() {
        XCTAssertEqual(scoreSystem.getCurrentScore(), 0)
        XCTAssertEqual(scoreSystem.getCurrentCombo(), 0)
        XCTAssertEqual(scoreSystem.getMaxCombo(), 0)
    }
    
    func testAddScore() {
        scoreSystem.addScore(100, reason: "Test")
        XCTAssertEqual(scoreSystem.getCurrentScore(), 100)
    }
    
    func testComboSystem() {
        // 連続撃破でコンボ増加
        let enemy = Hitodama(gameManager: gameManager)
        
        scoreSystem.addEnemyKillScore(enemy, at: CGPoint.zero)
        XCTAssertEqual(scoreSystem.getCurrentCombo(), 1)
        
        scoreSystem.addEnemyKillScore(enemy, at: CGPoint.zero)
        XCTAssertEqual(scoreSystem.getCurrentCombo(), 2)
        
        XCTAssertEqual(scoreSystem.getMaxCombo(), 2)
    }
    
    func testComboReset() {
        let enemy = Hitodama(gameManager: gameManager)
        scoreSystem.addEnemyKillScore(enemy, at: CGPoint.zero)
        
        scoreSystem.resetCombo()
        XCTAssertEqual(scoreSystem.getCurrentCombo(), 0)
    }
    
    func testItemCollectionScore() {
        let healthItem = Item(type: .health)
        let coinItem = Item(type: .coin)
        
        scoreSystem.addItemCollectionScore(healthItem, at: CGPoint.zero)
        scoreSystem.addItemCollectionScore(coinItem, at: CGPoint.zero)
        
        XCTAssertEqual(scoreSystem.getCurrentScore(), 150) // 100 + 50
    }
    
    func testGameStatistics() {
        var stats = scoreSystem.getGameStatistics()
        XCTAssertEqual(stats.enemiesKilled, 0)
        XCTAssertEqual(stats.itemsCollected, 0)
        XCTAssertEqual(stats.damagesTaken, 0)
        
        // 統計更新
        scoreSystem.recordDamageTaken()
        scoreSystem.recordOfudaFired()
        scoreSystem.recordOharaiUsed()
        scoreSystem.recordCrystalBallUsed()
        
        stats = scoreSystem.getGameStatistics()
        XCTAssertEqual(stats.damagesTaken, 1)
        XCTAssertEqual(stats.ofudaFired, 1)
        XCTAssertEqual(stats.oharaiUsed, 1)
        XCTAssertEqual(stats.crystalBallsUsed, 1)
    }
    
    func testScoreFormatting() {
        XCTAssertEqual(scoreSystem.formatScore(500), "500")
        XCTAssertEqual(scoreSystem.formatScore(1500), "1.5K")
        XCTAssertEqual(scoreSystem.formatScore(1500000), "1.5M")
    }
    
    func testPlayerRanking() {
        scoreSystem.addScore(5000, reason: "Test")
        XCTAssertEqual(scoreSystem.getPlayerRanking(), "初心者")
        
        scoreSystem.addScore(50000, reason: "Test")
        XCTAssertEqual(scoreSystem.getPlayerRanking(), "見習い巫女")
        
        scoreSystem.addScore(1000000, reason: "Test")
        XCTAssertEqual(scoreSystem.getPlayerRanking(), "神巫女")
    }
    
    // MARK: - Constants Tests
    
    func testGameConstants() {
        XCTAssertEqual(GameConstants.screenWidth, 1024)
        XCTAssertEqual(GameConstants.screenHeight, 768)
        XCTAssertEqual(GameConstants.playerMaxHealth, 3)
        XCTAssertEqual(GameConstants.ofudaMaxCount, 4)
    }
    
    func testCollisionCategories() {
        XCTAssertEqual(CollisionCategory.player, 1)
        XCTAssertEqual(CollisionCategory.enemy, 2)
        XCTAssertEqual(CollisionCategory.ofuda, 4)
        XCTAssertEqual(CollisionCategory.enemyBullet, 8)
        XCTAssertEqual(CollisionCategory.item, 16)
        XCTAssertEqual(CollisionCategory.oharai, 32)
        XCTAssertEqual(CollisionCategory.boundary, 64)
    }
    
    func testGameColorsExist() {
        XCTAssertNotNil(GameColors.healthRed)
        XCTAssertNotNil(GameColors.scoreWhite)
        XCTAssertNotNil(GameColors.playerWhite)
        XCTAssertNotNil(GameColors.ofudaYellow)
        XCTAssertNotNil(GameColors.powerOrange)
        XCTAssertNotNil(GameColors.powerBlue)
        XCTAssertNotNil(GameColors.powerGreen)
    }
    
    // MARK: - Extension Tests
    
    func testCGPointExtensions() {
        let point1 = CGPoint(x: 0, y: 0)
        let point2 = CGPoint(x: 3, y: 4)
        
        let sum = point1 + point2
        XCTAssertEqual(sum, CGPoint(x: 3, y: 4))
        
        let difference = point2 - point1
        XCTAssertEqual(difference, CGPoint(x: 3, y: 4))
        
        let scaled = point2 * 2
        XCTAssertEqual(scaled, CGPoint(x: 6, y: 8))
        
        let distance = point1.distance(to: point2)
        XCTAssertEqual(distance, 5.0, accuracy: 0.001)
    }
    
    func testCGVectorExtensions() {
        let vector = CGVector(dx: 3, dy: 4)
        
        XCTAssertEqual(vector.length, 5.0, accuracy: 0.001)
        
        let normalized = vector.normalized
        XCTAssertEqual(normalized.length, 1.0, accuracy: 0.001)
    }
    
    func testAngleExtensions() {
        let degrees: CGFloat = 90
        let radians = degrees.degreesToRadians
        XCTAssertEqual(radians, CGFloat.pi / 2, accuracy: 0.001)
        
        let backToDegrees = radians.radiansToDegrees
        XCTAssertEqual(backToDegrees, 90, accuracy: 0.001)
    }
    
    // MARK: - ItemType Tests
    
    func testItemTypes() {
        let healthItem = Item(type: .health)
        XCTAssertEqual(healthItem.itemType, .health)
        
        let powerUpItem = Item(type: .powerUp(.damage))
        if case .powerUp(let powerType) = powerUpItem.itemType {
            XCTAssertEqual(powerType, .damage)
        } else {
            XCTFail("Expected powerUp item type")
        }
    }
    
    func testItemConfiguration() {
        let healthConfig = ItemConfiguration.getConfig(for: .health)
        XCTAssertEqual(healthConfig.scoreValue, 100)
        
        let coinConfig = ItemConfiguration.getConfig(for: .coin)
        XCTAssertEqual(coinConfig.scoreValue, 50)
        
        let powerConfig = ItemConfiguration.getConfig(for: .powerUp(.damage))
        XCTAssertEqual(powerConfig.scoreValue, 300)
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceScoreAddition() {
        measure {
            for i in 0..<1000 {
                scoreSystem.addScore(i, reason: "Performance Test")
            }
        }
    }
    
    func testPerformanceComboSystem() {
        let enemy = Hitodama(gameManager: gameManager)
        
        measure {
            for _ in 0..<100 {
                scoreSystem.addEnemyKillScore(enemy, at: CGPoint.zero)
            }
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testGameManagerEdgeCases() {
        // 負の値でのダメージ
        gameManager.takeDamage(-1)
        XCTAssertEqual(gameManager.currentHealth, gameManager.maxHealth)
        
        // 過剰な回復
        gameManager.heal(100)
        XCTAssertEqual(gameManager.currentHealth, gameManager.maxHealth)
        
        // 負の値でのスコア加算
        gameManager.addScore(-100)
        XCTAssertEqual(gameManager.score, 0)
    }
    
    func testScoreSystemEdgeCases() {
        // 負の値でのスコア加算
        scoreSystem.addScore(-100, reason: "Negative Test")
        XCTAssertEqual(scoreSystem.getCurrentScore(), -100)
        
        // 大きな値でのスコア加算
        scoreSystem.addScore(Int.max, reason: "Large Value Test")
        // オーバーフローをチェック（実装依存）
    }
}

// MARK: - モックオブジェクト

class MockGameManager: GameManager {
    var mockGameState: GameState = .menu
    
    override var gameState: GameState {
        get { return mockGameState }
        set { mockGameState = newValue }
    }
}

class MockAudioSystem {
    var playedSounds: [String] = []
    var playedBGM: [String] = []
    
    func playSFX(_ soundName: String) {
        playedSounds.append(soundName)
    }
    
    func playBGM(_ soundName: String, loop: Bool = true) {
        playedBGM.append(soundName)
    }
}

// MARK: - 統合テスト

final class KikiKaikaiIntegrationTests: XCTestCase {
    
    func testGameFlow() {
        let gameManager = GameManager()
        
        // ゲーム開始
        gameManager.startNewGame()
        XCTAssertEqual(gameManager.gameState, .playing)
        
        // アイテム取得
        gameManager.collectItem(.health)
        gameManager.collectItem(.powerUp(.damage))
        
        // ダメージ
        gameManager.takeDamage(1)
        XCTAssertEqual(gameManager.currentHealth, gameManager.maxHealth) // 回復アイテムで回復
        
        // パワーアップ確認
        XCTAssertEqual(gameManager.getPowerLevel(.damage), 1)
    }
    
    func testScoreAndGameManagerIntegration() {
        let gameManager = GameManager()
        let scoreSystem = ScoreSystem.shared
        
        scoreSystem.resetGame()
        gameManager.startNewGame()
        
        // 敵撃破シミュレーション
        let enemy = Hitodama(gameManager: gameManager)
        scoreSystem.addEnemyKillScore(enemy, at: CGPoint.zero)
        
        XCTAssertGreaterThan(scoreSystem.getCurrentScore(), 0)
        XCTAssertEqual(scoreSystem.getCurrentCombo(), 1)
    }
}
