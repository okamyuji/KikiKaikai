import Cocoa
import SwiftUI

class GameController: NSObject {
    private var window: NSWindow!
    private var gameManager: GameManager!
    
    override init() {
        super.init()
        setupGame()
    }
    
    private func setupGame() {
        // ゲームマネージャーを初期化
        gameManager = GameManager()
        
        // ウィンドウを作成
        createWindow()
        
        print("奇々怪界ゲーム開始準備完了")
    }
    
    private func createWindow() {
        // ウィンドウのサイズと位置
        let windowSize = CGSize(width: 1024, height: 768)
        let screenFrame = NSScreen.main?.frame ?? CGRect.zero
        let windowFrame = CGRect(
            x: (screenFrame.width - windowSize.width) / 2,
            y: (screenFrame.height - windowSize.height) / 2,
            width: windowSize.width,
            height: windowSize.height
        )
        
        // ウィンドウを作成
        window = NSWindow(
            contentRect: windowFrame,
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "奇々怪界"
        window.isReleasedWhenClosed = false
        window.center()
        
        // SwiftUIビューをホスト
        let contentView = ContentView()
        let hostingView = NSHostingView(rootView: contentView)
        window.contentView = hostingView
        
        // ウィンドウデリゲートを設定
        window.delegate = self
    }
    
    func startGame() {
        // ウィンドウを表示
        window.makeKeyAndOrderFront(nil)
        
        // アプリケーションをアクティブにする
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - NSWindowDelegate
extension GameController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        // ウィンドウが閉じられる時の処理
        NSApplication.shared.terminate(nil)
    }
}