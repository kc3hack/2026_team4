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

    // バトル背景をランダムで選択（画面生成時に固定）
    private let backgroundImage: String

    private static let battleBackgrounds = [
        "back_battle_mori",
        "back_battle_sabaku",
        "back_battle_sougen",
    ]

    init(battleId: UUID, onFinish: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: BattleViewModel(battleId: battleId))
        self.onFinish = onFinish
        self.backgroundImage = Self.battleBackgrounds.randomElement()!
    }

    var body: some View {
        ZStack {
            // バトル背景
            Image(backgroundImage)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

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

            // 攻撃エフェクト
            if let gif = viewModel.attackEffectGif {
                GifImageComponent(name: gif, repeatCount: 1, speed: 3.0)
                    .frame(width: 80, height: 80)
                    .allowsHitTesting(false)
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
        VStack(spacing: 15) {
            // 相手側 — 右寄せ・小さめ（遠近感）
            HStack {
                Spacer()
                BattleMonsterHUDComponent(
                    imageData: viewModel.opponentThumbnail,
                    name: viewModel.opponentName ?? viewModel.opponentLabel?.displayName ?? "",
                    currentHp: viewModel.opponentHp,
                    maxHp: viewModel.opponentStats?.hp ?? 1,
                    type: viewModel.opponentLabel,
                    size: 80
                )
            }

            // 自分側 — 左寄せ・大きめ（手前）
            HStack {
                BattleMonsterHUDComponent(
                    imageData: viewModel.myThumbnail,
                    name: viewModel.myName ?? viewModel.myLabel?.displayName ?? "",
                    currentHp: viewModel.myHp,
                    maxHp: viewModel.myStats?.hp ?? 1,
                    type: viewModel.myLabel,
                    size: 110
                )
                Spacer()
            }

            // 攻撃ボタン
            HStack(spacing: 8) {
                ForEach(viewModel.myAttacks.indices, id: \.self) { i in
                    let pp = viewModel.attackPP.indices.contains(i) ? viewModel.attackPP[i] : nil
                    let ppEmpty = pp != nil && pp! <= 0
                    BattleAttackButtonComponent(
                        attack: viewModel.myAttacks[i],
                        effectiveness: viewModel.attackEffectiveness(at: i),
                        pp: pp,
                        isDisabled: !viewModel.isMyTurn || ppEmpty
                    ) {
                        viewModel.attack(index: i)
                    }
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
