import SpriteKit
import Carbon

class InputSystem {
    // キー状態管理
    private var keyStates: [UInt16: Bool] = [:]
    private var previousKeyStates: [UInt16: Bool] = [:]
    
    // 入力イベントのデリゲート
    weak var delegate: InputSystemDelegate?
    
    // キーコード定数
    struct KeyCodes {
        // 移動キー
        static let w: UInt16 = 13        // W
        static let a: UInt16 = 0         // A
        static let s: UInt16 = 1         // S
        static let d: UInt16 = 2         // D
        static let up: UInt16 = 126      // ↑
        static let down: UInt16 = 125    // ↓
        static let left: UInt16 = 123    // ←
        static let right: UInt16 = 124   // →
        
        // アクションキー
        static let space: UInt16 = 49    // スペース（お札）
        static let z: UInt16 = 6         // Z（御祓い棒）
        static let x: UInt16 = 7         // X（水晶玉）
        
        // システムキー
        static let escape: UInt16 = 53   // ESC（ポーズ）
        static let enter: UInt16 = 36    // Enter
        static let tab: UInt16 = 48      // Tab
        
        // デバッグキー（開発時のみ）
        static let f1: UInt16 = 122      // F1
        static let f2: UInt16 = 120      // F2
        static let f3: UInt16 = 99       // F3
    }
    
    // 入力方向
    enum InputDirection {
        case none
        case up, down, left, right
        case upLeft, upRight, downLeft, downRight
        
        var vector: CGVector {
            switch self {
            case .none: return CGVector.zero
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
    
    init() {
        setupEventMonitor()
    }
    
    // MARK: - イベント監視セットアップ
    
    private func setupEventMonitor() {
        // キーダウン・キーアップイベントを監視
        NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp]) { [weak self] event in
            self?.handleKeyEvent(event)
            return event
        }
    }
    
    private func handleKeyEvent(_ event: NSEvent) {
        let keyCode = event.keyCode
        let isPressed = event.type == .keyDown
        
        // 前回の状態を保存
        previousKeyStates[keyCode] = keyStates[keyCode] ?? false
        
        // 現在の状態を更新
        keyStates[keyCode] = isPressed
        
        // デリゲートに通知
        if isPressed && !wasKeyPressed(keyCode) {
            // キーが新しく押された
            delegate?.inputSystem(self, keyPressed: keyCode)
        } else if !isPressed && wasKeyPressed(keyCode) {
            // キーが離された
            delegate?.inputSystem(self, keyReleased: keyCode)
        }
    }
    
    // MARK: - キー状態チェック
    
    func isKeyPressed(_ keyCode: UInt16) -> Bool {
        return keyStates[keyCode] ?? false
    }
    
    func wasKeyPressed(_ keyCode: UInt16) -> Bool {
        return previousKeyStates[keyCode] ?? false
    }
    
    func isKeyJustPressed(_ keyCode: UInt16) -> Bool {
        return isKeyPressed(keyCode) && !wasKeyPressed(keyCode)
    }
    
    func isKeyJustReleased(_ keyCode: UInt16) -> Bool {
        return !isKeyPressed(keyCode) && wasKeyPressed(keyCode)
    }
    
    // MARK: - 移動入力処理
    
    func getCurrentMovementDirection() -> InputDirection {
        let upPressed = isKeyPressed(KeyCodes.w) || isKeyPressed(KeyCodes.up)
        let downPressed = isKeyPressed(KeyCodes.s) || isKeyPressed(KeyCodes.down)
        let leftPressed = isKeyPressed(KeyCodes.a) || isKeyPressed(KeyCodes.left)
        let rightPressed = isKeyPressed(KeyCodes.d) || isKeyPressed(KeyCodes.right)
        
        // 8方向の移動を判定
        if upPressed && leftPressed {
            return .upLeft
        } else if upPressed && rightPressed {
            return .upRight
        } else if downPressed && leftPressed {
            return .downLeft
        } else if downPressed && rightPressed {
            return .downRight
        } else if upPressed {
            return .up
        } else if downPressed {
            return .down
        } else if leftPressed {
            return .left
        } else if rightPressed {
            return .right
        } else {
            return .none
        }
    }
    
    func getMovementVector() -> CGVector {
        return getCurrentMovementDirection().vector
    }
    
    // MARK: - アクション入力チェック
    
    func isOfudaPressed() -> Bool {
        return isKeyPressed(KeyCodes.space)
    }
    
    func isOfudaJustPressed() -> Bool {
        return isKeyJustPressed(KeyCodes.space)
    }
    
    func isOharaiPressed() -> Bool {
        return isKeyPressed(KeyCodes.z)
    }
    
    func isOharaiJustPressed() -> Bool {
        return isKeyJustPressed(KeyCodes.z)
    }
    
    func isCrystalBallJustPressed() -> Bool {
        return isKeyJustPressed(KeyCodes.x)
    }
    
    func isPauseJustPressed() -> Bool {
        return isKeyJustPressed(KeyCodes.escape)
    }
    
    func isEnterJustPressed() -> Bool {
        return isKeyJustPressed(KeyCodes.enter)
    }
    
    // MARK: - デバッグ入力（開発時のみ）
    
    #if DEBUG
    func isDebugKey1JustPressed() -> Bool {
        return isKeyJustPressed(KeyCodes.f1)
    }
    
    func isDebugKey2JustPressed() -> Bool {
        return isKeyJustPressed(KeyCodes.f2)
    }
    
    func isDebugKey3JustPressed() -> Bool {
        return isKeyJustPressed(KeyCodes.f3)
    }
    #endif
    
    // MARK: - 状態更新
    
    func update() {
        // 前回の状態を現在の状態にコピー
        previousKeyStates = keyStates
        
        // 継続的な入力の処理
        delegate?.inputSystem(self, movementVector: getMovementVector())
        
        if isOfudaPressed() {
            delegate?.inputSystemOfudaContinuous(self)
        }
        
        if isOharaiPressed() {
            delegate?.inputSystemOharaiContinuous(self)
        }
    }
    
    // MARK: - リセット
    
    func reset() {
        keyStates.removeAll()
        previousKeyStates.removeAll()
    }
}

// MARK: - InputSystemDelegate プロトコル
protocol InputSystemDelegate: AnyObject {
    // キーイベント
    func inputSystem(_ inputSystem: InputSystem, keyPressed keyCode: UInt16)
    func inputSystem(_ inputSystem: InputSystem, keyReleased keyCode: UInt16)
    
    // 移動入力
    func inputSystem(_ inputSystem: InputSystem, movementVector: CGVector)
    
    // アクション入力
    func inputSystemOfudaPressed(_ inputSystem: InputSystem)
    func inputSystemOfudaContinuous(_ inputSystem: InputSystem)
    func inputSystemOharaiPressed(_ inputSystem: InputSystem)
    func inputSystemOharaiContinuous(_ inputSystem: InputSystem)
    func inputSystemCrystalBallPressed(_ inputSystem: InputSystem)
    func inputSystemPausePressed(_ inputSystem: InputSystem)
    
    // デバッグ入力
    #if DEBUG
    func inputSystemDebugKey1(_ inputSystem: InputSystem)
    func inputSystemDebugKey2(_ inputSystem: InputSystem)
    func inputSystemDebugKey3(_ inputSystem: InputSystem)
    #endif
}

// MARK: - デフォルト実装
extension InputSystemDelegate {
    func inputSystem(_ inputSystem: InputSystem, keyPressed keyCode: UInt16) {}
    func inputSystem(_ inputSystem: InputSystem, keyReleased keyCode: UInt16) {}
    func inputSystem(_ inputSystem: InputSystem, movementVector: CGVector) {}
    func inputSystemOfudaPressed(_ inputSystem: InputSystem) {}
    func inputSystemOfudaContinuous(_ inputSystem: InputSystem) {}
    func inputSystemOharaiPressed(_ inputSystem: InputSystem) {}
    func inputSystemOharaiContinuous(_ inputSystem: InputSystem) {}
    func inputSystemCrystalBallPressed(_ inputSystem: InputSystem) {}
    func inputSystemPausePressed(_ inputSystem: InputSystem) {}
    
    #if DEBUG
    func inputSystemDebugKey1(_ inputSystem: InputSystem) {}
    func inputSystemDebugKey2(_ inputSystem: InputSystem) {}
    func inputSystemDebugKey3(_ inputSystem: InputSystem) {}
    #endif
}

// MARK: - 入力設定管理
class InputSettings {
    static let shared = InputSettings()
    
    // キーコンフィグ
    private var keyBindings: [String: UInt16] = [
        "moveUp": InputSystem.KeyCodes.w,
        "moveDown": InputSystem.KeyCodes.s,
        "moveLeft": InputSystem.KeyCodes.a,
        "moveRight": InputSystem.KeyCodes.d,
        "ofuda": InputSystem.KeyCodes.space,
        "oharai": InputSystem.KeyCodes.z,
        "crystalBall": InputSystem.KeyCodes.x,
        "pause": InputSystem.KeyCodes.escape
    ]
    
    // 入力感度
    var movementSensitivity: CGFloat = 1.0
    var autoFireEnabled: Bool = false
    var autoFireRate: TimeInterval = 0.1
    
    private init() {
        loadSettings()
    }
    
    func getKeyCode(for action: String) -> UInt16? {
        return keyBindings[action]
    }
    
    func setKeyCode(_ keyCode: UInt16, for action: String) {
        keyBindings[action] = keyCode
        saveSettings()
    }
    
    private func loadSettings() {
        // UserDefaultsから設定を読み込み
        let defaults = UserDefaults.standard
        
        if let savedBindings = defaults.object(forKey: "keyBindings") as? [String: UInt16] {
            keyBindings = savedBindings
        }
        
        movementSensitivity = defaults.object(forKey: "movementSensitivity") as? CGFloat ?? 1.0
        autoFireEnabled = defaults.bool(forKey: "autoFireEnabled")
        autoFireRate = defaults.object(forKey: "autoFireRate") as? TimeInterval ?? 0.1
    }
    
    private func saveSettings() {
        // UserDefaultsに設定を保存
        let defaults = UserDefaults.standard
        
        defaults.set(keyBindings, forKey: "keyBindings")
        defaults.set(movementSensitivity, forKey: "movementSensitivity")
        defaults.set(autoFireEnabled, forKey: "autoFireEnabled")
        defaults.set(autoFireRate, forKey: "autoFireRate")
        
        defaults.synchronize()
    }
    
    func resetToDefaults() {
        keyBindings = [
            "moveUp": InputSystem.KeyCodes.w,
            "moveDown": InputSystem.KeyCodes.s,
            "moveLeft": InputSystem.KeyCodes.a,
            "moveRight": InputSystem.KeyCodes.d,
            "ofuda": InputSystem.KeyCodes.space,
            "oharai": InputSystem.KeyCodes.z,
            "crystalBall": InputSystem.KeyCodes.x,
            "pause": InputSystem.KeyCodes.escape
        ]
        
        movementSensitivity = 1.0
        autoFireEnabled = false
        autoFireRate = 0.1
        
        saveSettings()
    }
}

// MARK: - コンボシステム
class ComboSystem {
    private var comboSequence: [UInt16] = []
    private var lastInputTime: TimeInterval = 0
    private let comboTimeLimit: TimeInterval = 1.0
    
    // 特殊コンボの定義
    private let specialCombos: [[UInt16]] = [
        // 上上下下左右左右BA
        [InputSystem.KeyCodes.up, InputSystem.KeyCodes.up,
         InputSystem.KeyCodes.down, InputSystem.KeyCodes.down,
         InputSystem.KeyCodes.left, InputSystem.KeyCodes.right,
         InputSystem.KeyCodes.left, InputSystem.KeyCodes.right,
         InputSystem.KeyCodes.z, InputSystem.KeyCodes.space],
        
        // 無敵コマンド
        [InputSystem.KeyCodes.up, InputSystem.KeyCodes.left,
         InputSystem.KeyCodes.down, InputSystem.KeyCodes.right,
         InputSystem.KeyCodes.x]
    ]
    
    weak var delegate: ComboSystemDelegate?
    
    func registerInput(_ keyCode: UInt16) {
        let currentTime = CACurrentMediaTime()
        
        // タイムアウトチェック
        if currentTime - lastInputTime > comboTimeLimit {
            comboSequence.removeAll()
        }
        
        comboSequence.append(keyCode)
        lastInputTime = currentTime
        
        // コンボチェック
        checkCombos()
        
        // シーケンスが長すぎる場合は古いものを削除
        if comboSequence.count > 10 {
            comboSequence.removeFirst()
        }
    }
    
    private func checkCombos() {
        for (index, combo) in specialCombos.enumerated() {
            if comboSequence.suffix(combo.count).elementsEqual(combo) {
                delegate?.comboSystem(self, comboExecuted: index)
                comboSequence.removeAll()
                break
            }
        }
    }
    
    func reset() {
        comboSequence.removeAll()
        lastInputTime = 0
    }
}

// MARK: - ComboSystemDelegate プロトコル
protocol ComboSystemDelegate: AnyObject {
    func comboSystem(_ comboSystem: ComboSystem, comboExecuted comboIndex: Int)
}
