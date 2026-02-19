//
//  MonsterDetailView.swift
//  Pikumei
//

import SwiftUI
import SwiftData

/// モンスター詳細画面
struct MonsterDetailView: View {
    let monster: Monster

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let uiImage = monster.uiImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Text(monster.name ?? "名前なし")
                    .font(.title)
                    .bold()

                if let type = monster.classificationLabel {
                    Text("タイプ: \(type.rawValue)")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                Text("登録日: \(monster.createdAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle(monster.name ?? "モンスター詳細")
        .navigationBarTitleDisplayMode(.inline)
    }
}
