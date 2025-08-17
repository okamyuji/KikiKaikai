import Foundation
import SpriteKit
import SwiftUI

// MARK: - CGPoint Extensions
extension CGPoint {
    // ベクトル演算
    static func + (left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x + right.x, y: left.y + right.y)
    }
    
    static func - (left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x - right.x, y: left.y - right.y)
    }
    
    static func * (point: CGPoint, scalar: CGFloat) -> CGPoint {
        return CGPoint(x: point.x * scalar, y: point.y * scalar)
    }
    
    // 距離計算
    func distance(to point: CGPoint) -> CGFloat {
        return GameConstants.distance(from: self, to: point)
    }
    
    // 方向ベクトル
    func direction(to point: CGPoint) -> CGVector {
        let diff = point - self
        return GameConstants.normalizeVector(CGVector(dx: diff.x, dy: diff.y))
    }
    
    // 角度計算（ラジアン）
    func angle(to point: CGPoint) -> CGFloat {
        let diff = point - self
        return atan2(diff.y, diff.x)
    }
    
    // 画面境界内に制限
    func clamped(to rect: CGRect) -> CGPoint {
        return CGPoint(
            x: max(rect.minX, min(rect.maxX, self.x)),
            y: max(rect.minY, min(rect.maxY, self.y))
        )
    }
}

// MARK: - CGVector Extensions
extension CGVector {
    // 長さ
    var length: CGFloat {
        return sqrt(dx * dx + dy * dy)
    }
    
    // 正規化
    var normalized: CGVector {
        return GameConstants.normalizeVector(self)
    }
    
    // スカラー乗算
    static func * (vector: CGVector, scalar: CGFloat) -> CGVector {
        return CGVector(dx: vector.dx * scalar, dy: vector.dy * scalar)
    }
    
    // ベクトル加算
    static func + (left: CGVector, right: CGVector) -> CGVector {
        return CGVector(dx: left.dx + right.dx, dy: left.dy + right.dy)
    }
    
    // ベクトル減算
    static func - (left: CGVector, right: CGVector) -> CGVector {
        return CGVector(dx: left.dx - right.dx, dy: left.dy - right.dy)
    }
}

// MARK: - SKNode Extensions
extension SKNode {
    // 安全な子ノード削除
    func removeAllChildrenSafely() {
        for child in children {
            child.removeFromParent()
        }
    }
    
    // 特定タイプの子ノードを取得
    func childNodes<T: SKNode>(ofType type: T.Type) -> [T] {
        return children.compactMap { $0 as? T }
    }
    
    // アニメーション実行（完了コールバック付き）
    func runAction(_ action: SKAction, withKey key: String, completion: @escaping () -> Void) {
        let sequenceAction = SKAction.sequence([action, SKAction.run(completion)])
        run(sequenceAction, withKey: key)
    }
    
    // 画面境界チェック
    var isOnScreen: Bool {
        return GameConstants.isWithinBounds(position, margin: 50)
    }
}

// MARK: - SKSpriteNode Extensions
extension SKSpriteNode {
    // 便利なイニシャライザ
    convenience init(color: SKColor, size: CGSize, position: CGPoint) {
        self.init(color: color, size: size)
        self.position = position
    }
    
    // テクスチャからのイニシャライザ
    convenience init(imageNamed name: String, size: CGSize, position: CGPoint) {
        self.init(imageNamed: name)
        self.size = size
        self.position = position
    }
    
    // 境界矩形
    var boundingBox: CGRect {
        return CGRect(
            x: position.x - size.width / 2,
            y: position.y - size.height / 2,
            width: size.width,
            height: size.height
        )
    }
    
    // 衝突判定設定
    func setupPhysics(category: UInt32, contact: UInt32 = 0, collision: UInt32 = 0, isDynamic: Bool = true) {
        physicsBody = SKPhysicsBody(rectangleOf: size)
        physicsBody?.categoryBitMask = category
        physicsBody?.contactTestBitMask = contact
        physicsBody?.collisionBitMask = collision
        physicsBody?.isDynamic = isDynamic
        physicsBody?.affectedByGravity = false
        physicsBody?.allowsRotation = false
    }
}

// MARK: - SKAction Extensions
extension SKAction {
    // フェードイン・アウト
    static func fadeInOut(duration: TimeInterval) -> SKAction {
        return sequence([
            fadeOut(withDuration: duration / 2),
            fadeIn(withDuration: duration / 2)
        ])
    }
    
    // 点滅効果
    static func blink(times: Int, duration: TimeInterval) -> SKAction {
        let blinkAction = fadeInOut(duration: duration / TimeInterval(times))
        return SKAction.repeat(blinkAction, count: times)
    }
    
    // バウンス効果
    static func bounce(scaleValue: CGFloat, duration: TimeInterval) -> SKAction {
        return sequence([
            SKAction.scale(to: scaleValue, duration: duration / 2),
            SKAction.scale(to: 1.0, duration: duration / 2)
        ])
    }
    
    // 震え効果
    static func shake(intensity: CGFloat, duration: TimeInterval) -> SKAction {
        let moveCount = 10
        var moveActions: [SKAction] = []
        
        for _ in 0..<moveCount {
            let moveAction = moveBy(
                x: CGFloat.random(in: -intensity...intensity),
                y: CGFloat.random(in: -intensity...intensity),
                duration: duration / Double(moveCount)
            )
            moveActions.append(moveAction)
        }
        
        moveActions.append(moveBy(x: 0, y: 0, duration: 0))
        return sequence(moveActions)
    }
}

// MARK: - TimeInterval Extensions
extension TimeInterval {
    // フレーム数に変換
    var frames: Int {
        return Int(self * GameConstants.targetFPS)
    }
    
    // ミリ秒に変換
    var milliseconds: Int {
        return Int(self * 1000)
    }
}

// MARK: - Array Extensions
extension Array {
    // 安全な要素アクセス
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
    
    // ランダム要素取得
    var randomElement: Element? {
        guard !isEmpty else { return nil }
        return self[Int.random(in: 0..<count)]
    }
}

// MARK: - Angle Extensions
extension CGFloat {
    // 度数からラジアンに変換
    var degreesToRadians: CGFloat {
        return self * .pi / 180
    }
    
    // ラジアンから度数に変換
    var radiansToDegrees: CGFloat {
        return self * 180 / .pi
    }
    
    // 角度の正規化（0〜2π）
    var normalizedAngle: CGFloat {
        let twoPi = 2 * CGFloat.pi
        var angle = self
        while angle < 0 { angle += twoPi }
        while angle >= twoPi { angle -= twoPi }
        return angle
    }
}

// MARK: - Color Extensions
extension SKColor {
    // 便利なカラー作成
    convenience init(red: Int, green: Int, blue: Int, alpha: CGFloat = 1.0) {
        self.init(
            red: CGFloat(red) / 255.0,
            green: CGFloat(green) / 255.0,
            blue: CGFloat(blue) / 255.0,
            alpha: alpha
        )
    }
    
    // ランダムカラー
    static var random: SKColor {
        return SKColor(
            red: CGFloat.random(in: 0...1),
            green: CGFloat.random(in: 0...1),
            blue: CGFloat.random(in: 0...1),
            alpha: 1.0
        )
    }
}

// MARK: - Debug Extensions
extension SKNode {
    // デバッグ用境界ボックス表示
    func showBoundingBox(color: SKColor = .red) {
        #if DEBUG
        if let sprite = self as? SKSpriteNode {
            let box = SKShapeNode(rect: CGRect(
                x: -sprite.size.width / 2,
                y: -sprite.size.height / 2,
                width: sprite.size.width,
                height: sprite.size.height
            ))
            box.strokeColor = color
            box.lineWidth = 1
            box.fillColor = .clear
            box.name = "debugBoundingBox"
            box.zPosition = 1000
            addChild(box)
        }
        #endif
    }
    
    // デバッグ境界ボックス削除
    func hideBoundingBox() {
        childNode(withName: "debugBoundingBox")?.removeFromParent()
    }
}

// MARK: - Performance Extensions
extension SKNode {
    // 再帰的なノード数カウント
    var nodeCount: Int {
        return 1 + children.reduce(0) { count, node in
            return count + node.nodeCount
        }
    }
}
