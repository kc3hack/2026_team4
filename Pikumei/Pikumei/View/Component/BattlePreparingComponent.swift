//
//  BattlePreparingComponent.swift
//  Pikumei
//

import SwiftUI

/// バトル準備中の表示コンポーネント
struct BattlePreparingComponent: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("バトル準備中...")
                .font(.custom("DotGothic16-Regular", size: 17))
        }
    }
}
