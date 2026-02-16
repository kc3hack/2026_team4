//
//  Monster.swift
//  Pikumei
//

import Foundation
import SwiftData
import UIKit

/// スキャンしたモンスターの永続化エンティティ
@Model
final class Monster {
    /// 切り抜き画像の PNG データ（外部ストレージで大容量対応）
    @Attribute(.externalStorage) var imageData: Data
    /// ML 分類ラベル（未分類時は nil）
    var classificationLabel: String?
    /// ML 確信度（未分類時は nil）
    var classificationConfidence: Double?
    /// 作成日時
    var createdAt: Date
    /// Supabase にアップロード済みの場合、そのレコード ID
    var supabaseId: UUID?

    init(imageData: Data, classificationLabel: String? = nil, classificationConfidence: Double? = nil, createdAt: Date = .now, supabaseId: UUID? = nil) {
        self.imageData = imageData
        self.classificationLabel = classificationLabel
        self.classificationConfidence = classificationConfidence
        self.createdAt = createdAt
        self.supabaseId = supabaseId
    }
}

extension Monster {
    /// imageData → UIImage 変換
    var uiImage: UIImage? {
        UIImage(data: imageData)
    }

    /// ラベルから決定論的に計算されるステータス
    var stats: MonsterStats? {
        guard let label = classificationLabel else { return nil }
        return MonsterStatsGenerator.generate(from: label)
    }

    /// UIImage から Monster を生成（PNG で透過保持）
    convenience init?(image: UIImage, classificationLabel: String? = nil, classificationConfidence: Double? = nil) {
        guard let data = image.pngData() else { return nil }
        self.init(imageData: data, classificationLabel: classificationLabel, classificationConfidence: classificationConfidence)
    }
}
