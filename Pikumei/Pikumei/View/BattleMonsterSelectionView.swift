//
//  BattleMonsterSelectionView.swift
//  Pikumei
//

import SwiftUI
import SwiftData

/// モンスター選択画面
struct BattleMonsterSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var selectionVM: BattleMonsterSelectionViewModel
    @Query(sort: \Monster.createdAt, order: .reverse) private var monsters: [Monster]
    private let monsterListVM = MonsterListViewModel()
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]
    
    var body: some View {
        ZStack() {
            Image("back_splash")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            if monsters.isEmpty {
                emptyContent
            } else {
                content
            }
        }
        .navigationTitle("メイティ選択")
        .task {
            selectionVM.resetTouched()
        }
    }
    
    var content: some View {
        ScrollView {
            Spacer(minLength: 100)
            Text("バトルに出すメイティを選んでください")
                .font(.custom("RocknRollOne-Regular", size: 17))
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(monsters) { (monster: Monster) in
                    card(monster: monster)
                    
                }
            }
            .padding(8)
            .padding(.bottom, 160)
        }
        .toolbarBackground(.visible, for: .tabBar)
        .overlay() {
            VStack() {
                Spacer(minLength: 700)

                BlueButtonComponent(title: "決定") {
                    Task {
                        await selectionVM.confirmMonster()
                        dismiss()
                    }
                }
                .opacity(selectionVM.touched == nil ? 0.4 : 1.0)
                .disabled(selectionVM.touched == nil)

                Spacer(minLength: 80)
            }
        }
    }
    
    
    func card(monster: Monster) -> some View {
        Button {
            selectionVM.touched = monster.supabaseId
        } label: {
            MonsterCardComponent(
                monster: monster,
                stats: monsterListVM.stats(for: monster)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.pikumeiNavy, lineWidth: 3)
                    .opacity(monster.supabaseId == selectionVM.touched ? 1 : 0)
            )
            .scaleEffect(monster.supabaseId == selectionVM.touched ? 1.03 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: selectionVM.touched)
        }
    }
    
    var emptyContent: some View {
        ContentUnavailableView(
            "モンスターがいません",
            systemImage: "photo.on.rectangle.angled",
            description: Text("スキャンしてモンスターを集めよう")
        )
    }
    
    
}

#Preview {
    let selectionVM = BattleMonsterSelectionViewModel()
    NavigationStack {
        BattleMonsterSelectionView(selectionVM: selectionVM)
    }
    .modelContainer(for: Monster.self, inMemory: true)
}
