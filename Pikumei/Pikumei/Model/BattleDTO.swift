//
//  BattleDTO.swift
//  Pikumei
//
//  battles テーブルの Supabase 通信用レコード型
//

import Foundation

/// バトル作成用（INSERT）
struct BattleInsert: Codable {
    let player1Id: UUID
    let player1MonsterId: UUID

    enum CodingKeys: String, CodingKey {
        case player1Id = "player1_id"
        case player1MonsterId = "player1_monster_id"
    }
}

/// バトル参加用（UPDATE）
struct BattleJoinUpdate: Codable {
    let player2Id: UUID
    let player2MonsterId: UUID
    let status: String

    enum CodingKeys: String, CodingKey {
        case player2Id = "player2_id"
        case player2MonsterId = "player2_monster_id"
        case status
    }
}

/// バトル取得用（SELECT / レスポンス）
struct BattleRow: Codable {
    let id: UUID
    let status: String
}

/// モンスター ID のみ取得用
struct MonsterIdRow: Codable {
    let id: UUID
}
