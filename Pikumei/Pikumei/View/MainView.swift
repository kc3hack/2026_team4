//
//  MainView.swift
//  Pikumei
//

import SwiftUI

/// メイン画面（3タブ構成）
struct MainView: View {
    var body: some View {
        TabView {
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
