//
//  MonsterFusionViewModel.swift
//  Pikumei
//
//  モンスター合体のロジック
//

import Foundation
import SwiftData
import UIKit

@MainActor
@Observable
class MonsterFusionViewModel {

    private let syncService = MonsterSyncService()

    enum FusionPhase {
        case selectFirst        // 1体目（自分のモンスター）を選択
        case selectSecond       // 2体目（交換産モンスター）を選択
        case confirm            // 合体確認
        case result(Monster)    // 合体結果表示
    }

    var phase: FusionPhase = .selectFirst
    var firstMonster: Monster?   // 自分のモンスター
    var secondMonster: Monster?  // 交換産モンスター
    var previewStats: BattleStats?

    private var modelContext: ModelContext?

    func setModelContext(_ context: ModelContext) {
        modelContext = context
    }

    // MARK: - 合体可能なモンスターの取得

    /// 自分のモンスター（交換産でないもの、合体済み含む）
    func fetchOwnMonsters() -> [Monster] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<Monster>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let all = (try? context.fetch(descriptor)) ?? []
        return all.filter { !$0.isExchanged }
    }

    /// 交換で手に入れたモンスター（合体済み含む）
    func fetchExchangedMonsters() -> [Monster] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<Monster>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let all = (try? context.fetch(descriptor)) ?? []
        return all.filter { $0.isExchanged }
    }

    // MARK: - 選択

    func selectFirst(_ monster: Monster) {
        firstMonster = monster
        phase = .selectSecond
    }

    func selectSecond(_ monster: Monster) {
        secondMonster = monster
        previewStats = calculateFusedStats()
        phase = .confirm
    }

    func back() {
        switch phase {
        case .selectSecond:
            firstMonster = nil
            phase = .selectFirst
        case .confirm:
            secondMonster = nil
            previewStats = nil
            phase = .selectSecond
        default:
            break
        }
    }

    // MARK: - 合体実行

    func fuse() async {
        guard let first = firstMonster,
              let second = secondMonster,
              let context = modelContext else { return }

        // タイプをランダムに決定
        let types = [first.classificationLabel, second.classificationLabel].compactMap { $0 }
        let fusedType = types.randomElement()

        // previewStats は confirm フェーズで計算済み
        guard let stats = previewStats else { return }

        // 画像合成: 左右半分ずつ
        let fusedImageData: Data
        if let img1 = first.uiImage, let img2 = second.uiImage,
           let merged = ImageFusion.mergeLeftRight(img1, img2),
           let pngData = merged.pngData() {
            fusedImageData = pngData
        } else {
            // 合成失敗時は1体目の画像を使う
            fusedImageData = first.imageData
        }

        // 両方の名前を結合
        let firstName = first.name ?? "？？？"
        let secondName = second.name ?? "？？？"
        let fusedName = "\(firstName)\(secondName)"

        let fusedMonster = Monster(
            imageData: fusedImageData,
            classificationLabel: fusedType,
            classificationConfidence: max(
                first.classificationConfidence ?? 0,
                second.classificationConfidence ?? 0
            ),
            name: fusedName,
            isFused: true,
            fusedHp: stats.hp,
            fusedAttack: stats.attack,
            fusedSpecialAttack: stats.specialAttack,
            fusedSpecialDefense: stats.specialDefense
        )

        // 素材モンスターを削除して合体モンスターを保存
        context.delete(first)
        context.delete(second)
        context.insert(fusedMonster)
        do {
            try context.save()
        } catch {
            print("合体モンスターの保存に失敗: \(error)")
        }

        // Supabase にアップロードして supabaseId を付与（バトル参加に必要）
        do {
            try await syncService.upload(monster: fusedMonster)
            try context.save()
        } catch {
            print("合体モンスターのアップロードに失敗: \(error)")
        }

        firstMonster = nil
        secondMonster = nil
        phase = .result(fusedMonster)
    }

    // MARK: - ステータス計算

    /// 各ステータスの高い方を採用 + ボーナス(10%)
    private func calculateFusedStats() -> BattleStats? {
        guard let first = firstMonster, let second = secondMonster else { return nil }
        let stats1 = first.battleStats
        let stats2 = second.battleStats

        let bonusRate = 1.1

        return BattleStats(
            hp: Int(Double(max(stats1.hp, stats2.hp)) * bonusRate),
            attack: Int(Double(max(stats1.attack, stats2.attack)) * bonusRate),
            specialAttack: Int(Double(max(stats1.specialAttack, stats2.specialAttack)) * bonusRate),
            specialDefense: Int(Double(max(stats1.specialDefense, stats2.specialDefense)) * bonusRate)
        )
    }

    func reset() {
        phase = .selectFirst
        firstMonster = nil
        secondMonster = nil
        previewStats = nil
    }
}
