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
    private var subscribeTask: Task<Void, Never>?

    init(battleId: UUID) {
        self.battleId = battleId
    }

    // MARK: - 準備

    /// バトル情報を取得してステータスを算出し、Broadcast チャネルに接続する
    func prepare() async {
        do {
            let userId = try await client.auth.session.user.id
            self.userId = userId

            // battles テーブルからバトル詳細を取得
            let battle: BattleFullRow = try await client
                .from("battles")
                .select("id, status, player1_id, player1_monster_id, player2_id, player2_monster_id")
                .eq("id", value: battleId.uuidString)
                .single()
                .execute()
                .value

            isPlayer1 = battle.player1Id == userId

            guard let player2MonsterId = battle.player2MonsterId else {
                phase = .preparing
                return
            }

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

            // Broadcast チャネルを購読
            subscribeToBattle()

            // Player1 が先攻
            isMyTurn = isPlayer1
            phase = .battling
            print("[Battle] 準備完了 isPlayer1=\(isPlayer1) myHp=\(myHp) oppHp=\(opponentHp)")
        } catch {
            print("[Battle] prepare エラー: \(error)")
            battleLog.append("エラー: \(error.localizedDescription)")
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

        // Broadcast で相手に通知
        Task {
            do {
                try await channel?.broadcast(event: "attack", message: AttackMessage(type: "attack"))
                print("[Battle] attack 送信")
            } catch {
                print("[Battle] attack 送信エラー: \(error)")
            }
        }

        // 勝利判定
        if opponentHp <= 0 {
            opponentHp = 0
            phase = .won
            battleLog.append("勝利！")
            finishBattle(winnerId: userId)
        }
    }

    // MARK: - クリーンアップ

    func cleanup() {
        subscribeTask?.cancel()
        subscribeTask = nil
        subscription = nil
        if let channel {
            Task {
                await channel.unsubscribe()
                await client.removeChannel(channel)
            }
        }
        channel = nil
    }

    // MARK: - Private

    /// Broadcast チャネルを購読して攻撃イベントを受信する
    private func subscribeToBattle() {
        let ch = client.channel("battle-game-\(battleId.uuidString)")
        channel = ch

        // onBroadcast は subscribe() の前に登録する
        subscription = ch.onBroadcast(event: "attack") { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleOpponentAttack()
            }
        }

        subscribeTask = Task {
            do {
                try await ch.subscribeWithError()
                print("[Battle] Broadcast 購読成功")
            } catch {
                print("[Battle] Broadcast 購読失敗: \(error)")
            }
        }
    }

    /// 相手の攻撃を受信した時の処理
    private func handleOpponentAttack() {
        guard let opponentStats else { return }

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
