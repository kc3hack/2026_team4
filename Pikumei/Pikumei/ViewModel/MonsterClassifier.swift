//
//  MonsterClassifier.swift
//  Pikumei
//
//  Created by Daichi Sakai on 2026/02/18.
//

import UIKit
import CoreML
import Vision

let GHOST_CONFIDENCE_THRESHOLD: Double = 0.5

let labelToMonsterType: [String: MonsterType] = [
    "fire": .fire,
    "water": .water,
    "leaf": .leaf,
    "ghost": .ghost,
    "human": .human,
    "fish": .fish,
    "bird": .bird,
]

/// モンスターのタイプ分類を行う
class MonsterClassifier {
    private var resultFound: Bool = false
    private var monsterType: MonsterType = .bird
    private var confidence: Double = 0.0
    private var request: VNRequest? = nil
    
    init() {
        self.request = try? self.setupRequest()
    }
    
    /// モデルを読み込み、リクエストを作成する
    private func setupRequest() throws -> VNRequest{
        // モデルをロード
        let pikumeiClassifier = try? PikumeiClassifier2(configuration: MLModelConfiguration())
        guard let pikumeiClassifier else {
            throw MonsterClassifierError.modelNotAvailable
        }
        let model = try? VNCoreMLModel(for: pikumeiClassifier.model)
        guard let model else {
            throw MonsterClassifierError.modelLoadingFailed
        }
        
        // リクエストを作成
        let request = VNCoreMLRequest(model: model, completionHandler: { (request, error) in
            self.resultFound = false
            guard let results = request.results as? [VNClassificationObservation] else {return}
            guard let first = results.first else {return}
            self.monsterType = labelToMonsterType[first.identifier]!
            self.confidence = Double(first.confidence)
            self.resultFound = true
        })
        return request
    }
    
    /// ゴーストタイプ判定
    private func isGhostType(confidence: Double) -> Bool {
        // 信頼度が閾値よりも低かったら、ゴーストタイプとなる
        return confidence <= GHOST_CONFIDENCE_THRESHOLD
    }
    
    /// ゴーストタイプへ変換する
    private func toGhostType(monsterType: MonsterType, confidence: Double) -> (MonsterType, Double) {
        let newMonsterType = MonsterType.ghost
        let newConfidence = 1.0 - confidence
        return (newMonsterType, newConfidence)
    }
    
    /// 画像を分類器に入力し、モンスタータイプと信頼度を返す
    func classify(image: UIImage) throws -> (MonsterType, Double) {
        guard let request else {
            throw MonsterClassifierError.requestNotFound
        }
        
        // ハンドラーを作成
        guard let cgImage = image.cgImage else {
            throw MonsterClassifierError.invalidImage
        }
        let handler = VNImageRequestHandler(cgImage: cgImage)
        do {
            try handler.perform([request])
        } catch {
            throw MonsterClassifierError.requestFailed
        }
        
        // 出力
        guard self.resultFound else {
            throw MonsterClassifierError.resultNotFound
        }
        print("[1] monsterType: \(self.monsterType), confidence: \(self.confidence * 100)%")
        if isGhostType(confidence: self.confidence) {
            (self.monsterType, self.confidence) = toGhostType(monsterType: self.monsterType, confidence: self.confidence)
        }
        print("[2] monsterType: \(self.monsterType), confidence: \(self.confidence * 100)%")
        
        return (self.monsterType, self.confidence)
    }
}

/// タイプ分類に関するエラー
enum MonsterClassifierError: LocalizedError {
    case modelNotAvailable
    case modelLoadingFailed
    case requestNotFound
    case invalidImage
    case requestFailed
    case resultNotFound
    
    var errorDescription: String? {
        switch self {
        case .modelNotAvailable:
            return "モデルが取得できませんでした"
        case .modelLoadingFailed:
            return "モデルのロードに失敗しました"
        case .requestNotFound:
            return "リクエストが見つかりませんでした"
        case .invalidImage:
            return "不正な画像です"
        case .requestFailed:
            return "リクエストに失敗しました"
        case .resultNotFound:
            return "結果が見つかりませんでした"
        }
    }
}
