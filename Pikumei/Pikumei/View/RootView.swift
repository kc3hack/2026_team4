//
//  RootView.swift
//  Pikumei
//

import SwiftUI

/// AppPhase に応じて表示する View を切り替えるルートビュー
struct RootView: View {
    @State private var phase: AppPhase = .launching

    var body: some View {
        ZStack {
            switch phase {
            case .launching:
                LaunchingView(onFinish: {
                    phase = .main
                })
            case .main:
                MainView()
            }
        }
    }
}

#Preview {
    RootView()
}
