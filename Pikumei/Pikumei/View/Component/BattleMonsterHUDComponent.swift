//
//  BattleMonsterHUDComponent.swift
//  Pikumei
//
//  バトル画面でモンスターの画像・名前・HPバーを縦に表示するコンポーネント
//

import SwiftUI

struct BattleMonsterHUDComponent: View {
    let imageData: Data?
    let name: String
    let currentHp: Int
    let maxHp: Int
    let type: MonsterType?
    var size: CGFloat = 100

    var body: some View {
        VStack(spacing: 4) {
            // モンスター画像
            Group {
                if let imageData, let uiImage = UIImage(data: imageData) {
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
            .frame(width: size, height: size)

            // 名前
            Text(name)
                .font(.custom("DotGothic16-Regular", size: size * 0.14))
                .bold()
                .lineLimit(1)
                .shadow(color: .white, radius: 1)

            // HPバー
            hpBar
        }
        .frame(width: size + 20)
    }

    private var hpBar: some View {
        let ratio = maxHp > 0 ? Double(currentHp) / Double(maxHp) : 0
        let barColor = type?.color ?? .green

        return VStack(alignment: .leading, spacing: 2) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 10)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor)
                        .frame(
                            width: geo.size.width * Swift.max(ratio, 0),
                            height: 10
                        )
                        .animation(.easeInOut(duration: 0.3), value: currentHp)
                }
            }
            .frame(height: 10)

            Text("HP \(Swift.max(currentHp, 0)) / \(maxHp)")
                .font(.custom("DotGothic16-Regular", size: size * 0.1))
                .foregroundStyle(.secondary)
        }
    }
}

#Preview("大きめ（自分側）") {
    BattleMonsterHUDComponent(
        imageData: nil,
        name: "テストメイティ",
        currentHp: 80,
        maxHp: 100,
        type: .fire,
        size: 110
    )
}

#Preview("小さめ（相手側）") {
    BattleMonsterHUDComponent(
        imageData: nil,
        name: "あいてメイティ",
        currentHp: 45,
        maxHp: 100,
        type: .water,
        size: 80
    )
}
