//
//  MonsterResultView.swift
//  Pikumei
//

import SwiftUI

/// 切り抜き結果のプレビュー画面
struct MonsterResultView: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            RotatingCardComponent(frontImage: Image(uiImage: image))

            Spacer()

            Button("閉じる") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom, 32)
        }
    }
}

#Preview {
    MonsterResultView(
        image: UIImage(systemName: "photo")!
    )
}
