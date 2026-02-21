//
//  BattleGameView.swift
//  Pikumei
//
//  ターン制バトル画面
//

import SwiftUI
import SwiftData

struct BattleGameView: View {
    @StateObject private var viewModel: BattleViewModel
    @Environment(\.modelContext) private var modelContext
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

    /// ソロバトル用: 生成済みの ViewModel を直接受け取る
    init(viewModel: BattleViewModel, onFinish: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: viewModel)
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
                    VictoryComponent {
                        saveBattleHistory(isWin: true)
                        viewModel.cleanup()
                        onFinish()
                    }
                case .lost:
                    DefeatComponent {
                        saveBattleHistory(isWin: false)
                        viewModel.cleanup()
                        onFinish()
                    }
                case .connectionError:
                    ConnectionErrorComponent {
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

    /// バトル結果をSwiftDataに保存する
    private func saveBattleHistory(isWin: Bool) {
        guard let myType = viewModel.myLabel,
              let opponentType = viewModel.opponentLabel else { return }
        let store = BattleHistoryStore(modelContext: modelContext)
        store.save(
            isWin: isWin,
            myType: myType,
            myName: viewModel.myName,
            opponentType: opponentType,
            opponentName: viewModel.opponentName,
            opponentThumbnail: viewModel.opponentThumbnail
        )
    }
}
