//
//  BattleGameView.swift
//  Pikumei
//
//  ターン制バトル画面
//

import SwiftUI

struct BattleGameView: View {
    @StateObject private var viewModel: BattleViewModel

    init(battleId: UUID) {
        _viewModel = StateObject(wrappedValue: BattleViewModel(battleId: battleId))
    }

    var body: some View {
        Group {
            switch viewModel.phase {
            case .preparing:
                preparingView
            case .battling:
                battlingView
            case .won:
                resultView(won: true)
            case .lost:
                resultView(won: false)
            }
        }
        .task {
            await viewModel.prepare()
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }

    // MARK: - 準備中

    private var preparingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("バトル準備中...")
                .font(.headline)
        }
    }

    // MARK: - バトル中

    private var battlingView: some View {
        VStack(spacing: 20) {
            // 相手側
            VStack(alignment: .leading, spacing: 8) {
                Text("あいて")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(viewModel.opponentLabel)
                    .font(.title3)
                    .bold()
                hpBar(
                    current: viewModel.opponentHp,
                    maxHp: viewModel.opponentStats?.hp ?? 1,
                    color: .red
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            // 自分側
            VStack(alignment: .leading, spacing: 8) {
                Text("じぶん")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(viewModel.myLabel)
                    .font(.title3)
                    .bold()
                hpBar(
                    current: viewModel.myHp,
                    maxHp: viewModel.myStats?.hp ?? 1,
                    color: .green
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // 攻撃ボタン
            Button {
                viewModel.attack()
            } label: {
                Text("こうげき")
                    .font(.title3)
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.isMyTurn)

            if !viewModel.isMyTurn {
                Text("あいてのターン...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // バトルログ
            logSection
        }
        .padding()
    }

    // MARK: - HP バー

    private func hpBar(current: Int, maxHp: Int, color: Color) -> some View {
        let ratio = maxHp > 0 ? Double(current) / Double(maxHp) : 0

        return VStack(alignment: .leading, spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 16)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * Swift.max(ratio, 0), height: 16)
                        .animation(.easeInOut(duration: 0.3), value: current)
                }
            }
            .frame(height: 16)

            Text("HP \(Swift.max(current, 0)) / \(maxHp)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - ログ

    private var logSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("ログ")
                .font(.caption)
                .foregroundStyle(.secondary)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(viewModel.battleLog.indices, id: \.self) { i in
                        Text(viewModel.battleLog[i])
                            .font(.caption)
                    }
                }
            }
            .frame(maxHeight: 120)
        }
    }

    // MARK: - 結果画面

    private func resultView(won: Bool) -> some View {
        VStack(spacing: 24) {
            Image(systemName: won ? "crown.fill" : "xmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(won ? .yellow : .red)

            Text(won ? "勝利！" : "敗北...")
                .font(.largeTitle)
                .bold()

            // 最終ログ
            logSection

            Button("戻る") {
                viewModel.cleanup()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}
