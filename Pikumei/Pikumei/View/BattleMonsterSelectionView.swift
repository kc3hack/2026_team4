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
        NavigationStack {
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
            .navigationTitle("モンスター選択")
        }
        .task {
            selectionVM.resetTouched()
        }
    }
    
    var content: some View {
        ScrollView {
            Spacer(minLength: 100)
            Text("バトルに出すモンスターを選んでください")
                .font(.custom("DotGothic16-Regular", size: 17))
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(monsters) { (monster: Monster) in
                    card(monster: monster)
                    
                }
            }
            .padding(8)
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarBackground(.hidden, for: .tabBar)
        .overlay() {
            VStack() {
                Spacer(minLength: 700)
                
                Button{
                    Task {
                        await selectionVM.confirmMonster()
                        dismiss()
                    }
                } label: {
                    Text("決定")
                }
                .padding()
                .background(Color.blue)
                .accentColor(Color.white)
                .disabled(selectionVM.touched == nil)
                
                Spacer(minLength: .zero)
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
            .border(Color.red, width: (monster.supabaseId == selectionVM.touched) ? 4 : 0)
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
    BattleMonsterSelectionView(selectionVM: selectionVM)
        .modelContainer(for: Monster.self, inMemory: true)
}
