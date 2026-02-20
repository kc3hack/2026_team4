//
//  MonsterDetailView.swift
//  Pikumei
//

import SwiftUI
import SwiftData

/// モンスター詳細画面
struct MonsterDetailView: View {
    let monster: Monster
    /// バトル用ステータス（初期化時に一度だけ算出）
    let stats: BattleStats

    /// モンスターのタイプ（未分類時は .human をデフォルト）
    private var monsterType: MonsterType {
        monster.classificationLabel ?? .human
    }

    init(monster: Monster) {
        self.monster = monster
        self.stats = BattleStatsGenerator.generate(
            label: monster.classificationLabel,
            confidence: monster.classificationConfidence
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // モンスター画像（タイプカラーの枠 + シャドウ）
                if let uiImage = monster.uiImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(monsterType.color.opacity(0.3), lineWidth: 2)
                        )
                        .shadow(color: monsterType.color.opacity(0.2), radius: 6, x: 0, y: 3)
                }

                // モンスター名
                Text(monster.name ?? "名前なし")
                    .font(.custom("RocknRollOne-Regular", size: 28))
                    .bold()
                    .foregroundStyle(monsterType.color)

                // タイプラベル（アイコン付き）
                HStack(spacing: 6) {
                    TypeIconComponent(type: monsterType, size: 20)
                    Text("タイプ: \(monsterType.displayName)")
                        .font(.custom("DotGothic16-Regular", size: 15))
                        .foregroundStyle(monsterType.color)
                }

                if let confidence = monster.classificationConfidence {
                    Text("強さ: \(Int(confidence * 100))%")
                        .font(.custom("DotGothic16-Regular", size: 15))
                        .foregroundStyle(monsterType.color.opacity(0.8))
                }

                // レーダーチャート（pow(2) で差を強調、バーと同じスケール）
                RadarChartComponent(
                    axes: [
                        ("HP", pow(Double(stats.hp) / 180.0, 2)),
                        ("攻撃", pow(Double(stats.attack) / 55.0, 2)),
                        ("特攻", pow(Double(stats.specialAttack) / 55.0, 2)),
                        ("特防", pow(Double(stats.specialDefense) / 55.0, 2)),
                    ],
                    color: monsterType.color
                )
                .frame(width: 250, height: 250)

                // 数値表示
                statsTable

                Text("登録日: \(monster.createdAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.custom("DotGothic16-Regular", size: 12))
                    .foregroundStyle(monsterType.color.opacity(0.6))
            }
            .padding()
        }
        .background(
            LinearGradient(
                colors: [monsterType.bgColor.opacity(0.6), monsterType.bgColor.opacity(0.2)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationTitle(monster.name ?? "モンスター詳細")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - ステータス数値

    private var statsTable: some View {
        VStack(spacing: 8) {
            statRow(label: "HP", value: stats.hp, maxValue: 180)
            statRow(label: "攻撃", value: stats.attack, maxValue: 55)
            statRow(label: "特攻", value: stats.specialAttack, maxValue: 55)
            statRow(label: "特防", value: stats.specialDefense, maxValue: 55)
        }
        .padding(.horizontal)
    }

    private func statRow(label: String, value: Int, maxValue: Int) -> some View {
        HStack {
            Text(label)
                .font(.custom("DotGothic16-Regular", size: 12))
                .foregroundStyle(monsterType.color.opacity(0.8))
                .frame(width: 40, alignment: .leading)
            Text("\(value)")
                .font(.custom("DotGothic16-Regular", size: 12))
                .bold()
                .foregroundStyle(monsterType.color)
                .frame(width: 30, alignment: .trailing)
            StatBarComponent(value: value, maxValue: maxValue, color: monsterType.color.opacity(0.6))
        }
    }
}
