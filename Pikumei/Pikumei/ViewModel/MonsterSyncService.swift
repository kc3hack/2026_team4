//
//  MonsterSyncService.swift
//  Pikumei
//

import Foundation
import Supabase
import UIKit

/// モンスターを Supabase にアップロードする
/// フル画像はローカルのみ保持し、JPEG サムネイルだけを送信する
@MainActor
class MonsterSyncService {

    private let client = SupabaseClientProvider.shared

    /// モンスターを Supabase にアップロードし、ローカルの supabaseId を更新する
    func upload(monster: Monster) async throws {
        // すでにアップロード済みならスキップ
        guard monster.supabaseId == nil else { return }

        guard let label = monster.classificationLabel else {
            throw SyncError.noClassificationLabel
        }

        let thumbnail = try generateThumbnail(from: monster.imageData)

        // Anonymous Auth でサインイン（未認証の場合）
        try await ensureAuthenticated()

        let userId = try await client.auth.session.user.id

        let record = MonsterRecord(
            userId: userId,
            classificationLabel: label,
            thumbnail: thumbnail
        )

        // BYTEA のデコード問題を避けるため id のみ取得
        let inserted: InsertedId = try await client
            .from("monsters")
            .insert(record, returning: .representation)
            .select("id")
            .single()
            .execute()
            .value

        monster.supabaseId = inserted.id
    }

    // MARK: - Private

    /// PNG データから JPEG 200x200 サムネイルを生成
    private func generateThumbnail(from imageData: Data) throws -> Data {
        guard let image = UIImage(data: imageData) else {
            throw SyncError.imageConversionFailed
        }

        let size = CGSize(width: 200, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }

        guard let jpeg = resized.jpegData(compressionQuality: 0.7) else {
            throw SyncError.imageConversionFailed
        }
        return jpeg
    }

    /// Anonymous Auth でサインイン（セッションがなければ）
    private func ensureAuthenticated() async throws {
        let session = try? await client.auth.session
        if session == nil {
            try await client.auth.signInAnonymously()
        }
    }
}

// MARK: - Supabase 用のレコード型

/// Supabase monsters テーブルへの INSERT 用
struct MonsterRecord: Codable {
    var userId: UUID?
    let classificationLabel: String
    let thumbnail: Data

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case classificationLabel = "classification_label"
        case thumbnail
    }
}

/// INSERT 後のレスポンス用（id のみ）
private struct InsertedId: Codable {
    let id: UUID
}

// MARK: - エラー

enum SyncError: LocalizedError {
    case noClassificationLabel
    case imageConversionFailed

    var errorDescription: String? {
        switch self {
        case .noClassificationLabel:
            return "分類ラベルがないためアップロードできません"
        case .imageConversionFailed:
            return "サムネイルの生成に失敗しました"
        }
    }
}
