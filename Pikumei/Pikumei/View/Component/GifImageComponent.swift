//
//  GifImageComponent.swift
//  Pikumei
//

import SwiftUI
import UIKit
import ImageIO

/// GIFのフレームデータをキャッシュして高速に再生するためのストア
final class GifCacheStore {
    static let shared = GifCacheStore()
    private var cache: [String: (images: [UIImage], duration: Double)] = [:]

    private init() {}

    /// 指定したGIF名のフレームを事前読み込みする
    func preload(_ names: [String]) {
        for name in names where cache[name] == nil {
            cache[name] = decode(name: name)
        }
    }

    /// キャッシュからフレームを取得（なければその場でデコード）
    func frames(for name: String) -> (images: [UIImage], duration: Double)? {
        if let cached = cache[name] { return cached }
        let result = decode(name: name)
        cache[name] = result
        return result
    }

    private func decode(name: String) -> (images: [UIImage], duration: Double)? {
        guard let asset = NSDataAsset(name: name),
              let source = CGImageSourceCreateWithData(asset.data as CFData, nil) else {
            print("⚠️ GIF読み込み失敗: \(name)")
            return nil
        }

        let frameCount = CGImageSourceGetCount(source)
        var images: [UIImage] = []
        var duration: Double = 0

        for i in 0..<frameCount {
            if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(UIImage(cgImage: cgImage))
            }
            if let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [String: Any],
               let gif = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any],
               let delay = gif[kCGImagePropertyGIFDelayTime as String] as? Double {
                duration += delay
            }
        }

        return images.isEmpty ? nil : (images, duration)
    }
}

/// NSDataAssetからGIFアニメーションを再生するコンポーネント
struct GifImageComponent: UIViewRepresentable {
    let name: String
    var repeatCount: Int = 0   // 0 = 無限ループ, 1 = 1回だけ
    var speed: Double = 1.0    // 再生速度倍率（2.0 = 2倍速）

    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        loadGif(into: imageView)
        return imageView
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {}

    private func loadGif(into imageView: UIImageView) {
        guard let data = GifCacheStore.shared.frames(for: name) else { return }
        imageView.animationImages = data.images
        imageView.animationDuration = data.duration / speed
        imageView.animationRepeatCount = repeatCount
        imageView.startAnimating()
    }
}
