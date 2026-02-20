//
//  MonsterListView.swift
//  Pikumei
//

import SwiftUI
import SwiftData

/// モンスター一覧画面
struct MonsterListView: View {
    @Query(sort: \Monster.createdAt, order: .reverse) private var monsters: [Monster]
    private let viewModel = MonsterListViewModel()

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var body: some View {
        NavigationStack {
            Group {
                if monsters.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("モンスターがいません")
                            .font(.custom("RocknRollOne-Regular", size: 20))
                        Text("スキャンしてモンスターを集めよう")
                            .font(.custom("DotGothic16-Regular", size: 15))
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(monsters) { monster in
                                NavigationLink(destination: MonsterDetailView(monster: monster)) {
                                    MonsterCardComponent(
                                        monster: monster,
                                        stats: viewModel.stats(for: monster)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(8)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                Image("back_mokume")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationTitle("モンスター一覧")
        }
    }
}

#Preview {
    MonsterListView()
        .modelContainer(for: Monster.self, inMemory: true)
}
