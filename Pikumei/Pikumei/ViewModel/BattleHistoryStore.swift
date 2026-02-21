//
//  BattleHistoryStore.swift
//  Pikumei
//

import Foundation
import SwiftData

/// BattleHistory の CRUD 操作を提供する
@MainActor
@Observable
class BattleHistoryStore {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// バトル結果を保存する
    func save(
        isWin: Bool,
        myType: MonsterType,
        myName: String?,
        opponentType: MonsterType,
        opponentName: String?,
        opponentThumbnail: Data?
    ) {
        let history = BattleHistory(
            isWin: isWin,
            myType: myType,
            myName: myName,
            opponentType: opponentType,
            opponentName: opponentName,
            opponentThumbnail: opponentThumbnail
        )
        modelContext.insert(history)
        try? modelContext.save()
    }

    /// すべての履歴を新しい順に取得する
    func fetchAll() throws -> [BattleHistory] {
        let descriptor = FetchDescriptor<BattleHistory>(
            sortBy: [SortDescriptor(\.battleDate, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
}
