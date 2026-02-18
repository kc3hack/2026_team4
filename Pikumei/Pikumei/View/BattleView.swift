//
//  BattleView.swift
//  Pikumei
//
//  マッチング通信テスト画面
//

import SwiftUI

/// バトル画面 — マッチング通信テスト
struct BattleView: View {
    @StateObject private var matchingVM = BattleMatchingViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                switch matchingVM.phase {
                case .idle:
                    idleSection
                case .waiting:
                    waitingSection
                case .battling:
                    battlingSection
                case .error(let message):
                    errorSection(message: message)
                }
            }
            .padding()
            .navigationTitle("バトル")
            .onDisappear {
                matchingVM.unsubscribe()
            }
        }
    }

    // MARK: - 初期状態

    private var idleSection: some View {
        VStack(spacing: 16) {
            Text("マッチング通信テスト")
                .font(.headline)

            Button {
                Task { await matchingVM.createBattle() }
            } label: {
                Text("バトルを作成して待つ")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button {
                Task { await matchingVM.joinBattle() }
            } label: {
                Text("待機中バトルに参加")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - 待機中

    private var waitingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("相手を待っています...")
                .font(.headline)

            if let id = matchingVM.battleId {
                Text("Battle ID: \(id.uuidString.prefix(8))...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button("キャンセル") {
                matchingVM.reset()
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - バトル中

    private var battlingSection: some View {
        Group {
            if let battleId = matchingVM.battleId {
                BattleGameView(battleId: battleId)
            }
        }
    }

    // MARK: - エラー

    private func errorSection(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.red)

            Text(message)
                .font(.body)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)

            Button("戻る") {
                matchingVM.reset()
            }
            .buttonStyle(.bordered)
        }
    }
}

#Preview {
    BattleView()
}
