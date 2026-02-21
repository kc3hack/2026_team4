import SwiftUI

/// アプリ全体で共通して使用するローディング画面
struct GameLoadingView: View {
    // 表示するテキスト（「スキャン中...」など画面ごとに変えられるように）
    let loadingText: String
    
    @State private var selectedTip: String = ""
    
    var body: some View {
        ZStack {
            // 背景色はアプリのテーマに合わせて統一
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // 中央のインジケーター
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.blue)
                    
                    Text(loadingText)
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Tips表示エリア（再利用可能なデザイン）
                tipsCard
                    .padding(.bottom, 60)
            }
        }
        .onAppear {
            selectedTip = GameTip.random()
        }
    }
    
    // Tipsカード部分を切り出し
    private var tipsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("知ってた？")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Color.blue
                    )
                    .cornerRadius(20)
                
                Spacer()
            }
            
            Text(selectedTip)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(4)
        }
        .padding(20)
        .frame(maxWidth: 320)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(
                    color: .black.opacity(0.1),
                    radius: 10,
                    x: 0,
                    y: 5
                )
        )
    }
}
