//
//  BattleMonsterSelectionViewModel.swift
//  Pikumei
//
//  Created by Daichi Sakai on 2026/02/20.
//

import Combine
import Foundation
import Supabase

/// バトルに使用するモンスターの選択を管理する
@MainActor
class BattleMonsterSelectionViewModel: ObservableObject {
    private let client = SupabaseClientProvider.shared
    @Published public var monsterId: UUID? = nil // 選択されたモンスターのモンスターID
    @Published public var monster: Monster? = nil // 選択されたモンスター
    @Published public var stats: BattleStats? = nil // 選択されたモンスターのステータス
    
    @Published public var touched: UUID? = nil // タップされたモンスターのモンスターID
    
    public func updateMonster() async {
        guard let monster = try? await self.fetchMonster(self.monsterId) else {return}
        self.monster = monster
        self.stats = BattleStatsGenerator.generate(label: monster.classificationLabel, confidence: monster.classificationConfidence)
        print("[Monster Selection] updated")
    }
    
    /// モンスター情報を取得
    private func fetchMonster(_ monsterId: UUID?) async throws -> Monster? {
        guard let id = monsterId else {return nil}
        let monster: MonsterLabelRow = try await client
            .from("monsters")
            .select("id, classification_label, classification_confidence, name, thumbnail")
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
        
        guard let thumbnailData = monster.thumbnailData else {return nil}
        return Monster(imageData: thumbnailData,
                       classificationLabel: monster.classificationLabel,
                       classificationConfidence: monster.classificationConfidence,
                       supabaseId: id,
                       name: monster.name,
        )
    }
    
    // タップされたモンスターをリセット
    public func resetTouched() {
        self.touched = self.monsterId
    }
    
    /// モンスターを確定
    public func confirmMonster() async {
        self.monsterId = self.touched
        await self.updateMonster()
        
    }
    
    /// 自分のモンスターからランダムに1体取得する
    public func getRandomMonster() async throws -> Monster? {
        guard let userId = try? await client.auth.session.user.id else { // ユーザーID
            throw BattleMonsterSelectionViewModelError.failedFetchUserId
        }
        
        guard let monsters: [MonsterIdRow] = try? await client // モンスターを50体取得
            .from("monsters")
            .select("id")
            .eq("user_id", value: userId.uuidString)
            .limit(50)
            .execute()
            .value
        else {
            throw BattleMonsterSelectionViewModelError.failedFetchMonsters
        }
        
        guard let monsterIdRow = monsters.randomElement() else { // ランダムに1体抽出
            throw BattleMonsterSelectionViewModelError.noMonsters
        }
        return try? await fetchMonster(monsterIdRow.id)
    }
}

enum BattleMonsterSelectionViewModelError: LocalizedError{
    case failedFetchUserId
    case failedFetchMonsters
    case noMonsters
    
    var errorDiscription: String? {
        switch self {
        case .failedFetchUserId:
            return "ユーザーIDを取得できませんでした"
        case .failedFetchMonsters:
            return "モンスターリストを取得できませんでした"
        case .noMonsters:
            return "モンスターを持っていません"
        }
    }
}
