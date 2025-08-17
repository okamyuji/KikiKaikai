import AVFoundation
import Foundation

class AudioSystem {
    static let shared = AudioSystem()
    
    // オーディオプレイヤー
    private var bgmPlayer: AVAudioPlayer?
    private var sfxPlayers: [String: AVAudioPlayer] = [:]
    private var audioEngine: AVAudioEngine
    
    // 設定
    private var isMusicEnabled: Bool = true
    private var isSFXEnabled: Bool = true
    private var musicVolume: Float = 0.7
    private var sfxVolume: Float = 0.8
    
    // 現在再生中のBGM
    private var currentBGM: String?
    private var bgmQueue: [String] = []
    
    init() {
        audioEngine = AVAudioEngine()
        setupAudioSession()
        loadDefaultSounds()
    }
    
    // MARK: - オーディオセッション設定
    
    private func setupAudioSession() {
        // macOSではAVAudioSessionは使用できないため、何もしない
        // 必要に応じてmacOS固有のオーディオ設定を行う
        print("オーディオシステム初期化完了")
    }
    
    // MARK: - デフォルト音声読み込み
    
    private func loadDefaultSounds() {
        // プログラムで生成した基本的な効果音を作成
        createDefaultSFX()
    }
    
    private func createDefaultSFX() {
        // 基本的な効果音をプログラムで生成
        let sampleRate: Double = 44100
        let duration: Double = 0.5
        
        // お札発射音
        createBeepSound(name: SoundNames.ofudaShoot, frequency: 800, duration: 0.2, volume: 0.3)
        
        // 御祓い棒音
        createBeepSound(name: SoundNames.oharaiSwing, frequency: 400, duration: 0.3, volume: 0.4)
        
        // 敵ヒット音
        createBeepSound(name: SoundNames.enemyHit, frequency: 600, duration: 0.1, volume: 0.3)
        
        // 敵破壊音
        createBeepSound(name: SoundNames.enemyDestroy, frequency: 300, duration: 0.4, volume: 0.4)
        
        // プレイヤーダメージ音
        createBeepSound(name: SoundNames.playerDamage, frequency: 200, duration: 0.6, volume: 0.5)
        
        // アイテム取得音
        createBeepSound(name: SoundNames.itemGet, frequency: 1000, duration: 0.3, volume: 0.4)
        
        // パワーアップ音
        createBeepSound(name: SoundNames.powerUp, frequency: 1200, duration: 0.5, volume: 0.4)
        
        // 水晶玉使用音
        createBeepSound(name: SoundNames.crystalBall, frequency: 500, duration: 1.0, volume: 0.4)
        
        // ステージクリア音
        createMelody(name: SoundNames.stageCleared)
        
        // ゲームオーバー音
        createGameOverSound(name: SoundNames.gameOver)
    }
    
    private func createBeepSound(name: String, frequency: Double, duration: Double, volume: Float) {
        let sampleRate: Double = 44100
        let sampleCount = Int(sampleRate * duration)
        
        // PCMバッファを作成
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(sampleCount)) else { return }
        
        buffer.frameLength = AVAudioFrameCount(sampleCount)
        
        // サイン波を生成
        let angularFrequency = 2.0 * Double.pi * frequency
        for i in 0..<sampleCount {
            let time = Double(i) / sampleRate
            let amplitude = Float(sin(angularFrequency * time)) * volume
            
            // エンベロープ（フェードアウト）を適用
            let envelope = 1.0 - Float(time / duration)
            buffer.floatChannelData?[0][i] = amplitude * envelope
        }
        
        // AVAudioPlayerを作成
        do {
            let data = bufferToData(buffer: buffer)
            let player = try AVAudioPlayer(data: data)
            player.prepareToPlay()
            sfxPlayers[name] = player
        } catch {
            print("音声作成エラー (\(name)): \(error)")
        }
    }
    
    private func createMelody(name: String) {
        // 簡単なメロディーを作成（ドレミファソ）
        let notes: [Double] = [523.25, 587.33, 659.25, 698.46, 783.99] // C5, D5, E5, F5, G5
        let noteDuration: Double = 0.3
        let totalDuration = Double(notes.count) * noteDuration
        
        let sampleRate: Double = 44100
        let sampleCount = Int(sampleRate * totalDuration)
        
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(sampleCount)) else { return }
        
        buffer.frameLength = AVAudioFrameCount(sampleCount)
        
        for (noteIndex, frequency) in notes.enumerated() {
            let noteStartSample = Int(Double(noteIndex) * noteDuration * sampleRate)
            let noteEndSample = min(noteStartSample + Int(noteDuration * sampleRate), sampleCount)
            
            let angularFrequency = 2.0 * Double.pi * frequency
            
            for i in noteStartSample..<noteEndSample {
                let time = Double(i - noteStartSample) / sampleRate
                let amplitude = Float(sin(angularFrequency * time)) * 0.3
                
                // エンベロープ
                let envelope = sin(Double.pi * time / noteDuration)
                buffer.floatChannelData?[0][i] = amplitude * Float(envelope)
            }
        }
        
        do {
            let data = bufferToData(buffer: buffer)
            let player = try AVAudioPlayer(data: data)
            player.prepareToPlay()
            sfxPlayers[name] = player
        } catch {
            print("メロディー作成エラー (\(name)): \(error)")
        }
    }
    
    private func createGameOverSound(name: String) {
        // 下降音階
        let notes: [Double] = [783.99, 698.46, 659.25, 587.33, 523.25, 466.16, 415.30] // G5→C5下降
        let noteDuration: Double = 0.4
        let totalDuration = Double(notes.count) * noteDuration
        
        let sampleRate: Double = 44100
        let sampleCount = Int(sampleRate * totalDuration)
        
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(sampleCount)) else { return }
        
        buffer.frameLength = AVAudioFrameCount(sampleCount)
        
        for (noteIndex, frequency) in notes.enumerated() {
            let noteStartSample = Int(Double(noteIndex) * noteDuration * sampleRate)
            let noteEndSample = min(noteStartSample + Int(noteDuration * sampleRate), sampleCount)
            
            let angularFrequency = 2.0 * Double.pi * frequency
            
            for i in noteStartSample..<noteEndSample {
                let time = Double(i - noteStartSample) / sampleRate
                let amplitude = Float(sin(angularFrequency * time)) * 0.4
                
                // 長いフェードアウト
                let envelope = 1.0 - Float(Double(noteIndex) / Double(notes.count))
                buffer.floatChannelData?[0][i] = amplitude * envelope
            }
        }
        
        do {
            let data = bufferToData(buffer: buffer)
            let player = try AVAudioPlayer(data: data)
            player.prepareToPlay()
            sfxPlayers[name] = player
        } catch {
            print("ゲームオーバー音作成エラー (\(name)): \(error)")
        }
    }
    
    private func bufferToData(buffer: AVAudioPCMBuffer) -> Data {
        let audioFormat = buffer.format
        let frameLength = buffer.frameLength
        
        var data = Data()
        
        // WAVヘッダーを作成
        let sampleRate = Int32(audioFormat.sampleRate)
        let channels = Int16(audioFormat.channelCount)
        let bitsPerSample: Int16 = 16
        let blockAlign = channels * bitsPerSample / 8
        let byteRate = sampleRate * Int32(blockAlign)
        let dataSize = Int32(frameLength) * Int32(blockAlign)
        let fileSize = 36 + dataSize
        
        // WAVヘッダー
        data.append("RIFF".data(using: .ascii)!)
        var fileSizeLE = fileSize.littleEndian
        data.append(Data(bytes: &fileSizeLE, count: 4))
        data.append("WAVE".data(using: .ascii)!)
        data.append("fmt ".data(using: .ascii)!)
        
        var fmtSize: Int32 = 16
        var fmtSizeLE = fmtSize.littleEndian
        data.append(Data(bytes: &fmtSizeLE, count: 4))
        
        var audioFormat16: Int16 = 1 // PCM
        var audioFormat16LE = audioFormat16.littleEndian
        data.append(Data(bytes: &audioFormat16LE, count: 2))
        var channelsLE = channels.littleEndian
        data.append(Data(bytes: &channelsLE, count: 2))
        var sampleRateLE = sampleRate.littleEndian
        data.append(Data(bytes: &sampleRateLE, count: 4))
        var byteRateLE = byteRate.littleEndian
        data.append(Data(bytes: &byteRateLE, count: 4))
        var blockAlignLE = blockAlign.littleEndian
        data.append(Data(bytes: &blockAlignLE, count: 2))
        var bitsPerSampleLE = bitsPerSample.littleEndian
        data.append(Data(bytes: &bitsPerSampleLE, count: 2))
        
        data.append("data".data(using: .ascii)!)
        var dataSizeLE = dataSize.littleEndian
        data.append(Data(bytes: &dataSizeLE, count: 4))
        
        // オーディオデータ
        if let channelData = buffer.floatChannelData?[0] {
            for i in 0..<Int(frameLength) {
                let sample = Int16(channelData[i] * Float(Int16.max))
                var sampleLE = sample.littleEndian
                data.append(Data(bytes: &sampleLE, count: 2))
            }
        }
        
        return data
    }
    
    // MARK: - BGM制御
    
    func playBGM(_ soundName: String, loop: Bool = true) {
        guard isMusicEnabled else { return }
        
        // 同じBGMが再生中の場合は何もしない
        if currentBGM == soundName && bgmPlayer?.isPlaying == true {
            return
        }
        
        stopBGM()
        
        // 実際のBGMファイルがある場合の処理
        if let path = Bundle.main.path(forResource: soundName, ofType: "mp3") {
            do {
                bgmPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
                bgmPlayer?.numberOfLoops = loop ? -1 : 0
                bgmPlayer?.volume = musicVolume
                bgmPlayer?.play()
                currentBGM = soundName
            } catch {
                print("BGM再生エラー (\(soundName)): \(error)")
                // フォールバック: シンプルなループBGMを生成
                createSimpleBGM(soundName)
            }
        } else {
            // BGMファイルが存在しない場合、シンプルなBGMを生成
            createSimpleBGM(soundName)
        }
    }
    
    private func createSimpleBGM(_ name: String) {
        // シンプルなアンビエント音楽を生成
        let melodyPatterns: [[Double]] = [
            [523.25, 659.25, 783.99, 659.25], // C-E-G-E
            [587.33, 698.46, 880.00, 698.46], // D-F-A-F
            [493.88, 622.25, 739.99, 622.25], // B-Eb-Gb-Eb
        ]
        
        let pattern = melodyPatterns.randomElement ?? melodyPatterns[0]
        createLoopingMelody(name: name, notes: pattern, tempo: 0.8)
    }
    
    private func createLoopingMelody(name: String, notes: [Double], tempo: Double) {
        let noteDuration = tempo
        let totalDuration = Double(notes.count) * noteDuration
        
        let sampleRate: Double = 44100
        let sampleCount = Int(sampleRate * totalDuration)
        
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(sampleCount)) else { return }
        
        buffer.frameLength = AVAudioFrameCount(sampleCount)
        
        for (noteIndex, frequency) in notes.enumerated() {
            let noteStartSample = Int(Double(noteIndex) * noteDuration * sampleRate)
            let noteEndSample = min(noteStartSample + Int(noteDuration * sampleRate), sampleCount)
            
            let angularFrequency = 2.0 * Double.pi * frequency
            
            for i in noteStartSample..<noteEndSample {
                let time = Double(i - noteStartSample) / sampleRate
                let amplitude = Float(sin(angularFrequency * time)) * 0.15 // 低音量
                
                // スムーズなエンベロープ
                let envelope = sin(Double.pi * time / noteDuration) * 0.8 + 0.2
                buffer.floatChannelData?[0][i] = amplitude * Float(envelope)
            }
        }
        
        do {
            let data = bufferToData(buffer: buffer)
            bgmPlayer = try AVAudioPlayer(data: data)
            bgmPlayer?.numberOfLoops = -1 // 無限ループ
            bgmPlayer?.volume = musicVolume * 0.5 // BGMは控えめに
            bgmPlayer?.play()
            currentBGM = name
        } catch {
            print("BGM作成エラー (\(name)): \(error)")
        }
    }
    
    func stopBGM() {
        bgmPlayer?.stop()
        bgmPlayer = nil
        currentBGM = nil
    }
    
    func pauseBGM() {
        bgmPlayer?.pause()
    }
    
    func resumeBGM() {
        bgmPlayer?.play()
    }
    
    func fadeBGM(to volume: Float, duration: TimeInterval) {
        guard let player = bgmPlayer else { return }
        
        let startVolume = player.volume
        let volumeChange = volume - startVolume
        let steps = 50
        let stepDuration = duration / Double(steps)
        
        for i in 0...steps {
            let delay = stepDuration * Double(i)
            let newVolume = startVolume + (volumeChange * Float(i) / Float(steps))
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                player.volume = newVolume
            }
        }
    }
    
    // MARK: - 効果音制御
    
    func playSFX(_ soundName: String) {
        guard isSFXEnabled else { return }
        
        if let player = sfxPlayers[soundName] {
            player.stop()
            player.currentTime = 0
            player.volume = sfxVolume
            player.play()
        } else {
            print("効果音が見つかりません: \(soundName)")
        }
    }
    
    func playSFXWithVariation(_ soundName: String, pitchVariation: Float = 0.2) {
        guard isSFXEnabled else { return }
        
        if let player = sfxPlayers[soundName] {
            player.stop()
            player.currentTime = 0
            player.volume = sfxVolume
            
            // ピッチの変更（簡易版）
            let rate = 1.0 + (Float.random(in: -pitchVariation...pitchVariation))
            player.rate = rate
            player.enableRate = true
            
            player.play()
        }
    }
    
    func stopAllSFX() {
        for player in sfxPlayers.values {
            player.stop()
        }
    }
    
    // MARK: - 音量制御
    
    func setMusicVolume(_ volume: Float) {
        musicVolume = max(0.0, min(1.0, volume))
        bgmPlayer?.volume = musicVolume
        saveSettings()
    }
    
    func setSFXVolume(_ volume: Float) {
        sfxVolume = max(0.0, min(1.0, volume))
        saveSettings()
    }
    
    func setMusicEnabled(_ enabled: Bool) {
        isMusicEnabled = enabled
        if !enabled {
            stopBGM()
        }
        saveSettings()
    }
    
    func setSFXEnabled(_ enabled: Bool) {
        isSFXEnabled = enabled
        if !enabled {
            stopAllSFX()
        }
        saveSettings()
    }
    
    // MARK: - 設定の保存・読み込み
    
    private func saveSettings() {
        UserDefaults.standard.set(isMusicEnabled, forKey: "AudioSystem.musicEnabled")
        UserDefaults.standard.set(isSFXEnabled, forKey: "AudioSystem.sfxEnabled")
        UserDefaults.standard.set(musicVolume, forKey: "AudioSystem.musicVolume")
        UserDefaults.standard.set(sfxVolume, forKey: "AudioSystem.sfxVolume")
    }
    
    private func loadSettings() {
        isMusicEnabled = UserDefaults.standard.object(forKey: "AudioSystem.musicEnabled") as? Bool ?? true
        isSFXEnabled = UserDefaults.standard.object(forKey: "AudioSystem.sfxEnabled") as? Bool ?? true
        musicVolume = UserDefaults.standard.object(forKey: "AudioSystem.musicVolume") as? Float ?? 0.7
        sfxVolume = UserDefaults.standard.object(forKey: "AudioSystem.sfxVolume") as? Float ?? 0.8
    }
    
    // MARK: - ゲーム固有の音響効果
    
    func playGameStartSound() {
        playSFX(SoundNames.stageCleared)
    }
    
    func playGameOverSound() {
        stopBGM()
        playSFX(SoundNames.gameOver)
    }
    
    func playStageChangeSound() {
        playSFX(SoundNames.stageCleared)
        
        // BGMを次のステージ用に変更
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.playBGM(SoundNames.stage1BGM) // 実際にはステージに応じて変更
        }
    }
    
    func playCrystalBallActivatedSound() {
        playSFX(SoundNames.crystalBall)
        
        // BGMを一時的に低下
        fadeBGM(to: musicVolume * 0.3, duration: 0.5)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + GameConstants.crystalBallDuration) {
            self.fadeBGM(to: self.musicVolume, duration: 1.0)
        }
    }
    
    // MARK: - オーディオリソース管理
    
    func preloadSounds(_ soundNames: [String]) {
        for soundName in soundNames {
            if sfxPlayers[soundName] == nil {
                // 音声ファイルの読み込みを試行
                if let path = Bundle.main.path(forResource: soundName, ofType: "wav") {
                    do {
                        let player = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
                        player.prepareToPlay()
                        sfxPlayers[soundName] = player
                    } catch {
                        print("音声読み込みエラー (\(soundName)): \(error)")
                    }
                }
            }
        }
    }
    
    func cleanupUnusedSounds() {
        // 使用されていない音声プレイヤーを削除
        sfxPlayers = sfxPlayers.filter { _, player in
            player.isPlaying
        }
    }
    
    deinit {
        stopBGM()
        stopAllSFX()
    }
}

// MARK: - 音響設定管理
class AudioSettings {
    static let shared = AudioSettings()
    
    var masterVolume: Float = 1.0 {
        didSet {
            AudioSystem.shared.setMusicVolume(musicVolume * masterVolume)
            AudioSystem.shared.setSFXVolume(sfxVolume * masterVolume)
        }
    }
    
    var musicVolume: Float = 0.7 {
        didSet {
            AudioSystem.shared.setMusicVolume(musicVolume * masterVolume)
        }
    }
    
    var sfxVolume: Float = 0.8 {
        didSet {
            AudioSystem.shared.setSFXVolume(sfxVolume * masterVolume)
        }
    }
    
    private init() {}
}
