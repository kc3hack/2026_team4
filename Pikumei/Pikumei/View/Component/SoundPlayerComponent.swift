//
//  SoundPlayerComponent.swift
//  Pikumei
//

import AVFoundation
import UIKit

/// 効果音を再生するコンポーネント
final class SoundPlayerComponent {
    static let shared = SoundPlayerComponent()
    private var player: AVAudioPlayer?

    private init() {
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    func play(_ sound: Sound) {
        guard let asset = NSDataAsset(name: sound.rawValue) else { return }
        player = try? AVAudioPlayer(data: asset.data)
        player?.prepareToPlay()
        player?.play()
    }
}
