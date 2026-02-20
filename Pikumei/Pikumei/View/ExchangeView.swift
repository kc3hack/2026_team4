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
                        onSelect: { viewModel.selectMonster($0) }
                    )
                case .idle:
                    ExchangeIdleSection(
                        monster: viewModel.selectedMonster,
                        onCreate: { Task { await viewModel.createExchange() } },
                        onJoin: { Task { await viewModel.joinExchange() } },
                        onBack: { viewModel.deselectMonster() }
                    )
                case .waiting:
                    ExchangeWaitingSection(
                        exchangeId: viewModel.exchangeId,
                        onCancel: { viewModel.reset() }
                    )
                case .exchanging:
                    ExchangeProcessingSection()
                case .completed(let monster):
                    ExchangeCompletedSection(
                        monster: monster,
                        onClose: { viewModel.reset() }
                    )
                case .error(let message):
                    ExchangeErrorSection(
                        message: message,
                        onBack: { viewModel.reset() }
                    )
                }
            }
            .padding()
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
    var onSelect: (Monster) -> Void

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var body: some View {
        if monsters.isEmpty {
            ContentUnavailableView(
                "交換できるモンスターがいません",
                systemImage: "arrow.triangle.2.circlepath",
                description: Text("スキャンしてアップロードしたモンスターが必要です")
            )
        } else {
            VStack(spacing: 12) {
                Text("交換に出すモンスターを選んでください")
                    .font(.headline)

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(monsters) { monster in
                            Button {
                                onSelect(monster)
                            } label: {
                                VStack(spacing: 4) {
                                    if let uiImage = monster.uiImage {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .aspectRatio(1, contentMode: .fill)
                                            .clipped()
                                            .cornerRadius(8)
                                    }
                                    Text(monster.name ?? "名前なし")
                                        .font(.caption)
                                        .lineLimit(1)
                                }
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
    var onCreate: () -> Void
    var onJoin: () -> Void
    var onBack: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            if let monster, let uiImage = monster.uiImage {
                Text("交換に出すモンスター")
                    .font(.headline)

                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxWidth: 160)
                    .cornerRadius(12)

                Text(monster.name ?? "名前なし")
                    .font(.subheadline)

                if let label = monster.classificationLabel {
                    Text(label.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
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
            .font(.caption)
        }
    }
}

// MARK: - 待機中

private struct ExchangeWaitingSection: View {
    let exchangeId: UUID?
    var onCancel: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("相手を待っています...")
                .font(.headline)

            if let id = exchangeId {
                Text("Exchange ID: \(id.uuidString.prefix(8))...")
                    .font(.caption)
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
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("交換しています...")
                .font(.headline)
        }
    }
}

// MARK: - 交換完了

private struct ExchangeCompletedSection: View {
    let monster: Monster
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)

            Text("交換完了！")
                .font(.title2)
                .bold()

            if let uiImage = monster.uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxWidth: 160)
                    .cornerRadius(12)
            }

            Text(monster.name ?? "名前なし")
                .font(.headline)

            if let label = monster.classificationLabel {
                Text(label.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text("新しいモンスターを手に入れた！")
                .font(.body)

            Button("閉じる") {
                onClose()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

// MARK: - エラー

private struct ExchangeErrorSection: View {
    let message: String
    var onBack: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.red)

            Text(message)
                .font(.body)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)

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
