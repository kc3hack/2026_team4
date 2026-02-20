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
            
            print("[BattleMonsterSelector.setMonster] succeeded")
        } catch {
            print("[BattleMonsterSelector.setMonster] \(error)")
        }
    }
    
    public func setRandomMonster() async {
        guard let monsterId: UUID = try? await fetchRandomMonster() else {return}
        await setMonster(monsterId: monsterId)
    }
    
    
    /// 自分のモンスターからランダムに1体選ぶ
    private func fetchRandomMonster() async throws -> UUID {
        let userId = try await client.auth.session.user.id
        let monsters: [MonsterIdRow] = try await client
            .from("monsters")
            .select("id")
            .eq("user_id", value: userId.uuidString)
            .limit(50)
            .execute()
            .value
        
        guard let monster = monsters.randomElement() else {
            throw MatchingError.noMonsters
        }
        return monster.id
    }
}
