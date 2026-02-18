//
//  BattleStatsGenerator.swift
//  Pikumei
//
//  classificationLabel + confidence から BattleStats を生成するロジック
//

import Foundation

enum BattleStatsGenerator {

    private static let hpRange = 80...180
    private static let attackRange = 15...55

    /// label + confidence からステータスを生成（nil 時はランダム fallback）
    static func generate(label: String?, confidence: Double?) -> BattleStats {
        guard let label, let confidence else {
            // ML 未実装 or 分類失敗 → ランダム
            return BattleStats(
                hp: Int.random(in: hpRange),
                attack: Int.random(in: attackRange)
            )
        }

        // label の hash で 0.0〜1.0 の決定的な値を作る（同じラベル → 同じ個性）
        let seed = normalizedHash(label)

        // confidence が高いほど強くなるよう、base を confidence で底上げする
        let clampedConf = min(max(confidence, 0), 1)

        // seed で個体差、confidence で全体的な強さを決める
        let hp = stat(in: hpRange, seed: seed, confidence: clampedConf)
        let attack = stat(in: attackRange, seed: seed * 0.7 + 0.3, confidence: clampedConf)

        return BattleStats(hp: hp, attack: attack)
    }

    // MARK: - Private

    /// label 文字列を 0.0〜1.0 に写す決定的ハッシュ
    private static func normalizedHash(_ label: String) -> Double {
        var h: UInt64 = 5381
        for byte in label.utf8 {
            h = h &* 33 &+ UInt64(byte)
        }
        return Double(h % 10000) / 10000.0
    }

    /// seed（個体差）と confidence（強さ係数）からステータス値を算出
    private static func stat(in range: ClosedRange<Int>, seed: Double, confidence: Double) -> Int {
        let span = Double(range.upperBound - range.lowerBound)

        // confidence で下限を引き上げる（高 confidence → 最低値が高い）
        let floor = confidence * span * 0.4
        // seed で残りの幅を決定
        let variable = seed * span * 0.6

        let value = Double(range.lowerBound) + floor + variable
        return min(max(Int(value), range.lowerBound), range.upperBound)
    }
}
