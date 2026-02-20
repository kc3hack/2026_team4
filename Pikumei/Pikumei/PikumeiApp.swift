//
//  PikumeiApp.swift
//  Pikumei
//
//  Created by Sakurai Erika on 2026/02/15.
//

import SwiftData
import SwiftUI

@main
struct PikumeiApp: App {
    init() {
        // ナビゲーションバーのフォントをゲームチックに統一
        let largeTitleFont = UIFont(name: "RocknRollOne-Regular", size: 34)!
        let inlineTitleFont = UIFont(name: "RocknRollOne-Regular", size: 17)!

        UINavigationBar.appearance().largeTitleTextAttributes = [.font: largeTitleFont]
        UINavigationBar.appearance().titleTextAttributes = [.font: inlineTitleFont]

        // タブバーのフォントをゲームチックに統一
        let tabBarFont = UIFont(name: "DotGothic16-Regular", size: 10)!
        UITabBarItem.appearance().setTitleTextAttributes([.font: tabBarFont], for: .normal)
        UITabBarItem.appearance().setTitleTextAttributes([.font: tabBarFont], for: .selected)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                    // 明示的な .font() がないテキスト・ボタンのデフォルトフォント
                    .environment(\.font, .custom("DotGothic16-Regular", size: 15))
        }
        .modelContainer(for: Monster.self)
    }
}
