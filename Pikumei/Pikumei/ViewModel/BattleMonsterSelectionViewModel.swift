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
    @Published public var monsterId: UUID? = nil
    @Published public var monster: Monster? = nil
    @Published public var stats: BattleStats? = nil
    
    
    public func updateMonster() async {
        guard let monster = try? await self.fetchMonster() else {return}
        self.monster = monster
        self.stats = BattleStatsGenerator.generate(label: monster.classificationLabel, confidence: monster.classificationConfidence)
        print("[Monster Selection] updated")
    }
    
    /// 自分のモンスターからランダムに選択する
    public func setRandomMonster() async throws {
        guard let userId = try? await client.auth.session.user.id else { // ユーザーID
            throw BattleMonsterSelectionViewModelError.failedFetchUserId
        }
        
        guard let monsters: [MonsterIdRow] = try? await client // モンスターを50体取得
            .from("monsters")
            .select("id")
            .eq("user_id", value: userId.uuidString)
            .limit(50)
            .execute()
            .value else {
            throw BattleMonsterSelectionViewModelError.failedFetchMonsters
        }
        
        guard let monster = monsters.randomElement() else { // ランダムに1体抽出
            throw BattleMonsterSelectionViewModelError.noMonsters
        }
        
        self.monsterId = monster.id
        print("[Monster Selection] selected monster(id: \(self.monsterId!))")
    }
    
    /// モンスター情報を取得
    private func fetchMonster() async throws -> Monster? {
        guard let id = self.monsterId else {return nil}
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
