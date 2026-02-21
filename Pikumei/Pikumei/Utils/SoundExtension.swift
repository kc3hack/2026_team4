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
    case miss = "waza_miss"

    // UI効果音
    case sceneTransition = "bamentenkan"
    
    //バトル勝利/敗北時の効果音
    case victory = "victory_sound"
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

    /// 攻撃名に対応するエフェクトGIF名
    var effectGif: String {
        switch name {
        case "ほのお":     return "explosion"
        case "みずしぶき": return "drop-water"
        case "リーフ":     return "lighting"
        case "たたり":     return "lighting"
        case "パンチ":     return "flash-effect"
        case "しっぽ":     return "slashing-effect"
        case "かぜきり":   return "slashing-effect"
        default:          return "flash-effect"
        }
    }
}
