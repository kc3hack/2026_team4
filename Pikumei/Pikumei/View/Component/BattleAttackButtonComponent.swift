//
//  BattleAttackButtonComponent.swift
//  Pikumei
//
//  バトル画面の攻撃ボタン（タイプカラー背景付き）
//

import SwiftUI

struct BattleAttackButtonComponent: View {
    let attack: BattleAttack
    let effectiveness: Double?
    let pp: Int?
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                // タイプアイコン（薄いパステル色で表示）
                TypeIconComponent(type: attack.type, size: 24, color: attack.type.bgColor)

                // 技名
                Text(attack.name)
                    .font(.custom("DotGothic16-Regular", size: 13))
                    .foregroundStyle(.white)
                    .bold()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                // 相性 + PP
                HStack(spacing: 4) {
                    if let eff = effectiveness {
                        if eff > 1.0 {
                            Text("▲有利")
                                .font(.custom("DotGothic16-Regular", size: 9))
                                .foregroundStyle(.yellow)
                        } else if eff < 1.0 {
                            Text("▼不利")
                                .font(.custom("DotGothic16-Regular", size: 9))
                                .foregroundStyle(.red.opacity(0.8))
                        }
                    }
                    if let pp {
                        Text("\(pp)/2")
                            .font(.custom("DotGothic16-Regular", size: 9))
                            .foregroundStyle(pp > 0 ? .white.opacity(0.8) : .white.opacity(0.4))
                    }
                }
                .frame(height: 12)
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
