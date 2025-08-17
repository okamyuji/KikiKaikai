# macOS Game Prototype

## 概要

macOS向けプロトタイプアクションシューティングゲームです。Swift Package ManagerとSpriteKitを使用して開発された学習・実験用の基本的な2Dシューティングゲームです。

## 特徴

### ゲームプレイ

- **8方向移動**: WASDキーまたは矢印キーでスムーズな移動
- **2つの攻撃方法**: お札（遠距離弾丸）と御祓い棒（近距離攻撃）
- **水晶玉システム**: 敵を一時停止させる特殊能力
- **基本的なパワーアップ**: ダメージ、スピード、貫通の3種類
- **スコアシステム**: 敵撃破によるスコア獲得

### システム

- **プロトタイプグラフィック**: 色付きの基本図形で構成
- **基本的な衝突検出**: SpriteKitの物理エンジンを使用
- **シンプルなエフェクト**: パーティクル効果
- **完全Swift実装**: SwiftUI + SpriteKit + Cocoa

### 現在の実装状況

- ✅ 基本的なプレイヤー移動（白い四角形）
- ✅ 4種類の敵キャラクター（色付き図形）
- ✅ お札と御祓い棒の攻撃システム
- ✅ アイテムシステム（体力回復、パワーアップ等）
- ✅ スコアシステム
- ✅ 基本的なUI（SwiftUI）
- ❌ BGM・効果音（フレームワークのみ実装）
- ❌ 本格的なグラフィック
- ❌ ステージ進行システム
- ❌ ボス戦

## 必要システム

- **macOS**: 12.0 以上
- **メモリ**: 2GB以上
- **ストレージ**: 50MB以上
- **GPU**: Metal対応

## インストール・実行方法

### Swift Package Managerでビルド・実行

```bash
# リポジトリをクローン
git clone [repository-url]
cd KikiKaikai

# ビルド
swift build

# 実行（GUIアプリとして起動）
./.build/debug/KikiKaikai
```

> **注意**: XcodeプロジェクトファイルやSwift Package ManagerのGUIモードは現在非対応です。

## 操作方法

### 基本操作

- **移動**: WASDキーまたは矢印キー
- **お札攻撃**: スペースキー（連打可能）
- **御祓い棒**: Zキー（近距離範囲攻撃）
- **水晶玉**: Xキー（敵一時停止・回数制限あり）
- **ポーズ**: Escキー

### デバッグキー（DEBUG版のみ）

- **F1**: デバッグ情報表示切り替え
- **F2**: 衝突ボックス表示切り替え
- **F3**: 全敵削除

### ゲームシステム

- **体力**: 3ポイント（敵との接触で減少）
- **スコア**: 敵撃破で獲得
- **アイテム**: 敵撃破時にランダムドロップ
    - コイン（スコア）
    - ハート（体力回復）
    - 水晶玉（補充）
    - パワーアップ（攻撃力・速度・貫通）

## ゲーム仕様

### 登場敵キャラクター

現在実装されている敵は基本的な色付き図形です：

1. **人魂（Hitodama）**: 紫色の円、プレイヤーを追跡
2. **化け提灯（BakeChouchin）**: 赤色の四角形、弾丸発射
3. **ろくろ首（Rokurokubi）**: 緑色の四角形、突進攻撃
4. **留無留（Rumuru）**: 紫色の小さな円、プレイヤーに取り憑く

### プレイヤーキャラクター

- 白色の32x32ピクセルの四角形
- 体力3ポイント
- 8方向移動可能
- 2種類の攻撃方法

## アーキテクチャ

### 技術スタック

- **Swift 5.9+**
- **Cocoa**: ウィンドウ管理
- **SwiftUI**: UI管理
- **SpriteKit**: ゲームエンジン・2D描画
- **Foundation**: 基本システム

### プロジェクト構造

```text
Sources/KikiKaikai/
├── main.swift              # エントリーポイント
├── GameController.swift    # ゲーム制御
├── App/                    # SwiftUIアプリケーション
│   └── ContentView.swift
├── Game/                   # ゲームコア
│   ├── GameManager.swift
│   └── GameScene.swift
├── Entities/               # ゲームオブジェクト
│   ├── Player.swift
│   ├── Enemy.swift
│   └── Item.swift
├── Systems/                # ゲームシステム
│   ├── InputSystem.swift
│   ├── CollisionSystem.swift
│   ├── ScoreSystem.swift
│   └── AudioSystem.swift
├── Utils/                  # ユーティリティ
│   ├── Constants.swift
│   ├── Extensions.swift
│   ├── AssetManager.swift
│   └── ScoreDisplay.swift
└── Resources/              # リソースファイル（情報のみ）
```

### 設計パターン

- **Delegate Pattern**: システム間通信
- **Observer Pattern**: 状態変更通知
- **Singleton Pattern**: AudioSystem、ScoreSystem
- **Component Pattern**: エンティティシステム

## 開発・デバッグ

### ビルド

```bash
# デバッグビルド（デフォルト）
swift build

# リリースビルド
swift build -c release

# 詳細ログ付きビルド
swift build -v
```

### 実行

```bash
# 通常実行
./.build/debug/KikiKaikai

# リリース版実行
./.build/release/KikiKaikai
```

### ログ出力

- ゲーム開始・終了
- 敵生成・撃破
- アイテム取得
- スコア変化
- エラー情報

## トラブルシューティング

### よくある問題

**Q: ビルドエラーが発生する**
A:

```bash
# キャッシュクリア
swift package reset
swift package resolve
swift build
```

**Q: ウィンドウが表示されない**
A:

- ターミナルから直接実行しているか確認
- macOSのセキュリティ設定を確認

**Q: キー入力が効かない**
A:

- ゲームウィンドウがアクティブか確認
- 他のアプリケーションとのキーコンフリクトを確認

**Q: 動作が重い**
A:

- Activity Monitorでメモリ使用量を確認
- 他のアプリケーションを終了

## 学習ポイント

このプロジェクトから学べる技術要素：

- **Swift Package Manager**: CLIベースでのSwiftアプリケーション開発
- **Cocoa**: NSApplicationとNSWindowを使用したネイティブアプリ
- **SpriteKit**: 2Dゲーム開発の基礎
- **SwiftUI**: モダンなUI作成
- **物理エンジン**: 衝突検出システム
- **ゲームアーキテクチャ**: ECS的な設計パターン

## 今後の改善案

### 基本機能

- [ ] 本格的なグラフィック（スプライト画像）
- [ ] BGM・効果音の実装
- [ ] ステージ制システム
- [ ] ボス戦の実装
- [ ] セーブ・ロード機能

### ゲームプレイ

- [ ] 難易度選択
- [ ] より多様な敵キャラクター
- [ ] 特殊武器・アイテム
- [ ] ミニマップ
- [ ] チュートリアルモード

### 技術的改善

- [ ] パフォーマンス最適化
- [ ] メモリ使用量削減
- [ ] オブジェクトプーリング
- [ ] マルチスレッド対応
- [ ] ユニットテスト

## ライセンス

MIT License

## クレジット

- **Original Game Inspiration**: Taito Corporation (1986)
- **Development**: Swift学習プロジェクト
- **Architecture**: SpriteKit + SwiftUI + Cocoa

---

**重要**: このプロジェクトは学習・実験目的で作成されたプロトタイプです。

## 変更履歴

### Version 0.1.0 (2025)

- プロトタイプ版リリース
- 基本ゲームプレイ実装
- 4種類の敵キャラクター
- 基本的なアイテムシステム
- SwiftUI + SpriteKitアーキテクチャ
- Swift Package Manager対応
