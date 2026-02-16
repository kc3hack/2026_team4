//
//  BattleViewModel.swift
//  Pikumei
//

import Foundation
import Supabase
import SwiftData
import Combine

/// バトル画面の状態
enum BattlePhase: Equatable {
    case selectMonster       // モンスター選択
    case uploading           // Supabase へアップロード中
    case waiting             // 対戦相手を待機中
    case matched             // マッチ成立
    case battling            // バトル演出中
    case result(won: Bool)   // 結果表示
}

/// バトル画面の状態管理
@MainActor
class BattleViewModel: ObservableObject {
    @Published var phase: BattlePhase = .selectMonster
    @Published var selectedMonster: Monster?
    @Published var opponentLabel: String?
    @Published var battleLog: [BattleTurn] = []
    @Published var errorMessage: String?

    private let client = SupabaseClientProvider.shared
    private let syncService = MonsterSyncService()
    private var battleId: UUID?
    private var realtimeChannel: RealtimeChannelV2?

    // MARK: - バトル開始

    /// モンスターを選択してバトルを開始する
    func startBattle(monster: Monster) async {
        selectedMonster = monster
        phase = .uploading
        errorMessage = nil

        do {
            // Supabase にアップロード（未済の場合）
            try await syncService.upload(monster: monster)

            guard let supabaseId = monster.supabaseId else {
                throw BattleError.uploadFailed
            }

            // まず待機中のバトルを探す
            let waitingBattle = try await findWaitingBattle(excludingUserId: client.auth.session.user.id)

            if let battle = waitingBattle {
                // 既存のバトルに参加
                try await joinBattle(battleId: battle.id, monsterId: supabaseId)
            } else {
                // 新しいバトルを作成して待機
                try await createBattle(monsterId: supabaseId)
            }
        } catch {
            errorMessage = error.localizedDescription
            phase = .selectMonster
        }
    }

    /// バトルをキャンセルする（waiting 中のみ）
    func cancelBattle() async {
        guard let battleId, phase == .waiting else { return }

        do {
            try await client
                .from("battles")
                .delete()
                .eq("id", value: battleId.uuidString)
                .execute()
        } catch {
            print("バトルキャンセルエラー: \(error)")
        }

        await unsubscribeRealtime()
        self.battleId = nil
        phase = .selectMonster
    }

    // MARK: - マッチング

    /// 待機中のバトルを検索（自分以外が作成したもの）
    private func findWaitingBattle(excludingUserId userId: UUID) async throws -> BattleRecord? {
        let battles: [BattleRecord] = try await client
            .from("battles")
            .select()
            .eq("status", value: "waiting")
            .neq("player1_id", value: userId.uuidString)
            .order("created_at", ascending: true)
            .limit(1)
            .execute()
            .value

        return battles.first
    }

    /// 新しいバトルを作成して Realtime で監視する
    private func createBattle(monsterId: UUID) async throws {
        let userId = try await client.auth.session.user.id

        let record = BattleInsert(
            player1Id: userId,
            player1MonsterId: monsterId
        )

        let inserted: BattleRecord = try await client
            .from("battles")
            .insert(record, returning: .representation)
            .select()
            .single()
            .execute()
            .value

        battleId = inserted.id
        phase = .waiting
        await subscribeToRealtime(battleId: inserted.id)
    }

    /// 待機中のバトルに参加する
    private func joinBattle(battleId: UUID, monsterId: UUID) async throws {
        let userId = try await client.auth.session.user.id

        let updated: BattleRecord = try await client
            .from("battles")
            .update([
                "player2_id": AnyJSON.string(userId.uuidString),
                "player2_monster_id": AnyJSON.string(monsterId.uuidString),
                "status": AnyJSON.string("matched"),
            ])
            .eq("id", value: battleId.uuidString)
            .select()
            .single()
            .execute()
            .value

        self.battleId = updated.id

        // 相手のモンスター情報を取得
        if let opponentMonsterId = updated.player1MonsterId {
            await fetchOpponentMonster(monsterId: opponentMonsterId)
        }

        phase = .matched

        // バトル開始
        await startBattleSequence(battle: updated)
    }

    // MARK: - Realtime

    /// バトルの状態変化を監視する
    private func subscribeToRealtime(battleId: UUID) async {
        let channel = client.realtimeV2.channel("battle-\(battleId.uuidString)")

        let changes = channel.postgresChange(
            UpdateAction.self,
            schema: "public",
            table: "battles",
            filter: "id=eq.\(battleId.uuidString)"
        )

        await channel.subscribe()
        self.realtimeChannel = channel

        // バックグラウンドで変更を監視
        Task { [weak self] in
            for await change in changes {
                guard let self else { return }
                await self.handleBattleUpdate(change)
            }
        }
    }

    /// Realtime の更新を処理する
    private func handleBattleUpdate(_ change: UpdateAction) async {
        let decoder = JSONDecoder()
        guard let record = try? change.decodeRecord(decoder: decoder) as BattleRecord else { return }

        if record.status == "matched" && phase == .waiting {
            // 相手のモンスター情報を取得
            if let opponentMonsterId = record.player2MonsterId {
                await fetchOpponentMonster(monsterId: opponentMonsterId)
            }
            phase = .matched
            await startBattleSequence(battle: record)
        }
    }

    private func unsubscribeRealtime() async {
        if let channel = realtimeChannel {
            await channel.unsubscribe()
            realtimeChannel = nil
        }
    }

    // MARK: - 相手のモンスター情報取得

    private func fetchOpponentMonster(monsterId: UUID) async {
        do {
            let record: OpponentInfo = try await client
                .from("monsters")
                .select("classification_label")
                .eq("id", value: monsterId.uuidString)
                .single()
                .execute()
                .value

            opponentLabel = record.classificationLabel
        } catch {
            print("相手モンスター取得エラー: \(error)")
        }
    }

    // MARK: - バトルロジック

    /// バトルのターン制計算を実行する
    /// battle.id をシードにして両者が同じ結果を独立計算する
    /// 両者で同じ結果にするため、常に player1/player2 の順で渡す
    private func startBattleSequence(battle: BattleRecord) async {
        phase = .battling

        guard let myMonster = selectedMonster,
              let myLabel = myMonster.classificationLabel,
              let opLabel = opponentLabel else {
            phase = .selectMonster
            return
        }

        let userId = try? await client.auth.session.user.id
        let isPlayer1 = battle.player1Id == userId

        // DB の player1/player2 の順序で統一（両者で同じ結果を得るため）
        let p1Label = isPlayer1 ? myLabel : opLabel
        let p2Label = isPlayer1 ? opLabel : myLabel
        let p1Stats = MonsterStatsGenerator.generate(from: p1Label)
        let p2Stats = MonsterStatsGenerator.generate(from: p2Label)

        let result = BattleEngine.simulate(
            player1Stats: p1Stats,
            player2Stats: p2Stats,
            seed: battle.id
        )

        // 演出用の遅延（各ターンを順番に見せる）
        for i in 0..<result.turns.count {
            try? await Task.sleep(for: .seconds(1))
            battleLog = Array(result.turns.prefix(i + 1))
        }

        let won = (result.winner == 1 && isPlayer1) || (result.winner == 2 && !isPlayer1)

        phase = .result(won: won)

        // 勝者を Supabase に記録
        if isPlayer1 {
            let winnerId = result.winner == 1 ? battle.player1Id : battle.player2Id
            try? await client
                .from("battles")
                .update(["status": AnyJSON.string("finished"), "winner_id": AnyJSON.string(winnerId?.uuidString ?? "")])
                .eq("id", value: battle.id.uuidString)
                .execute()
        }

        await unsubscribeRealtime()
    }

    /// 初期状態に戻す
    func reset() {
        phase = .selectMonster
        selectedMonster = nil
        opponentLabel = nil
        battleLog = []
        battleId = nil
        errorMessage = nil
    }
}

// MARK: - Supabase レコード型

struct BattleRecord: Codable {
    let id: UUID
    let status: String
    let player1Id: UUID
    let player1MonsterId: UUID?
    let player2Id: UUID?
    let player2MonsterId: UUID?
    let winnerId: UUID?

    enum CodingKeys: String, CodingKey {
        case id, status
        case player1Id = "player1_id"
        case player1MonsterId = "player1_monster_id"
        case player2Id = "player2_id"
        case player2MonsterId = "player2_monster_id"
        case winnerId = "winner_id"
    }
}

/// 相手モンスター情報の取得用
struct OpponentInfo: Codable {
    let classificationLabel: String

    enum CodingKeys: String, CodingKey {
        case classificationLabel = "classification_label"
    }
}

struct BattleInsert: Codable {
    let player1Id: UUID
    let player1MonsterId: UUID

    enum CodingKeys: String, CodingKey {
        case player1Id = "player1_id"
        case player1MonsterId = "player1_monster_id"
    }
}

// MARK: - エラー

enum BattleError: LocalizedError {
    case uploadFailed

    var errorDescription: String? {
        switch self {
        case .uploadFailed:
            return "モンスターのアップロードに失敗しました"
        }
    }
}
