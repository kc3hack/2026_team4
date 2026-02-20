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
        .fire:  [0.1, 0.3, 0.4, 0.2],
        .water: [0.2, 0.3, 0.3, 0.2],
        .leaf:  [0.2, 0.2, 0.2, 0.4],
        .ghost: [0.4, 0.1, 0.3, 0.2],
        .human: [0.4, 0.4, 0.1, 0.1],
        .fish:  [0.2, 0.3, 0.3, 0.2],
        .bird:  [0.2, 0.4, 0.2, 0.2],
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
    
    private static func adjustConfidence(_ confidence: Double) -> Double {
        let span = 1.0 - MonsterClassifier.GHOST_CONFIDENCE_THRESHOLD
        let addition = span * confidence
        let adjustedConf = MonsterClassifier.GHOST_CONFIDENCE_THRESHOLD + addition
        return adjustedConf
    }
    
    /// seed（個体差）と confidence（強さ係数）からステータス値を算出
    private static func stat(in range: ClosedRange<Int>, scale: Double, confidence: Double) -> Int {
        let span = Double(range.upperBound - range.lowerBound)
        let addition = Int(floor(span * scale * confidence))
        let stat = range.lowerBound + addition
        return stat
    }
}
