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
                        VStack(spacing: 16) {
                            ForEach(MonsterType.allCases, id: \.self) { type in
                                let filtered = monsters.filter { $0.classificationLabel == type }
                                if !filtered.isEmpty {
                                    Section {
                                        LazyVGrid(columns: columns, spacing: 12) {
                                            ForEach(filtered) { monster in
                                                NavigationLink(destination: MonsterDetailView(monster: monster)) {
                                                    MonsterCardComponent(
                                                        monster: monster,
                                                        stats: viewModel.stats(for: monster)
                                                    )
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                    } header: {
                                        TypeLabelComponent(type: type, text: "\(type.displayName)タイプ", iconSize: 22, fontSize: 16)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                            }
                        }
                        .padding(8)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                ZStack {
                    Image("back_mokume")
                        .resizable()
                        .scaledToFill()
                    Color.white.opacity(0.3)
                }
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
