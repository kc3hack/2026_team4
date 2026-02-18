import SwiftUI
import SwiftData

struct MonsterListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Monster.createdAt, order: .reverse) private var monsters: [Monster]
    
    @State private var monsterToDelete: Monster?
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if monsters.isEmpty {
                    ContentUnavailableView(
                        "モンスターがいません",
                        systemImage: "photo.on.rectangle.angled",
                        description: Text("スキャンしてモンスターを集めよう")
                    )
                } else {
                    // 横スクロールの設定
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(monsters) { monster in
                                monsterCard(monster)
                            }
                        }
                        .padding(.horizontal, 40) // 両端の余白
                        .padding(.top, 50)
                    }
                    // スクロールの挙動を中央で止まるように調整（iOS 17+）
                    .scrollTargetBehavior(.viewAligned)
                }
            }
            .navigationTitle("一覧画面")
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
    
    // 各モンスターのカードビュー
    @ViewBuilder
    private func monsterCard(_ monster: Monster) -> some View {
        VStack(spacing: 15) {
            // モンスター画像部分
            if let uiImage = monster.uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 250, height: 250) // カードのサイズ
                    .background(Color.gray.opacity(0.1)) // 背景を少し明るく
                    .cornerRadius(15)
                // 画像の輪郭（枠線）を描写
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.orange, lineWidth: 3)
                    )
                // 長押しメニュー
                    .contextMenu {
                        Button(role: .destructive) {
                            monsterToDelete = monster
                            showingDeleteAlert = true
                        } label: {
                            Label("削除する", systemImage: "trash")
                        }
                    }
            }
            
            // テキスト情報（イメージ画像に基づいた配置）
            VStack(spacing: 5) {
                Text("名前") // monster.name などがあれば差し替え
                    .font(.headline)
                Text("属性")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("誰からのぴくめい")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(monster.createdAt, style: .date) // 追加した日
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        // スクロールで中央に止まるターゲットに指定
        .scrollTargetLayout()
    }
    
    private func deleteMonster(_ monster: Monster) {
        modelContext.delete(monster)
    }
}
