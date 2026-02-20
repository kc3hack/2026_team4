//
//  MonsterListView.swift
//  Pikumei
//

import SwiftUI
import SwiftData

/// モンスター一覧画面
struct MonsterListView: View {
    @Query(sort: \Monster.createdAt, order: .reverse) private var monsters: [Monster]
    
    // グリッドのカラム設定（2列）
    private let columns = [
        GridItem(.flexible(), alignment: .top), // 比率がバラバラな時は alignment: .top が綺麗です
        GridItem(.flexible(), alignment: .top),
    ]
    
    var body: some View {
        NavigationStack {
            if monsters.isEmpty {
                ContentUnavailableView(
                    "モンスターがいません",
                    systemImage: "photo.on.rectangle.angled",
                    description: Text("スキャンしてモンスターを集めよう")
                )
                .navigationTitle("モンスター一覧")
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) { // 上下の間隔を少し広めに設定
                        ForEach(monsters) { monster in
                            if let uiImage = monster.uiImage {
                                NavigationLink(destination: MonsterDetailView(monster: monster)) {
                                    VStack(spacing: 8) {
                                        // 画像：被写体の比率を維持
                                        Image(uiImage: uiImage)
                                            .renderingMode(.original)
                                            .resizable()
                                            .scaledToFit() // ここが重要：比率を維持して収める
                                            .cornerRadius(8)
                                            .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
                                        
                                        // モンスター名
                                        Text(monster.name ?? "名前なし")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .lineLimit(1)
                                            .padding(.horizontal, 4)
                                        // 木目背景でも文字が見えやすいように少し装飾
                                            .background(Color.white.opacity(0.6))
                                            .cornerRadius(4)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(12)
                }
                .background(
                    Image("back_mokume")
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                )
                .navigationTitle("モンスター一覧")
            }
        }
    }
}

#Preview {
    MonsterListView()
        .modelContainer(for: Monster.self, inMemory: true)
}
