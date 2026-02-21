//
//  BattleHistoryViewModel.swift
//  Pikumei
//
//  Charts用データ集計ロジック
//

import Foundation

/// 戦績サマリー
struct BattleSummary {
    let totalBattles: Int
    let wins: Int
    let losses: Int
    let winRate: Double
}

/// バトルごとの累積勝率（折れ線グラフ用）
struct WinRateTrend: Identifiable {
    let id: Int        // バトル番号（1始まり）
    let winRate: Double // その時点での累積勝率（0.0〜1.0）
}

/// タイプ別の勝敗数（棒グラフ用）
struct TypeMatchupStat: Identifiable {
    var id: String { "\(opponentType.rawValue)-\(isWin)" }
    let opponentType: MonsterType
    let isWin: Bool
    let count: Int
}

/// BattleHistory配列からグラフ用データを算出する純粋関数群
enum BattleHistoryViewModel {

    /// 戦績サマリーを計算する
    static func summary(from histories: [BattleHistory]) -> BattleSummary {
        let total = histories.count
        let wins = histories.filter { $0.isWin }.count
        let losses = total - wins
        let winRate = total > 0 ? Double(wins) / Double(total) : 0
        return BattleSummary(totalBattles: total, wins: wins, losses: losses, winRate: winRate)
    }

    /// バトルごとの累積勝率を計算する（古い順）
    static func winRateTrend(from histories: [BattleHistory]) -> [WinRateTrend] {
        // 古い順にソート
        let sorted = histories.sorted { $0.battleDate < $1.battleDate }
        var wins = 0
        return sorted.enumerated().map { index, history in
            if history.isWin { wins += 1 }
            let battleNumber = index + 1
            let rate = Double(wins) / Double(battleNumber)
            return WinRateTrend(id: battleNumber, winRate: rate)
        }
    }

    /// タイプ別の勝敗数を計算する
    static func typeMatchupStats(from histories: [BattleHistory]) -> [TypeMatchupStat] {
        var stats: [String: Int] = [:]
        for history in histories {
            let key = "\(history.opponentType.rawValue)-\(history.isWin)"
            stats[key, default: 0] += 1
        }
        return stats.map { key, count in
            let parts = key.split(separator: "-")
            let type = MonsterType(rawValue: String(parts[0]))!
            let isWin = parts[1] == "true"
            return TypeMatchupStat(opponentType: type, isWin: isWin, count: count)
        }
        .sorted { $0.opponentType.rawValue < $1.opponentType.rawValue }
    }
}
