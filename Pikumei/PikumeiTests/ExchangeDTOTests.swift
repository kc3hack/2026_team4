//
//  ExchangeDTOTests.swift
//  PikumeiTests
//

import Foundation
import Testing
@testable import Pikumei

struct ExchangeDTOTests {

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = .sortedKeys
        return e
    }()

    // MARK: - ExchangeInsert

    @Test func exchangeInsertEncodesWithSnakeCaseKeys() throws {
        let id1 = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let id2 = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let insert = ExchangeInsert(player1Id: id1, player1MonsterId: id2)

        let data = try encoder.encode(insert)
        let json = try #require(String(data: data, encoding: .utf8))
        #expect(json.contains("\"player1_id\""))
        #expect(json.contains("\"player1_monster_id\""))
        #expect(!json.contains("\"player1Id\""))
        #expect(!json.contains("\"player1MonsterId\""))
    }

    // MARK: - ExchangeJoinUpdate

    @Test func exchangeJoinUpdateEncodesWithSnakeCaseKeys() throws {
        let id1 = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let id2 = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let update = ExchangeJoinUpdate(player2Id: id1, player2MonsterId: id2, status: "matched")

        let data = try encoder.encode(update)
        let json = try #require(String(data: data, encoding: .utf8))
        #expect(json.contains("\"player2_id\""))
        #expect(json.contains("\"player2_monster_id\""))
        #expect(!json.contains("\"player2Id\""))
        #expect(!json.contains("\"player2MonsterId\""))
    }

    // MARK: - ExchangeFullRow

    @Test func exchangeFullRowDecodesFromSnakeCaseJSON() throws {
        let json = """
        {
            "id": "00000000-0000-0000-0000-000000000001",
            "status": "matched",
            "player1_id": "00000000-0000-0000-0000-000000000002",
            "player1_monster_id": "00000000-0000-0000-0000-000000000003",
            "player2_id": "00000000-0000-0000-0000-000000000004",
            "player2_monster_id": "00000000-0000-0000-0000-000000000005"
        }
        """
        let row = try JSONDecoder().decode(ExchangeFullRow.self, from: Data(json.utf8))
        #expect(row.id.uuidString.lowercased() == "00000000-0000-0000-0000-000000000001")
        #expect(row.status == "matched")
        #expect(row.player1Id.uuidString.lowercased() == "00000000-0000-0000-0000-000000000002")
        #expect(row.player2Id?.uuidString.lowercased() == "00000000-0000-0000-0000-000000000004")
    }

    @Test func exchangeFullRowDecodesWithNilPlayer2() throws {
        let json = """
        {
            "id": "00000000-0000-0000-0000-000000000001",
            "status": "waiting",
            "player1_id": "00000000-0000-0000-0000-000000000002",
            "player1_monster_id": "00000000-0000-0000-0000-000000000003"
        }
        """
        let row = try JSONDecoder().decode(ExchangeFullRow.self, from: Data(json.utf8))
        #expect(row.player2Id == nil)
        #expect(row.player2MonsterId == nil)
    }

    // MARK: - ExchangeRow

    @Test func exchangeRowDecodesBasicFields() throws {
        let json = """
        {
            "id": "00000000-0000-0000-0000-000000000001",
            "status": "waiting"
        }
        """
        let row = try JSONDecoder().decode(ExchangeRow.self, from: Data(json.utf8))
        #expect(row.id.uuidString.lowercased() == "00000000-0000-0000-0000-000000000001")
        #expect(row.status == "waiting")
    }
}
