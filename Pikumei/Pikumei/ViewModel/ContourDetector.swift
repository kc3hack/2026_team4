//
//  ContourDetector.swift
//  Pikumei
//

import UIKit
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

/// CIFilter 前処理 + Vision 輪郭検出 + マスク切り抜きを行うユーティリティ
enum ContourDetector {

    /// 元画像から輪郭を検出し、切り抜いた画像を返す
    nonisolated static func detectAndCutout(from image: UIImage) async throws -> UIImage {
        guard let ciImage = CIImage(image: image) else {
            throw ContourError.invalidImage
        }

        let context = CIContext()

        // 1. グレースケール化
        let grayscale = ciImage.applyingFilter("CIColorControls", parameters: [
            kCIInputSaturationKey: 0.0
        ])

        // 2. 二値化
        let binary = grayscale.applyingFilter("CIColorThreshold", parameters: [
            "inputThreshold": 0.3
        ])

        // 3. CGImage に変換（Vision で使うため）
        guard let binaryCG = context.createCGImage(binary, from: binary.extent) else {
            throw ContourError.processingFailed
        }

        // 4. Vision 輪郭検出
        let contours = try detectContours(in: binaryCG)

        guard let largestContour = findLargestContour(from: contours) else {
            throw ContourError.noContourFound
        }

        // 5. マスク画像を生成（元画像と同じピクセルサイズで）
        let imageSize = CGSize(width: binaryCG.width, height: binaryCG.height)
        let maskImage = renderMask(contour: largestContour, size: imageSize)

        guard let maskCI = CIImage(image: maskImage) else {
            throw ContourError.processingFailed
        }

        // 6. CIBlendWithMask で切り抜き
        let blended = ciImage.applyingFilter("CIBlendWithMask", parameters: [
            kCIInputMaskImageKey: maskCI
        ])

        guard let outputCG = context.createCGImage(blended, from: blended.extent) else {
            throw ContourError.processingFailed
        }

        return UIImage(cgImage: outputCG)
    }

    // MARK: - Private

    /// Vision で輪郭を検出
    private nonisolated static func detectContours(in cgImage: CGImage) throws -> [VNContour] {
        let request = VNDetectContoursRequest()
        request.contrastAdjustment = 1.0
        request.detectsDarkOnLight = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        guard let result = request.results?.first else {
            throw ContourError.noContourFound
        }

        return result.topLevelContours
    }

    /// 最も大きい輪郭を選択（点の数が最も多い輪郭）
    private nonisolated static func findLargestContour(from contours: [VNContour]) -> VNContour? {
        contours.max(by: { $0.pointCount < $1.pointCount })
    }

    /// VNContour の normalizedPath からマスク画像を生成
    private nonisolated static func renderMask(contour: VNContour, size: CGSize) -> UIImage {
        // scale = 1.0 で元画像と同じピクセルサイズにする（デバイススケールを使わない）
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { ctx in
            let cgContext = ctx.cgContext

            // 背景を黒で塗りつぶし
            cgContext.setFillColor(UIColor.black.cgColor)
            cgContext.fill(CGRect(origin: .zero, size: size))

            // Vision の normalizedPath は左下原点・0〜1 の正規化座標
            // UIGraphicsImageRenderer の CGContext は左上原点なので Y を反転
            cgContext.saveGState()
            cgContext.translateBy(x: 0, y: size.height)
            cgContext.scaleBy(x: size.width, y: -size.height)

            // マスク部分を白で塗りつぶし
            cgContext.setFillColor(UIColor.white.cgColor)
            cgContext.addPath(contour.normalizedPath)
            cgContext.fillPath()

            cgContext.restoreGState()
        }
    }
}

/// 輪郭検出関連のエラー
enum ContourError: LocalizedError {
    case invalidImage
    case processingFailed
    case noContourFound

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "画像の読み込みに失敗しました"
        case .processingFailed:
            return "画像処理に失敗しました"
        case .noContourFound:
            return "輪郭を検出できませんでした"
        }
    }
}
