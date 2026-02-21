import SwiftUI

/// メイン画面（5タブ構成）
struct MainView: View {
    @State private var selectedTab = 4
    @State private var isShowingHelp = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            TabView(selection: $selectedTab) {
                BattleView()
                    .tabItem {
                        Label("バトル", systemImage: "bolt.fill")
                    }
                    .tag(0)

                ExchangeView()
                    .tabItem {
                        Label("こうかん", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .tag(1)

                MonsterScanView()
                    .tabItem {
                        Label("スキャン", systemImage: "camera.viewfinder")
                    }
                    .tag(2)

                MonsterListView()
                    .tabItem {
                        Label("一覧", systemImage: "list.bullet")
                    }
                    .tag(3)

                HomeView()
                    .tabItem {
                        Label("ホーム", systemImage: "house.fill")
                    }
                    .tag(4)
            }
            .tint(.pikumeiNavy)

            // スキャンタブ以外で「？」ボタンを表示
            if selectedTab != 2 {
                HelpButtonComponent(isShowingHelp: $isShowingHelp)
                    .padding(.top, 8)
                    .padding(.trailing, 16)
            }
        }
        .sheet(isPresented: $isShowingHelp) {
            HelpSheetComponent()
        }
    }
}

#Preview {
    MainView()
}
