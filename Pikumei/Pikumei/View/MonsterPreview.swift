//
//  MonsterPreview.swift
//  Pikumei
//

import SwiftUI

/// 切り抜き結果のプレビュー画面
struct MonsterPreview: View {
    let image: UIImage
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .padding()

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
    MonsterPreview(
        image: UIImage(systemName: "photo")!,
        onRetry: {}
    )
}
