//  BattleView.swift
//  Pikumei
//
//  バトル画面（マッチング → バトル / ソロバトル）
//

import SwiftUI
import SwiftData

struct BattleView: View {
    @StateObject private var matchingVM = BattleMatchingViewModel()
    @StateObject private var selectionVM = BattleMonsterSelectionViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var soloBattleVM: SoloBattleViewModel?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                switch matchingVM.phase {
                case .idle:
                    BattleIdleSection(
                        onCreate: { Task {
                            await matchingVM.createBattle(selectionVM: selectionVM)
                        } },
                        onJoin: { Task {
                            await matchingVM.joinBattle(selectionVM: selectionVM)
                        } },
                        onSolo: { Task {
                            soloBattleVM = await matchingVM.startSoloBattle(
                                selectionVM: selectionVM,
                                modelContext: modelContext
                            )
                        } },
                        soloErrorMessage: matchingVM.soloErrorMessage,
                        selectionVM: selectionVM
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
                case .soloBattling:
                    if let soloVM = soloBattleVM {
                        BattleGameView(viewModel: soloVM) {
                            soloBattleVM = nil
                            matchingVM.phase = .idle
                        }
                    }
                case .error(let message):
                    BattleErrorSection(
                        message: message,
                        onBack: { matchingVM.reset() }
                    )
                }
            }
            .padding(matchingVM.phase.isBattling ? 0 : 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(alignment: .top) {
                if !matchingVM.phase.isBattling {
                    Image("back_splash")
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                }
            }
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
    
    var onSolo: () -> Void
    var soloErrorMessage: String?
    @StateObject var selectionVM: BattleMonsterSelectionViewModel
    
    
    var body: some View {
        VStack(spacing: 16) {
            MonsterSelectionSection(
                selectionVM: selectionVM
            )
            
            Text("2人でバトル")
                .font(.custom("RocknRollOne-Regular", size: 22))
            
            BlueButtonComponent(title: "バトルを作成して待つ") {
                onCreate()
            }
            
            
            BrownButtonComponent(title: "待機中バトルに参加"){
                onJoin()
            }
            
            Divider()
                .padding(.vertical, 8)
            
            Text("ひとりでバトル")
                .font(.custom("RocknRollOne-Regular", size: 22))
            
            BlueButtonComponent(title: "CPUとバトル") {
                onSolo()
            }
            
            if let errorMessage = soloErrorMessage {
                Text(errorMessage)
                    .font(.custom("DotGothic16-Regular", size: 13))
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
            
            NavigationLink(destination: BattleHistoryView()) {
                HStack(spacing: 6) {
                    Image(systemName: "clock.arrow.circlepath")
                    Text("バトル履歴")
                }
                .font(.custom("DotGothic16-Regular", size: 15))
                .foregroundStyle(Color.pikumeiNavy)
                .padding(.top, 8)
            }
        }
    }
}

/// モンスター選択セクション
private struct MonsterSelectionSection: View {
    @StateObject var selectionVM: BattleMonsterSelectionViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            Text("メイティ選択")
                .font(.custom("RocknRollOne-Regular", size: 22))
            
            
            NavigationLink{BattleMonsterSelectionView(selectionVM: selectionVM)
            } label: {
                VStack() {
                    Text("タップして選択")
                    if let monster = selectionVM.monster, let stats = selectionVM.stats {
                        MonsterCardComponent(
                            monster: monster,
                            stats: stats
                        )
                        .padding(.top, 8)
                        .padding(.horizontal, 50)
                    }
                }
            }
            .task {
                await selectionVM.updateMonster()
            }
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
                .font(.custom("DotGothic16-Regular", size: 17))
            
            if let id = battleId {
                Text("Battle ID: \(id.uuidString.prefix(8))...")
                    .font(.custom("DotGothic16-Regular", size: 12))
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
                .font(.custom("DotGothic16-Regular", size: 15))
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
