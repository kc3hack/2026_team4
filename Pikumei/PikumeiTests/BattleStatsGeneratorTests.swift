//
//  BattleStatsGeneratorTests.swift
//  PikumeiTests
//

import Testing
@testable import Pikumei

struct BattleStatsGeneratorTests {

    @Test func ghostHighConfidenceProducesHighStats() {
        let stats = BattleStatsGenerator.generate(label: .ghost, confidence: 0.95)
        // ghost は seed 最高(0.90)、高 confidence → 高ステータスになるはず
        #expect(stats.hp >= 140, "ghost+高confidence の HP は高いはず")
        #expect(stats.attack >= 35, "ghost+高confidence の Attack は高いはず")
    }

    @Test func fishLowConfidenceProducesLowStats() {
        let stats = BattleStatsGenerator.generate(label: .fish, confidence: 0.1)
        // fish は seed 最低(0.30)、低 confidence → 低ステータスになるはず
        #expect(stats.hp <= 130, "fish+低confidence の HP は低いはず")
        #expect(stats.attack <= 35, "fish+低confidence の Attack は低いはず")
    }

    @Test func statsAreWithinValidRange() {
        for type in MonsterType.allCases {
            for conf in [0.0, 0.5, 1.0] {
                let stats = BattleStatsGenerator.generate(label: type, confidence: conf)
                #expect((80...180).contains(stats.hp),
                        "\(type) conf=\(conf): HP \(stats.hp) out of range")
                #expect((15...55).contains(stats.attack),
                        "\(type) conf=\(conf): Attack \(stats.attack) out of range")
                #expect((15...55).contains(stats.specialAttack),
                        "\(type) conf=\(conf): SpecialAttack \(stats.specialAttack) out of range")
                #expect((10...40).contains(stats.specialDefense),
                        "\(type) conf=\(conf): SpecialDefense \(stats.specialDefense) out of range")
            }
        }
    }

    @Test func sameInputProducesSameOutput() {
        let a = BattleStatsGenerator.generate(label: .fire, confidence: 0.8)
        let b = BattleStatsGenerator.generate(label: .fire, confidence: 0.8)
        #expect(a.hp == b.hp)
        #expect(a.attack == b.attack)
        #expect(a.specialAttack == b.specialAttack)
        #expect(a.specialDefense == b.specialDefense)
    }

    @Test func nilInputProducesStatsWithinRange() {
        // ランダムなので複数回実行して範囲内であることを確認
        for _ in 0..<20 {
            let stats = BattleStatsGenerator.generate(label: nil, confidence: nil)
            #expect((80...180).contains(stats.hp), "nil HP \(stats.hp) out of range")
            #expect((15...55).contains(stats.attack), "nil Attack \(stats.attack) out of range")
            #expect((15...55).contains(stats.specialAttack), "nil SpecialAttack \(stats.specialAttack) out of range")
            #expect((10...40).contains(stats.specialDefense), "nil SpecialDefense \(stats.specialDefense) out of range")
        }
    }
}
