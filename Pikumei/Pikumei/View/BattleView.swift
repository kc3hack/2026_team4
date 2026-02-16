//
//  BattleView.swift
//  Pikumei
//

import SwiftUI
import SwiftData
import Supabase

/// バトル画面
struct BattleView: View {
    @StateObject private var viewModel = BattleViewModel()
    @Query(sort: \Monster.createdAt, order: .reverse) private var monsters: [Monster]
    @Environment(\.modelContext) private var modelContext
    @State private var connectionStatus: String?
    @State private var isTesting = false

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
            // TODO: テスト用（確認後に削除）
            connectionTestSection

            Button("モックモンスターを追加") {
                MockMonsterFactory.insertSamples(into: modelContext)
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom, 4)

            let battleReady = monsters.filter { $0.classificationLabel != nil }

            if battleReady.isEmpty {
                ContentUnavailableView(
                    "バトルできるモンスターがいません",
                    systemImage: "photo.on.rectangle.angled",
                    description: Text("モックモンスターを追加してください")
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

    // MARK: - 接続テスト（確認後に削除）

    private var connectionTestSection: some View {
        VStack(spacing: 8) {
            Button {
                Task { await testConnection() }
            } label: {
                HStack {
                    if isTesting {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    Text("Supabase 接続テスト")
                }
            }
            .buttonStyle(.bordered)
            .disabled(isTesting)

            if let status = connectionStatus {
                Text(status)
                    .font(.caption)
                    .foregroundStyle(status.contains("OK") ? .green : .red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding(.top, 8)
    }

    private func testConnection() async {
        isTesting = true
        connectionStatus = nil

        let client = SupabaseClientProvider.shared

        do {
            // 1. Anonymous Auth テスト
            try await client.auth.signInAnonymously()
            let userId = try await client.auth.session.user.id

            // 2. monsters テーブルへの SELECT テスト
            try await client
                .from("monsters")
                .select("classification_label")
                .limit(1)
                .execute()

            connectionStatus = "OK: 接続成功\nUser: \(userId.uuidString.prefix(8))..."
        } catch {
            connectionStatus = "NG: \(error.localizedDescription)"
        }

        isTesting = false
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
