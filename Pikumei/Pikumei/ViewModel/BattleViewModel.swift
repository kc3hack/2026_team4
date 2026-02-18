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
    @Published var myLabel: String = ""
    @Published var opponentLabel: String = ""
    @Published var battleLog: [String] = []

    let battleId: UUID
    private var isPlayer1 = false
    private var userId: UUID?
    private let client = SupabaseClientProvider.shared
    private var channel: RealtimeChannelV2?
    private var subscription: RealtimeSubscription?
    private var readySubscription: RealtimeSubscription?
    private var subscribeTask: Task<Void, Never>?
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
            for attempt in 0..<5 {
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

                print("[Battle] player2 未設定、リトライ \(attempt + 1)/5")
                try await Task.sleep(for: .seconds(1))
            }

            guard let battle, let player2MonsterId = battle.player2MonsterId else {
                battleLog.append("対戦相手の情報を取得できませんでした")
                phase = .lost
                return
            }

            isPlayer1 = battle.player1Id == userId

            // 両方のモンスターの label を取得
            let myMonsterId = isPlayer1 ? battle.player1MonsterId : player2MonsterId
            let oppMonsterId = isPlayer1 ? player2MonsterId : battle.player1MonsterId

            let myMonster: MonsterLabelRow = try await client
                .from("monsters")
                .select("id, classification_label")
                .eq("id", value: myMonsterId.uuidString)
                .single()
                .execute()
                .value

            let oppMonster: MonsterLabelRow = try await client
                .from("monsters")
                .select("id, classification_label")
                .eq("id", value: oppMonsterId.uuidString)
                .single()
                .execute()
                .value

            // BattleStats を算出（confidence は DB にないため固定値）
            let my = BattleStatsGenerator.generate(label: myMonster.classificationLabel, confidence: 0.85)
            let opp = BattleStatsGenerator.generate(label: oppMonster.classificationLabel, confidence: 0.85)

            myStats = my
            opponentStats = opp
            myHp = my.hp
            opponentHp = opp.hp
            myLabel = myMonster.classificationLabel
            opponentLabel = oppMonster.classificationLabel

            // Broadcast チャネルを購読（ready ハンドシェイク後にターン開始）
            subscribeToBattle()

            phase = .battling
            print("[Battle] 準備完了 isPlayer1=\(isPlayer1) myHp=\(myHp) oppHp=\(opponentHp)")
        } catch {
            print("[Battle] prepare エラー: \(error)")
            battleLog.append("エラー: \(error.localizedDescription)")
            phase = .lost
        }
    }

    // MARK: - 攻撃

    /// 攻撃を送信し、相手の HP を減らす
    func attack() {
        guard isMyTurn, let myStats else { return }
        isMyTurn = false

        // 相手の HP を減らす（自分側に即時反映）
        opponentHp -= myStats.attack
        battleLog.append("\(myLabel) の攻撃！ \(myStats.attack) ダメージ！")

        // Broadcast 送信完了後に勝利判定（送信前に cleanup されるのを防ぐ）
        Task {
            try? await channel?.broadcast(event: "attack", message: AttackMessage(type: "attack"))
            print("[Battle] attack 送信")

            if opponentHp <= 0, self.phase == .battling {
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
        subscribeTask?.cancel()
        subscribeTask = nil
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
    private func subscribeToBattle() {
        let ch = client.channel("battle-game-\(battleId.uuidString)")
        channel = ch

        // onBroadcast は subscribe() の前に登録する
        subscription = ch.onBroadcast(event: "attack") { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleOpponentAttack()
            }
        }

        readySubscription = ch.onBroadcast(event: "ready") { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleOpponentReady()
            }
        }

        subscribeTask = Task {
            do {
                try await ch.subscribeWithError()
                print("[Battle] Broadcast 購読成功")
                // ready の定期送信を開始
                await MainActor.run {
                    self.startReadyPing()
                }
            } catch {
                print("[Battle] Broadcast 購読失敗: \(error)")
            }
        }
    }

    /// ready イベントを定期送信（相手の ready を受信するまで）
    private func startReadyPing() {
        readyPingTask = Task {
            while !opponentReady {
                do {
                    try await channel?.broadcast(event: "ready", message: ReadyMessage(type: "ready"))
                    print("[Battle] ready 送信")
                    try await Task.sleep(for: .seconds(1))
                } catch {
                    break
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
        print("[Battle] 相手の ready 受信")

        // 相手に ready を返す（相手がまだ受信していない可能性があるため）
        Task {
            try? await channel?.broadcast(event: "ready", message: ReadyMessage(type: "ready"))
        }

        isMyTurn = isPlayer1
        battleLog.append("バトル開始！")
    }

    /// 相手の攻撃を受信した時の処理
    private func handleOpponentAttack() {
        guard phase == .battling, let opponentStats else { return }

        myHp -= opponentStats.attack
        battleLog.append("\(opponentLabel) の攻撃！ \(opponentStats.attack) ダメージ！")

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
                print("[Battle] バトル終了 winner=\(winnerId)")
            } catch {
                print("[Battle] バトル終了更新エラー: \(error)")
            }
        }
    }

}

// MARK: - Broadcast メッセージ

/// 攻撃イベント用（Codable で broadcast に渡す）
private struct AttackMessage: Codable {
    let type: String
}

/// 準備完了イベント用
private struct ReadyMessage: Codable {
    let type: String
}
