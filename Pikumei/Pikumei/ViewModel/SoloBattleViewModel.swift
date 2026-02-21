//
//  SoloBattleViewModel.swift
//  Pikumei
//
//  ローカルデータのみで動くCPU対戦用ViewModel
//  BattleViewModelのサブクラスとして、Supabase通信を一切使わない
//

import Foundation
import SwiftData
import UIKit

@MainActor
class SoloBattleViewModel: BattleViewModel {
    private var monster: Monster
    private let modelContext: ModelContext
    private var cpuAttacks: [BattleAttack] = []
    private var cpuAttackPP: [Int?] = []
    private var cpuAttackTask: Task<Void, Never>?
    private var isFinishing = false

    init(monster: Monster, modelContext: ModelContext) {
        self.monster = monster
        self.modelContext = modelContext
        super.init(battleId: UUID())
    }

    // MARK: - 準備

    /// SwiftDataからモンスターを1体ランダム取得してバトルを開始する
    override func prepare() async {
        do {
            let descriptor = FetchDescriptor<Monster>()
            let monsters = try modelContext.fetch(descriptor)
            guard monsters.count >= 1 else {
                phase = .connectionError
                return
            }

            let myMonster = self.monster
            let cpuMonster = monsters.shuffled()[0]

            let myType = myMonster.classificationLabel ?? .fire
            let cpuType = cpuMonster.classificationLabel ?? .fire

            // ステータス算出（合体モンスターは合体ステータスを使用）
            let my = myMonster.battleStats
            let opp = cpuMonster.battleStats

            myStats = my
            opponentStats = opp
            myHp = my.hp
            opponentHp = opp.hp
            myLabel = myMonster.classificationLabel
            opponentLabel = cpuMonster.classificationLabel
            myName = myMonster.name
            opponentName = cpuMonster.name ?? "CPU"
            myThumbnail = myMonster.imageData
            opponentThumbnail = cpuMonster.imageData

            myAttacks = myType.attacks
            cpuAttacks = cpuType.attacks

            // ばつぐん技のみ PP 2、それ以外は無制限
            attackPP = myAttacks.map { atk in
                let eff = atk.type.effectiveness(against: cpuType)
                return eff > 1.0 ? 2 : nil
            }
            cpuAttackPP = cpuAttacks.map { atk in
                let eff = atk.type.effectiveness(against: myType)
                return eff > 1.0 ? 2 : nil
            }

            // 攻撃エフェクトGIFを事前読み込み
            GifCacheStore.shared.preload(myAttacks.map { $0.effectGif })
            GifCacheStore.shared.preload(cpuAttacks.map { $0.effectGif })

            // 即座にバトル開始（Broadcast不要）
            phase = .battling
            isMyTurn = true
            showBattleMessage("バトル開始！")
            startTurnTimer()

            // 切り抜きはバックグラウンドで実行
            Task {
                let myData = myMonster.imageData
                let oppData = cpuMonster.imageData
                async let myCutout = cutoutThumbnail(myData)
                async let oppCutout = cutoutThumbnail(oppData)
                self.myThumbnail = await myCutout
                self.opponentThumbnail = await oppCutout
            }
        } catch {
            phase = .connectionError
        }
    }

    // MARK: - プレイヤー攻撃

    /// 選択した攻撃を実行し、CPUの反撃を1〜2秒後にスケジュールする
    override func attack(index: Int) {
        guard isMyTurn, let myStats, let opponentStats, let opponentLabel else { return }
        guard index < myAttacks.count else { return }
        if let pp = attackPP[index], pp <= 0 { return }

        stopTurnTimer()
        isMyTurn = false

        let chosen = myAttacks[index]
        let multiplier = chosen.type.effectiveness(against: opponentLabel)

        // PP 消費
        if attackPP[index] != nil { attackPP[index]! -= 1 }

        // 命中判定
        let accuracy: Double = multiplier > 1.0 ? 0.7 : (multiplier < 1.0 ? 1.0 : 0.9)
        let hit = Double.random(in: 0..<1) < accuracy

        let damage: Int
        if hit {
            SoundPlayerComponent.shared.play(chosen.sound)
            showAttackEffect(attack: chosen, target: .opponent)
            parformDamageAnimation(target: .opponent)
            // メイン技（powerRate 1.0）は特攻、サブ技は攻撃を使用
            let attackStat = chosen.powerRate >= 1.0 ? myStats.specialAttack : myStats.attack
            let defStat = opponentStats.specialDefense
            let rawDamage = Double(attackStat) * chosen.powerRate * multiplier
            damage = max(Int(rawDamage * 100.0 / (100.0 + Double(defStat))), 1)
            opponentHp -= damage
            damageToOpponent = damage
            let name = myName ?? "〇〇"
            if multiplier > 1.0 {
                showBattleMessage("\(name)の\(chosen.name)攻撃！\nこうかはばつぐんだ！")
            } else if multiplier < 1.0 {
                showBattleMessage("\(name)の\(chosen.name)攻撃！\nこうかはいまひとつ...")
            } else {
                showBattleMessage("\(name)の\(chosen.name)攻撃！")
            }
        } else {
            SoundPlayerComponent.shared.play(.miss)
            parformMissAnimation(target: .opponent)
            damage = 0
            damageToOpponent = 0
            let name = myName ?? "〇〇"
            showBattleMessage("\(name)の攻撃は外れた！")
        }

        // ダメージ表示を1秒後に消す
        Task {
            try? await Task.sleep(for: .seconds(1.0))
            damageToOpponent = nil
        }

        // 勝利判定
        if hit, opponentHp <= 0 {
            opponentHp = 0
            isFinishing = true
            Task {
                try? await Task.sleep(for: .seconds(1.5))
                self.phase = .won
            }
            return
        }

        // CPUの攻撃を1〜2秒後に実行
        cpuAttackTask = Task {
            let delay = Double.random(in: 1.0...2.0)
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled, self.phase == .battling else { return }
            self.performCPUAttack()
        }
    }

    // MARK: - CPU攻撃

    /// CPUの攻撃ロジック（少し賢い: 60%で有利な技を優先）
    private func performCPUAttack() {
        guard let opponentStats, let myStats, let myLabel else { return }

        // 使える技を絞り込む
        let available = cpuAttacks.indices.filter { i in
            guard let pp = cpuAttackPP[i] else { return true }
            return pp > 0
        }
        guard !available.isEmpty else {
            // 全技PP切れ → プレイヤーにターンを渡す
            let oppName = opponentName ?? "CPU"
            showBattleMessage("\(oppName)は技を出せない！")
            isMyTurn = true
            startTurnTimer()
            return
        }

        // AI戦略: 60%で有利な技を優先、40%でランダム
        let chosenIndex: Int
        if Double.random(in: 0..<1) < 0.6 {
            let superEffective = available.filter { i in
                cpuAttacks[i].type.effectiveness(against: myLabel) > 1.0
            }
            chosenIndex = superEffective.randomElement() ?? available.randomElement()!
        } else {
            chosenIndex = available.randomElement()!
        }

        let chosen = cpuAttacks[chosenIndex]
        let multiplier = chosen.type.effectiveness(against: myLabel)

        // PP 消費
        if cpuAttackPP[chosenIndex] != nil { cpuAttackPP[chosenIndex]! -= 1 }

        // 命中判定
        let accuracy: Double = multiplier > 1.0 ? 0.7 : (multiplier < 1.0 ? 1.0 : 0.9)
        let hit = Double.random(in: 0..<1) < accuracy

        if hit {
            SoundPlayerComponent.shared.play(chosen.sound)
            showAttackEffect(attack: chosen, target: .me)
            parformDamageAnimation(target: .me)
            let attackStat = chosen.powerRate >= 1.0 ? opponentStats.specialAttack : opponentStats.attack
            let defStat = myStats.specialDefense
            let rawDamage = Double(attackStat) * chosen.powerRate * multiplier
            let damage = max(Int(rawDamage * 100.0 / (100.0 + Double(defStat))), 1)
            myHp -= damage
            damageToMe = damage
            let oppName = opponentName ?? "CPU"
            if multiplier > 1.0 {
                showBattleMessage("\(oppName)の\(chosen.name)攻撃！\nこうかはばつぐんだ！")
            } else if multiplier < 1.0 {
                showBattleMessage("\(oppName)の\(chosen.name)攻撃！\nこうかはいまひとつ...")
            } else {
                showBattleMessage("\(oppName)の\(chosen.name)攻撃！")
            }
        } else {
            SoundPlayerComponent.shared.play(.miss)
            parformMissAnimation(target: .me)
            damageToMe = 0
            let oppName = opponentName ?? "CPU"
            showBattleMessage("\(oppName)の攻撃は外れた！")
        }

        // ダメージ表示を1秒後に消す
        Task {
            try? await Task.sleep(for: .seconds(1.0))
            damageToMe = nil
        }

        // 敗北判定
        if hit, myHp <= 0 {
            myHp = 0
            isFinishing = true
            Task {
                try? await Task.sleep(for: .seconds(1.5))
                self.phase = .lost
            }
        } else {
            isMyTurn = true
            startTurnTimer()
        }
    }

    // MARK: - クリーンアップ

    override func cleanup() {
        cpuAttackTask?.cancel()
        cpuAttackTask = nil
        isFinishing = false
        stopTurnTimer()
    }

    // MARK: - Private

    /// サムネイルを SubjectDetector で切り抜く（失敗時は元データをそのまま返す）
    private func cutoutThumbnail(_ data: Data?) async -> Data? {
        guard let data, let image = UIImage(data: data) else { return data }
        guard let cutout = try? await SubjectDetector.detectAndCutout(from: image) else { return data }
        return cutout.pngData()
    }
}
