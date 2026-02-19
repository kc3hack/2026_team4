//  BattleView.swift
//  Pikumei
//
//  バトル画面（マッチング → バトル）
//

import SwiftUI

struct BattleView: View {
    @StateObject private var matchingVM = BattleMatchingViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                switch matchingVM.phase {
                case .idle:
                    BattleIdleSection(
                        onCreate: { Task { await matchingVM.createBattle() } },
                        onJoin: { Task { await matchingVM.joinBattle() } }
                    )
                case .waiting:
                    BattleWaitingSection(
                        battleId: matchingVM.battleId,
                        onCancel: { matchingVM.reset() }
                    )
                case .battling:
                    if let battleId = matchingVM.battleId {
                        BattleGameView(battleId: battleId) {
                            matchingVM.reset()
                        }
                    }
                case .error(let message):
                    BattleErrorSection(
                        message: message,
                        onBack: { matchingVM.reset() }
                    )
                }
            }
            .padding()
            .toolbar(
                matchingVM.phase.isBattling ? .hidden : .visible,
                for: .tabBar
            )
            .onDisappear {
                matchingVM.unsubscribe()
            }
        }
    }
}

// MARK: - 初期状態

private struct BattleIdleSection: View {
    var onCreate: () -> Void
    var onJoin: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image("battle-logo")
                .resizable()
                //.scaledToFill()
                .frame(width: UIScreen.main.bounds.width * 1.13, height: 400)
                .rotationEffect(Angle(degrees: -8))
                .padding(.bottom, 40)
            
            Text("マッチング通信テスト")
                .font(.headline)

            Button {
                onCreate()
            } label: {
                Text("バトルを作成して待つ")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button {
                onJoin()
            } label: {
                Text("待機中バトルに参加")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }
}

// MARK: - 待機中

private struct BattleWaitingSection: View {
    let battleId: UUID?
    var onCancel: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("相手を待っています...")
                .font(.headline)

            if let id = battleId {
                Text("Battle ID: \(id.uuidString.prefix(8))...")
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

// MARK: - エラー

private struct BattleErrorSection: View {
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
    BattleView()
}
