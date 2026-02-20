//
//  VictoryComponent.swift
//  Pikumei
//

import SwiftUI

/// バトル勝利時の結果表示コンポーネント
struct VictoryComponent: View {
    let battleLog: [String]
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "crown.fill")
                .font(.system(size: 64))
                .foregroundStyle(.yellow)

            Text("勝利！")
                .font(.custom("RocknRollOne-Regular", size: 34))
                .bold()

            BattleLogComponent(battleLog: battleLog)

            Button("戻る") {
                onBack()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}
