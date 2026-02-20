//
//  MonsterType.swift
//  Pikumei
//

import SwiftUI

enum MonsterType: String, Codable, CaseIterable {
    case fire
    case water
    case leaf
    case ghost
    case human
    case fish
    case bird
}

extension MonsterType {
    /// タイプに対応するアセット画像名
    var imageName: String {
        rawValue
    }

    /// タイプに対応するカラーアセット名（濃い色）
    var colorName: String {
        switch self {
        case .fire:  return "FireType"
        case .water: return "WaterType"
        case .leaf:  return "LeafType"
        case .ghost: return "GhostType"
        case .human: return "HumanType"
        case .fish:  return "FishType"
        case .bird:  return "BirdType"
        }
    }

    /// タイプに対応する背景カラーアセット名（パステル）
    var bgColorName: String {
        switch self {
        case .fire:  return "FireType-Bg"
        case .water: return "WaterType-Bg"
        case .leaf:  return "LeafType-Bg"
        case .ghost: return "GhostType-Bg"
        case .human: return "HumanType-Bg"
        case .fish:  return "FishType-Bg"
        case .bird:  return "BirdType-Bg"
        }
    }

    /// SwiftUI用のカラー（濃い色）
    var color: Color {
        Color(colorName)
    }

    /// SwiftUI用の背景カラー（パステル）
    var bgColor: Color {
        Color(bgColorName)
    }

    /// 日本語の表示名
    var displayName: String {
        switch self {
        case .fire:  return "ほのお"
        case .water: return "みず"
        case .leaf:  return "くさ"
        case .ghost: return "ゴースト"
        case .human: return "ヒト"
        case .fish:  return "さかな"
        case .bird:  return "とり"
        }
    }

    /// このタイプのモンスターが使える攻撃一覧（メイン技1 + サブ技2）
    var attacks: [BattleAttack] {
        switch self {
        case .fire:
            return [
                BattleAttack(name: "ほのお", type: .fire, powerRate: 1.0),
                BattleAttack(name: "リーフ", type: .leaf, powerRate: 0.7),
                BattleAttack(name: "たたり", type: .ghost, powerRate: 0.7),
            ]
        case .water:
            return [
                BattleAttack(name: "みずしぶき", type: .water, powerRate: 1.0),
                BattleAttack(name: "ほのお", type: .fire, powerRate: 0.7),
                BattleAttack(name: "パンチ", type: .human, powerRate: 0.7),
            ]
        case .leaf:
            return [
                BattleAttack(name: "リーフ", type: .leaf, powerRate: 1.0),
                BattleAttack(name: "みずしぶき", type: .water, powerRate: 0.7),
                BattleAttack(name: "かぜきり", type: .bird, powerRate: 0.7),
            ]
        case .ghost:
            return [
                BattleAttack(name: "たたり", type: .ghost, powerRate: 1.0),
                BattleAttack(name: "ほのお", type: .fire, powerRate: 0.7),
                BattleAttack(name: "しっぽ", type: .fish, powerRate: 0.7),
            ]
        case .human:
            return [
                BattleAttack(name: "パンチ", type: .human, powerRate: 1.0),
                BattleAttack(name: "かぜきり", type: .bird, powerRate: 0.7),
                BattleAttack(name: "リーフ", type: .leaf, powerRate: 0.7),
            ]
        case .fish:
            return [
                BattleAttack(name: "しっぽ", type: .fish, powerRate: 1.0),
                BattleAttack(name: "たたり", type: .ghost, powerRate: 0.7),
                BattleAttack(name: "ほのお", type: .fire, powerRate: 0.7),
            ]
        case .bird:
            return [
                BattleAttack(name: "かぜきり", type: .bird, powerRate: 1.0),
                BattleAttack(name: "みずしぶき", type: .water, powerRate: 0.7),
                BattleAttack(name: "パンチ", type: .human, powerRate: 0.7),
            ]
        }
    }

    /// 攻撃側(self) → 防御側(defender) のダメージ倍率
    func effectiveness(against defender: MonsterType) -> Double {
        switch (self, defender) {
        case (.fire, .leaf), (.fire, .bird):        return 1.5
        case (.fire, .water):                       return 0.5
        case (.water, .fire):                       return 1.5
        case (.water, .leaf):                       return 0.5
        case (.leaf, .water), (.leaf, .fish):       return 1.5
        case (.leaf, .fire), (.leaf, .bird):        return 0.5
        case (.ghost, .human):                      return 1.5
        case (.ghost, .bird):                       return 0.5
        case (.human, .fish):                       return 1.5
        case (.human, .ghost):                      return 0.5
        case (.fish, .bird):                        return 1.5
        case (.fish, .leaf), (.fish, .human):       return 0.5
        case (.bird, .leaf), (.bird, .ghost):       return 1.5
        case (.bird, .fire), (.bird, .fish):        return 0.5
        default:                                    return 1.0
        }
    }
}
