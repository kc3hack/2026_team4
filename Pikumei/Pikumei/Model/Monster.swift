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
    var classificationLabel: MonsterType?
    /// ML 確信度（未分類時は nil）
    var classificationConfidence: Double?
    /// 作成日時
    var createdAt: Date
    /// Supabase にアップロード済みの場合、そのレコード ID
    var supabaseId: UUID?
    /// ユーザーが付けたモンスター名
    var name: String?
    /// 交換で手に入れたモンスターかどうか
    var isExchanged: Bool = false
    /// 合体で生まれたモンスターかどうか（再合体不可）
    var isFused: Bool = false
    /// 合体後のステータス（合体モンスターのみ使用）
    var fusedHp: Int?
    var fusedAttack: Int?
    var fusedSpecialAttack: Int?
    var fusedSpecialDefense: Int?

    init(imageData: Data, classificationLabel: MonsterType? = nil, classificationConfidence: Double? = nil, createdAt: Date = .now, supabaseId: UUID? = nil, name: String? = nil, isExchanged: Bool = false, isFused: Bool = false, fusedHp: Int? = nil, fusedAttack: Int? = nil, fusedSpecialAttack: Int? = nil, fusedSpecialDefense: Int? = nil) {
        self.imageData = imageData
        self.classificationLabel = classificationLabel
        self.classificationConfidence = classificationConfidence
        self.createdAt = createdAt
        self.supabaseId = supabaseId
        self.name = name
        self.isExchanged = isExchanged
        self.isFused = isFused
        self.fusedHp = fusedHp
        self.fusedAttack = fusedAttack
        self.fusedSpecialAttack = fusedSpecialAttack
        self.fusedSpecialDefense = fusedSpecialDefense
    }
}

extension Monster {
    /// imageData → UIImage 変換
    var uiImage: UIImage? {
        UIImage(data: imageData)
    }

    /// UIImage から Monster を生成（PNG で透過保持）
    convenience init?(image: UIImage, classificationLabel: MonsterType? = nil, classificationConfidence: Double? = nil) {
        guard let data = image.pngData() else { return nil }
        self.init(imageData: data, classificationLabel: classificationLabel, classificationConfidence: classificationConfidence)
    }

    /// 合体済みならそのステータスを、そうでなければ BattleStatsGenerator で算出
    var battleStats: BattleStats {
        if isFused,
           let hp = fusedHp,
           let atk = fusedAttack,
           let spAtk = fusedSpecialAttack,
           let spDef = fusedSpecialDefense {
            return BattleStats(hp: hp, attack: atk, specialAttack: spAtk, specialDefense: spDef)
        }
        return BattleStatsGenerator.generate(
            label: classificationLabel,
            confidence: classificationConfidence
        )
    }
}
