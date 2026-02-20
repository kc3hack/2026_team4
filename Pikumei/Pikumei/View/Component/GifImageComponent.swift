//
//  GifImageComponent.swift
//  Pikumei
//

import SwiftUI
import UIKit
import ImageIO

/// NSDataAssetからGIFアニメーションを再生するコンポーネント
struct GifImageComponent: UIViewRepresentable {
    let name: String
    var repeatCount: Int = 0  // 0 = 無限ループ, 1 = 1回だけ

    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        loadGif(into: imageView)
        return imageView
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {}

    private func loadGif(into imageView: UIImageView) {
        guard let asset = NSDataAsset(name: name),
              let source = CGImageSourceCreateWithData(asset.data as CFData, nil) else { return }

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

        imageView.animationImages = images
        imageView.animationDuration = duration
        imageView.animationRepeatCount = repeatCount
        imageView.startAnimating()
    }
}
