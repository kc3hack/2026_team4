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
    
    /// タイプごとのステータス分布(0.0 ~ 1.0)
    private static let statsDistributions: [MonsterType: [Double]] = [
        .fire:  [0.5, 0.5, 0.8, 0.6],
        .water: [0.5, 0.4, 0.9, 0.8],
        .leaf:  [0.5, 0.7, 0.7, 0.7],
        .ghost: [1.0, 0.2, 0.8, 0.2],
        .human: [0.8, 0.8, 0.5, 0.3],
        .fish:  [0.6, 0.8, 0.5, 0.4],
        .bird:  [0.6, 0.9, 0.3, 0.6],
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
        
        // ステータス分布を取得
        let distribution = statsDistributions[label] ?? [0.25, 0.25, 0.25, 0.25]
        let adjustedConf = adjustConfidence(confidence)
        
        // ステータス分布とconfidenceに基づいてステータスを算出
        let hp = stat(in: hpRange, scale: distribution[0], confidence: adjustedConf)
        let attack = stat(in: attackRange, scale: distribution[1], confidence: adjustedConf)
        let specialAttack = stat(in: specialAttackRange, scale: distribution[2], confidence: adjustedConf)
        let specialDefense = stat(in: specialDefenseRange, scale: distribution[3], confidence: adjustedConf)
        
        return BattleStats(hp: hp, attack: attack, specialAttack: specialAttack, specialDefense: specialDefense)
    }
    
    /// confidenceの範囲を[0.0, 1.0] に正規化
    private static func adjustConfidence(_ confidence: Double) -> Double
    {
        let threshold = MonsterClassifier.GHOST_CONFIDENCE_THRESHOLD
        // [threshold, 1.0] → [0.0, 1.0] に正規化
        return (confidence - threshold) / (1.0 - threshold)
    }
    
    /// scale(タイプごとのステータス倍率)とconfidence(個体ごとのステータス倍率)からステータス値を算出
    private static func stat(in range: ClosedRange<Int>, scale: Double, confidence: Double) -> Int {
        let span = Double(range.upperBound - range.lowerBound)
        let addition = Int(floor(span * scale * confidence))
        let stat = range.lowerBound + addition
        return max(range.lowerBound, min(stat, range.upperBound))
    }
}
