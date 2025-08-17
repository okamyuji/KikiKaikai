import SwiftUI
import SpriteKit

struct ContentView: View {
    @StateObject private var gameManager = GameManager()
    @State private var showMenu = true
    
    var body: some View {
        ZStack {
            if showMenu {
                MainMenuView(gameManager: gameManager, showMenu: $showMenu)
            } else {
                GameView(gameManager: gameManager, showMenu: $showMenu)
            }
        }
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}

struct MainMenuView: View {
    @ObservedObject var gameManager: GameManager
    @Binding var showMenu: Bool
    
    var body: some View {
        VStack(spacing: 30) {
            Text("奇々怪界")
                .font(.system(size: 72, weight: .bold, design: .serif))
                .foregroundColor(.white)
                .shadow(color: .red, radius: 3, x: 2, y: 2)
            
            Text("KIKI KAIKAI")
                .font(.system(size: 24, weight: .medium, design: .monospaced))
                .foregroundColor(.gray)
            
            VStack(spacing: 20) {
                MenuButton(title: "ゲーム開始", action: {
                    gameManager.startNewGame()
                    showMenu = false
                })
                
                MenuButton(title: "設定", action: {
                    // 設定画面（未実装）
                })
                
                MenuButton(title: "終了", action: {
                    NSApplication.shared.terminate(nil)
                })
            }
            .padding(.top, 50)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [.purple.opacity(0.3), .black]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

struct MenuButton: View {
    let title: String
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(isHovered ? .yellow : .white)
                .padding(.horizontal, 40)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isHovered ? Color.yellow : Color.gray, lineWidth: 2)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(isHovered ? Color.yellow.opacity(0.1) : Color.clear)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct GameView: View {
    @ObservedObject var gameManager: GameManager
    @Binding var showMenu: Bool
    
    var gameScene: GameScene {
        let scene = GameScene(gameManager: gameManager)
        scene.size = CGSize(width: 1024, height: 768)
        scene.scaleMode = .aspectFit
        return scene
    }
    
    var body: some View {
        ZStack {
            SpriteView(scene: gameScene)
                .frame(width: 1024, height: 768)
                .clipped()
            
            // UI オーバーレイ
            VStack {
                HStack {
                    // 体力表示
                    HStack(spacing: 5) {
                        ForEach(0..<gameManager.maxHealth, id: \.self) { index in
                            Image(systemName: index < gameManager.currentHealth ? "heart.fill" : "heart")
                                .foregroundColor(index < gameManager.currentHealth ? .red : .gray)
                                .font(.title2)
                        }
                    }
                    
                    Spacer()
                    
                    // スコア表示
                    Text("SCORE: \(gameManager.score)")
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 1, x: 1, y: 1)
                    
                    Spacer()
                    
                    // 水晶玉残数
                    HStack(spacing: 5) {
                        Image(systemName: "circle.fill")
                            .foregroundColor(.blue)
                        Text("\(gameManager.crystalBalls)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                Spacer()
            }
            
            // ゲームオーバー画面
            if gameManager.gameState == .gameOver {
                GameOverView(gameManager: gameManager, showMenu: $showMenu)
            }
        }
        .background(Color.black)
        .onAppear {
            // キーボード入力の代替処理が必要な場合はここに追加
        }
    }
}

struct GameOverView: View {
    @ObservedObject var gameManager: GameManager
    @Binding var showMenu: Bool
    
    var body: some View {
        VStack(spacing: 30) {
            Text("GAME OVER")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.red)
                .shadow(color: .black, radius: 2, x: 2, y: 2)
            
            Text("SCORE: \(gameManager.score)")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
            
            HStack(spacing: 30) {
                MenuButton(title: "リトライ", action: {
                    gameManager.startNewGame()
                })
                
                MenuButton(title: "メニューに戻る", action: {
                    showMenu = true
                })
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.8))
    }
}

#Preview {
    ContentView()
}
