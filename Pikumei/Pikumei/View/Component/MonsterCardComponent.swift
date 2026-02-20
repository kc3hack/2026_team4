//
//  MonsterCardComponent.swift
//  Pikumei
//

import SwiftUI

struct MonsterCardComponent: View {
    let monster: Monster
    let stats: BattleStats

    /// モンスターのタイプ（未分類時は .human をデフォルト）
    private var monsterType: MonsterType {
        monster.classificationLabel ?? .human
    }

    var body: some View {
        VStack(spacing: 6) {
            // モンスター画像
            if let uiImage = monster.uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // モンスター名 + タイプアイコン
            HStack(spacing: 4) {
                TypeIconComponent(type: monsterType, size: 18)
                Text(monster.name ?? "なまえなし")
                    .font(.custom("RocknRollOne-Regular", size: 13))
                    .foregroundStyle(monsterType.color)
                    .lineLimit(1)
            }

            // HP バー
            VStack(spacing: 2) {
                HStack {
                    Text("HP")
                        .font(.custom("DotGothic16-Regular", size: 10))
                        .foregroundStyle(monsterType.color)
                    Spacer()
                    Text("\(stats.hp)")
                        .font(.custom("DotGothic16-Regular", size: 10))
                        .foregroundStyle(monsterType.color)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.5))
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(monsterType.color)
                            .frame(width: geo.size.width * hpRatio, height: 6)
                    }
                }
                .frame(height: 6)
            }

            // ステータス
            HStack(spacing: 8) {
                statLabel("ATK", value: stats.attack)
                statLabel("S.ATK", value: stats.specialAttack)
                statLabel("S.DEF", value: stats.specialDefense)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(monsterType.bgColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(monsterType.color.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    /// HP のバー表示用比率（最大255想定）
    private var hpRatio: CGFloat {
        min(CGFloat(stats.hp) / 255.0, 1.0)
    }

    private func statLabel(_ label: String, value: Int) -> some View {
        VStack(spacing: 1) {
            Text(label)
                .font(.custom("DotGothic16-Regular", size: 8))
                .foregroundStyle(monsterType.color.opacity(0.7))
            Text("\(value)")
                .font(.custom("DotGothic16-Regular", size: 10))
                .foregroundStyle(monsterType.color)
        }
    }
}

// MARK: - Preview

#Preview("Fire タイプ") {
    let monster = Monster(
        imageData: UIImage(systemName: "flame.fill")!.pngData()!,
        classificationLabel: .fire,
        name: "ほのおくん"
    )
    let stats = BattleStats(hp: 180, attack: 120, specialAttack: 90, specialDefense: 70)

    MonsterCardComponent(monster: monster, stats: stats)
        .frame(width: 160)
        .padding()
}

#Preview("全タイプ一覧") {
    let types: [(MonsterType, String)] = [
        (.fire, "ほのおくん"),
        (.water, "みずちゃん"),
        (.leaf, "はっぱ"),
        (.ghost, "おばけ"),
        (.human, "ヒトくん"),
        (.fish, "さかなん"),
        (.bird, "とりぴー"),
    ]

    ScrollView {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(types, id: \.0) { type, name in
                let monster = Monster(
                    imageData: UIImage(systemName: "star.fill")!.pngData()!,
                    classificationLabel: type,
                    name: name
                )
                let stats = BattleStats(hp: 150, attack: 100, specialAttack: 80, specialDefense: 60)
                MonsterCardComponent(monster: monster, stats: stats)
            }
        }
        .padding()
    }
}
