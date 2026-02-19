//
//  SoundExtension.swift
//  Pikumei
//

import Foundation

/// アセットカタログに登録された効果音の定義
enum Sound: String {
    // 攻撃技の効果音
    case honou = "waza_honou"
    case mizushibuki = "waza_mizusibuki"
    case leaf = "waza_leaf"
    case tatari = "waza_tatari"
    case panch = "waza_panch"
    case shippo = "waza_sippo"
    case kazekiri = "waza_kazekiri"

    // UI効果音
    case sceneTransition = "bamentenkan"
}

extension BattleAttack {
    /// 攻撃名に対応する効果音
    var sound: Sound {
        switch name {
        case "ほのお":     return .honou
        case "みずしぶき": return .mizushibuki
        case "リーフ":     return .leaf
        case "たたり":     return .tatari
        case "パンチ":     return .panch
        case "しっぽ":     return .shippo
        case "かぜきり":   return .kazekiri
        default:          return .panch
        }
    }
}
