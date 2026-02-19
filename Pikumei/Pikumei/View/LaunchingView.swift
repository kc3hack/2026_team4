//
//  LaunchingView.swift
//  Pikumei
//

import SwiftUI

/// アプリ起動時に表示される Loading 画面

struct LaunchingView: View {
    var onFinish: () -> Void
    
    // アプリの戦略に合わせたTipsリスト
    let tips = [
        "🔥 ほのおは、くさやとりに強い！でもみずには注意。",
        "💧 みずしぶきで、ほのおを消し止めよう。",
        "🌿 くさタイプは、みずやさかなに有利だよ。",
        "👻 ゴーストはヒトに強いけど、とりには勝てない…",
        "👤 ヒトはさかなに強い！知恵を絞って戦おう。",
        "🐟 さかなはとりを驚かせるのが得意！",
        "🐦 とりは空からくさやゴーストを狙い撃ち！",
        "📸 はっきり撮るほど、モンスターの絆ゲージが貯まりやすい！"
    ]
    
    @State private var selectedTip: String = ""
    
    var body: some View {
        ZStack {
            // 背景（アプリのテーマカラーに合わせて調整してください）
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // アニメーション付きの読み込み
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.blue)
                
                Text("Loading...")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Tips表示エリア
                VStack(alignment: .leading, spacing: 8) {
                    Text("知ってた？")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                    
                    Text(selectedTip)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .frame(maxWidth: 300)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            // 画面が表示されるたびにランダムでTipsを選択
            selectedTip = tips.randomElement() ?? "冒険の準備中..."
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
