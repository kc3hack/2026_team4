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

            logSection

            Button("戻る") {
                onBack()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }

    private var logSection: some View {
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
