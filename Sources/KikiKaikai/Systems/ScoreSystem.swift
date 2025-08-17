import Foundation
import SpriteKit
import QuartzCore

class ScoreSystem {
    static let shared = ScoreSystem()
    
    // 現在のゲームスコア
    private var currentScore: Int = 0
    private var currentCombo: Int = 0
    private var maxCombo: Int = 0
    private var lastKillTime: TimeInterval = 0
    private let comboTimeLimit: TimeInterval = 3.0
    
    // スコア履歴
    private var scoreHistory: [ScoreEntry] = []
    private var highScores: [HighScore] = []
    private let maxHighScores = 10
    
    // 統計情報
    private var gameStatistics = GameStatistics()
    
    // 通知デリゲート
    weak var delegate: ScoreSystemDelegate?
    
    private init() {
        loadHighScores()
    }
    
    // MARK: - スコア構造体
    
    struct ScoreEntry {
        let points: Int
        let reason: String
        let timestamp: TimeInterval
        let position: CGPoint?
        let combo: Int
        
        init(points: Int, reason: String, position: CGPoint? = nil, combo: Int = 0) {
            self.points = points
            self.reason = reason
            self.timestamp = CACurrentMediaTime()
            self.position = position
            self.combo = combo
        }
    }
    
    struct HighScore: Codable {
        let score: Int
        let playerName: String
        let date: Date
        let stage: Int
        let playtime: TimeInterval
        let enemiesKilled: Int
        let itemsCollected: Int
        let maxCombo: Int
        
        init(score: Int, playerName: String, stage: Int, statistics: GameStatistics) {
            self.score = score
            self.playerName = playerName
            self.date = Date()
            self.stage = stage
            self.playtime = statistics.playtime
            self.enemiesKilled = statistics.enemiesKilled
            self.itemsCollected = statistics.itemsCollected
            self.maxCombo = statistics.maxCombo
        }
    }
    
    struct GameStatistics {
        var playtime: TimeInterval = 0
        var enemiesKilled: Int = 0
        var itemsCollected: Int = 0
        var maxCombo: Int = 0
        var damagesTaken: Int = 0
        var ofudaFired: Int = 0
        var oharaiUsed: Int = 0
        var crystalBallsUsed: Int = 0
        
        var accuracy: Double {
            guard ofudaFired > 0 else { return 0.0 }
            return Double(enemiesKilled) / Double(ofudaFired)
        }
        
        var survivability: Double {
            guard playtime > 0 else { return 0.0 }
            return max(0.0, 1.0 - (Double(damagesTaken) / (playtime / 60.0)))
        }
    }
    
    // MARK: - スコア加算
    
    func addScore(_ points: Int, reason: String, at position: CGPoint? = nil) {
        let comboMultiplier = getComboMultiplier()
        let actualPoints = points * comboMultiplier
        
        currentScore += actualPoints
        
        let entry = ScoreEntry(
            points: actualPoints,
            reason: reason,
            position: position,
            combo: currentCombo
        )
        scoreHistory.append(entry)
        
        // デリゲートに通知
        delegate?.scoreSystem(self, scoreAdded: actualPoints, reason: reason, at: position)
        
        // 特定のスコア閾値でボーナス
        checkScoreMilestones()
    }
    
    func addEnemyKillScore(_ enemy: Enemy, at position: CGPoint) {
        updateCombo()
        gameStatistics.enemiesKilled += 1
        
        let baseScore = enemy.scoreValue
        let comboBonus = getComboBonus(baseScore: baseScore)
        let totalScore = baseScore + comboBonus
        
        addScore(totalScore, reason: "敵撃破", at: position)
        
        // コンボ表示
        if currentCombo > 1 {
            delegate?.scoreSystem(self, comboUpdated: currentCombo, at: position)
        }
    }
    
    func addItemCollectionScore(_ item: Item, at position: CGPoint) {
        gameStatistics.itemsCollected += 1
        
        let config = ItemConfiguration.getConfig(for: item.itemType)
        addScore(config.scoreValue, reason: "アイテム取得", at: position)
    }
    
    func addBonusScore(_ points: Int, reason: String, at position: CGPoint? = nil) {
        // ボーナススコアは特別なエフェクト付き
        addScore(points, reason: reason, at: position)
        delegate?.scoreSystem(self, bonusScoreAdded: points, reason: reason, at: position)
    }
    
    // MARK: - コンボシステム
    
    private func updateCombo() {
        let currentTime = CACurrentMediaTime()
        
        if currentTime - lastKillTime <= comboTimeLimit {
            currentCombo += 1
            maxCombo = max(maxCombo, currentCombo)
            gameStatistics.maxCombo = maxCombo
        } else {
            currentCombo = 1
        }
        
        lastKillTime = currentTime
    }
    
    func resetCombo() {
        currentCombo = 0
        lastKillTime = 0
    }
    
    private func getComboMultiplier() -> Int {
        switch currentCombo {
        case 0...2: return 1
        case 3...5: return 2
        case 6...10: return 3
        case 11...20: return 4
        default: return 5
        }
    }
    
    private func getComboBonus(baseScore: Int) -> Int {
        let comboLevel = min(currentCombo / 5, 10) // 5コンボごとにレベルアップ、最大10レベル
        return baseScore * comboLevel / 10
    }
    
    // MARK: - スコア閾値とマイルストーン
    
    private func checkScoreMilestones() {
        let milestones = [10000, 50000, 100000, 250000, 500000, 1000000]
        
        for milestone in milestones {
            if currentScore >= milestone && !hasReachedMilestone(milestone) {
                reachMilestone(milestone)
                break
            }
        }
    }
    
    private func hasReachedMilestone(_ milestone: Int) -> Bool {
        return scoreHistory.contains { entry in
            entry.reason == "マイルストーン達成" && entry.points == milestone / 10
        }
    }
    
    private func reachMilestone(_ milestone: Int) {
        let bonusPoints = milestone / 10
        addBonusScore(bonusPoints, reason: "マイルストーン達成")
        
        delegate?.scoreSystem(self, milestoneReached: milestone)
        
        // 実績解除音
        AudioSystem.shared.playSFX(SoundNames.powerUp)
    }
    
    // MARK: - ライフボーナス
    
    func calculateLifeBonus(remainingLives: Int) -> Int {
        return remainingLives * 10000
    }
    
    func calculateTimeBonus(remainingTime: TimeInterval) -> Int {
        return Int(remainingTime) * 100
    }
    
    func calculateNoDamageBonus(stageDamage: Int) -> Int {
        return stageDamage == 0 ? 50000 : 0
    }
    
    func calculatePerfectBonus(accuracy: Double) -> Int {
        if accuracy >= 0.95 {
            return 25000
        } else if accuracy >= 0.8 {
            return 10000
        } else {
            return 0
        }
    }
    
    // MARK: - ハイスコア管理
    
    func registerGameEnd(playerName: String, stage: Int) {
        let highScore = HighScore(
            score: currentScore,
            playerName: playerName,
            stage: stage,
            statistics: gameStatistics
        )
        
        highScores.append(highScore)
        highScores.sort { $0.score > $1.score }
        
        if highScores.count > maxHighScores {
            highScores = Array(highScores.prefix(maxHighScores))
        }
        
        saveHighScores()
        
        // ハイスコア判定
        if let rank = getHighScoreRank(currentScore) {
            delegate?.scoreSystem(self, newHighScore: currentScore, rank: rank)
        }
    }
    
    func getHighScoreRank(_ score: Int) -> Int? {
        for (index, highScore) in highScores.enumerated() {
            if score >= highScore.score {
                return index + 1
            }
        }
        return nil
    }
    
    func isNewHighScore(_ score: Int) -> Bool {
        return highScores.isEmpty || score > (highScores.last?.score ?? 0) || highScores.count < maxHighScores
    }
    
    // MARK: - データ永続化
    
    private func saveHighScores() {
        do {
            let data = try JSONEncoder().encode(highScores)
            UserDefaults.standard.set(data, forKey: "ScoreSystem.highScores")
        } catch {
            print("ハイスコア保存エラー: \(error)")
        }
    }
    
    private func loadHighScores() {
        guard let data = UserDefaults.standard.data(forKey: "ScoreSystem.highScores") else { return }
        
        do {
            highScores = try JSONDecoder().decode([HighScore].self, from: data)
        } catch {
            print("ハイスコア読み込みエラー: \(error)")
        }
    }
    
    // MARK: - ゲーム統計更新
    
    func recordDamageTaken() {
        gameStatistics.damagesTaken += 1
        resetCombo() // ダメージでコンボリセット
    }
    
    func recordOfudaFired() {
        gameStatistics.ofudaFired += 1
    }
    
    func recordOharaiUsed() {
        gameStatistics.oharaiUsed += 1
    }
    
    func recordCrystalBallUsed() {
        gameStatistics.crystalBallsUsed += 1
    }
    
    func updatePlaytime(_ deltaTime: TimeInterval) {
        gameStatistics.playtime += deltaTime
    }
    
    // MARK: - リセット・取得メソッド
    
    func resetGame() {
        currentScore = 0
        currentCombo = 0
        maxCombo = 0
        lastKillTime = 0
        scoreHistory.removeAll()
        gameStatistics = GameStatistics()
    }
    
    func getCurrentScore() -> Int {
        return currentScore
    }
    
    func getCurrentCombo() -> Int {
        return currentCombo
    }
    
    func getMaxCombo() -> Int {
        return maxCombo
    }
    
    func getHighScores() -> [HighScore] {
        return highScores
    }
    
    func getGameStatistics() -> GameStatistics {
        return gameStatistics
    }
    
    func getRecentScoreEntries(count: Int = 10) -> [ScoreEntry] {
        return Array(scoreHistory.suffix(count))
    }
    
    // MARK: - スコア表示フォーマット
    
    func formatScore(_ score: Int) -> String {
        if score >= 1000000 {
            return String(format: "%.1fM", Double(score) / 1000000.0)
        } else if score >= 1000 {
            return String(format: "%.1fK", Double(score) / 1000.0)
        } else {
            return "\(score)"
        }
    }
    
    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func formatAccuracy(_ accuracy: Double) -> String {
        return String(format: "%.1f%%", accuracy * 100)
    }
    
    // MARK: - ランキング・実績システム
    
    func getPlayerRanking() -> String {
        let score = currentScore
        
        switch score {
        case 0..<10000: return "初心者"
        case 10000..<50000: return "見習い巫女"
        case 50000..<100000: return "巫女"
        case 100000..<250000: return "熟練巫女"
        case 250000..<500000: return "巫女師範"
        case 500000..<1000000: return "巫女の達人"
        case 1000000...: return "神巫女"
        default: return "未知"
        }
    }
    
    func getAchievements() -> [String] {
        var achievements: [String] = []
        
        if gameStatistics.maxCombo >= 50 {
            achievements.append("コンボマスター")
        }
        
        if gameStatistics.accuracy >= 0.9 {
            achievements.append("神射手")
        }
        
        if gameStatistics.damagesTaken == 0 {
            achievements.append("完璧な巫女")
        }
        
        if currentScore >= 1000000 {
            achievements.append("スコアマスター")
        }
        
        if gameStatistics.enemiesKilled >= 1000 {
            achievements.append("妖怪ハンター")
        }
        
        return achievements
    }
}

// MARK: - ScoreSystemDelegate プロトコル
protocol ScoreSystemDelegate: AnyObject {
    func scoreSystem(_ scoreSystem: ScoreSystem, scoreAdded points: Int, reason: String, at position: CGPoint?)
    func scoreSystem(_ scoreSystem: ScoreSystem, bonusScoreAdded points: Int, reason: String, at position: CGPoint?)
    func scoreSystem(_ scoreSystem: ScoreSystem, comboUpdated combo: Int, at position: CGPoint?)
    func scoreSystem(_ scoreSystem: ScoreSystem, milestoneReached milestone: Int)
    func scoreSystem(_ scoreSystem: ScoreSystem, newHighScore score: Int, rank: Int)
}

// MARK: - デフォルト実装
extension ScoreSystemDelegate {
    func scoreSystem(_ scoreSystem: ScoreSystem, scoreAdded points: Int, reason: String, at position: CGPoint?) {}
    func scoreSystem(_ scoreSystem: ScoreSystem, bonusScoreAdded points: Int, reason: String, at position: CGPoint?) {}
    func scoreSystem(_ scoreSystem: ScoreSystem, comboUpdated combo: Int, at position: CGPoint?) {}
    func scoreSystem(_ scoreSystem: ScoreSystem, milestoneReached milestone: Int) {}
    func scoreSystem(_ scoreSystem: ScoreSystem, newHighScore score: Int, rank: Int) {}
}
