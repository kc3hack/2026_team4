//
//  BattleHistoryViewModelTests.swift
//  PikumeiTests
//

import Foundation
import Testing
@testable import Pikumei

struct BattleHistoryViewModelTests {

    // MARK: - summary(from:)

    @Test func summaryFromEmptyList() {
        let result = BattleHistoryViewModel.summary(from: [])
        #expect(result.totalBattles == 0)
        #expect(result.wins == 0)
        #expect(result.losses == 0)
        #expect(result.winRate == 0)
    }

    @Test func summaryAllWins() {
        let histories = [
            BattleHistory(isWin: true, myType: .fire, opponentType: .water),
            BattleHistory(isWin: true, myType: .fire, opponentType: .leaf),
            BattleHistory(isWin: true, myType: .fire, opponentType: .ghost),
        ]
        let result = BattleHistoryViewModel.summary(from: histories)
        #expect(result.totalBattles == 3)
        #expect(result.wins == 3)
        #expect(result.losses == 0)
        #expect(result.winRate == 1.0)
    }

    @Test func summaryAllLosses() {
        let histories = [
            BattleHistory(isWin: false, myType: .fire, opponentType: .water),
            BattleHistory(isWin: false, myType: .fire, opponentType: .leaf),
        ]
        let result = BattleHistoryViewModel.summary(from: histories)
        #expect(result.totalBattles == 2)
        #expect(result.wins == 0)
        #expect(result.losses == 2)
        #expect(result.winRate == 0)
    }

    @Test func summaryMixedResults() {
        let histories = [
            BattleHistory(isWin: true, myType: .fire, opponentType: .water),
            BattleHistory(isWin: false, myType: .fire, opponentType: .leaf),
            BattleHistory(isWin: true, myType: .fire, opponentType: .ghost),
            BattleHistory(isWin: false, myType: .fire, opponentType: .bird),
        ]
        let result = BattleHistoryViewModel.summary(from: histories)
        #expect(result.totalBattles == 4)
        #expect(result.wins == 2)
        #expect(result.losses == 2)
        #expect(result.winRate == 0.5)
    }

    // MARK: - winRateTrend(from:)

    @Test func winRateTrendFromEmptyList() {
        let result = BattleHistoryViewModel.winRateTrend(from: [])
        #expect(result.isEmpty)
    }

    @Test func winRateTrendCumulativeCalculation() {
        let base = Date(timeIntervalSince1970: 0)
        let histories = [
            BattleHistory(isWin: true, battleDate: base, myType: .fire, opponentType: .water),
            BattleHistory(isWin: false, battleDate: base.addingTimeInterval(60), myType: .fire, opponentType: .leaf),
            BattleHistory(isWin: true, battleDate: base.addingTimeInterval(120), myType: .fire, opponentType: .ghost),
        ]
        let trend = BattleHistoryViewModel.winRateTrend(from: histories)
        #expect(trend.count == 3)
        #expect(trend[0].id == 1)
        #expect(trend[0].winRate == 1.0)   // 1勝 / 1戦
        #expect(trend[1].id == 2)
        #expect(trend[1].winRate == 0.5)   // 1勝 / 2戦
        #expect(trend[2].id == 3)
    }

    @Test func winRateTrendSortsByDate() {
        let base = Date(timeIntervalSince1970: 0)
        // わざと日付順を逆に渡す
        let histories = [
            BattleHistory(isWin: false, battleDate: base.addingTimeInterval(120), myType: .fire, opponentType: .ghost),
            BattleHistory(isWin: true, battleDate: base, myType: .fire, opponentType: .water),
        ]
        let trend = BattleHistoryViewModel.winRateTrend(from: histories)
        // ソート後: win(base) → loss(base+120)
        #expect(trend[0].winRate == 1.0)  // 最初が勝ち
        #expect(trend[1].winRate == 0.5)  // 1勝1敗
    }

    // MARK: - typeMatchupStats(from:)

    @Test func typeMatchupStatsFromEmptyList() {
        let result = BattleHistoryViewModel.typeMatchupStats(from: [])
        #expect(result.isEmpty)
    }

    @Test func typeMatchupStatsGroupsByType() {
        let histories = [
            BattleHistory(isWin: true, myType: .fire, opponentType: .water),
            BattleHistory(isWin: false, myType: .fire, opponentType: .water),
            BattleHistory(isWin: true, myType: .fire, opponentType: .water),
        ]
        let stats = BattleHistoryViewModel.typeMatchupStats(from: histories)
        let waterWins = stats.first { $0.opponentType == .water && $0.isWin }
        let waterLosses = stats.first { $0.opponentType == .water && !$0.isWin }
        #expect(waterWins?.count == 2)
        #expect(waterLosses?.count == 1)
    }

    @Test func typeMatchupStatsSortedByType() {
        let histories = [
            BattleHistory(isWin: true, myType: .fire, opponentType: .water),
            BattleHistory(isWin: true, myType: .fire, opponentType: .bird),
        ]
        let stats = BattleHistoryViewModel.typeMatchupStats(from: histories)
        #expect(stats.count == 2)
        // "bird" < "water" のアルファベット順
        #expect(stats[0].opponentType == .bird)
        #expect(stats[1].opponentType == .water)
    }
}
