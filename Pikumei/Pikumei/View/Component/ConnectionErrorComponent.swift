//
//  ConnectionErrorComponent.swift
//  Pikumei
//

import SwiftUI

/// バトル通信エラー時の表示コンポーネント
struct ConnectionErrorComponent: View {
    let battleLog: [String]
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 64))
                .foregroundStyle(.orange)

            Text("通信エラー")
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
