//
//  BattleHistory.swift
//  Pikumei
//

import Foundation
import SwiftData

/// バトル結果の永続化エンティティ
@Model
final class BattleHistory {
    var isWin: Bool
    var battleDate: Date
    var myType: MonsterType
    var myName: String?
    var opponentType: MonsterType
    var opponentName: String?
    @Attribute(.externalStorage) var opponentThumbnail: Data?

    init(
        isWin: Bool,
        battleDate: Date = .now,
        myType: MonsterType,
        myName: String? = nil,
        opponentType: MonsterType,
        opponentName: String? = nil,
        opponentThumbnail: Data? = nil
    ) {
        self.isWin = isWin
        self.battleDate = battleDate
        self.myType = myType
        self.myName = myName
        self.opponentType = opponentType
        self.opponentName = opponentName
        self.opponentThumbnail = opponentThumbnail
    }
}
