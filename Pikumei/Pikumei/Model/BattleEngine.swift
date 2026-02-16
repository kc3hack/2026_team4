//
//  BattleEngine.swift
//  Pikumei
//

import Foundation

/// バトルの 1 ターン分のログ
struct BattleTurn {
    let attackerName: String
    let damage: Int
    let player1Hp: Int
    let player2Hp: Int
}

/// バトルの結果
struct BattleResult {
    let turns: [BattleTurn]
    let winner: Int  // 1 or 2
}

/// ターン制バトルのシミュレーション
/// battle.id をシードにして両者が同じ結果を独立計算する
enum BattleEngine {

    static func simulate(player1Stats: MonsterStats, player2Stats: MonsterStats, seed: UUID) -> BattleResult {
        var rng = SeededRNG(seed: djb2Hash(seed.uuidString))
        var hp1 = player1Stats.hp
        var hp2 = player2Stats.hp
        var turns: [BattleTurn] = []
        var turnCount = 0

        // 素早さで先攻を決定
        let player1First = player1Stats.speed >= player2Stats.speed

        while hp1 > 0 && hp2 > 0 && turnCount < 20 {
            turnCount += 1

            if player1First {
                // Player1 の攻撃
                let dmg = calcDamage(atk: player1Stats.attack, def: player2Stats.defense, rng: &rng)
                hp2 = max(0, hp2 - dmg)
                turns.append(BattleTurn(attackerName: player1Stats.typeName, damage: dmg, player1Hp: hp1, player2Hp: hp2))
                if hp2 <= 0 { break }

                // Player2 の攻撃
                let dmg2 = calcDamage(atk: player2Stats.attack, def: player1Stats.defense, rng: &rng)
                hp1 = max(0, hp1 - dmg2)
                turns.append(BattleTurn(attackerName: player2Stats.typeName, damage: dmg2, player1Hp: hp1, player2Hp: hp2))
            } else {
                // Player2 先攻
                let dmg = calcDamage(atk: player2Stats.attack, def: player1Stats.defense, rng: &rng)
                hp1 = max(0, hp1 - dmg)
                turns.append(BattleTurn(attackerName: player2Stats.typeName, damage: dmg, player1Hp: hp1, player2Hp: hp2))
                if hp1 <= 0 { break }

                let dmg2 = calcDamage(atk: player1Stats.attack, def: player2Stats.defense, rng: &rng)
                hp2 = max(0, hp2 - dmg2)
                turns.append(BattleTurn(attackerName: player1Stats.typeName, damage: dmg2, player1Hp: hp1, player2Hp: hp2))
            }
        }

        let winner = hp1 > hp2 ? 1 : 2
        return BattleResult(turns: turns, winner: winner)
    }

    // MARK: - Private

    private static func calcDamage(atk: Int, def: Int, rng: inout SeededRNG) -> Int {
        let base = max(1, atk - def / 2)
        let variance = rng.next(in: 80...120)
        return max(1, base * variance / 100)
    }

    private static func djb2Hash(_ string: String) -> UInt64 {
        var hash: UInt64 = 5381
        for char in string.utf8 {
            hash = hash &* 33 &+ UInt64(char)
        }
        return hash
    }
}

// MARK: - 決定論的な乱数生成器（xorshift64）

struct SeededRNG {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 1 : seed
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }

    mutating func next(in range: ClosedRange<Int>) -> Int {
        let span = UInt64(range.upperBound - range.lowerBound + 1)
        return range.lowerBound + Int(next() % span)
    }
}
