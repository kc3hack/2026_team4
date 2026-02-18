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
    }

    @Published var phase: MatchingPhase = .idle
    @Published var battleId: UUID?

    private let client = SupabaseClientProvider.shared
    private var channel: RealtimeChannelV2?
    private var subscription: RealtimeSubscription?
    private var subscribeTask: Task<Void, Never>?

    // MARK: - バトル作成（端末A用）

    /// 自分のモンスターをランダムに選んでバトルを作成し、相手を待つ
    func createBattle() async {
        do {
            try await ensureAuthenticated()
            let userId = try await client.auth.session.user.id
            print("[Matching] userId: \(userId)")
            let monsterId = try await fetchRandomMonster()
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

            subscribeToMatch(battleId: inserted.id)
        } catch {
            print("[Matching] createBattle エラー: \(error)")
            phase = .error("バトル作成失敗: \(error.localizedDescription)")
        }
    }

    // MARK: - バトル参加（端末B用）

    /// 待機中のバトルを探して自分のモンスターで参加する
    func joinBattle() async {
        do {
            try await ensureAuthenticated()
            let userId = try await client.auth.session.user.id
            let monsterId = try await fetchRandomMonster()

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

            let response = try await client
                .from("battles")
                .update(update)
                .eq("id", value: target.id.uuidString)
                .execute()

            print("[Matching] UPDATE レスポンス status: \(response.status)")
            phase = .battling
        } catch {
            print("[Matching] joinBattle エラー: \(error)")
            phase = .error("参加失敗: \(error.localizedDescription)")
        }
    }

    // MARK: - Realtime 購読

    /// battles テーブルの UPDATE を監視し、status が matched になったら通知
    func subscribeToMatch(battleId: UUID) {
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

        subscribeTask = Task {
            do {
                try await ch.subscribeWithError()
                print("[Matching] Realtime 購読成功 channel status: \(ch.status)")
            } catch {
                print("[Matching] Realtime 購読失敗: \(error)")
            }
        }
    }

    /// 購読解除
    func unsubscribe() {
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

    /// 状態をリセット
    func reset() {
        unsubscribe()
        phase = .idle
        battleId = nil
    }

    // MARK: - Private

    /// Supabase 上のモンスターからランダムに1体選ぶ
    private func fetchRandomMonster() async throws -> UUID {
        let monsters: [MonsterIdRow] = try await client
            .from("monsters")
            .select("id")
            .limit(50)
            .execute()
            .value

        guard let monster = monsters.randomElement() else {
            throw MatchingError.noMonsters
        }
        return monster.id
    }

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
