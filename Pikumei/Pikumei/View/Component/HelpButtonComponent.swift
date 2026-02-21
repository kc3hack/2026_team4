//
//  HelpButtonComponent.swift
//  Pikumei
//

import SwiftUI

/// 「？」フローティングボタン（ヘルプ表示用）
struct HelpButtonComponent: View {
    @Binding var isShowingHelp: Bool

    var body: some View {
        Button {
            isShowingHelp = true
        } label: {
            Label("ヘルプ", systemImage: "questionmark.circle")
                .font(.custom("RocknRollOne-Regular", size: 13))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.pikumeiNavy)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
        }
    }
}

#Preview {
    HelpButtonComponent(isShowingHelp: .constant(false))
        .padding()
}
