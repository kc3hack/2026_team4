//
//  BattleView.swift
//  Pikumei
//

import SwiftUI
import SwiftData

/// バトル画面
struct BattleView: View {
    @StateObject private var viewModel = BattleViewModel()
    @Query(sort: \Monster.createdAt, order: .reverse) private var monsters: [Monster]

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.phase {
                case .selectMonster:
                    monsterSelectView
                case .uploading:
                    progressView(message: "アップロード中...")
                case .waiting:
                    waitingView
                case .matched:
                    progressView(message: "マッチ成立！バトル開始...")
                case .battling:
                    battleView
                case .result(let won):
                    resultView(won: won)
                }
            }
            .navigationTitle("バトル")
            .alert("エラー", isPresented: .init(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    // MARK: - モンスター選択

    private var monsterSelectView: some View {
        VStack {
            let battleReady = monsters.filter { $0.classificationLabel != nil }

            if battleReady.isEmpty {
                ContentUnavailableView(
                    "バトルできるモンスターがいません",
                    systemImage: "photo.on.rectangle.angled",
                    description: Text("スキャンしてモンスターを集めよう")
                )
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(battleReady) { monster in
                            if let uiImage = monster.uiImage {
                                Button {
                                    Task {
                                        await viewModel.startBattle(monster: monster)
                                    }
                                } label: {
                                    VStack(spacing: 4) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .aspectRatio(1, contentMode: .fill)
                                            .clipped()
                                            .cornerRadius(8)

                                        if let stats = monster.stats {
                                            Text(stats.typeName)
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }

    // MARK: - 待機中

    private var waitingView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)
            Text("対戦相手を待っています...")
                .font(.headline)
            Button("キャンセル") {
                Task { await viewModel.cancelBattle() }
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - バトル中

    private var battleView: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(Array(viewModel.battleLog.enumerated()), id: \.offset) { _, turn in
                    HStack {
                        Text(turn.attackerName)
                            .fontWeight(.bold)
                        Text("が \(turn.damage) ダメージ！")
                    }
                    .font(.caption)
                    .padding(.horizontal)

                    HStack {
                        Text("自分: \(turn.player1Hp)")
                        Spacer()
                        Text("相手: \(turn.player2Hp)")
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                    Divider()
                }
            }
            .padding(.top)
        }
    }

    // MARK: - 結果

    private func resultView(won: Bool) -> some View {
        VStack(spacing: 24) {
            Text(won ? "勝利！" : "敗北...")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(won ? .green : .red)

            Button("もう一度") {
                viewModel.reset()
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - 共通

    private func progressView(message: String) -> some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text(message)
                .font(.headline)
        }
    }
}

#Preview {
    BattleView()
        .modelContainer(for: Monster.self, inMemory: true)
}
