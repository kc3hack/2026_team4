//
//  BattleLogComponent.swift
//  Pikumei
//

import SwiftUI

/// バトルログ表示コンポーネント
struct BattleLogComponent: View {
    let battleLog: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("ログ")
                .font(.custom("DotGothic16-Regular", size: 12))
                .foregroundStyle(.secondary)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(battleLog.indices, id: \.self) { i in
                        Text(battleLog[i])
                            .font(.custom("DotGothic16-Regular", size: 12))
                    }
                }
            }
            .frame(maxHeight: 120)
        }
    }
}
