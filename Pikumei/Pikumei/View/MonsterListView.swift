//
//  MonsterListView.swift
//  Pikumei
//

import SwiftUI
import SwiftData

/// モンスター一覧画面
struct MonsterListView: View {
    @Query(sort: \Monster.createdAt, order: .reverse) private var monsters: [Monster]

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
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
                    LazyVGrid(columns: columns, spacing: 4) {
                        ForEach(monsters) { monster in
                            if let uiImage = monster.uiImage {
                                NavigationLink(destination: MonsterDetailView(monster: monster)) {
                                    VStack(spacing: 4) {
                                        Image(uiImage: uiImage)
                                            .renderingMode(.original)
                                            .resizable()
                                            .aspectRatio(1, contentMode: .fit)
                                            .background(.clear)

                                        Text(monster.name ?? "名前なし")
                                            .font(.custom("DotGothic16-Regular", size: 12))
                                            .lineLimit(1)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(4)
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
