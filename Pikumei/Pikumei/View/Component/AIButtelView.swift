import SwiftUI

// MARK: - メインビュー
struct aiBattleView: View {
    @StateObject private var matchingVM = BattleMatchingViewModel()
    
    // 画像のUIに基づいた選択状態の管理
    @State private var myCharacter: String? = nil
    @State private var opponentCharacter: String? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()
                
                switch matchingVM.phase {
                case .idle:
                    // 画像のUIを再現したメインセクション
                    BattleSelectionSection(
                        myCharacter: $myCharacter,
                        opponentCharacter: $opponentCharacter,
                        onBattleStart: {
                            Task { await matchingVM.createBattle() }
                        }
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
            .navigationTitle("対戦準備")
            .navigationBarTitleDisplayMode(.inline)
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

// MARK: - 画像のデザインを再現したセクション (BattleIdleSectionの代わり)
private struct BattleSelectionSection: View {
    @Binding var myCharacter: String?
    @Binding var opponentCharacter: String?
    var onBattleStart: () -> Void
    
    // 両方選択されているかチェックする計算プロパティ
    var isReady: Bool {
        myCharacter != nil && opponentCharacter != nil
    }
    
    var body: some View {
        VStack(spacing: 30) {
            Text("どのぴくめいと対戦する？")
                .font(.system(size: 24, weight: .regular))
                .padding(.top, 40)
            
            // --- 自分の選択エリア ---
            VStack(spacing: 15) {
                Text("自分")
                    .font(.system(size: 28))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 40)
                
                CharacterSearchButton(selectedName: myCharacter) {
                    // 本来はここでキャラ選択画面へ遷移
                    myCharacter = "選択済みキャラ"
                }
            }
            
            // --- 対戦相手の選択エリア ---
            VStack(spacing: 15) {
                Text("対戦相手")
                    .font(.system(size: 28))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 40)
                
                CharacterSearchButton(selectedName: opponentCharacter) {
                    opponentCharacter = "対戦相手キャラ"
                }
            }
            
            Spacer()
            
            // --- 下部：Let's 対戦ボタンと注意書き ---
            VStack(spacing: 12) {
                Button(action: onBattleStart) {
                    Text("Let's対戦")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.black)
                        .frame(width: 220, height: 55)
                    // 画像のように薄い青（選択時は少し濃く）
                        .background(isReady ? Color.blue.opacity(0.15) : Color.blue.opacity(0.05))
                        .clipShape(Capsule())
                }
                .disabled(!isReady) // 条件を満たさないと押せない
                
                Text("自分と対戦相手の両方が選択されて\nいなかったら押せない")
                    .font(.system(size: 16))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.bottom, 50)
        }
    }
}

// MARK: - キャラ探索ボタン (共通パーツ)
private struct CharacterSearchButton: View {
    let selectedName: String?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(selectedName ?? "キャラ探索")
                .font(.system(size: 24))
                .foregroundColor(.black)
                .frame(width: 300, height: 75)
                .background(Color(white: 0.85)) // 画像のようなグレー
                .clipShape(Capsule())
        }
    }
}

// MARK: - 待機中セクション
private struct BattleWaitingSection: View {
    let battleId: UUID?
    var onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("相手を待っています...")
                .font(.headline)
            
            if let id = battleId {
                Text("ID: \(id.uuidString.prefix(8))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Button("キャンセル") {
                onCancel()
            }
            .buttonStyle(.bordered)
            .padding(.top, 20)
        }
    }
}

// MARK: - エラーセクション
private struct BattleErrorSection: View {
    let message: String
    var onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.red)
            
            Text(message)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("戻る") {
                onBack()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    aiBattleView()
}
