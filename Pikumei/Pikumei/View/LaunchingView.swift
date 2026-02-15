//
//  LaunchingView.swift
//  Pikumei
//

import SwiftUI

/// アプリ起動時に表示される Loading 画面
struct LaunchingView: View {
    var onFinish: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading...")
        }
        .task {
            // 2秒後にメイン画面へ遷移
            try? await Task.sleep(for: .seconds(2))
            onFinish()
        }
    }
}

#Preview {
    LaunchingView(onFinish: {})
}
