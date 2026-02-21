//
//  SubjectDetector.swift
//  Pikumei
//

import UIKit
import Vision
import CoreImage

/// Subject Lifting API で前景を切り抜くユーティリティ
enum SubjectDetector {

    /// 元画像から前景を自動セグメンテーションして切り抜いた画像を返す
    static func detectAndCutout(from image: UIImage) async throws -> UIImage {
        guard let cgImage = image.cgImage else {
            throw SubjectDetectorError.invalidImage
        }

        // 1. VNGenerateForegroundInstanceMaskRequest で前景マスクを生成
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        guard let result = request.results?.first else {
            throw SubjectDetectorError.noSubjectFound
        }

        // 2. マスクを元画像サイズの CVPixelBuffer として取得
        let maskBuffer = try result.generateScaledMaskForImage(
            forInstances: result.allInstances,
            from: handler
        )

        // 3. マスクで元画像を切り抜き
        let ciImage = CIImage(cgImage: cgImage)
        let maskCI = CIImage(cvPixelBuffer: maskBuffer)

        let context = CIContext()

        let blended = ciImage.applyingFilter("CIBlendWithMask", parameters: [
            kCIInputMaskImageKey: maskCI
        ])

        guard let outputCG = context.createCGImage(blended, from: blended.extent) else {
            throw SubjectDetectorError.processingFailed
        }

        // 4. 透過領域をトリミングして被写体だけの画像にする
        let trimmed = trimTransparentArea(outputCG) ?? outputCG

        // 元画像の向き情報を引き継ぐ（カメラ撮影時の回転を維持）
        return UIImage(cgImage: trimmed, scale: image.scale, orientation: image.imageOrientation)
    }

    /// 不透明ピクセルの最小矩形でクロップし、透過余白を除去する
    private static func trimTransparentArea(_ cgImage: CGImage) -> CGImage? {
        let width = cgImage.width
        let height = cgImage.height

        guard let data = cgImage.dataProvider?.data,
              let ptr = CFDataGetBytePtr(data) else { return nil }

        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let bytesPerRow = cgImage.bytesPerRow

        // アルファチャンネルの位置を特定
        let alphaInfo = cgImage.alphaInfo
        let alphaOffset: Int
        switch alphaInfo {
        case .premultipliedFirst, .first, .noneSkipFirst:
            alphaOffset = 0
        case .premultipliedLast, .last, .noneSkipLast:
            alphaOffset = bytesPerPixel - 1
        default:
            return nil
        }

        var minX = width, minY = height, maxX = 0, maxY = 0

        for y in 0..<height {
            for x in 0..<width {
                let offset = y * bytesPerRow + x * bytesPerPixel + alphaOffset
                if ptr[offset] > 0 {
                    minX = min(minX, x)
                    minY = min(minY, y)
                    maxX = max(maxX, x)
                    maxY = max(maxY, y)
                }
            }
        }

        guard minX <= maxX, minY <= maxY else { return nil }

        // 少し余白を残す（被写体がギリギリにならないように）
        let padding = Int(Double(max(maxX - minX, maxY - minY)) * 0.05)
        let cropRect = CGRect(
            x: max(0, minX - padding),
            y: max(0, minY - padding),
            width: min(width - max(0, minX - padding), maxX - minX + 1 + padding * 2),
            height: min(height - max(0, minY - padding), maxY - minY + 1 + padding * 2)
        )

        return cgImage.cropping(to: cropRect)
    }
}

/// 切り抜き関連のエラー
enum SubjectDetectorError: LocalizedError {
    case invalidImage
    case processingFailed
    case noSubjectFound

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "画像の読み込みに失敗しました"
        case .processingFailed:
            return "画像処理に失敗しました"
        case .noSubjectFound:
            return "対象物を検出できませんでした"
        }
    }
}
