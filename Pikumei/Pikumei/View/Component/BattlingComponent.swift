//
//  BattlingComponent.swift
//  Pikumei
//

import SwiftUI

/// バトル中の画面コンポーネント
struct BattlingComponent: View {
    @ObservedObject var viewModel: BattleViewModel
    
    var body: some View {
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
                    size: 120,
                    blinkTrigger: viewModel.opponentBlinkTrigger,
                    flipTrigger: viewModel.opponentFlipTrigger
                )
                .overlay {
                    if let gif = viewModel.effectOnOpponent {
                        GifImageComponent(name: gif, repeatCount: 1, speed: 1.5)
                            .frame(width: 120, height: 120)
                            .allowsHitTesting(false)
                    }
                }
                .overlay { DamageLabelComponent(damage: viewModel.damageToOpponent) }
            }
            
            // 自分側 — 左寄せ・大きめ（手前）
            HStack {
                BattleMonsterHUDComponent(
                    imageData: viewModel.myThumbnail,
                    name: viewModel.myName ?? viewModel.myLabel?.displayName ?? "",
                    currentHp: viewModel.myHp,
                    maxHp: viewModel.myStats?.hp ?? 1,
                    type: viewModel.myLabel,
                    size: 160,
                    blinkTrigger: viewModel.myBlinkTrigger,
                    flipTrigger: viewModel.myFlipTrigger
                )
                .overlay {
                    if let gif = viewModel.effectOnMe {
                        GifImageComponent(name: gif, repeatCount: 1, speed: 1.5)
                            .frame(width: 160, height: 160)
                            .allowsHitTesting(false)
                    }
                }
                .overlay { DamageLabelComponent(damage: viewModel.damageToMe) }
                Spacer()
            }
            
            // バトルメッセージ（高さ固定でボタンが動かないようにする）
            Group {
                if let message = viewModel.battleMessage {
                    Text(message)
                        .font(.custom("DotGothic16-Regular", size: 16))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                } else {
                    Text(" ")
                        .font(.custom("DotGothic16-Regular", size: 16))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(.black.opacity(viewModel.battleMessage != nil ? 0.6 : 0))
            .cornerRadius(8)
            .animation(.easeInOut(duration: 0.3), value: viewModel.battleMessage)
            
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
            
            // ターン情報（高さ固定でボタン位置がずれないようにする）
            Group {
                if viewModel.isMyTurn && viewModel.turnTimeRemaining > 0 {
                    Text("のこり \(viewModel.turnTimeRemaining)秒")
                        .font(.custom("DotGothic16-Regular", size: 14))
                        .foregroundStyle(viewModel.turnTimeRemaining <= 10 ? .red : .primary)
                } else if !viewModel.isMyTurn {
                    Text("あいてのターン...")
                        .font(.custom("DotGothic16-Regular", size: 12))
                        .foregroundStyle(.secondary)
                } else {
                    Text(" ")
                        .font(.custom("DotGothic16-Regular", size: 14))
                }
            }
            .frame(height: 20)
        }
        .padding()
    }
}

// MARK: - ダメージ表示

/// HUD 上にフローティング表示するダメージラベル
struct DamageLabelComponent: View {
    let damage: Int?
    
    var body: some View {
        Group {
            if let damage {
                Text(damage == 0 ? "MISS" : "-\(damage)")
                    .font(.custom("DotGothic16-Regular", size: 36))
                    .bold()
                    .foregroundStyle(damage == 0 ? .white : .red)
                    .shadow(color: .black.opacity(0.6), radius: 2, x: 1, y: 1)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.15), value: damage)
    }
}

// MARK - Preview

#Preview {
    @Previewable @ObservedObject var viewModel = BattleViewModel(battleId: UUID())
    
    BattlingComponent(viewModel: viewModel)
        .overlay(
            VStack {
                Button("Damage opponent") {
                    viewModel.parformDamageAnimation(target: .opponent)
                }
                
                Button("Miss opponent") {
                    viewModel.parformMissAnimation(target: .opponent)
                }
                
                Button("Damage me") {
                    viewModel.parformDamageAnimation(target: .me)
                }
                
                Button("Miss me") {
                    viewModel.parformMissAnimation(target: .me)
                }
            }
        )
}
