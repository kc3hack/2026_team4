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
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(monsters) { monster in
                            NavigationLink(destination: MonsterDetailView(monster: monster)) {
                                MonsterCardComponent(
                                    monster: monster,
                                    stats: BattleStatsGenerator.generate(
                                        label: monster.classificationLabel,
                                        confidence: monster.classificationConfidence
                                    )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(8)
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
