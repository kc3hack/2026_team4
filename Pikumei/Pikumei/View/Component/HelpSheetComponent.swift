//
//  HelpSheetComponent.swift
//  Pikumei
//

import SwiftUI

/// ヘルプシート（タイプ相性表・バトル仕様・わざ一覧）
struct HelpSheetComponent: View {
    @Environment(\.dismiss) private var dismiss

    private let allTypes = MonsterType.allCases

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    typeMatchupSection
                    battleRulesSection
                    attackListSection
                }
                .padding()
            }
            .navigationTitle("ヘルプ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("とじる") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - セクション1: タイプ相性表

    private var typeMatchupSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("タイプ相性表")

            // 凡例
            HStack(spacing: 12) {
                legendItem(symbol: "◎", label: "ばつぐん(1.5x)", color: .green)
                legendItem(symbol: "△", label: "いまひとつ(0.5x)", color: .red)
                legendItem(symbol: "-", label: "等倍(1.0x)", color: .gray)
            }
            .font(.custom("RocknRollOne-Regular", size: 10))

            // 表の説明
            HStack(spacing: 4) {
                Text("→ 攻撃側")
                    .font(.custom("RocknRollOne-Regular", size: 10))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("↓ 防御側")
                    .font(.custom("RocknRollOne-Regular", size: 10))
                    .foregroundStyle(.secondary)
            }

            // 相性グリッド
            matchupGrid
        }
    }

    private var matchupGrid: some View {
        let cellSize: CGFloat = 36

        return Grid(alignment: .center, horizontalSpacing: 2, verticalSpacing: 2) {
            // ヘッダー行（攻撃側）
            GridRow {
                // 左上の空セル
                Color.clear
                    .frame(width: cellSize, height: cellSize)
                ForEach(allTypes, id: \.self) { attackType in
                    TypeIconComponent(type: attackType, size: 20)
                        .frame(width: cellSize, height: cellSize)
                }
            }

            // 各防御タイプの行
            ForEach(allTypes, id: \.self) { defenderType in
                GridRow {
                    // 行ヘッダー（防御側）
                    TypeIconComponent(type: defenderType, size: 20)
                        .frame(width: cellSize, height: cellSize)

                    // 各攻撃タイプとの相性セル
                    ForEach(allTypes, id: \.self) { attackType in
                        matchupCell(attacker: attackType, defender: defenderType)
                            .frame(width: cellSize, height: cellSize)
                    }
                }
            }
        }
    }

    private func matchupCell(attacker: MonsterType, defender: MonsterType) -> some View {
        let effectiveness = attacker.effectiveness(against: defender)
        let (symbol, color): (String, Color) = {
            if effectiveness > 1.0 {
                return ("◎", .green)
            } else if effectiveness < 1.0 {
                return ("△", .red)
            } else {
                return ("-", .gray)
            }
        }()

        return Text(symbol)
            .font(.custom("RocknRollOne-Regular", size: 14))
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(color.opacity(0.1))
            .cornerRadius(4)
    }

    private func legendItem(symbol: String, label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Text(symbol)
                .foregroundStyle(color)
            Text(label)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - セクション2: バトルのしくみ

    private var battleRulesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("バトルのしくみ")

            VStack(alignment: .leading, spacing: 6) {
                ruleItem(title: "命中率", description: "ばつぐん70% / 等倍90% / いまひとつ100%")
                ruleItem(title: "PP制限", description: "ばつぐん技は1バトル2回まで、それ以外は無制限")
                ruleItem(title: "ダメージ", description: "メイン技→特攻使用 / サブ技→攻撃使用")
                ruleItem(title: "制限時間", description: "15秒（時間切れでランダム自動攻撃）")
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }

    private func ruleItem(title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(title)
                .font(.custom("RocknRollOne-Regular", size: 12))
                .foregroundStyle(Color.pikumeiNavy)
                .frame(width: 60, alignment: .leading)
            Text(description)
                .font(.custom("RocknRollOne-Regular", size: 11))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - セクション3: タイプ別わざ一覧

    private var attackListSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("タイプ別わざ一覧")

            ForEach(allTypes, id: \.self) { monsterType in
                typeAttackCard(for: monsterType)
            }
        }
    }

    private func typeAttackCard(for monsterType: MonsterType) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // タイプヘッダー
            TypeLabelComponent(type: monsterType, text: monsterType.displayName, iconSize: 16, fontSize: 13)

            // わざ一覧
            ForEach(monsterType.attacks, id: \.name) { attack in
                HStack(spacing: 8) {
                    TypeIconComponent(type: attack.type, size: 14)
                    Text(attack.name)
                        .font(.custom("RocknRollOne-Regular", size: 12))
                    Spacer()
                    Text(attack.powerRate >= 1.0 ? "メイン" : "サブ")
                        .font(.custom("RocknRollOne-Regular", size: 10))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray5))
                        .cornerRadius(4)
                }
                .padding(.leading, 4)
            }
        }
        .padding(10)
        .background(monsterType.bgColor.opacity(0.3))
        .cornerRadius(10)
    }

    // MARK: - 共通

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.custom("RocknRollOne-Regular", size: 16))
            .foregroundStyle(Color.pikumeiNavy)
    }
}

#Preview {
    HelpSheetComponent()
}
