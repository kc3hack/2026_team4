//
//  BattleMatchingViewModel.swift
//  Pikumei
//
//  2端末間のマッチング通信テスト用
//

import Combine
import Foundation
import Supabase

@MainActor
class BattleMatchingViewModel: ObservableObject {
    enum MatchingPhase {
        case idle           // 初期状態
        case waiting        // バトル作成済み、相手待ち
        case battling       // マッチ成立 → バトル中
        case error(String)  // エラー

        var isBattling: Bool {
            if case .battling = self { return true }
            return false
        }
    }

    @Published var phase: MatchingPhase = .idle
    @Published var battleId: UUID?

    private let client = SupabaseClientProvider.shared
    private var channel: RealtimeChannelV2?
    private var subscription: RealtimeSubscription?

    // MARK: - バトル作成（端末A用）

    /// バトルを作成し、相手を待つ
    func createBattle(monsterId monsterIdWrapper: UUID?) async {
        guard let monsterId = monsterIdWrapper else {
            phase = .error("モンスターが選択されていません")
            return
        }
        
        do {
            try await ensureAuthenticated()
            let userId = try await client.auth.session.user.id
            print("[Matching] userId: \(userId)")
            print("[Matching] monsterId: \(monsterId)")

            let record = BattleInsert(
                player1Id: userId,
                player1MonsterId: monsterId
            )

            let inserted: BattleRow = try await client
                .from("battles")
                .insert(record, returning: .representation)
                .select("id, status")
                .single()
                .execute()
                .value

            print("[Matching] INSERT 成功 battleId: \(inserted.id), status: \(inserted.status)")
            battleId = inserted.id
            phase = .waiting

            await subscribeToMatch(battleId: inserted.id)
        } catch {
            print("[Matching] createBattle エラー: \(error)")
            phase = .error("バトル作成失敗: \(error.localizedDescription)")
        }
    }

    // MARK: - バトル参加（端末B用）

    /// 待機中のバトルを探して自分のモンスターで参加する
    func joinBattle(monsterId monsterIdWrapper: UUID?) async {
        guard let monsterId = monsterIdWrapper else {
            phase = .error("モンスターが選択されていません")
            return
        }
        
        do {
            try await ensureAuthenticated()
            let userId = try await client.auth.session.user.id

            // 自分以外が作った直近5分以内の waiting バトルを1件取得
            let fiveMinutesAgo = ISO8601DateFormatter().string(
                from: Date().addingTimeInterval(-300)
            )
            let battles: [BattleRow] = try await client
                .from("battles")
                .select("id, status")
                .eq("status", value: "waiting")
                .neq("player1_id", value: userId.uuidString)
                .gte("created_at", value: fiveMinutesAgo)
                .order("created_at", ascending: false)
                .limit(1)
                .execute()
                .value

            print("[Matching] waiting バトル検索結果: \(battles.count) 件")
            guard let target = battles.first else {
                phase = .error("待機中のバトルが見つかりません")
                return
            }

            print("[Matching] 参加対象 battleId: \(target.id)")
            battleId = target.id

            // player2 として参加し status を matched に更新
            let update = BattleJoinUpdate(
                player2Id: userId,
                player2MonsterId: monsterId,
                status: "matched"
            )

            // status=waiting のバトルだけ更新（楽観的排他制御）
            let updated: [BattleRow] = try await client
                .from("battles")
                .update(update, returning: .representation)
                .eq("id", value: target.id.uuidString)
                .eq("status", value: "waiting")
                .select("id, status")
                .execute()
                .value

            guard !updated.isEmpty else {
                phase = .error("他のプレイヤーが先に参加しました")
                return
            }

            print("[Matching] UPDATE 成功")
            phase = .battling
        } catch {
            print("[Matching] joinBattle エラー: \(error)")
            phase = .error("参加失敗: \(error.localizedDescription)")
        }
    }

    // MARK: - Realtime 購読

    /// battles テーブルの UPDATE を監視し、status が matched になったら通知
    func subscribeToMatch(battleId: UUID) async {
        print("[Matching] Realtime 購読開始 battleId: \(battleId)")
        let ch = client.channel("battle-\(battleId.uuidString)")
        channel = ch

        // onPostgresChange は subscribe() の前に登録する必要がある
        subscription = ch.onPostgresChange(
            UpdateAction.self,
            table: "battles",
            filter: "id=eq.\(battleId.uuidString)"
        ) { [weak self] action in
            print("[Matching] Realtime UPDATE 受信: \(action.record)")
            if let status = action.record["status"]?.stringValue,
               status == "matched" {
                print("[Matching] status=matched 検出！→ バトル開始")
                Task { @MainActor [weak self] in
                    self?.unsubscribe()
                    self?.phase = .battling
                }
            }
        }

        do {
            try await ch.subscribeWithError()
            print("[Matching] Realtime 購読成功 channel status: \(ch.status)")

            // 購読完了前に相手が参加していた場合のフォールバック
            let current: BattleRow = try await client
                .from("battles")
                .select("id, status")
                .eq("id", value: battleId.uuidString)
                .single()
                .execute()
                .value

            if current.status == "matched" {
                print("[Matching] 購読前にマッチ済み → バトル開始")
                unsubscribe()
                phase = .battling
            }
        } catch {
            print("[Matching] Realtime 購読失敗: \(error)")
        }
    }

    /// 購読解除
    func unsubscribe() {
        subscription = nil
        if let channel {
            Task {
                await channel.unsubscribe()
                await client.removeChannel(channel)
            }
        }
        channel = nil
    }

    /// 状態をリセット（DB 上の waiting バトルもキャンセルする）
    func reset() {
        if let battleId {
            Task {
                _ = try? await client
                    .from("battles")
                    .update(["status": "cancelled"])
                    .eq("id", value: battleId.uuidString)
                    .eq("status", value: "waiting")
                    .execute()
                print("[Matching] バトル \(battleId) をキャンセル")
            }
        }
        unsubscribe()
        phase = .idle
        battleId = nil
    }

    // MARK: - Private

    private func ensureAuthenticated() async throws {
        let session = try? await client.auth.session
        if session == nil {
            try await client.auth.signInAnonymously()
        }
    }
}

// MARK: - エラー

enum MatchingError: LocalizedError {
    case noMonsters

    var errorDescription: String? {
        switch self {
        case .noMonsters:
            return "モンスターがありません。先にスキャンしてアップロードしてください"
        }
    }
}
