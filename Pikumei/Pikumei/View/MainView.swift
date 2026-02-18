//
//  MainView.swift
//  Pikumei
//

import SwiftUI

/// メイン画面（3タブ構成）
struct MainView: View {
    var body: some View {
        TabView {
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
            
            aiBattleView()
                .tabItem {
                    Label("AIバトル", systemImage: "bolt.fill")
                }
            MonsterListView()
                .tabItem {
                    Label("一覧", systemImage: "list.bullet")
                }
        }
    }
}

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


