//
//  DefeatComponent.swift
//  Pikumei
//

import SwiftUI

/// バトル敗北時の結果表示コンポーネント
struct DefeatComponent: View {
    let battleLog: [String]
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.red)

            Text("敗北...")
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
