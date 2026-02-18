//
//  BattlePhase.swift
//  Pikumei
//
//  バトル進行状態
//

import Foundation

enum BattlePhase {
    case preparing   // ステータス取得中
    case battling    // バトル中
    case won         // 勝利
    case lost        // 敗北
}
