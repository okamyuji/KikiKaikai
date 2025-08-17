import SwiftUI
import Combine

enum GameState {
    case menu
    case playing
    case paused
    case gameOver
    case stageClear
}

enum PowerType {
    case damage  // 橙色の力玉
    case speed   // 青色の力玉
    case pierce  // 緑色の力玉
}

class GameManager: ObservableObject {
    // ゲーム状態
    @Published var gameState: GameState = .menu
    @Published var currentStage: Int = 1
    @Published var score: Int = 0
    @Published var currentHealth: Int = 3
    @Published var crystalBalls: Int = 2
    
    // 設定
    let maxHealth: Int = 3
    let maxStages: Int = 5
    
    // パワーアップ状態
    @Published var powerLevels: [PowerType: Int] = [
        .damage: 0,
        .speed: 0,
        .pierce: 0
    ]
    
    // ゲーム統計
    @Published var enemiesKilled: Int = 0
    @Published var itemsCollected: Int = 0
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupGameSubscriptions()
    }
    
    private func setupGameSubscriptions() {
        // ゲーム状態の変更を監視
        $gameState
            .sink { [weak self] state in
                self?.handleGameStateChange(state)
            }
            .store(in: &cancellables)
    }
    
    private func handleGameStateChange(_ state: GameState) {
        switch state {
        case .menu:
            print("メニュー画面に戻りました")
        case .playing:
            print("ゲーム開始")
        case .gameOver:
            print("ゲームオーバー - 最終スコア: \(score)")
        case .stageClear:
            print("ステージ\(currentStage)クリア!")
        case .paused:
            print("ゲーム一時停止")
        }
    }
    
    // MARK: - ゲーム制御メソッド
    
    func startNewGame() {
        resetGameState()
        gameState = .playing
    }
    
    func pauseGame() {
        if gameState == .playing {
            gameState = .paused
        }
    }
    
    func resumeGame() {
        if gameState == .paused {
            gameState = .playing
        }
    }
    
    func gameOver() {
        gameState = .gameOver
    }
    
    func nextStage() {
        if currentStage < maxStages {
            currentStage += 1
            // ステージ切り替え時の処理
            crystalBalls = min(crystalBalls + 1, 3) // 水晶玉補充
            gameState = .playing
        } else {
            // 全ステージクリア
            gameState = .gameOver
        }
    }
    
    private func resetGameState() {
        currentStage = 1
        score = 0
        currentHealth = maxHealth
        crystalBalls = 2
        enemiesKilled = 0
        itemsCollected = 0
        
        // パワーアップリセット
        powerLevels = [
            .damage: 0,
            .speed: 0,
            .pierce: 0
        ]
    }
    
    // MARK: - プレイヤー状態管理
    
    func takeDamage(_ damage: Int = 1) {
        currentHealth = max(0, currentHealth - damage)
        if currentHealth <= 0 {
            gameOver()
        }
    }
    
    func heal(_ amount: Int = 1) {
        currentHealth = min(maxHealth, currentHealth + amount)
    }
    
    func useCrystalBall() -> Bool {
        guard crystalBalls > 0 else { return false }
        crystalBalls -= 1
        return true
    }
    
    func addCrystalBall() {
        crystalBalls = min(3, crystalBalls + 1)
    }
    
    // MARK: - スコア・アイテム管理
    
    func addScore(_ points: Int) {
        score += points
    }
    
    func enemyKilled(scoreValue: Int) {
        enemiesKilled += 1
        addScore(scoreValue)
    }
    
    func collectItem(_ itemType: ItemType) {
        itemsCollected += 1
        
        switch itemType {
        case .health:
            heal()
            addScore(100)
        case .crystalBall:
            addCrystalBall()
            addScore(200)
        case .powerUp(let type):
            upgradePower(type)
            addScore(300)
        case .coin:
            addScore(50)
        }
    }
    
    private func upgradePower(_ type: PowerType) {
        powerLevels[type] = min(3, (powerLevels[type] ?? 0) + 1)
    }
    
    // MARK: - ゲーム設定
    
    func getPowerLevel(_ type: PowerType) -> Int {
        return powerLevels[type] ?? 0
    }
    
    func getOfudaDamage() -> Int {
        return 1 + getPowerLevel(.damage)
    }
    
    func getOfudaSpeed() -> CGFloat {
        return 300.0 + CGFloat(getPowerLevel(.speed) * 100)
    }
    
    func getOfudaPierce() -> Bool {
        return getPowerLevel(.pierce) >= 2
    }
    
    func getOfudaRange() -> CGFloat {
        return 400.0 + CGFloat(getPowerLevel(.speed) * 100)
    }
}

// アイテムタイプの定義
enum ItemType {
    case health
    case crystalBall
    case powerUp(PowerType)
    case coin
}
