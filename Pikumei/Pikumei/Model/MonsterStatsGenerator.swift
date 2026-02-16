//
//  MonsterStatsGenerator.swift
//  Pikumei
//

import Foundation

/// ML 分類ラベルからモンスターステータスを決定論的に生成する
/// Swift の hashValue はプロセスごとに変わるため、DJB2 安定ハッシュを使用
enum MonsterStatsGenerator {

    static func generate(from label: String) -> MonsterStats {
        let seed = djb2Hash(label)
        return MonsterStats(
            hp: rangeValue(seed: seed, offset: 0, min: 60, max: 100),
            attack: rangeValue(seed: seed, offset: 1, min: 40, max: 70),
            defense: rangeValue(seed: seed, offset: 2, min: 40, max: 70),
            speed: rangeValue(seed: seed, offset: 3, min: 30, max: 70),
            typeName: typeName(for: label)
        )
    }

    // MARK: - Private

    /// DJB2 ハッシュ（プロセス間で安定した値を返す）
    private static func djb2Hash(_ string: String) -> UInt64 {
        var hash: UInt64 = 5381
        for char in string.utf8 {
            hash = hash &* 33 &+ UInt64(char)
        }
        return hash
    }

    /// シードと offset から min〜max の範囲の値を生成
    private static func rangeValue(seed: UInt64, offset: Int, min: Int, max: Int) -> Int {
        let shifted = seed &* UInt64(offset + 7) &+ UInt64(offset * 13)
        let mixed = shifted ^ (shifted >> 16)
        return min + Int(mixed % UInt64(max - min + 1))
    }

    /// ラベルから日本語タイプ名を生成
    private static func typeName(for label: String) -> String {
        let mapping: [String: String] = [
            "dog": "いぬ",
            "cat": "ねこ",
            "bird": "とり",
            "fish": "さかな",
            "car": "くるま",
            "flower": "はな",
            "tree": "きのこ",
            "person": "ひと",
            "bottle": "ボトル",
            "cup": "カップ",
            "chair": "いす",
            "book": "ほん",
        ]

        let lowered = label.lowercased()
        for (key, value) in mapping {
            if lowered.contains(key) {
                return "\(value)タイプ"
            }
        }

        // マッピングにないラベルはそのまま使う
        return "\(label)タイプ"
    }
}
