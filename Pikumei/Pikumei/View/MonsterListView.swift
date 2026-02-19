import SwiftUI
import SwiftData

struct MonsterListView: View {
    @Environment(\.modelContext) private var modelContext // 削除に必要
    @Query(sort: \Monster.createdAt, order: .reverse) private var monsters: [Monster]
    
    // 削除対象を保持するステート
    @State private var monsterToDelete: Monster?
    @State private var showingDeleteAlert = false
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]
    
    var body: some View {
        if monsters.isEmpty {
            ContentUnavailableView(
                "モンスターがいません",
                systemImage: "photo.on.rectangle.angled",
                description: Text("スキャンしてモンスターを集めよう")
            )
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(monsters) { monster in
                        if let uiImage = monster.uiImage {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(1, contentMode: .fill)
                                .frame(minWidth: 0, maxWidth: .infinity) // サイズ固定を推奨
                                .clipped()
                            // 長押しメニューの追加
                                .contextMenu {
                                    Button(role: .destructive) {
                                        monsterToDelete = monster
                                        showingDeleteAlert = true
                                    } label: {
                                        Label("削除する", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
                .padding(4)
            }
            // 削除確認アラート
            .alert("モンスターの削除", isPresented: $showingDeleteAlert) {
                Button("キャンセル", role: .cancel) {}
                Button("削除", role: .destructive) {
                    if let monster = monsterToDelete {
                        deleteMonster(monster)
                    }
                }
            } message: {
                Text("このモンスターを逃がしますか？（元には戻せません）")
            }
        }
    }
    
    /// 削除処理
    private func deleteMonster(_ monster: Monster) {
        modelContext.delete(monster)
        // SwiftDataはContextを削除すれば自動で保存・UI反映されますが、
        // 明示的に保存したい場合は try? modelContext.save() を入れます
    }
}
