//
//  MonsterListViewModel.swift
//  Pikumei
//

import Foundation

/// モンスター一覧画面の ViewModel
class MonsterListViewModel {

    /// モンスターからバトルステータスを生成する（合体モンスターは合体ステータスを返す）
    func stats(for monster: Monster) -> BattleStats {
        monster.battleStats
    }
}
