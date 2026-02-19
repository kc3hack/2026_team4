//
//  BattleGameView.swift
//  Pikumei
//
//  ターン制バトル画面
//

import SwiftUI

struct BattleGameView: View {
    @StateObject private var viewModel: BattleViewModel
    var onFinish: () -> Void

    init(battleId: UUID, onFinish: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: BattleViewModel(battleId: battleId))
        self.onFinish = onFinish
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
            case .connectionError:
                connectionErrorView
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
            HStack(spacing: 12) {
                monsterThumbnail(data: viewModel.opponentThumbnail)

                VStack(alignment: .leading, spacing: 8) {
                    Text("あいて")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(viewModel.opponentName ?? viewModel.opponentLabel?.displayName ?? "")
                        .font(.title3)
                        .bold()
                    hpBar(
                        current: viewModel.opponentHp,
                        maxHp: viewModel.opponentStats?.hp ?? 1,
                        color: .red
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            // 自分側
            HStack(spacing: 12) {
                monsterThumbnail(data: viewModel.myThumbnail)

                VStack(alignment: .leading, spacing: 8) {
                    Text("じぶん")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(viewModel.myName ?? viewModel.myLabel?.displayName ?? "")
                        .font(.title3)
                        .bold()
                    hpBar(
                        current: viewModel.myHp,
                        maxHp: viewModel.myStats?.hp ?? 1,
                        color: .green
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // 攻撃ボタン
            HStack(spacing: 8) {
                ForEach(viewModel.myAttacks.indices, id: \.self) { i in
                    let atk = viewModel.myAttacks[i]
                    let pp = viewModel.attackPP.indices.contains(i) ? viewModel.attackPP[i] : nil
                    let ppEmpty = pp != nil && pp! <= 0
                    Button {
                        viewModel.attack(index: i)
                    } label: {
                        VStack(spacing: 2) {
                            Text(atk.name)
                                .font(.caption)
                                .bold()
                            if let eff = viewModel.attackEffectiveness(at: i) {
                                // 相性表示
                                if eff > 1.0 {
                                    Text("▲有利")
                                        .font(.caption2)
                                        .foregroundStyle(.green)
                                } else if eff < 1.0 {
                                    Text("▼不利")
                                        .font(.caption2)
                                        .foregroundStyle(.red)
                                }
                                // 命中率表示
                                if let acc = viewModel.attackAccuracy(at: i) {
                                    Text("\(acc)%")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            // PP 表示
                            if let pp {
                                Text("\(pp)/2")
                                    .font(.caption2)
                                    .foregroundStyle(pp > 0 ? .orange : .gray)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.bordered)
                    .disabled(!viewModel.isMyTurn || ppEmpty)
                }
            }

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

    // MARK: - モンスターサムネイル

    private func monsterThumbnail(data: Data?) -> some View {
        Group {
            if let data, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "questionmark.circle")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 60, height: 60)
        .clipShape(RoundedRectangle(cornerRadius: 8))
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

    // MARK: - 通信エラー画面

    private var connectionErrorView: some View {
        VStack(spacing: 24) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 64))
                .foregroundStyle(.orange)

            Text("通信エラー")
                .font(.largeTitle)
                .bold()

            logSection

            Button("戻る") {
                viewModel.cleanup()
                onFinish()
            }
            .buttonStyle(.bordered)
        }
        .padding()
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
                onFinish()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}
