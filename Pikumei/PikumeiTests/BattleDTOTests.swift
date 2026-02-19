//
//  BattleDTOTests.swift
//  PikumeiTests
//

import Foundation
import Testing
@testable import Pikumei

struct BattleDTOTests {

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = .sortedKeys
        return e
    }()

    // MARK: - BattleInsert

    @Test func battleInsertEncodesWithSnakeCaseKeys() throws {
        let id1 = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let id2 = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let insert = BattleInsert(player1Id: id1, player1MonsterId: id2)

        let data = try encoder.encode(insert)
        let json = try #require(String(data: data, encoding: .utf8))
        #expect(json.contains("\"player1_id\""))
        #expect(json.contains("\"player1_monster_id\""))
        // camelCase キーが含まれていないこと
        #expect(!json.contains("\"player1Id\""))
        #expect(!json.contains("\"player1MonsterId\""))
    }

    // MARK: - BattleFullRow

    @Test func battleFullRowDecodesFromSnakeCaseJSON() throws {
        let json = """
        {
            "id": "00000000-0000-0000-0000-000000000001",
            "status": "active",
            "player1_id": "00000000-0000-0000-0000-000000000002",
            "player1_monster_id": "00000000-0000-0000-0000-000000000003",
            "player2_id": "00000000-0000-0000-0000-000000000004",
            "player2_monster_id": "00000000-0000-0000-0000-000000000005"
        }
        """
        let row = try JSONDecoder().decode(BattleFullRow.self, from: Data(json.utf8))
        #expect(row.id.uuidString.lowercased() == "00000000-0000-0000-0000-000000000001")
        #expect(row.status == "active")
        #expect(row.player1Id.uuidString.lowercased() == "00000000-0000-0000-0000-000000000002")
        #expect(row.player2Id?.uuidString.lowercased() == "00000000-0000-0000-0000-000000000004")
    }

    @Test func battleFullRowDecodesWithNilPlayer2() throws {
        let json = """
        {
            "id": "00000000-0000-0000-0000-000000000001",
            "status": "waiting",
            "player1_id": "00000000-0000-0000-0000-000000000002",
            "player1_monster_id": "00000000-0000-0000-0000-000000000003"
        }
        """
        let row = try JSONDecoder().decode(BattleFullRow.self, from: Data(json.utf8))
        #expect(row.player2Id == nil)
        #expect(row.player2MonsterId == nil)
    }

    // MARK: - MonsterLabelRow

    @Test func monsterLabelRowDecodesClassificationLabel() throws {
        let json = """
        {
            "id": "00000000-0000-0000-0000-000000000001",
            "classification_label": "fire",
            "classification_confidence": 0.95,
            "name": "テスト",
            "thumbnail": null
        }
        """
        let row = try JSONDecoder().decode(MonsterLabelRow.self, from: Data(json.utf8))
        #expect(row.classificationLabel == .fire)
        #expect(row.classificationConfidence == 0.95)
        #expect(row.name == "テスト")
    }

    // MARK: - BattleFinishUpdate

    @Test func battleFinishUpdateEncodesWithSnakeCaseKeys() throws {
        let id = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let update = BattleFinishUpdate(winnerId: id, status: "finished")

        let data = try encoder.encode(update)
        let json = try #require(String(data: data, encoding: .utf8))
        #expect(json.contains("\"winner_id\""))
        #expect(!json.contains("\"winnerId\""))
    }
}
