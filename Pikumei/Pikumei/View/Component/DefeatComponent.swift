import SwiftUI
import Lottie

//VictoryComponent をベースにした敗北画面
struct DefeatComponent: View {
    let onBack: () -> Void
    
    // アニメーション制御用の状態変数（Victoryと同じ）
    @State private var showCharacter = false
    @State private var showText = false
    @State private var showButton = false
    
    
    var body: some View {
        ZStack {
            LinearGradient(
                // くすんだ青紫
                colors: [Color(red: 0.6, green: 0.7, blue: 0.85), Color(red: 0.45, green: 0.5, blue: 0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            LottieView(animation: .named("RainDrop.json"))
                .playing(loopMode: .loop)
                .resizable()
                .ignoresSafeArea()
            // 少し暗くして背景になじませる
                .opacity(0.6)
            
            // メインコンテンツ
            VStack(spacing: 40) {
                // ③ 敗北テキスト
                Text("YOU LOSE...")
                    .font(.system(size: 60, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                // 影の色を暗い紫系に変更
                    .shadow(color: .purple.opacity(0.8), radius: 5, x: 0, y: 5)
                // 勝利画面と同じ出現アニメーション
                    .scaleEffect(showText ? 1.0 : 0.1)
                    .opacity(showText ? 1.0 : 0.0)
                

                LottieView(animation: .named("Rainyicon.json"))
                    .playing(loopMode: .loop)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 350, height: 350)
                // 勝利画面と同じ出現アニメーションをそのまま適用！
                    .offset(y: showCharacter ? 0 : 200)
                    .scaleEffect(showCharacter ? 1.0 : 0.5)
                    .opacity(showCharacter ? 1.0 : 0.0)
                // 勝利画面と同じ出現アニメーション
                    .offset(y: showCharacter ? 0 : 200)
                    .scaleEffect(showCharacter ? 1.0 : 0.5)
                    .opacity(showCharacter ? 1.0 : 0.0)
                
                
                Spacer().frame(height: 20)
                
                // ⑤ ボタン
                if showButton {
                    Button {
                        onBack()
                    } label: {
                        Text("ホームに戻る")
                            .font(.title3.bold())
                            .foregroundColor(.gray) // 文字色をグレー系に
                            .frame(width: 220, height: 55)
                            .background(Color.white)
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.3), radius: 5)
                    }

                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding()
        }
        .onAppear {
            startLoseAnimation()
        }
    }
    
    // 勝利画面のロジックをそのまま流用した時間差アニメーション
    private func startLoseAnimation() {
        // 1. キャラが下からドーンと出る（少しバウンドを弱めに調整）
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) { showCharacter = true }
        // 2. テキストが遅れてボンッと出る
        withAnimation(.bouncy(duration: 0.5, extraBounce: 0.2).delay(0.4)) { showText = true }
        // 3. ボタンが最後にスッと出る
        withAnimation(.easeOut(duration: 0.3).delay(1.8)) { showButton = true }
    }
}

// プレビュー
#Preview {
    DefeatComponent(
        onBack: { print("ホームに戻る") }
    )
    // ダークモードでの見え方も確認
    .preferredColorScheme(.dark)
}
