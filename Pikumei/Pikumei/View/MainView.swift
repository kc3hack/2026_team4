import SwiftUI

struct MainView: View {
    var body: some View {
        TabView {
            // 1. 起動時に最初に表示されるホーム画面（新設）
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

/// アプリ起動時に表示されるホーム画面
struct HomeView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("ぴくめい")
                .font(.system(size: 48, weight: .bold, design: .rounded))
            
            Text("物を\n戦わせよう！")
                .font(.title2)
                .multilineTextAlignment(.center)
                .lineSpacing(8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white) // 背景色が必要な場合はここで調整
    }
}

#Preview {
    MainView()
}
