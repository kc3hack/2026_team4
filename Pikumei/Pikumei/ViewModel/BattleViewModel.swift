//
//  BattleViewModel.swift
//  Pikumei
//
//  バトルロジック + Realtime Broadcast 同期
//

import Foundation
import Supabase
import Combine

@MainActor
class BattleViewModel: ObservableObject {
    @Published var phase: BattlePhase = .preparing
    @Published var myStats: BattleStats?
    @Published var opponentStats: BattleStats?
    @Published var myHp: Int = 0
    @Published var opponentHp: Int = 0
    @Published var isMyTurn: Bool = false
    @Published var myLabel: MonsterType?
    @Published var opponentLabel: MonsterType?
    @Published var myName: String?
    @Published var opponentName: String?
    @Published var myThumbnail: Data?
    @Published var opponentThumbnail: Data?
    @Published var battleLog: [String] = []
    @Published var myAttacks: [BattleAttack] = []
    @Published var attackPP: [Int?] = []  // nil = 無制限, 数値 = 残り回数
    @Published var attackEffectGif: String?  // 攻撃エフェクトのGIF名

    let battleId: UUID
    private var isPlayer1 = false
    private var userId: UUID?
    private let client = SupabaseClientProvider.shared
    private var channel: RealtimeChannelV2?
    private var subscription: RealtimeSubscription?
    private var readySubscription: RealtimeSubscription?
    private var readyPingTask: Task<Void, Never>?
    private var opponentReady = false

    init(battleId: UUID) {
        self.battleId = battleId
    }

    // MARK: - 準備

    /// バトル情報を取得してステータスを算出し、Broadcast チャネルに接続する
    func prepare() async {
        do {
            let userId = try await client.auth.session.user.id
            self.userId = userId

            // battles テーブルからバトル詳細を取得（player2 未設定時はリトライ）
            var battle: BattleFullRow?
            for _ in 0..<5 {
                let row: BattleFullRow = try await client
                    .from("battles")
                    .select("id, status, player1_id, player1_monster_id, player2_id, player2_monster_id")
                    .eq("id", value: battleId.uuidString)
                    .single()
                    .execute()
                    .value

                if row.player2MonsterId != nil {
                    battle = row
                    break
                }

                try await Task.sleep(for: .seconds(1))
            }

            guard let battle, let player2MonsterId = battle.player2MonsterId else {
                battleLog.append("対戦相手の情報を取得できませんでした")
                phase = .connectionError
                return
            }

            isPlayer1 = battle.player1Id == userId

            // 両方のモンスターの label を取得
            let myMonsterId = isPlayer1 ? battle.player1MonsterId : player2MonsterId
            let oppMonsterId = isPlayer1 ? player2MonsterId : battle.player1MonsterId

            let myMonster: MonsterLabelRow = try await client
                .from("monsters")
                .select("id, classification_label, classification_confidence, name, thumbnail")
                .eq("id", value: myMonsterId.uuidString)
                .single()
                .execute()
                .value

            let oppMonster: MonsterLabelRow = try await client
                .from("monsters")
                .select("id, classification_label, classification_confidence, name, thumbnail")
                .eq("id", value: oppMonsterId.uuidString)
                .single()
                .execute()
                .value

            // BattleStats を算出
            let my = BattleStatsGenerator.generate(label: myMonster.classificationLabel, confidence: myMonster.classificationConfidence ?? 0.85)
            let opp = BattleStatsGenerator.generate(label: oppMonster.classificationLabel, confidence: oppMonster.classificationConfidence ?? 0.85)

            myStats = my
            opponentStats = opp
            myHp = my.hp
            opponentHp = opp.hp
            myLabel = myMonster.classificationLabel
            opponentLabel = oppMonster.classificationLabel
            myName = myMonster.name
            opponentName = oppMonster.name
            myThumbnail = myMonster.thumbnailData
            opponentThumbnail = oppMonster.thumbnailData
            myAttacks = myMonster.classificationLabel.attacks

            // ばつぐん技のみ PP 2、それ以外は無制限
            attackPP = myAttacks.map { atk in
                let eff = atk.type.effectiveness(against: oppMonster.classificationLabel)
                return eff > 1.0 ? 2 : nil
            }

            // 攻撃エフェクトGIFを事前読み込み
            GifCacheStore.shared.preload(myAttacks.map { $0.effectGif })

            // Broadcast チャネルを購読（ready ハンドシェイク後にターン開始）
            try await subscribeToBattle()

            phase = .battling
        } catch {
            battleLog.append("エラー: \(error.localizedDescription)")
            phase = .connectionError
        }
    }

    // MARK: - 攻撃表示用

    /// 攻撃の相性倍率を返す
    func attackEffectiveness(at index: Int) -> Double? {
        guard index < myAttacks.count, let opponentLabel else { return nil }
        return myAttacks[index].type.effectiveness(against: opponentLabel)
    }

    /// 攻撃の命中率（%）を返す
    func attackAccuracy(at index: Int) -> Int? {
        guard let eff = attackEffectiveness(at: index) else { return nil }
        return eff > 1.0 ? 70 : (eff < 1.0 ? 100 : 90)
    }

    /// 攻撃エフェクトを表示して再生完了後に消す
    private let effectSpeed: Double = 3.0

    func showAttackEffect(attack: BattleAttack) {
        let gifName = attack.effectGif
        attackEffectGif = gifName
        // キャッシュから実際の再生時間を取得し、速度倍率で割った時間後に消す
        let originalDuration = GifCacheStore.shared.frames(for: gifName)?.duration ?? 1.0
        let displayDuration = originalDuration / effectSpeed
        Task {
            try? await Task.sleep(for: .seconds(displayDuration))
            attackEffectGif = nil
        }
    }

    // MARK: - 攻撃

    /// 選択した攻撃を送信し、相手の HP を減らす
    func attack(index: Int) {
        guard isMyTurn, let myStats, let opponentStats, let opponentLabel else { return }
        guard index < myAttacks.count else { return }
        // PP チェック
        if let pp = attackPP[index], pp <= 0 { return }
        isMyTurn = false

        let chosen = myAttacks[index]
        SoundPlayerComponent.shared.play(chosen.sound)
        showAttackEffect(attack: chosen)
        let multiplier = chosen.type.effectiveness(against: opponentLabel)

        // PP 消費
        if attackPP[index] != nil { attackPP[index]! -= 1 }

        // 命中判定
        let accuracy: Double = multiplier > 1.0 ? 0.7 : (multiplier < 1.0 ? 1.0 : 0.9)
        let hit = Double.random(in: 0..<1) < accuracy

        if hit {
            // メイン技（powerRate 1.0）は特攻、サブ技は攻撃を使用
            let attackStat = chosen.powerRate >= 1.0 ? myStats.specialAttack : myStats.attack
            let defStat = opponentStats.specialDefense
            let rawDamage = Double(attackStat) * chosen.powerRate * multiplier
            let damage = max(Int(rawDamage * 100.0 / (100.0 + Double(defStat))), 1)
            opponentHp -= damage
            battleLog.append("\(chosen.name)攻撃！ \(damage) ダメージ！")
            if multiplier > 1.0 { battleLog.append("こうかはばつぐんだ！") }
            else if multiplier < 1.0 { battleLog.append("こうかはいまひとつ...") }
        } else {
            battleLog.append("\(chosen.name)攻撃！ ...しかし外れた！")
        }

        // Broadcast 送信完了後に勝利判定（送信前に cleanup されるのを防ぐ）
        Task {
            do {
                try await channel?.broadcast(
                    event: "attack",
                    message: AttackMessage(type: "attack", attackType: chosen.type.rawValue, hit: hit)
                )
            } catch {
                battleLog.append("攻撃の送信に失敗しました")
            }

            if hit, opponentHp <= 0, self.phase == .battling {
                opponentHp = 0
                phase = .won
                battleLog.append("勝利！")
                finishBattle(winnerId: userId)
            }
        }
    }

    // MARK: - クリーンアップ

    func cleanup() {
        readyPingTask?.cancel()
        readyPingTask = nil
        subscription = nil
        readySubscription = nil
        if let channel {
            Task {
                await channel.unsubscribe()
                await client.removeChannel(channel)
            }
        }
        channel = nil
    }

    // MARK: - Private

    /// Broadcast チャネルを購読して攻撃・ready イベントを受信する
    private func subscribeToBattle() async throws {
        let ch = client.channel("battle-game-\(battleId.uuidString)")
        channel = ch

        // onBroadcast は subscribe() の前に登録する
        subscription = ch.onBroadcast(event: "attack") { [weak self] payload in
            // SDK は message を payload["payload"] の下にネストする
            let inner = payload["payload"]?.objectValue
            let attackTypeRaw = inner?["attackType"]?.stringValue
            let hit = inner?["hit"]?.boolValue ?? true
            Task { @MainActor [weak self] in
                self?.handleOpponentAttack(attackTypeRaw: attackTypeRaw, hit: hit)
            }
        }

        readySubscription = ch.onBroadcast(event: "ready") { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleOpponentReady()
            }
        }

        // subscribe 完了を待ってから phase を遷移させる
        try await ch.subscribeWithError()
        startReadyPing()
    }

    /// ready イベントを定期送信（相手の ready を受信するまで、10秒でタイムアウト）
    private func startReadyPing() {
        readyPingTask = Task {
            var elapsed = 0
            while !opponentReady, elapsed < 10 {
                do {
                    try await channel?.broadcast(event: "ready", message: ReadyMessage(type: "ready"))
                    try await Task.sleep(for: .seconds(1))
                    elapsed += 1
                } catch {
                    break
                }
            }
            // タイムアウト: 相手が応答しなかった
            if !opponentReady {
                await MainActor.run {
                    battleLog.append("対戦相手との接続がタイムアウトしました")
                    phase = .connectionError
                }
            }
        }
    }

    /// 相手の ready を受信
    private func handleOpponentReady() {
        guard phase == .battling, !opponentReady else { return }
        opponentReady = true
        readyPingTask?.cancel()
        readyPingTask = nil

        // 相手に ready を返す（相手がまだ受信していない可能性があるため）
        Task {
            try? await channel?.broadcast(event: "ready", message: ReadyMessage(type: "ready"))
        }

        isMyTurn = isPlayer1
        battleLog.append("バトル開始！")
    }

    /// 相手の攻撃を受信した時の処理
    private func handleOpponentAttack(attackTypeRaw: String?, hit: Bool) {
        guard phase == .battling, let myStats, let opponentStats, let opponentLabel, let myLabel else { return }

        let attackType = MonsterType(rawValue: attackTypeRaw ?? "") ?? opponentLabel
        let opponentAttack = opponentLabel.attacks.first { $0.type == attackType }
        let attackName = opponentAttack?.name ?? "???"

        // 相手の技の効果音・エフェクトを再生
        SoundPlayerComponent.shared.play(opponentAttack?.sound ?? .panch)
        if let opponentAttack {
            showAttackEffect(attack: opponentAttack)
        }

        if hit {
            let powerRate = opponentLabel.attacks.first { $0.type == attackType }?.powerRate ?? 1.0
            let multiplier = attackType.effectiveness(against: myLabel)
            // メイン技（powerRate 1.0）は特攻、サブ技は攻撃を使用
            let attackStat = powerRate >= 1.0 ? opponentStats.specialAttack : opponentStats.attack
            let defStat = myStats.specialDefense
            let rawDamage = Double(attackStat) * powerRate * multiplier
            let damage = max(Int(rawDamage * 100.0 / (100.0 + Double(defStat))), 1)
            myHp -= damage

            battleLog.append("\(attackName)攻撃！ \(damage) ダメージ！")
            if multiplier > 1.0 { battleLog.append("こうかはばつぐんだ！") }
            else if multiplier < 1.0 { battleLog.append("こうかはいまひとつ...") }
        } else {
            battleLog.append("\(attackName)攻撃！ ...しかし外れた！")
        }

        if myHp <= 0 {
            myHp = 0
            phase = .lost
            battleLog.append("敗北...")
        } else {
            isMyTurn = true
        }
    }

    /// バトル終了を DB に記録する
    private func finishBattle(winnerId: UUID?) {
        guard let winnerId else { return }
        Task {
            do {
                let update = BattleFinishUpdate(winnerId: winnerId, status: "finished")
                try await client
                    .from("battles")
                    .update(update)
                    .eq("id", value: battleId.uuidString)
                    .execute()
            } catch {
                print("⚠️ バトル結果の記録に失敗: \(error)")
            }
        }
    }

}

// MARK: - Broadcast メッセージ

/// 攻撃イベント用（Codable で broadcast に渡す）
private struct AttackMessage: Codable {
    let type: String
    let attackType: String
    let hit: Bool
}

/// 準備完了イベント用
private struct ReadyMessage: Codable {
    let type: String
}
