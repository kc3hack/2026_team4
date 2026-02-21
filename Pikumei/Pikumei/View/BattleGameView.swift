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
                    BattlePreparingComponent()
                case .battling:
                    BattlingComponent(viewModel: viewModel)
                case .won:
                    VictoryComponent(battleLog: viewModel.battleLog) {
                        viewModel.cleanup()
                        onFinish()
                    }
                case .lost:
                    DefeatComponent(battleLog: viewModel.battleLog) {
                        viewModel.cleanup()
                        onFinish()
                    }
                case .connectionError:
                    ConnectionErrorComponent(battleLog: viewModel.battleLog) {
                        viewModel.cleanup()
                        onFinish()
                    }
                }
            }

        }
        .task {
            await viewModel.prepare()
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }
}
