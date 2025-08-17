import Cocoa
import SwiftUI

// KikiKaikai - メインエントリーポイント

let app = NSApplication.shared
app.setActivationPolicy(.regular)

// ゲームコントローラーを作成して起動
let gameController = GameController()
gameController.startGame()

// アプリケーションを実行
app.run()
