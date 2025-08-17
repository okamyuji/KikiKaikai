import SpriteKit
import SwiftUI

class GameScene: SKScene, InputSystemDelegate, ScoreSystemDelegate {
    // ゲーム管理
    private var gameManager: GameManager
    private var inputSystem: InputSystem
    private var collisionSystem: CollisionSystem?
    private var scoreSystem: ScoreSystem
    private var audioSystem: AudioSystem
    
    // ゲームオブジェクト
    private var player: Player?
    private var enemies: [BaseEnemy] = []
    private var items: [Item] = []
    
    // システム管理
    private var lastUpdateTime: TimeInterval = 0
    private var enemySpawnTimer: TimeInterval = 0
    private var gameTime: TimeInterval = 0
    
    // UI要素
    private var uiLayer: SKNode!
    private var backgroundLayer: SKNode!
    private var gameplayLayer: SKNode!
    private var effectsLayer: SKNode!
    
    // 背景
    private var backgroundNodes: [SKNode] = []
    private var backgroundScrollSpeed: CGFloat = 30
    
    // 敵生成
    private var enemySpawnPoints: [CGPoint] = []
    private var currentWave: Int = 1
    private var enemiesInWave: Int = 0
    private let maxEnemiesOnScreen = 15
    
    // 水晶玉効果
    private var isCrystalBallActive = false
    private var crystalBallTimer: TimeInterval = 0
    
    // デバッグ
    #if DEBUG
    private var debugLabel: SKLabelNode?
    private var showDebugInfo = false
    #endif
    
    init(gameManager: GameManager) {
        self.gameManager = gameManager
        self.inputSystem = InputSystem()
        self.scoreSystem = ScoreSystem.shared
        self.audioSystem = AudioSystem.shared
        
        super.init(size: CGSize(width: GameConstants.screenWidth, height: GameConstants.screenHeight))
        
        setupScene()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - シーン初期化
    
    private func setupScene() {
        // 基本設定
        backgroundColor = SKColor.black
        anchorPoint = CGPoint(x: 0, y: 0)
        
        // 物理世界設定
        physicsWorld.gravity = CGVector.zero
        physicsWorld.speed = 1.0
        
        // レイヤー作成
        setupLayers()
        
        // システム初期化
        setupSystems()
        
        // 背景作成
        setupBackground()
        
        // 敵スポーンポイント設定
        setupEnemySpawnPoints()
        
        // UI作成
        setupUI()
        
        // BGM開始
        audioSystem.playBGM(SoundNames.stage1BGM)
        
        #if DEBUG
        setupDebugUI()
        #endif
    }
    
    private func setupLayers() {
        // 背景レイヤー
        backgroundLayer = SKNode()
        backgroundLayer.zPosition = GameLayers.background
        addChild(backgroundLayer)
        
        // ゲームプレイレイヤー
        gameplayLayer = SKNode()
        gameplayLayer.zPosition = GameLayers.player
        addChild(gameplayLayer)
        
        // エフェクトレイヤー
        effectsLayer = SKNode()
        effectsLayer.zPosition = GameLayers.effects
        addChild(effectsLayer)
        
        // UIレイヤー
        uiLayer = SKNode()
        uiLayer.zPosition = GameLayers.ui
        addChild(uiLayer)
    }
    
    private func setupSystems() {
        // 入力システム
        inputSystem.delegate = self
        
        // 衝突システム
        collisionSystem = CollisionSystem(scene: self, gameManager: gameManager)
        
        // スコアシステム
        scoreSystem.delegate = self
        scoreSystem.resetGame()
        
        // プレイヤー作成
        createPlayer()
    }
    
    private func setupBackground() {
        // 和風な背景パターン
        createScrollingBackground()
        
        // 装飾要素
        createBackgroundDecorations()
    }
    
    private func createScrollingBackground() {
        // グラデーション背景
        let gradientTexture = createGradientTexture()
        
        for i in 0..<3 {
            let backgroundNode = SKSpriteNode(texture: gradientTexture)
            backgroundNode.size = CGSize(width: size.width, height: size.height)
            backgroundNode.position = CGPoint(x: size.width / 2, y: size.height * CGFloat(i))
            backgroundNode.zPosition = GameLayers.background
            backgroundLayer.addChild(backgroundNode)
            backgroundNodes.append(backgroundNode)
        }
    }
    
    private func createGradientTexture() -> SKTexture {
        let size = CGSize(width: 256, height: 256)
        
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(data: nil,
                                    width: Int(size.width),
                                    height: Int(size.height),
                                    bitsPerComponent: 8,
                                    bytesPerRow: 0,
                                    space: colorSpace,
                                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return SKTexture()
        }
        
        // 紫から黒のグラデーション
        let colors = [
            NSColor.purple.withAlphaComponent(0.3).cgColor,
            NSColor.black.cgColor
        ]
        
        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: nil) else {
            return SKTexture()
        }
        
        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: 0, y: size.height),
            end: CGPoint(x: 0, y: 0),
            options: []
        )
        
        guard let cgImage = context.makeImage() else {
            return SKTexture()
        }
        
        let nsImage = NSImage(cgImage: cgImage, size: size)
        return SKTexture(image: nsImage)
    }
    
    private func createBackgroundDecorations() {
        // 星（光る点）
        for _ in 0..<50 {
            let star = SKSpriteNode(color: .white, size: CGSize(width: 2, height: 2))
            star.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height * 2)
            )
            star.alpha = CGFloat.random(in: 0.3...1.0)
            star.zPosition = GameLayers.backgroundDecoration
            backgroundLayer.addChild(star)
            backgroundNodes.append(star)
            
            // きらめきアニメーション
            let twinkle = SKAction.sequence([
                SKAction.fadeIn(withDuration: CGFloat.random(in: 1.0...3.0)),
                SKAction.fadeOut(withDuration: CGFloat.random(in: 1.0...3.0))
            ])
            star.run(SKAction.repeatForever(twinkle))
        }
        
        // 雲（薄い雰囲気）
        for _ in 0..<8 {
            let cloud = createCloudNode()
            cloud.position = CGPoint(
                x: CGFloat.random(in: -50...size.width + 50),
                y: CGFloat.random(in: 0...size.height * 2)
            )
            cloud.zPosition = GameLayers.backgroundDecoration
            backgroundLayer.addChild(cloud)
            backgroundNodes.append(cloud)
        }
    }
    
    private func createCloudNode() -> SKNode {
        let cloud = SKNode()
        
        // 複数の円で雲を作成
        for _ in 0..<5 {
            let circle = SKShapeNode(circleOfRadius: CGFloat.random(in: 15...30))
            circle.fillColor = .white
            circle.alpha = CGFloat.random(in: 0.1...0.3)
            circle.position = CGPoint(
                x: CGFloat.random(in: -20...20),
                y: CGFloat.random(in: -10...10)
            )
            cloud.addChild(circle)
        }
        
        return cloud
    }
    
    private func setupEnemySpawnPoints() {
        // 画面上部、左右からのスポーンポイント
        enemySpawnPoints = [
            // 上部
            CGPoint(x: size.width * 0.25, y: size.height + 50),
            CGPoint(x: size.width * 0.5, y: size.height + 50),
            CGPoint(x: size.width * 0.75, y: size.height + 50),
            
            // 左右
            CGPoint(x: -50, y: size.height * 0.7),
            CGPoint(x: size.width + 50, y: size.height * 0.7),
            CGPoint(x: -50, y: size.height * 0.5),
            CGPoint(x: size.width + 50, y: size.height * 0.5),
            
            // 上部角
            CGPoint(x: -30, y: size.height + 30),
            CGPoint(x: size.width + 30, y: size.height + 30)
        ]
    }
    
    private func setupUI() {
        // UI要素は ContentView で管理されるため、ここでは最小限
    }
    
    #if DEBUG
    private func setupDebugUI() {
        debugLabel = SKLabelNode(text: "Debug Info")
        debugLabel?.fontName = "Courier"
        debugLabel?.fontSize = 12
        debugLabel?.fontColor = .green
        debugLabel?.position = CGPoint(x: 10, y: size.height - 30)
        debugLabel?.horizontalAlignmentMode = .left
        debugLabel?.zPosition = GameLayers.ui + 10
        uiLayer.addChild(debugLabel!)
    }
    #endif
    
    // MARK: - プレイヤー管理
    
    private func createPlayer() {
        player = Player(gameManager: gameManager)
        if let player = player {
            gameplayLayer.addChild(player)
        }
    }
    
    // MARK: - 敵管理
    
    private func spawnEnemies(_ deltaTime: TimeInterval) {
        enemySpawnTimer += deltaTime
        
        let spawnInterval = max(0.5, GameConstants.enemySpawnInterval - (gameTime / 60.0)) // 時間とともに間隔短縮
        
        if enemySpawnTimer >= spawnInterval && enemies.count < maxEnemiesOnScreen {
            spawnRandomEnemy()
            enemySpawnTimer = 0
        }
        
        // ウェーブ管理
        if enemiesInWave <= 0 && enemies.isEmpty {
            startNextWave()
        }
    }
    
    private func spawnRandomEnemy() {
        guard let spawnPoint = enemySpawnPoints.randomElement else { return }
        
        let enemyTypes: [(Enemy.Type, Int)] = [
            (Hitodama.self, 40),
            (BakeChouchin.self, 30),
            (Rokurokubi.self, 20),
            (Rumuru.self, 10)
        ]
        
        let totalWeight = enemyTypes.reduce(0) { $0 + $1.1 }
        let randomValue = Int.random(in: 0..<totalWeight)
        
        var currentWeight = 0
        var selectedType: Enemy.Type = Hitodama.self
        
        for (enemyType, weight) in enemyTypes {
            currentWeight += weight
            if randomValue < currentWeight {
                selectedType = enemyType
                break
            }
        }
        
        let enemy = createEnemy(type: selectedType, at: spawnPoint)
        enemies.append(enemy)
        gameplayLayer.addChild(enemy)
        
        enemiesInWave -= 1
    }
    
    private func createEnemy(type: Enemy.Type, at position: CGPoint) -> BaseEnemy {
        let enemy: BaseEnemy
        
        switch type {
        case is Hitodama.Type:
            enemy = Hitodama(gameManager: gameManager)
        case is BakeChouchin.Type:
            enemy = BakeChouchin(gameManager: gameManager)
        case is Rokurokubi.Type:
            enemy = Rokurokubi(gameManager: gameManager)
        case is Rumuru.Type:
            enemy = Rumuru(gameManager: gameManager)
        default:
            enemy = Hitodama(gameManager: gameManager)
        }
        
        enemy.position = position
        return enemy
    }
    
    private func startNextWave() {
        currentWave += 1
        enemiesInWave = min(10 + currentWave * 2, 25) // ウェーブごとに敵数増加
        
        print("ウェーブ \(currentWave) 開始 - 敵数: \(enemiesInWave)")
    }
    
    private func removeDestroyedEnemies() {
        enemies.removeAll { enemy in
            if enemy.parent == nil {
                return true
            }
            return false
        }
    }
    
    // MARK: - アイテム管理
    
    private func updateItems(_ deltaTime: TimeInterval) {
        // アイテムの自動削除は各アイテムが管理
        items.removeAll { item in
            item.parent == nil
        }
    }
    
    // MARK: - 背景更新
    
    private func updateBackground(_ deltaTime: TimeInterval) {
        for backgroundNode in backgroundNodes {
            backgroundNode.position.y -= backgroundScrollSpeed * CGFloat(deltaTime)
            
            // 画面下に出たら上に移動
            if backgroundNode.position.y < -size.height {
                backgroundNode.position.y += size.height * 3
            }
        }
    }
    
    // MARK: - 水晶玉効果
    
    private func activateCrystalBall() {
        guard gameManager.useCrystalBall() else { return }
        
        isCrystalBallActive = true
        crystalBallTimer = GameConstants.crystalBallDuration
        
        // 全ての敵を停止
        for enemy in enemies {
            enemy.isStopped = true
            
            // 停止エフェクト
            let stopEffect = SKSpriteNode(color: .cyan, size: CGSize(width: 40, height: 40))
            stopEffect.position = enemy.position
            stopEffect.alpha = 0.3
            stopEffect.zPosition = GameLayers.effects
            effectsLayer.addChild(stopEffect)
            
            let effectAction = SKAction.sequence([
                SKAction.fadeOut(withDuration: GameConstants.crystalBallDuration),
                SKAction.removeFromParent()
            ])
            stopEffect.run(effectAction)
        }
        
        // 画面エフェクト
        createCrystalBallScreenEffect()
        
        // 音響効果
        audioSystem.playCrystalBallActivatedSound()
    }
    
    private func createCrystalBallScreenEffect() {
        let overlay = SKSpriteNode(color: .cyan, size: size)
        overlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.alpha = 0.0
        overlay.zPosition = GameLayers.effects + 10
        effectsLayer.addChild(overlay)
        
        let effectAction = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.2, duration: 0.5),
            SKAction.wait(forDuration: GameConstants.crystalBallDuration - 1.0),
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ])
        overlay.run(effectAction)
    }
    
    private func updateCrystalBall(_ deltaTime: TimeInterval) {
        if isCrystalBallActive {
            crystalBallTimer -= deltaTime
            
            if crystalBallTimer <= 0 {
                deactivateCrystalBall()
            }
        }
    }
    
    private func deactivateCrystalBall() {
        isCrystalBallActive = false
        crystalBallTimer = 0
        
        // 敵の停止解除
        for enemy in enemies {
            enemy.isStopped = false
        }
    }
    
    // MARK: - ゲームループ
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        // ゲーム開始
        startGame()
    }
    
    private func startGame() {
        lastUpdateTime = 0
        gameTime = 0
        currentWave = 0
        
        startNextWave()
        
        print("ゲーム開始")
    }
    
    override func update(_ currentTime: TimeInterval) {
        // デルタタイム計算
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
            return
        }
        
        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        gameTime += deltaTime
        
        // ゲーム状態チェック
        guard gameManager.gameState == .playing else { return }
        
        // システム更新
        inputSystem.update()
        
        // プレイヤー更新
        player?.update(deltaTime)
        
        // 敵更新
        for enemy in enemies {
            if !isCrystalBallActive {
                enemy.update(deltaTime)
            }
        }
        
        // アイテム更新
        updateItems(deltaTime)
        
        // 敵スポーン
        spawnEnemies(deltaTime)
        
        // 背景更新
        updateBackground(deltaTime)
        
        // 水晶玉効果更新
        updateCrystalBall(deltaTime)
        
        // 破壊された敵の削除
        removeDestroyedEnemies()
        
        // 統計更新
        scoreSystem.updatePlaytime(deltaTime)
        
        #if DEBUG
        updateDebugInfo()
        #endif
    }
    
    #if DEBUG
    private func updateDebugInfo() {
        guard let debugLabel = debugLabel, showDebugInfo else { return }
        
        let fps = 1.0 / (1.0 / 60.0) // 簡易FPS
        let nodeCount = children.count
        let enemyCount = enemies.count
        let itemCount = items.count
        
        debugLabel.text = """
        FPS: \(Int(fps))
        Nodes: \(nodeCount)
        Enemies: \(enemyCount)
        Items: \(itemCount)
        Wave: \(currentWave)
        Time: \(String(format: "%.1f", gameTime))
        """
    }
    #endif
    
    // MARK: - InputSystemDelegate
    
    func inputSystem(_ inputSystem: InputSystem, movementVector: CGVector) {
        player?.setMovement(direction: movementVector)
    }
    
    func inputSystemOfudaPressed(_ inputSystem: InputSystem) {
        guard let player = player else { return }
        
        if let ofuda = player.shootOfuda(currentTime: lastUpdateTime) {
            gameplayLayer.addChild(ofuda)
            audioSystem.playSFXWithVariation(SoundNames.ofudaShoot)
            scoreSystem.recordOfudaFired()
        }
    }
    
    func inputSystemOfudaContinuous(_ inputSystem: InputSystem) {
        inputSystemOfudaPressed(inputSystem)
    }
    
    func inputSystemOharaiPressed(_ inputSystem: InputSystem) {
        guard let player = player else { return }
        
        if let oharai = player.useOharaiStick(currentTime: lastUpdateTime) {
            gameplayLayer.addChild(oharai)
            audioSystem.playSFX(SoundNames.oharaiSwing)
            scoreSystem.recordOharaiUsed()
        }
    }
    
    func inputSystemOharaiContinuous(_ inputSystem: InputSystem) {
        // 御祓い棒は連続使用不可
    }
    
    func inputSystemCrystalBallPressed(_ inputSystem: InputSystem) {
        activateCrystalBall()
        scoreSystem.recordCrystalBallUsed()
    }
    
    func inputSystemPausePressed(_ inputSystem: InputSystem) {
        gameManager.pauseGame()
    }
    
    #if DEBUG
    func inputSystemDebugKey1(_ inputSystem: InputSystem) {
        showDebugInfo.toggle()
        debugLabel?.isHidden = !showDebugInfo
    }
    
    func inputSystemDebugKey2(_ inputSystem: InputSystem) {
        collisionSystem?.showCollisionBoxes(showDebugInfo)
    }
    
    func inputSystemDebugKey3(_ inputSystem: InputSystem) {
        // デバッグ用: 敵を全て削除
        for enemy in enemies {
            enemy.removeFromParent()
        }
        enemies.removeAll()
    }
    #endif
    
    // MARK: - ScoreSystemDelegate
    
    func scoreSystem(_ scoreSystem: ScoreSystem, scoreAdded points: Int, reason: String, at position: CGPoint?) {
        if let position = position {
            ScoreDisplay.createScorePopup(points: points, at: position, scene: self)
        }
    }
    
    func scoreSystem(_ scoreSystem: ScoreSystem, bonusScoreAdded points: Int, reason: String, at position: CGPoint?) {
        if let position = position {
            ScoreDisplay.createBonusPopup(points: points, reason: reason, at: position, scene: self)
        }
    }
    
    func scoreSystem(_ scoreSystem: ScoreSystem, comboUpdated combo: Int, at position: CGPoint?) {
        if let position = position {
            ScoreDisplay.createComboPopup(combo: combo, at: position, scene: self)
        }
    }
    
    func scoreSystem(_ scoreSystem: ScoreSystem, milestoneReached milestone: Int) {
        // マイルストーン達成エフェクト
        let centerPosition = CGPoint(x: size.width / 2, y: size.height / 2)
        ScoreDisplay.createBonusPopup(points: milestone, reason: "マイルストーン達成!", at: centerPosition, scene: self)
    }
    
    func scoreSystem(_ scoreSystem: ScoreSystem, newHighScore score: Int, rank: Int) {
        print("新ハイスコア! スコア: \(score), 順位: \(rank)")
    }
    
    // MARK: - ゲーム終了処理
    
    func endGame() {
        // ゲーム終了処理
        audioSystem.stopBGM()
        audioSystem.playGameOverSound()
        
        // ハイスコア登録
        scoreSystem.registerGameEnd(playerName: "プレイヤー", stage: gameManager.currentStage)
        
        print("ゲーム終了 - 最終スコア: \(scoreSystem.getCurrentScore())")
    }
    
    // MARK: - クリーンアップ
    
    deinit {
        inputSystem.reset()
    }
}

// MARK: - ゲームシーン拡張
extension GameScene {
    
    // 画面シェイク効果
    func shakeScreen(intensity: CGFloat, duration: TimeInterval) {
        let shakeAction = SKAction.shake(intensity: intensity, duration: duration)
        run(shakeAction)
    }
    
    // 画面フラッシュ効果
    func flashScreen(color: SKColor, duration: TimeInterval) {
        let flash = SKSpriteNode(color: color, size: size)
        flash.position = CGPoint(x: size.width / 2, y: size.height / 2)
        flash.alpha = 0.0
        flash.zPosition = GameLayers.effects + 20
        addChild(flash)
        
        let flashAction = SKAction.sequence([
            SKAction.fadeIn(withDuration: duration / 4),
            SKAction.fadeOut(withDuration: duration * 3 / 4),
            SKAction.removeFromParent()
        ])
        flash.run(flashAction)
    }
    
    // スローモーション効果
    func activateSlowMotion(factor: CGFloat, duration: TimeInterval) {
        speed = factor
        
        let normalizeAction = SKAction.sequence([
            SKAction.wait(forDuration: duration * Double(factor)),
            SKAction.run { [weak self] in
                self?.speed = 1.0
            }
        ])
        run(normalizeAction)
    }
}
