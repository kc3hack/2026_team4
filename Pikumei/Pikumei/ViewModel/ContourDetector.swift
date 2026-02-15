//
//  ContourDetector.swift
//  Pikumei
//

import UIKit
import Vision
import CoreImage

/// Subject Lifting API で前景を切り抜くユーティリティ
enum ContourDetector {

    /// 元画像から前景を自動セグメンテーションして切り抜いた画像を返す
    static func detectAndCutout(from image: UIImage) async throws -> UIImage {
        guard let cgImage = image.cgImage else {
            throw ContourError.invalidImage
        }

        // 1. VNGenerateForegroundInstanceMaskRequest で前景マスクを生成
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        guard let result = request.results?.first else {
            throw ContourError.noSubjectFound
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
            throw ContourError.processingFailed
        }

        // 元画像の向き情報を引き継ぐ（カメラ撮影時の回転を維持）
        return UIImage(cgImage: outputCG, scale: image.scale, orientation: image.imageOrientation)
    }
}

/// 切り抜き関連のエラー
enum ContourError: LocalizedError {
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
