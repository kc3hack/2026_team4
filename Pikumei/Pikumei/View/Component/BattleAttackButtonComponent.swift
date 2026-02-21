//
//  BattleAttackButtonComponent.swift
//  Pikumei
//
//  バトル画面の攻撃ボタン（タイプカラー背景付き）
//
//
import SwiftUI

struct BattleAttackButtonComponent: View {
    let attack: BattleAttack
    let effectiveness: Double?
    let pp: Int?
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        // 1. ボタンと下の文字をまとめる外側のVStack
        VStack(spacing: 8) {
            
            // --- ここからボタン本体 ---
            Button(action: action) {
                VStack(spacing: 4) {
                    // タイプアイコン
                    TypeIconComponent(type: attack.type, size: 24, color: attack.type.bgColor)

                    // 技名
                    Text(attack.name)
                        .font(.custom("DotGothic16-Regular", size: 13))
                        .foregroundStyle(.white)
                        .bold()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    
                    // 🌟 ボタンの中にあったPPのコードはここから削除しました！
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .padding(.horizontal, 4)
                .background(
                    Image("battle_button_bg")
                        .resizable()
                        .colorMultiply(attack.type.color)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.white.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(isDisabled)
            .opacity(isDisabled ? 0.4 : 1.0)
            // --- ボタン本体ここまで ---

            // 🌟 2. 有利・不利とPPをボタンの下に横並び（HStack）で配置
            ZStack {
                // ガタつき防止用の透明な文字（有利とPPの両方を含めた長さにして高さを確保）
                Text("▲有利 2/2")
                    .font(.custom("DotGothic16-Regular", size: 20))
                    .opacity(0)
                
                // 🌟 横に並べるために HStack を追加
                HStack(spacing: 8) {
                    // ① 有利・不利の表示
                    if let eff = effectiveness {
                        if eff > 1.0 {
                            Text("▲有利")
                                .font(.custom("DotGothic16-Regular", size: 20))
                                .foregroundStyle(Color(red: 0.0, green: 0.48, blue: 1.0, opacity: 1.0))
                        } else if eff < 1.0 {
                            Text("▼不利")
                                .font(.custom("DotGothic16-Regular", size: 20))
                                .foregroundStyle(.pink)
                        }
                    }
                    
                    // ② PPの表示（ここにお引越し）
                    if let pp {
                        Text("\(pp)/2")
                            // 有利・不利の文字サイズ(20)に合わせるか、少し小さめ(16~18)にするかはお好みで！
                            .font(.custom("DotGothic16-Regular", size: 18))
                            // _外に出たので、少し明るめの白にして見やすくしています
                            .foregroundStyle(pp > 0 ? .blue : .blue.opacity(0.4))
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("横3つ並び") {
    HStack(spacing: 8) {
        BattleAttackButtonComponent(
            attack: BattleAttack(name: "ほのお", type: .fire, powerRate: 1.0),
            effectiveness: 1.5,
            pp: 2,
            isDisabled: false,
            action: {}
        )
        BattleAttackButtonComponent(
            attack: BattleAttack(name: "リーフ", type: .leaf, powerRate: 0.7),
            effectiveness: 0.5,
            pp: 1,
            isDisabled: false,
            action: {}
        )
        BattleAttackButtonComponent(
            attack: BattleAttack(name: "たたり", type: .ghost, powerRate: 0.7),
            effectiveness: nil,
            pp: nil,
            isDisabled: false,
            action: {}
        )
    }
    .padding()
    .background(Color.black.opacity(0.5))
}

#Preview("disabled 状態") {
    HStack(spacing: 8) {
        BattleAttackButtonComponent(
            attack: BattleAttack(name: "みずしぶき", type: .water, powerRate: 1.0),
            effectiveness: 1.5,
            pp: 0,
            isDisabled: true,
            action: {}
        )
        BattleAttackButtonComponent(
            attack: BattleAttack(name: "パンチ", type: .human, powerRate: 0.7),
            effectiveness: nil,
            pp: 2,
            isDisabled: false,
            action: {}
        )
        BattleAttackButtonComponent(
            attack: BattleAttack(name: "かぜきり", type: .bird, powerRate: 0.7),
            effectiveness: 1.0,
            pp: 1,
            isDisabled: false,
            action: {}
        )
    }
    .padding()
    .background(Color.black.opacity(0.5))
}
