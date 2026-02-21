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
            Text("？")
                .font(.custom("RocknRollOne-Regular", size: 18))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Color.pikumeiNavy)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
        }
    }
}

#Preview {
    HelpButtonComponent(isShowingHelp: .constant(false))
        .padding()
}
