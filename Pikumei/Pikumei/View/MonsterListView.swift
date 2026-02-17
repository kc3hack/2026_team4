import SwiftUI
import SwiftData

/// モンスター一覧画面
struct MonsterListView: View {
    @Environment(\.modelContext) private var modelContext // 1. 削除実行用
    @Query(sort: \Monster.createdAt, order: .reverse) private var monsters: [Monster]
    
    // 削除確認用のアラート状態
    @State private var showingDeleteAlert = false
    @State private var monsterToDelete: Monster?
    
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
                                .frame(minWidth: 0, maxWidth: .infinity) // グリッド内で安定させる
                                .clipped()
                            // 2. 長押し時の挙動
                                .onLongPressGesture {
                                    monsterToDelete = monster
                                    showingDeleteAlert = true
                                }
                        }
                    }
                }
                .padding(4)
            }
            // 3. 削除確認アラート
            .alert("削除しますか？", isPresented: $showingDeleteAlert) {
                Button("はい", role: .destructive) {
                    if let monster = monsterToDelete {
                        deleteMonster(monster)
                    }
                }
                Button("いいえ", role: .cancel) {
                    monsterToDelete = nil
                }
            } message: {
                Text("このモンスターを削除すると元に戻せません。")
            }
        }
    }
    
    /// データを削除する関数
    private func deleteMonster(_ monster: Monster) {
        modelContext.delete(monster)
        // SwiftDataは自動的にUIを更新しますが、明示的に保存することも可能です
        try? modelContext.save()
    }
}
