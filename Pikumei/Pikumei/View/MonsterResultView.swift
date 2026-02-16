//
//  MonsterResultView.swift
//  Pikumei
//

import SwiftUI

/// 切り抜き結果のプレビュー画面
struct MonsterResultView: View {
    let image: UIImage
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            RotatingCardComponent(frontImage: Image(uiImage: image))

            Spacer()

            Button("もう一度スキャン") {
                onRetry()
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom, 32)
        }
    }
}

#Preview {
    MonsterResultView(
        image: UIImage(systemName: "photo")!,
        onRetry: {}
    )
}
