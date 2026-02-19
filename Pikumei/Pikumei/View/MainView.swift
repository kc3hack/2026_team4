import SwiftUI

/// メイン画面（4タブ構成）
struct MainView: View {
    var body: some View {
        TabView {
            // 1. 起動時に最初に表示されるホーム画面
            HomeView()
                .tabItem {
                    Label("ホーム", systemImage: "house.fill")
                }
            
            MonsterScanView()
                .tabItem {
                    Label("スキャン", systemImage: "camera.viewfinder")
                }
            
            BattleView()
                .tabItem {
                    Label("バトル", systemImage: "bolt.fill")
                }
            
            MonsterListView()
                .tabItem {
                    Label("一覧", systemImage: "list.bullet")
                }
        }
    }
}

#Preview {
    MainView()
}
