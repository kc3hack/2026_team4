//
//  MonsterTypeTests.swift
//  PikumeiTests
//

import Testing
@testable import Pikumei

struct MonsterTypeTests {

    // MARK: - effectiveness

    @Test func fireIsStrongAgainstLeaf() {
        #expect(MonsterType.fire.effectiveness(against: .leaf) == 1.5)
    }

    @Test func fireIsStrongAgainstBird() {
        #expect(MonsterType.fire.effectiveness(against: .bird) == 1.5)
    }

    @Test func fireIsWeakAgainstWater() {
        #expect(MonsterType.fire.effectiveness(against: .water) == 0.5)
    }

    @Test func waterIsStrongAgainstFire() {
        #expect(MonsterType.water.effectiveness(against: .fire) == 1.5)
    }

    @Test func waterIsWeakAgainstLeaf() {
        #expect(MonsterType.water.effectiveness(against: .leaf) == 0.5)
    }

    @Test func leafIsStrongAgainstWater() {
        #expect(MonsterType.leaf.effectiveness(against: .water) == 1.5)
    }

    @Test func leafIsWeakAgainstFire() {
        #expect(MonsterType.leaf.effectiveness(against: .fire) == 0.5)
    }

    @Test func ghostIsStrongAgainstHuman() {
        #expect(MonsterType.ghost.effectiveness(against: .human) == 1.5)
    }

    @Test func ghostIsWeakAgainstBird() {
        #expect(MonsterType.ghost.effectiveness(against: .bird) == 0.5)
    }

    @Test func sameTypeIsNeutral() {
        #expect(MonsterType.fire.effectiveness(against: .fire) == 1.0)
        #expect(MonsterType.water.effectiveness(against: .water) == 1.0)
    }

    @Test func humanIsStrongAgainstFish() {
        #expect(MonsterType.human.effectiveness(against: .fish) == 1.5)
    }

    @Test func fishIsWeakAgainstHuman() {
        #expect(MonsterType.fish.effectiveness(against: .human) == 0.5)
    }

    @Test func birdIsStrongAgainstGhost() {
        #expect(MonsterType.bird.effectiveness(against: .ghost) == 1.5)
    }

    // MARK: - attacks

    @Test func allTypesHaveThreeAttacks() {
        for type in MonsterType.allCases {
            #expect(type.attacks.count == 3, "\(type) should have 3 attacks")
        }
    }

    @Test func mainAttackIsSameTypeWithFullPower() {
        for type in MonsterType.allCases {
            let main = type.attacks[0]
            #expect(main.type == type, "\(type) main attack type mismatch")
            #expect(main.powerRate == 1.0, "\(type) main attack powerRate should be 1.0")
        }
    }

    @Test func subAttacksHaveReducedPower() {
        for type in MonsterType.allCases {
            let sub1 = type.attacks[1]
            let sub2 = type.attacks[2]
            #expect(sub1.powerRate == 0.7, "\(type) sub1 powerRate should be 0.7")
            #expect(sub2.powerRate == 0.7, "\(type) sub2 powerRate should be 0.7")
        }
    }
}
