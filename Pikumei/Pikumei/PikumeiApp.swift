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

        // ナビバー背景を透明にしつつフォントを維持
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithTransparentBackground()
        navBarAppearance.largeTitleTextAttributes = [.font: largeTitleFont]
        navBarAppearance.titleTextAttributes = [.font: inlineTitleFont]
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance


        // タブバーのフォント・色・背景をゲームチックに統一
        let tabBarFont = UIFont(name: "DotGothic16-Regular", size: 10)!
        let navyColor = UIColor(red: 0x1E / 255.0, green: 0x33 / 255.0, blue: 0x65 / 255.0, alpha: 1)
        UITabBarItem.appearance().setTitleTextAttributes([.font: tabBarFont, .foregroundColor: navyColor], for: .selected)
        UITabBarItem.appearance().setTitleTextAttributes([.font: tabBarFont, .foregroundColor: navyColor.withAlphaComponent(0.4)], for: .normal)
        UITabBar.appearance().unselectedItemTintColor = navyColor.withAlphaComponent(0.4)

        // タブバー背景: 白っぽい半透明でやわらかい印象に
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        tabBarAppearance.backgroundColor = UIColor.white.withAlphaComponent(0.85)
        tabBarAppearance.shadowColor = UIColor.gray.withAlphaComponent(0.15)
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
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
