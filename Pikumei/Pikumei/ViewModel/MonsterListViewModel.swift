//
//  MonsterListViewModel.swift
//  Pikumei
//

import Foundation

/// モンスター一覧画面の ViewModel
class MonsterListViewModel {

    /// モンスターからバトルステータスを生成する
    func stats(for monster: Monster) -> BattleStats {
        BattleStatsGenerator.generate(
            label: monster.classificationLabel,
            confidence: monster.classificationConfidence
        )
    }
}
