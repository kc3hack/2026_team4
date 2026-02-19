//
//  MonsterDetailView.swift
//  Pikumei
//

import SwiftUI
import SwiftData

/// モンスター詳細画面
struct MonsterDetailView: View {
    let monster: Monster

    /// バトル用ステータス（label + confidence から算出）
    private var stats: BattleStats {
        BattleStatsGenerator.generate(
            label: monster.classificationLabel,
            confidence: monster.classificationConfidence
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let uiImage = monster.uiImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Text(monster.name ?? "名前なし")
                    .font(.title)
                    .bold()

                if let type = monster.classificationLabel {
                    Text("タイプ: \(type.rawValue)")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                // レーダーチャート
                RadarChartComponent(
                    axes: [
                        ("HP", Double(stats.hp) / 180.0),
                        ("攻撃", Double(stats.attack) / 55.0),
                        ("特攻", Double(stats.specialAttack) / 55.0),
                        ("特防", Double(stats.specialDefense) / 40.0),
                    ],
                    color: .blue
                )
                .frame(width: 250, height: 250)

                // 数値表示
                statsTable

                Text("登録日: \(monster.createdAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle(monster.name ?? "モンスター詳細")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - ステータス数値

    private var statsTable: some View {
        VStack(spacing: 8) {
            statRow(label: "HP", value: stats.hp, maxValue: 180)
            statRow(label: "攻撃", value: stats.attack, maxValue: 55)
            statRow(label: "特攻", value: stats.specialAttack, maxValue: 55)
            statRow(label: "特防", value: stats.specialDefense, maxValue: 40)
        }
        .padding(.horizontal)
    }

    private func statRow(label: String, value: Int, maxValue: Int) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .frame(width: 40, alignment: .leading)
            Text("\(value)")
                .font(.caption)
                .bold()
                .frame(width: 30, alignment: .trailing)
            StatBarComponent(value: value, maxValue: maxValue)
        }
    }
}
