//
//  SupabaseTestViewModel.swift
//  Pikumei
//
//  Supabase 接続・画像取得のテスト用（確認後に削除）
//

import Foundation
import Supabase
import UIKit

@MainActor
class SupabaseTestViewModel: ObservableObject {
    @Published var connectionStatus: String?
    @Published var isTesting = false
    @Published var fetchedMonsters: [FetchedMonster] = []
    @Published var isFetchingImages = false
    @Published var fetchError: String?

    private let client = SupabaseClientProvider.shared

    // MARK: - 接続テスト

    func testConnection() async {
        isTesting = true
        connectionStatus = nil

        do {
            try await client.auth.signInAnonymously()
            let userId = try await client.auth.session.user.id

            try await client
                .from("monsters")
                .select("classification_label")
                .limit(1)
                .execute()

            connectionStatus = "OK: 接続成功\nUser: \(userId.uuidString.prefix(8))..."
        } catch {
            connectionStatus = "NG: \(error.localizedDescription)"
        }

        isTesting = false
    }

    // MARK: - 画像取得テスト

    func fetchImages() async {
        isFetchingImages = true
        fetchedMonsters = []
        fetchError = nil

        do {
            try await client.auth.signInAnonymously()

            fetchedMonsters = try await client
                .from("monsters")
                .select("id, classification_label, thumbnail")
                .limit(9)
                .execute()
                .value
        } catch {
            fetchError = "NG: \(error.localizedDescription)"
        }

        isFetchingImages = false
    }
}

// MARK: - Supabase レコード型

/// Supabase から取得したモンスター
/// BYTEA は hex 文字列で返るため String で受けて Data+ByteaHex で変換する
struct FetchedMonster: Codable, Identifiable {
    let id: UUID
    let classificationLabel: String
    let thumbnailHex: String

    enum CodingKeys: String, CodingKey {
        case id
        case classificationLabel = "classification_label"
        case thumbnailHex = "thumbnail"
    }

    var thumbnail: Data? {
        Data(byteaHex: thumbnailHex)
    }

    var uiImage: UIImage? {
        guard let data = thumbnail else { return nil }
        return UIImage(data: data)
    }
}
