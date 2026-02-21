//
//  BattleViewModel.swift
//  Pikumei
//
//  バトルロジック + Realtime Broadcast 同期
//

import Foundation
import UIKit
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
    @Published var battleMessage: String?     // 画面に一時表示するメッセージ
    @Published var myAttacks: [BattleAttack] = []
    @Published var attackPP: [Int?] = []  // nil = 無制限, 数値 = 残り回数
    @Published var effectOnOpponent: String?  // 相手モンスター上に表示するエフェクト
    @Published var effectOnMe: String?        // 自分モンスター上に表示するエフェクト
    @Published var damageToOpponent: Int?  // 相手へのダメージ（0 = MISS）
    @Published var damageToMe: Int?  // 自分へのダメージ（0 = MISS）
    @Published var turnTimeRemaining: Int = 0  // ターン制限時間の残り秒数

    let battleId: UUID
    private var isPlayer1 = false
    private var userId: UUID?
    private let client = SupabaseClientProvider.shared
    private var channel: RealtimeChannelV2?
    private var subscription: RealtimeSubscription?
    private var readySubscription: RealtimeSubscription?
    private var readyPingTask: Task<Void, Never>?
    private var attackResendTask: Task<Void, Never>?
    private var opponentTimeoutTask: Task<Void, Never>?
    var turnTimerTask: Task<Void, Never>?
    private var finishedSubscription: RealtimeSubscription?
    private var opponentReady = false
    private var myTurnCount = 0          // 自分の攻撃ターン番号（送信用）
    private var lastReceivedTurn = -1    // 相手から受信した最新ターン番号（重複排除用）

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
            // まず生データを表示し、チャネル接続を優先する
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

            // 切り抜きは接続後にバックグラウンドで実行（白背景を除去）
            Task {
                let myData = myMonster.thumbnailData
                let oppData = oppMonster.thumbnailData
                async let myCutout = cutoutThumbnail(myData)
                async let oppCutout = cutoutThumbnail(oppData)
                self.myThumbnail = await myCutout
                self.opponentThumbnail = await oppCutout
            }
        } catch {
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
    private let effectSpeed: Double = 1.5

    enum AttackTarget { case opponent, me }

    func showAttackEffect(attack: BattleAttack, target: AttackTarget) {
        let gifName = attack.effectGif
        let originalDuration = GifCacheStore.shared.frames(for: gifName)?.duration ?? 1.0
        let displayDuration = originalDuration / effectSpeed

        switch target {
        case .opponent:
            effectOnOpponent = gifName
            Task {
                try? await Task.sleep(for: .seconds(displayDuration))
                effectOnOpponent = nil
            }
        case .me:
            effectOnMe = gifName
            Task {
                try? await Task.sleep(for: .seconds(displayDuration))
                effectOnMe = nil
            }
        }
    }

    // MARK: - 攻撃

    /// 選択した攻撃を送信し、相手の HP を減らす
    func attack(index: Int) {
        guard isMyTurn, let myStats, let opponentStats, let opponentLabel else { return }
        guard index < myAttacks.count else { return }
        // PP チェック
        if let pp = attackPP[index], pp <= 0 { return }
        stopTurnTimer()
        isMyTurn = false
        // 相手の攻撃待ちタイムアウト監視を開始
        startOpponentTimeout()

        let chosen = myAttacks[index]
        let multiplier = chosen.type.effectiveness(against: opponentLabel)

        // PP 消費
        if attackPP[index] != nil { attackPP[index]! -= 1 }

        // 命中判定
        let accuracy: Double = multiplier > 1.0 ? 0.7 : (multiplier < 1.0 ? 1.0 : 0.9)
        let hit = Double.random(in: 0..<1) < accuracy

        let damage: Int
        if hit {
            // ヒット時のみ攻撃エフェクト・効果音を再生
            SoundPlayerComponent.shared.play(chosen.sound)
            showAttackEffect(attack: chosen, target: .opponent)
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
            // ミス時はGIFエフェクトなしでミス効果音のみ再生
            SoundPlayerComponent.shared.play(.miss)
            damage = 0
            damageToOpponent = 0  // 0 = MISS 表示用
            let name = myName ?? "〇〇"
            showBattleMessage("\(name)の攻撃は外れた！")
        }

        // ダメージ表示を1秒後に消す
        Task {
            try? await Task.sleep(for: .seconds(1.0))
            damageToOpponent = nil
        }

        // 攻撃 Broadcast を相手が応答するまで定期再送（startReadyPing パターン）
        myTurnCount += 1
        let message = AttackMessage(type: "attack", turn: myTurnCount, attackType: chosen.type.rawValue, hit: hit, damage: damage)
        attackResendTask?.cancel()
        attackResendTask = Task {
            // 初回送信
            try? await channel?.broadcast(event: "attack", message: message)

            // 勝利判定（初回送信後）
            if hit, opponentHp <= 0, self.phase == .battling {
                opponentHp = 0
                phase = .won
                finishBattle(winnerId: userId)
                // 敗者に終了を通知
                if let winnerId = self.userId {
                    let finishedMsg = FinishedMessage(type: "finished", winnerId: winnerId.uuidString)
                    try? await self.channel?.broadcast(event: "finished", message: finishedMsg)
                }
            }

            // 相手が応答（次の攻撃を送信）するまで 2 秒ごとに再送
            // タイムアウト検知は opponentTimeoutTask に委譲
            var elapsed = 0
            while !Task.isCancelled, !self.isMyTurn, elapsed < 20 {
                let p = self.phase
                guard p == .battling || p == .won else { break }
                try? await Task.sleep(for: .seconds(2))
                elapsed += 2
                guard !Task.isCancelled, !self.isMyTurn else { break }
                let p2 = self.phase
                guard p2 == .battling || p2 == .won else { break }
                try? await channel?.broadcast(event: "attack", message: message)
                // 勝利確定済みなら finished も再送
                if p2 == .won, let winnerId = self.userId {
                    let finishedMsg = FinishedMessage(type: "finished", winnerId: winnerId.uuidString)
                    try? await self.channel?.broadcast(event: "finished", message: finishedMsg)
                }
            }
        }
    }

    // MARK: - クリーンアップ

    func cleanup() {
        readyPingTask?.cancel()
        readyPingTask = nil
        attackResendTask?.cancel()
        attackResendTask = nil
        opponentTimeoutTask?.cancel()
        opponentTimeoutTask = nil
        stopTurnTimer()
        subscription = nil
        readySubscription = nil
        finishedSubscription = nil
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
            let turn = inner?["turn"]?.intValue
            let attackTypeRaw = inner?["attackType"]?.stringValue
            let hit = inner?["hit"]?.boolValue ?? false  // 安全側デフォルト
            let damage = inner?["damage"]?.intValue
            Task { @MainActor [weak self] in
                self?.handleOpponentAttack(turn: turn, attackTypeRaw: attackTypeRaw, hit: hit, damage: damage)
            }
        }

        readySubscription = ch.onBroadcast(event: "ready") { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleOpponentReady()
            }
        }

        // 相手の勝利通知を受信したら敗北に遷移する
        finishedSubscription = ch.onBroadcast(event: "finished") { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.phase == .battling else { return }
                self.opponentTimeoutTask?.cancel()
                self.opponentTimeoutTask = nil
                self.myHp = 0
                self.phase = .lost
            }
        }

        // subscribe 完了を待ってから phase を遷移させる
        try await ch.subscribeWithError()

        // 相手が subscribe 完了するまで少し待つ（レースコンディション対策）
        try await Task.sleep(for: .seconds(2))

        startReadyPing()
    }

    /// ready イベントを定期送信（相手の ready を受信するまで、20秒でタイムアウト）
    private func startReadyPing() {
        readyPingTask = Task {
            var elapsed = 0
            while !opponentReady, elapsed < 20 {
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
                    phase = .connectionError
                }
            }
        }
    }

    /// 相手の攻撃待ちタイムアウト（相手のターン制限15秒＋通信遅延を考慮して20秒）
    private func startOpponentTimeout() {
        opponentTimeoutTask?.cancel()
        opponentTimeoutTask = Task {
            try? await Task.sleep(for: .seconds(20))
            guard !Task.isCancelled, !self.isMyTurn, self.phase == .battling else { return }
            phase = .connectionError
        }
    }

    /// ターン制限タイマーを開始（15秒で自動攻撃）
    func startTurnTimer() {
        stopTurnTimer()
        turnTimeRemaining = 15
        turnTimerTask = Task {
            for _ in 0..<15 {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                turnTimeRemaining -= 1
            }
            guard !Task.isCancelled, self.isMyTurn, self.phase == .battling else { return }
            // 時間切れ：PP が残っている技からランダムに自動攻撃
            let available = myAttacks.indices.filter { i in
                guard let pp = attackPP[i] else { return true }  // nil = 無制限
                return pp > 0
            }
            let chosen = available.randomElement() ?? 0
            attack(index: chosen)
        }
    }

    /// ターン制限タイマーを停止
    func stopTurnTimer() {
        turnTimerTask?.cancel()
        turnTimerTask = nil
        turnTimeRemaining = 0
    }

    /// 相手の ready を受信
    private func handleOpponentReady() {
        guard phase == .battling, !opponentReady else { return }
        opponentReady = true
        readyPingTask?.cancel()
        readyPingTask = nil

        // 相手に ready を複数回返す（相手が受信できていない可能性があるため）
        Task {
            for _ in 0..<3 {
                try? await channel?.broadcast(event: "ready", message: ReadyMessage(type: "ready"))
                try? await Task.sleep(for: .milliseconds(200))
            }
        }

        isMyTurn = isPlayer1
        showBattleMessage("バトル開始！")

        // Player1（先攻）はターン制限タイマーを開始
        if isMyTurn {
            startTurnTimer()
        }

        // Player2（受信待ち側）はタイムアウト監視を開始
        if !isMyTurn {
            startOpponentTimeout()
        }
    }

    /// 相手の攻撃を受信した時の処理
    private func handleOpponentAttack(turn: Int?, attackTypeRaw: String?, hit: Bool, damage receivedDamage: Int?) {
        // ターン番号による重複排除：同じターンのリトライメッセージは無視する
        if let turn, turn <= lastReceivedTurn { return }
        if let turn { lastReceivedTurn = turn }

        guard phase == .battling, let myStats, let opponentStats, let opponentLabel, let myLabel else { return }

        // 攻撃を受信したのでタイムアウト監視をキャンセル
        opponentTimeoutTask?.cancel()
        opponentTimeoutTask = nil

        // 前回攻撃のリトライ停止（相手がこちらの攻撃を受信済みであることが確認できた）
        attackResendTask?.cancel()
        attackResendTask = nil

        let attackType = MonsterType(rawValue: attackTypeRaw ?? "") ?? opponentLabel
        let opponentAttack = opponentLabel.attacks.first { $0.type == attackType }
        let attackName = opponentAttack?.name

        if hit {
            // ヒット時のみ攻撃エフェクト・効果音を再生
            SoundPlayerComponent.shared.play(opponentAttack?.sound ?? .panch)
            if let opponentAttack {
                showAttackEffect(attack: opponentAttack, target: .me)
            }
            let actualDamage: Int
            if let receivedDamage, receivedDamage > 0 {
                // 送信側が計算したダメージ値を使用
                actualDamage = receivedDamage
            } else {
                // フォールバック（旧バージョン互換）
                let powerRate = opponentLabel.attacks.first { $0.type == attackType }?.powerRate ?? 1.0
                let multiplier = attackType.effectiveness(against: myLabel)
                let attackStat = powerRate >= 1.0 ? opponentStats.specialAttack : opponentStats.attack
                let defStat = myStats.specialDefense
                let rawDamage = Double(attackStat) * powerRate * multiplier
                actualDamage = max(Int(rawDamage * 100.0 / (100.0 + Double(defStat))), 1)
            }
            myHp -= actualDamage
            damageToMe = actualDamage

            let oppName = opponentName ?? "〇〇"
            let atkLabel = attackName.map { "\($0)" } ?? ""
            let multiplier = attackType.effectiveness(against: myLabel)
            if multiplier > 1.0 {
                showBattleMessage("\(oppName)の\(atkLabel)攻撃！\nこうかはばつぐんだ！")
            } else if multiplier < 1.0 {
                showBattleMessage("\(oppName)の\(atkLabel)攻撃！\nこうかはいまひとつ...")
            } else {
                showBattleMessage("\(oppName)の\(atkLabel)攻撃！")
            }
        } else {
            // ミス時はGIFエフェクトなしでミス効果音のみ再生
            SoundPlayerComponent.shared.play(.miss)
            damageToMe = 0  // 0 = MISS 表示用
            let oppName = opponentName ?? "〇〇"
            showBattleMessage("\(oppName)の攻撃は外れた！")
        }

        // ダメージ表示を1秒後に消す
        Task {
            try? await Task.sleep(for: .seconds(1.0))
            damageToMe = nil
        }

        if myHp <= 0 {
            myHp = 0
            phase = .lost
        } else {
            isMyTurn = true
            startTurnTimer()
        }
    }

    /// battleMessage をセットする（次のメッセージで上書きされるまで表示し続ける）
    func showBattleMessage(_ text: String) {
        battleMessage = text
    }

    /// サムネイルを SubjectDetector で切り抜く（失敗時は元データをそのまま返す）
    private func cutoutThumbnail(_ data: Data?) async -> Data? {
        guard let data, let image = UIImage(data: data) else { return data }
        guard let cutout = try? await SubjectDetector.detectAndCutout(from: image) else { return data }
        return cutout.pngData()
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
    let turn: Int     // ターン番号（リトライ重複排除用）
    let attackType: String
    let hit: Bool
    let damage: Int   // hit 時のダメージ量（miss 時は 0）
}

/// 準備完了イベント用
private struct ReadyMessage: Codable {
    let type: String
}

/// バトル終了イベント用（勝者が敗者に終了を通知する）
private struct FinishedMessage: Codable {
    let type: String
    let winnerId: String
}
