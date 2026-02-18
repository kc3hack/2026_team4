//
//  MonsterStore.swift
//  Pikumei
//

import Foundation
import SwiftData
import UIKit

/// Monster の CRUD 操作を提供する
@MainActor
@Observable
class MonsterStore {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// モンスターを保存する
    func save(image: UIImage, label: MonsterType? = nil, confidence: Double? = nil) throws {
        guard let monster = Monster(image: image, classificationLabel: label, classificationConfidence: confidence) else {
            throw MonsterStoreError.imageConversionFailed
        }
        modelContext.insert(monster)
        try modelContext.save()
    }

    /// すべてのモンスターを新しい順に取得する
    func fetchAll() throws -> [Monster] {
        let descriptor = FetchDescriptor<Monster>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// モンスターの名前を更新する
    func updateName(monster: Monster, name: String) throws {
        monster.name = name
        try modelContext.save()
    }

    /// モンスターを削除する
    func delete(_ monster: Monster) throws {
        modelContext.delete(monster)
        try modelContext.save()
    }
}

/// MonsterStore 関連のエラー
enum MonsterStoreError: LocalizedError {
    case imageConversionFailed

    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "画像データの変換に失敗しました"
        }
    }
}
