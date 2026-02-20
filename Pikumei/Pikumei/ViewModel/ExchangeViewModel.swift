//
//  ExchangeViewModel.swift
//  Pikumei
//
//  モンスター交換のマッチング・実行ロジック
//

import Combine
import Foundation
import Supabase
import SwiftData
import UIKit

@MainActor
class ExchangeViewModel: ObservableObject {

    enum ExchangePhase {
        case selectMonster      // モンスター選択中
        case idle               // 選択完了、作成/参加ボタン表示
        case waiting            // 交換作成済み、Realtime 購読中
        case exchanging         // マッチ成立、データ受け渡し中
        case completed(Monster) // 交換完了、結果表示
        case error(String)      // エラー表示
    }

    @Published var phase: ExchangePhase = .selectMonster
    @Published var exchangeId: UUID?
    @Published var selectedMonster: Monster?

    private let client = SupabaseClientProvider.shared
    private var channel: RealtimeChannelV2?
    private var subscription: RealtimeSubscription?
    private var modelContext: ModelContext?
    private var isCompleting = false

    /// View から ModelContext を注入する
    func setModelContext(_ context: ModelContext) {
        modelContext = context
    }

    // MARK: - モンスター選択

    func selectMonster(_ monster: Monster) {
        selectedMonster = monster
        phase = .idle
    }

    func deselectMonster() {
        selectedMonster = nil
        phase = .selectMonster
    }

    // MARK: - 交換作成（Player A 用）

    /// 選択中のモンスターで交換を作成し、相手を待つ
    func createExchange() async {
        guard let monster = selectedMonster, let supabaseId = monster.supabaseId else {
            phase = .error("アップロード済みのメイティを選択してください")
            return
        }

        do {
            try await ensureAuthenticated()
            let userId = try await client.auth.session.user.id

            let record = ExchangeInsert(
                player1Id: userId,
                player1MonsterId: supabaseId
            )

            let inserted: ExchangeRow = try await client
                .from("exchanges")
                .insert(record, returning: .representation)
                .select("id, status")
                .single()
                .execute()
                .value

            print("[Exchange] INSERT 成功 exchangeId: \(inserted.id)")
            exchangeId = inserted.id
            phase = .waiting

            await subscribeToMatch(exchangeId: inserted.id)
        } catch {
            print("[Exchange] createExchange エラー: \(error)")
            phase = .error("交換の作成に失敗しました: \(error.localizedDescription)")
        }
    }

    // MARK: - 交換参加（Player B 用）

    /// 待機中の交換を探して参加し、交換を完了する
    func joinExchange() async {
        guard let monster = selectedMonster, let supabaseId = monster.supabaseId else {
            phase = .error("アップロード済みのメイティを選択してください")
            return
        }

        do {
            try await ensureAuthenticated()
            let userId = try await client.auth.session.user.id

            // 自分以外が作った直近5分以内の waiting 交換を1件取得
            let fiveMinutesAgo = ISO8601DateFormatter().string(
                from: Date().addingTimeInterval(-300)
            )
            let exchanges: [ExchangeRow] = try await client
                .from("exchanges")
                .select("id, status")
                .eq("status", value: "waiting")
                .neq("player1_id", value: userId.uuidString)
                .gte("created_at", value: fiveMinutesAgo)
                .order("created_at", ascending: false)
                .limit(1)
                .execute()
                .value

            print("[Exchange] waiting 交換検索結果: \(exchanges.count) 件")
            guard let target = exchanges.first else {
                phase = .error("待機中の交換が見つかりません")
                return
            }

            print("[Exchange] 参加対象 exchangeId: \(target.id)")
            exchangeId = target.id

            // player2 として参加し status を matched に更新
            let update = ExchangeJoinUpdate(
                player2Id: userId,
                player2MonsterId: supabaseId,
                status: "matched"
            )

            // status=waiting の交換だけ更新（楽観的排他制御）
            let updated: [ExchangeRow] = try await client
                .from("exchanges")
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

            print("[Exchange] UPDATE 成功 → 交換処理開始")
            phase = .exchanging
            await completeExchange(exchangeId: target.id)
        } catch {
            print("[Exchange] joinExchange エラー: \(error)")
            phase = .error("参加に失敗しました: \(error.localizedDescription)")
        }
    }

    // MARK: - Realtime 購読

    /// exchanges テーブルの UPDATE を監視し、status が matched になったら交換処理を実行
    private func subscribeToMatch(exchangeId: UUID) async {
        print("[Exchange] Realtime 購読開始 exchangeId: \(exchangeId)")
        let ch = client.channel("exchange-\(exchangeId.uuidString)")
        channel = ch

        subscription = ch.onPostgresChange(
            UpdateAction.self,
            table: "exchanges",
            filter: "id=eq.\(exchangeId.uuidString)"
        ) { [weak self] action in
            print("[Exchange] Realtime UPDATE 受信: \(action.record)")
            if let status = action.record["status"]?.stringValue,
               status == "matched" {
                print("[Exchange] status=matched 検出 → 交換処理開始")
                Task { @MainActor [weak self] in
                    self?.unsubscribe()
                    self?.phase = .exchanging
                    await self?.completeExchange(exchangeId: exchangeId)
                }
            }
        }

        do {
            try await ch.subscribeWithError()
            print("[Exchange] Realtime 購読成功")

            // 購読完了前に相手が参加していた場合のフォールバック
            let current: ExchangeRow = try await client
                .from("exchanges")
                .select("id, status")
                .eq("id", value: exchangeId.uuidString)
                .single()
                .execute()
                .value

            if current.status == "matched" {
                print("[Exchange] 購読前にマッチ済み → 交換処理開始")
                unsubscribe()
                phase = .exchanging
                await completeExchange(exchangeId: exchangeId)
            }
        } catch {
            print("[Exchange] Realtime 購読失敗: \(error)")
        }
    }

    // MARK: - 交換完了処理

    /// 相手のモンスターデータを取得し、ローカルに保存して渡したモンスターを削除する
    private func completeExchange(exchangeId: UUID) async {
        // Realtime コールバックとフォールバックの両方から呼ばれうるため重複実行を防止
        guard !isCompleting else { return }
        isCompleting = true
        defer { isCompleting = false }

        do {
            let userId = try await client.auth.session.user.id

            // 交換の詳細を取得
            let exchange: ExchangeFullRow = try await client
                .from("exchanges")
                .select("id, status, player1_id, player1_monster_id, player2_id, player2_monster_id")
                .eq("id", value: exchangeId.uuidString)
                .single()
                .execute()
                .value

            // 自分が player1 か player2 かで相手のモンスター ID を決定
            let isPlayer1 = exchange.player1Id == userId
            let opponentMonsterId: UUID
            if isPlayer1 {
                guard let id = exchange.player2MonsterId else {
                    phase = .error("相手のメイティ情報がありません")
                    return
                }
                opponentMonsterId = id
            } else {
                opponentMonsterId = exchange.player1MonsterId
            }

            // 相手のモンスター情報を取得
            let opponentMonster: MonsterLabelRow = try await client
                .from("monsters")
                .select("id, classification_label, classification_confidence, name, thumbnail")
                .eq("id", value: opponentMonsterId.uuidString)
                .single()
                .execute()
                .value

            // 相手のモンスターをローカルに保存
            guard let context = modelContext else {
                phase = .error("データの保存に失敗しました")
                return
            }

            // サムネイルから切り抜き画像を生成してPNGで保存
            guard let thumbnailData = opponentMonster.thumbnailData,
                  let thumbnailImage = UIImage(data: thumbnailData) else {
                phase = .error("相手のメイティ画像を取得できませんでした")
                return
            }

            let imageData: Data
            if let cutout = try? await SubjectDetector.detectAndCutout(from: thumbnailImage),
               let pngData = cutout.pngData() {
                imageData = pngData
            } else {
                // 切り抜き失敗時はそのままPNG変換
                imageData = thumbnailImage.pngData() ?? thumbnailData
            }

            let newMonster = Monster(
                imageData: imageData,
                classificationLabel: opponentMonster.classificationLabel,
                classificationConfidence: opponentMonster.classificationConfidence,
                supabaseId: opponentMonster.id,
                name: opponentMonster.name
            )
            context.insert(newMonster)

            // 渡したモンスターをローカルから削除
            if let givenMonster = selectedMonster {
                context.delete(givenMonster)
            }

            try context.save()

            // exchanges の status を completed に更新
            try await client
                .from("exchanges")
                .update(["status": "completed"])
                .eq("id", value: exchangeId.uuidString)
                .execute()

            print("[Exchange] 交換完了")
            phase = .completed(newMonster)
        } catch {
            print("[Exchange] completeExchange エラー: \(error)")
            phase = .error("交換処理に失敗しました: \(error.localizedDescription)")
        }
    }

    // MARK: - クリーンアップ

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

    /// 状態をリセット（DB 上の waiting 交換もキャンセルする）
    func reset() {
        if let exchangeId {
            Task {
                do {
                    try await client
                        .from("exchanges")
                        .update(["status": "cancelled"])
                        .eq("id", value: exchangeId.uuidString)
                        .eq("status", value: "waiting")
                        .execute()
                    print("[Exchange] 交換 \(exchangeId) をキャンセル")
                } catch {
                    print("[Exchange] キャンセル失敗 \(exchangeId): \(error)")
                }
            }
        }
        unsubscribe()
        phase = .selectMonster
        exchangeId = nil
        selectedMonster = nil
        isCompleting = false
    }

    // MARK: - Private

    private func ensureAuthenticated() async throws {
        let session = try? await client.auth.session
        if session == nil {
            try await client.auth.signInAnonymously()
        }
    }
}
