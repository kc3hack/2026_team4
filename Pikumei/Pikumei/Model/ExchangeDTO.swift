//
//  ExchangeDTO.swift
//  Pikumei
//
//  exchanges テーブルの Supabase 通信用レコード型
//

import Foundation

/// 交換作成用（INSERT）
struct ExchangeInsert: Codable {
    let player1Id: UUID
    let player1MonsterId: UUID

    enum CodingKeys: String, CodingKey {
        case player1Id = "player1_id"
        case player1MonsterId = "player1_monster_id"
    }
}

/// 交換参加用（UPDATE）
struct ExchangeJoinUpdate: Codable {
    let player2Id: UUID
    let player2MonsterId: UUID
    let status: String

    enum CodingKeys: String, CodingKey {
        case player2Id = "player2_id"
        case player2MonsterId = "player2_monster_id"
        case status
    }
}

/// 交換取得用（SELECT / レスポンス）
struct ExchangeRow: Codable {
    let id: UUID
    let status: String
}

/// 交換詳細取得用（SELECT）
struct ExchangeFullRow: Codable {
    let id: UUID
    let status: String
    let player1Id: UUID
    let player1MonsterId: UUID
    let player2Id: UUID?
    let player2MonsterId: UUID?

    enum CodingKeys: String, CodingKey {
        case id
        case status
        case player1Id = "player1_id"
        case player1MonsterId = "player1_monster_id"
        case player2Id = "player2_id"
        case player2MonsterId = "player2_monster_id"
    }
}
