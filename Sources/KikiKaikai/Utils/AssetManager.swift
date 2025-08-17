import Foundation
import SpriteKit
import AppKit
import AVFoundation

class AssetManager {
    static let shared = AssetManager()
    
    // アセットの状態
    enum LoadingState: Equatable {
        case notLoaded
        case loading
        case loaded
        case failed(Error)
        
        static func == (lhs: LoadingState, rhs: LoadingState) -> Bool {
            switch (lhs, rhs) {
            case (.notLoaded, .notLoaded), (.loading, .loading), (.loaded, .loaded):
                return true
            case (.failed, .failed):
                return true
            default:
                return false
            }
        }
    }
    
    // テクスチャ管理
    private var textures: [String: SKTexture] = [:]
    private var textureAtlases: [String: SKTextureAtlas] = [:]
    
    // サウンド管理
    private var sounds: [String: AVAudioPlayer] = [:]
    private var soundBuffers: [String: Data] = [:]
    
    // フォント管理
    private var fonts: [String: String] = [:]
    
    // 読み込み状態
    private var loadingState: LoadingState = .notLoaded
    private var loadingProgress: Float = 0.0
    
    // コールバック
    private var loadingCallbacks: [(LoadingState, Float) -> Void] = []
    
    private init() {
        registerDefaultAssets()
    }
    
    // MARK: - アセット登録
    
    private func registerDefaultAssets() {
        // デフォルトで使用するアセットを登録
        registerTextures()
        registerSounds()
        registerFonts()
    }
    
    private func registerTextures() {
        // プレイヤー関連テクスチャ
        registerTextureAsset("player_idle", filename: "player_idle")
        registerTextureAsset("player_walk", filename: "player_walk")
        registerTextureAsset("player_damage", filename: "player_damage")
        
        // 敵関連テクスチャ
        registerTextureAsset("hitodama", filename: "enemy_hitodama")
        registerTextureAsset("bakechouchin", filename: "enemy_bakechouchin")
        registerTextureAsset("rokurokubi", filename: "enemy_rokurokubi")
        registerTextureAsset("rumuru", filename: "enemy_rumuru")
        
        // 弾丸・攻撃テクスチャ
        registerTextureAsset("ofuda", filename: "projectile_ofuda")
        registerTextureAsset("oharai_effect", filename: "effect_oharai")
        registerTextureAsset("enemy_bullet", filename: "projectile_enemy")
        
        // アイテムテクスチャ
        registerTextureAsset("item_health", filename: "item_heart")
        registerTextureAsset("item_crystal", filename: "item_crystal")
        registerTextureAsset("item_power_orange", filename: "item_power_orange")
        registerTextureAsset("item_power_blue", filename: "item_power_blue")
        registerTextureAsset("item_power_green", filename: "item_power_green")
        registerTextureAsset("item_coin", filename: "item_coin")
        
        // エフェクトテクスチャ
        registerTextureAsset("explosion", filename: "effect_explosion")
        registerTextureAsset("hit_effect", filename: "effect_hit")
        registerTextureAsset("sparkle", filename: "effect_sparkle")
        
        // 背景テクスチャ
        registerTextureAsset("background_01", filename: "bg_stage1")
        registerTextureAsset("background_02", filename: "bg_stage2")
        registerTextureAsset("cloud", filename: "bg_cloud")
        registerTextureAsset("star", filename: "bg_star")
        
        // UIテクスチャ
        registerTextureAsset("ui_heart", filename: "ui_heart")
        registerTextureAsset("ui_crystal", filename: "ui_crystal")
        registerTextureAsset("ui_frame", filename: "ui_frame")
    }
    
    private func registerSounds() {
        // BGM
        registerSoundAsset(SoundNames.menuBGM, filename: "bgm_menu")
        registerSoundAsset(SoundNames.stage1BGM, filename: "bgm_stage1")
        registerSoundAsset(SoundNames.stage2BGM, filename: "bgm_stage2")
        registerSoundAsset(SoundNames.bossBGM, filename: "bgm_boss")
        
        // 効果音
        registerSoundAsset(SoundNames.ofudaShoot, filename: "sfx_ofuda")
        registerSoundAsset(SoundNames.oharaiSwing, filename: "sfx_oharai")
        registerSoundAsset(SoundNames.enemyHit, filename: "sfx_enemy_hit")
        registerSoundAsset(SoundNames.enemyDestroy, filename: "sfx_enemy_destroy")
        registerSoundAsset(SoundNames.playerDamage, filename: "sfx_player_damage")
        registerSoundAsset(SoundNames.itemGet, filename: "sfx_item_get")
        registerSoundAsset(SoundNames.powerUp, filename: "sfx_power_up")
        registerSoundAsset(SoundNames.crystalBall, filename: "sfx_crystal_ball")
        registerSoundAsset(SoundNames.stageCleared, filename: "sfx_stage_clear")
        registerSoundAsset(SoundNames.gameOver, filename: "sfx_game_over")
    }
    
    private func registerFonts() {
        // ゲーム用フォント
        fonts["default"] = "Helvetica"
        fonts["ui"] = "Helvetica-Bold"
        fonts["score"] = "Courier-Bold"
        fonts["japanese"] = "Hiragino Sans"
    }
    
    private func registerTextureAsset(_ name: String, filename: String) {
        // 実際のファイルが存在するかチェックし、存在しない場合はプレースホルダーを作成
        if Bundle.main.path(forResource: filename, ofType: "png") != nil {
            // ファイルが存在する場合
            textures[name] = SKTexture(imageNamed: filename)
        } else {
            // ファイルが存在しない場合、プレースホルダーテクスチャを作成
            textures[name] = createPlaceholderTexture(for: name)
        }
    }
    
    private func registerSoundAsset(_ name: String, filename: String) {
        // サウンドファイルの存在確認は AudioSystem で行う
        // ここでは登録のみ
    }
    
    // MARK: - プレースホルダー作成
    
    private func createPlaceholderTexture(for name: String) -> SKTexture {
        let size = getDefaultSizeForAsset(name)
        let color = getDefaultColorForAsset(name)
        
        let image = NSImage(size: size)
        image.lockFocus()
        defer { image.unlockFocus() }
        
        guard let context = NSGraphicsContext.current?.cgContext else {
            return SKTexture()
        }
        
        // 背景色を設定
        context.setFillColor(color.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        
        // 簡単な識別用の模様を追加
        addPlaceholderPattern(context: context, size: size, name: name)
        
        return SKTexture(image: image)
    }
    
    private func getDefaultSizeForAsset(_ name: String) -> CGSize {
        switch name {
        case "player_idle", "player_walk", "player_damage":
            return GameConstants.playerSize
        case "hitodama", "bakechouchin", "rokurokubi", "rumuru":
            return CGSize(width: 32, height: 32)
        case "ofuda":
            return GameConstants.ofudaSize
        case "item_health", "item_crystal", "item_power_orange", "item_power_blue", "item_power_green":
            return GameConstants.itemSize
        case "item_coin":
            return CGSize(width: 16, height: 16)
        case "explosion", "hit_effect":
            return CGSize(width: 64, height: 64)
        case "sparkle":
            return CGSize(width: 16, height: 16)
        case "background_01", "background_02":
            return CGSize(width: 512, height: 512)
        case "cloud":
            return CGSize(width: 128, height: 64)
        case "star":
            return CGSize(width: 8, height: 8)
        default:
            return CGSize(width: 32, height: 32)
        }
    }
    
    private func getDefaultColorForAsset(_ name: String) -> NSColor {
        switch name {
        case "player_idle", "player_walk", "player_damage":
            return .white
        case "hitodama":
            return .cyan
        case "bakechouchin":
            return .red
        case "rokurokubi":
            return .green
        case "rumuru":
            return .purple
        case "ofuda":
            return .yellow
        case "item_health":
            return .red
        case "item_crystal":
            return .blue
        case "item_power_orange":
            return .orange
        case "item_power_blue":
            return .blue
        case "item_power_green":
            return .green
        case "item_coin":
            return .yellow
        case "explosion":
            return .orange
        case "hit_effect":
            return .yellow
        case "sparkle":
            return .white
        case "background_01", "background_02":
            return .purple
        case "cloud":
            return .lightGray
        case "star":
            return .white
        default:
            return .gray
        }
    }
    
    private func addPlaceholderPattern(context: CGContext, size: CGSize, name: String) {
        context.setStrokeColor(NSColor.white.cgColor)
        context.setLineWidth(2.0)
        
        // 枠線
        context.stroke(CGRect(origin: .zero, size: size))
        
        // X印（プレースホルダーの印）
        context.move(to: CGPoint.zero)
        context.addLine(to: CGPoint(x: size.width, y: size.height))
        context.move(to: CGPoint(x: 0, y: size.height))
        context.addLine(to: CGPoint(x: size.width, y: 0))
        context.strokePath()
        
        // 名前の最初の文字を中央に描画
        if let firstChar = name.first {
            let text = String(firstChar).uppercased()
            let font = NSFont.systemFont(ofSize: min(size.width, size.height) * 0.3)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor.white
            ]
            
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            
            text.draw(in: textRect, withAttributes: attributes)
        }
    }
    
    // MARK: - 非同期読み込み
    
    func loadAssets(completion: @escaping (Bool) -> Void) {
        guard loadingState == .notLoaded else {
            completion(loadingState == .loaded)
            return
        }
        
        loadingState = .loading
        loadingProgress = 0.0
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.performAssetLoading { success in
                DispatchQueue.main.async {
                    if success {
                        self?.loadingState = .loaded
                        self?.loadingProgress = 1.0
                    } else {
                        self?.loadingState = .failed(AssetError.loadingFailed)
                    }
                    completion(success)
                }
            }
        }
    }
    
    private func performAssetLoading(completion: @escaping (Bool) -> Void) {
        let totalAssets = textures.count + sounds.count
        var loadedAssets = 0
        
        // テクスチャの事前読み込み
        for (name, texture) in textures {
            // テクスチャを事前に読み込み
            _ = texture.size()
            
            loadedAssets += 1
            loadingProgress = Float(loadedAssets) / Float(totalAssets)
            notifyLoadingProgress()
            
            // プログレスの更新間隔を調整
            Thread.sleep(forTimeInterval: 0.01)
        }
        
        // サウンドの事前読み込み（AudioSystem経由）
        let soundNames = Array(sounds.keys)
        AudioSystem.shared.preloadSounds(soundNames)
        
        loadedAssets = totalAssets
        loadingProgress = 1.0
        notifyLoadingProgress()
        
        completion(true)
    }
    
    private func notifyLoadingProgress() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            for callback in self.loadingCallbacks {
                callback(self.loadingState, self.loadingProgress)
            }
        }
    }
    
    func addLoadingCallback(_ callback: @escaping (LoadingState, Float) -> Void) {
        loadingCallbacks.append(callback)
    }
    
    // MARK: - アセット取得
    
    func getTexture(_ name: String) -> SKTexture? {
        return textures[name]
    }
    
    func getTextureAtlas(_ name: String) -> SKTextureAtlas? {
        return textureAtlases[name]
    }
    
    func getFont(_ name: String) -> String {
        return fonts[name] ?? "Helvetica"
    }
    
    // MARK: - テクスチャ操作
    
    func createAnimationTextures(from atlas: String, prefix: String, count: Int) -> [SKTexture] {
        guard let textureAtlas = textureAtlases[atlas] else {
            return []
        }
        
        var textures: [SKTexture] = []
        for i in 1...count {
            let textureName = "\(prefix)_\(String(format: "%02d", i))"
            let texture = textureAtlas.textureNamed(textureName)
            textures.append(texture)
        }
        
        return textures
    }
    
    func createColorVariant(of texture: SKTexture, color: NSColor) -> SKTexture {
        let originalSize = texture.size()
        
        let image = NSImage(size: originalSize)
        image.lockFocus()
        defer { image.unlockFocus() }
        
        guard let context = NSGraphicsContext.current?.cgContext else {
            return texture
        }
        
        // オリジナルテクスチャを描画
        let cgImage = texture.cgImage()
        context.draw(cgImage, in: CGRect(origin: .zero, size: originalSize))
        
        // カラーオーバーレイ
        context.setFillColor(color.cgColor)
        context.setBlendMode(.multiply)
        context.fill(CGRect(origin: .zero, size: originalSize))
        
        return SKTexture(image: image)
    }
    
    // MARK: - メモリ管理
    
    func clearUnusedAssets() {
        // 使用されていないテクスチャを削除
        for (name, texture) in textures {
            if texture.useCount() == 0 {
                textures.removeValue(forKey: name)
            }
        }
        
        // サウンドのクリーンアップ
        AudioSystem.shared.cleanupUnusedSounds()
    }
    
    func preloadCriticalAssets() {
        // ゲーム開始に必要な最小限のアセットを事前読み込み
        let criticalAssets = [
            "player_idle",
            "ofuda",
            "hitodama",
            "item_health",
            "explosion"
        ]
        
        for assetName in criticalAssets {
            if let texture = textures[assetName] {
                _ = texture.size() // 事前読み込み
            }
        }
    }
    
    // MARK: - デバッグ・統計
    
    func getLoadingStatistics() -> (loaded: Int, total: Int, memoryUsage: Int) {
        let totalAssets = textures.count + sounds.count
        let loadedAssets = textures.filter { $0.value.useCount() > 0 }.count
        
        // 概算メモリ使用量（バイト）
        var memoryUsage = 0
        for texture in textures.values {
            let size = texture.size()
            memoryUsage += Int(size.width * size.height * 4) // RGBA
        }
        
        return (loadedAssets, totalAssets, memoryUsage)
    }
    
    func listAssets() -> [String: String] {
        var assetList: [String: String] = [:]
        
        for name in textures.keys {
            assetList[name] = "Texture"
        }
        
        for name in sounds.keys {
            assetList[name] = "Sound"
        }
        
        for name in fonts.keys {
            assetList[name] = "Font"
        }
        
        return assetList
    }
    
    #if DEBUG
    func debugInfo() -> String {
        let stats = getLoadingStatistics()
        return """
        === Asset Manager Debug Info ===
        Loading State: \(loadingState)
        Progress: \(Int(loadingProgress * 100))%
        Loaded Assets: \(stats.loaded) / \(stats.total)
        Memory Usage: \(stats.memoryUsage / 1024 / 1024) MB
        
        Textures: \(textures.count)
        Sounds: \(sounds.count)
        Fonts: \(fonts.count)
        """
    }
    #endif
}

// MARK: - エラー定義
enum AssetError: Error {
    case fileNotFound(String)
    case loadingFailed
    case invalidFormat(String)
    case memoryError
    
    var localizedDescription: String {
        switch self {
        case .fileNotFound(let filename):
            return "ファイルが見つかりません: \(filename)"
        case .loadingFailed:
            return "アセットの読み込みに失敗しました"
        case .invalidFormat(let format):
            return "無効なファイル形式: \(format)"
        case .memoryError:
            return "メモリ不足です"
        }
    }
}

// MARK: - アセット設定
struct AssetConfiguration {
    static let maxTextureSize: CGSize = CGSize(width: 2048, height: 2048)
    static let compressionQuality: Float = 0.8
    static let enableMipmaps: Bool = true
    static let textureFilteringMode: SKTextureFilteringMode = .linear
}

// MARK: - SKTexture拡張
extension SKTexture {
    func useCount() -> Int {
        // 実際の実装では参照カウントを取得
        // ここでは簡易版として1を返す
        return 1
    }
}
