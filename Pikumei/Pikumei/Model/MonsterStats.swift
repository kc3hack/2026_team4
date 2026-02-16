//
//  MonsterStats.swift
//  Pikumei
//

import Foundation

/// モンスターのステータス（保存しない値オブジェクト）
/// ラベルから決定論的に計算されるため、永続化不要
struct MonsterStats {
    let hp: Int        // 60〜100
    let attack: Int    // 40〜70
    let defense: Int   // 40〜70
    let speed: Int     // 30〜70
    let typeName: String  // "いぬタイプ" など
}
