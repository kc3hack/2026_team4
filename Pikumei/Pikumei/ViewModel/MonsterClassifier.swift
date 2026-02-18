//
//  MonsterClassifier.swift
//  Pikumei
//
//  Created by Daichi Sakai on 2026/02/18.
//

import UIKit
import CoreML
import Vision

/// モンスターのタイプ分類を行う
class MonsterClassifier {
    var label: String
    var confidence: Float
    
    init(label: String, confidence: Float) {
        self.label = label
        self.confidence = confidence
    }
    
    /// 画像を分類器に入力し、モンスタータイプと信頼度を返す
    func classify(from image: UIImage) throws -> (String, Float) {
        // モデルをロード
        let pikumeiClassifier = try? PikumeiClassifier(configuration: MLModelConfiguration())
        guard let pikumeiClassifier else {
            throw MonsterClassifierError.modelNotAvailable
        }
        let model = try? VNCoreMLModel(for: pikumeiClassifier.model)
        guard let model else {
            throw MonsterClassifierError.modelLoadingFailed
        }
        
        // リクエストを作成
        let request = VNCoreMLRequest(model: model, completionHandler: { (request, error) in
            guard let results = request.results as? [VNClassificationObservation] else {return}
            guard let first = results.first else {return}
            self.label = first.identifier
            self.confidence = first.confidence
        })
        
        // ハンドラーを作成
        let handler = VNImageRequestHandler(cgImage: image.cgImage!)
        do {
            try handler.perform([request])
        } catch {
            throw MonsterClassifierError.requestFailed
        }
        
        // 出力
        return (label, confidence)
    }
}

/// タイプ分類に関するエラー
enum MonsterClassifierError: LocalizedError {
    case modelNotAvailable
    case modelLoadingFailed
    case requestFailed
    
    var errorDescription: String? {
        switch self {
        case .modelNotAvailable:
            return "モデルが取得できませんでした"
        case .modelLoadingFailed:
            return "モデルのロードに失敗しました"
        case .requestFailed:
            return "リクエストに失敗しました"
        }
    }
}
