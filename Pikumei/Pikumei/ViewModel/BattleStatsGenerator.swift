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
    private static let specialAttackRange = 15...55
    private static let specialDefenseRange = 10...40

    /// タイプごとの固定 seed（0.0〜1.0、バランス調整用）
    private static let typeSeed: [MonsterType: Double] = [
        .fire:  0.75,
        .water: 0.55,
        .leaf:  0.40,
        .ghost: 0.90,
        .human: 0.50,
        .fish:  0.30,
        .bird:  0.65,
    ]

    /// label + confidence からステータスを生成（nil 時はランダム fallback）
    static func generate(label: MonsterType?, confidence: Double?) -> BattleStats {
        guard let label, let confidence else {
            // ML 未実装 or 分類失敗 → ランダム
            return BattleStats(
                hp: Int.random(in: hpRange),
                attack: Int.random(in: attackRange),
                specialAttack: Int.random(in: specialAttackRange),
                specialDefense: Int.random(in: specialDefenseRange)
            )
        }

        let seed = typeSeed[label] ?? 0.5

        // confidence が高いほど強くなるよう、base を confidence で底上げする
        let clampedConf = min(max(confidence, 0), 1)

        // seed で個体差、confidence で全体的な強さを決める
        let hp = stat(in: hpRange, seed: seed, confidence: clampedConf)
        let attack = stat(in: attackRange, seed: seed * 0.7 + 0.3, confidence: clampedConf)
        // 特攻は攻撃と逆の傾向（攻撃が高いタイプは特攻が低め）
        let specialAttack = stat(in: specialAttackRange, seed: (1.0 - seed) * 0.6 + 0.4, confidence: clampedConf)
        // 特防はタイプ固有の耐久性を反映
        let specialDefense = stat(in: specialDefenseRange, seed: seed * 0.5 + 0.25, confidence: clampedConf)

        return BattleStats(hp: hp, attack: attack, specialAttack: specialAttack, specialDefense: specialDefense)
    }

    // MARK: - Private

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
