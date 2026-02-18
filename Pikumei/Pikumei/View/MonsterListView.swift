import SwiftUI
import SwiftData

struct MonsterListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Monster.createdAt, order: .reverse) private var monsters: [Monster]
    
    @State private var monsterToDelete: Monster?
    @State private var showingDeleteAlert = false
    
    // 検索画面の表示管理
    @State private var showingSearchSheet = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // --- 上部の検索ボタン ---
                Button {
                    showingSearchSheet = true
                } label: {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("検索")
                        Spacer()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(25)
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
                .foregroundColor(.primary)
                
                if monsters.isEmpty {
                    Spacer()
                    ContentUnavailableView(
                        "モンスターがいません",
                        systemImage: "photo.on.rectangle.angled",
                        description: Text("スキャンしてモンスターを集めよう")
                    )
                    Spacer()
                } else {
                    // --- 横スクロールの一覧 ---
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 30) {
                            ForEach(monsters) { monster in
                                monsterCard(monster)
                            }
                        }
                        .padding(.horizontal, 50)
                        .padding(.top, 40)
                    }
                    .scrollTargetBehavior(.viewAligned)
                }
            }
            .navigationTitle("一覧画面")
            .navigationBarTitleDisplayMode(.inline)
            // 削除アラート
            .alert("モンスターの削除", isPresented: $showingDeleteAlert) {
                Button("キャンセル", role: .cancel) {}
                Button("削除", role: .destructive) {
                    if let monster = monsterToDelete { deleteMonster(monster) }
                }
            } message: {
                Text("このモンスターを逃がしますか？")
            }
            // --- 検索用ハーフシート ---
            .sheet(isPresented: $showingSearchSheet) {
                SearchFilterView()
                    .presentationDetents([.medium, .large]) // 半分の高さと全画面を切り替え
                    .presentationDragIndicator(.visible)
            }
        }
    }
    
    // モンスターカードの表示
    @ViewBuilder
    private func monsterCard(_ monster: Monster) -> some View {
        VStack(spacing: 15) {
            if let uiImage = monster.uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 250, height: 250)
                    .background(Color.white)
                    .cornerRadius(15)
                    .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.orange, lineWidth: 3))
                    .contextMenu {
                        Button(role: .destructive) {
                            monsterToDelete = monster
                            showingDeleteAlert = true
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                    }
            }
            
            VStack(spacing: 6) {
                Text("名前").font(.headline)
                Text("属性").font(.subheadline).foregroundColor(.secondary)
                Text("誰からのぴくめい").font(.caption).foregroundColor(.gray)
                Text(monster.createdAt, style: .date).font(.caption2).foregroundColor(.gray)
            }
        }
        .scrollTargetLayout()
    }
    
    private func deleteMonster(_ monster: Monster) {
        modelContext.delete(monster)
    }
}

// --- 検索設定画面 (別のViewとして定義) ---
struct SearchFilterView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("名前で探す").font(.headline)) {
                    Text("なまえ一覧がここに出ます...")
                }
                
                Section(header: Text("属性").font(.headline)) {
                    Text("火属性")
                    Text("水属性")
                    Text("草属性")
                }
                
                Section(header: Text("誰から？").font(.headline)) {
                    Text("友達A")
                    Text("家族")
                    Text("不明")
                }
                
                Section(header: Text("カレンダーで探す").font(.headline)) {
                    
                }
            }
            .navigationTitle("検索条件")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }
}
