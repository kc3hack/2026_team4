//
//  BattleMonsterSelector.swift
//  Pikumei
//
//  Created by Daichi Sakai on 2026/02/20.
//

import Combine
import Foundation
import Supabase

/// バトルに使用するモンスターの選択を管理する
@MainActor
class BattleMonsterSelector: ObservableObject {
    private let client = SupabaseClientProvider.shared
    @Published public var name: String? = nil
    @Published public var thumbnail: Data? = nil
    
    /// 指定したIDのモンスターを選択する
    public func setMonster(monsterId: UUID) async {
        do {
            let monster: MonsterLabelRow = try await client
                .from("monsters")
                .select("id, classification_label, classification_confidence, name, thumbnail")
                .eq("id", value: monsterId.uuidString)
                .single()
                .execute()
                .value
            
            self.name = monster.name
            self.thumbnail = monster.thumbnailData
            
            print("[BattleMonsterSelector.setMonster] succeeded, monsterId: \(monsterId)")
        } catch {
            print("[BattleMonsterSelector.setMonster] \(error)")
        }
    }
    
    /// 自分のモンスターからランダムに選択する
    public func setRandomMonster() async throws {
        guard let userId = try? await client.auth.session.user.id else { // ユーザーID
            throw BattleMonsterSelectorError.failedFetchUserId
        }
        
        guard let monsters: [MonsterIdRow] = try? await client // モンスターを50体取得
            .from("monsters")
            .select("id")
            .eq("user_id", value: userId.uuidString)
            .limit(50)
            .execute()
            .value else {
            throw BattleMonsterSelectorError.failedFetchMonsters
        }
        
        guard let monster = monsters.randomElement() else { // ランダムに1体抽出
            throw BattleMonsterSelectorError.noMonsters
        }
        
        await setMonster(monsterId: monster.id)
    }
}

enum BattleMonsterSelectorError: LocalizedError{
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
