//
//  ExchangeView.swift
//  Pikumei
//
//  モンスター交換画面
//

import SwiftUI
import SwiftData

struct ExchangeView: View {
    @StateObject private var viewModel = ExchangeViewModel()
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Monster.createdAt, order: .reverse) private var monsters: [Monster]

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                switch viewModel.phase {
                case .selectMonster:
                    ExchangeSelectSection(
                        monsters: monsters.filter { $0.supabaseId != nil },
                        statsFor: { viewModel.stats(for: $0) },
                        onSelect: { viewModel.selectMonster($0) }
                    )
                case .idle:
                    ExchangeIdleSection(
                        monster: viewModel.selectedMonster,
                        stats: viewModel.selectedMonster.map { viewModel.stats(for: $0) },
                        onCreate: { Task { await viewModel.createExchange() } },
                        onJoin: { Task { await viewModel.joinExchange() } },
                        onBack: { viewModel.deselectMonster() }
                    )
                case .waiting:
                    ExchangeWaitingSection(
                        monster: viewModel.selectedMonster,
                        stats: viewModel.selectedMonster.map { viewModel.stats(for: $0) },
                        exchangeId: viewModel.exchangeId,
                        onCancel: { viewModel.reset() }
                    )
                case .exchanging:
                    ExchangeProcessingSection(
                        monster: viewModel.selectedMonster,
                        stats: viewModel.selectedMonster.map { viewModel.stats(for: $0) }
                    )
                case .completed(let monster):
                    ExchangeCompletedSection(
                        monster: monster,
                        stats: viewModel.stats(for: monster),
                        onClose: { viewModel.reset() }
                    )
                case .error(let message):
                    ExchangeErrorSection(
                        monster: viewModel.selectedMonster,
                        stats: viewModel.selectedMonster.map { viewModel.stats(for: $0) },
                        message: message,
                        onBack: { viewModel.reset() }
                    )
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                Image("back_gray")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationTitle("こうかん")
            .onAppear {
                viewModel.setModelContext(modelContext)
            }
            .onDisappear {
                viewModel.unsubscribe()
            }
        }
    }
}

// MARK: - モンスター選択

private struct ExchangeSelectSection: View {
    let monsters: [Monster]
    var statsFor: (Monster) -> BattleStats
    var onSelect: (Monster) -> Void

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var body: some View {
        if monsters.isEmpty {
            VStack(spacing: 16) {
                Spacer()
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                Text("交換できるモンスターがいません")
                    .font(.custom("RocknRollOne-Regular", size: 20))
                Text("スキャンしてアップロードした\nモンスターが必要です")
                    .font(.custom("DotGothic16-Regular", size: 15))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Spacer()
            }
        } else {
            VStack(spacing: 12) {
                Text("交換に出すモンスターを選んでください")
                    .font(.custom("DotGothic16-Regular", size: 17))

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(monsters) { monster in
                            Button {
                                onSelect(monster)
                            } label: {
                                MonsterCardComponent(
                                    monster: monster,
                                    stats: statsFor(monster)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 選択完了（作成/参加）

private struct ExchangeIdleSection: View {
    let monster: Monster?
    let stats: BattleStats?
    var onCreate: () -> Void
    var onJoin: () -> Void
    var onBack: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            if let monster, let stats {
                Text("交換に出すモンスター")
                    .font(.custom("DotGothic16-Regular", size: 17))

                MonsterCardComponent(monster: monster, stats: stats)
            }

            Button {
                onCreate()
            } label: {
                Text("交換を作成して待つ")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button {
                onJoin()
            } label: {
                Text("待機中の交換に参加")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Button("モンスターを選び直す") {
                onBack()
            }
            .font(.custom("DotGothic16-Regular", size: 12))
        }
    }
}

// MARK: - 待機中

private struct ExchangeWaitingSection: View {
    let monster: Monster?
    let stats: BattleStats?
    let exchangeId: UUID?
    var onCancel: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            if let monster, let stats {
                MonsterCardComponent(monster: monster, stats: stats)
            }

            ProgressView()
            Text("相手を待っています...")
                .font(.custom("DotGothic16-Regular", size: 17))

            if let id = exchangeId {
                Text("Exchange ID: \(id.uuidString.prefix(8))...")
                    .font(.custom("DotGothic16-Regular", size: 12))
                    .foregroundStyle(.secondary)
            }

            Button("キャンセル") {
                onCancel()
            }
            .buttonStyle(.bordered)
        }
    }
}

// MARK: - 交換処理中

private struct ExchangeProcessingSection: View {
    let monster: Monster?
    let stats: BattleStats?

    var body: some View {
        VStack(spacing: 16) {
            if let monster, let stats {
                MonsterCardComponent(monster: monster, stats: stats)
            }

            ProgressView()
            Text("交換しています...")
                .font(.custom("DotGothic16-Regular", size: 17))
        }
    }
}

// MARK: - 交換完了

private struct ExchangeCompletedSection: View {
    let monster: Monster
    let stats: BattleStats
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)

            Text("交換完了！")
                .font(.custom("RocknRollOne-Regular", size: 22))
                .bold()

            MonsterCardComponent(monster: monster, stats: stats)

            Text("新しいモンスターを手に入れた！")
                .font(.custom("DotGothic16-Regular", size: 15))

            Button("閉じる") {
                onClose()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

// MARK: - エラー

private struct ExchangeErrorSection: View {
    let monster: Monster?
    let stats: BattleStats?
    let message: String
    var onBack: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.red)

            Text(message)
                .font(.custom("DotGothic16-Regular", size: 15))
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)

            if let monster, let stats {
                MonsterCardComponent(monster: monster, stats: stats)
            }

            Button("戻る") {
                onBack()
            }
            .buttonStyle(.bordered)
        }
    }
}

#Preview {
    ExchangeView()
        .modelContainer(for: Monster.self, inMemory: true)
}
