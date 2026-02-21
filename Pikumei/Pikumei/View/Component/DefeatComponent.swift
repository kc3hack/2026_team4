import SwiftUI
import Lottie

//VictoryComponent をベースにした敗北画面
struct DefeatComponent: View {
    let onBack: () -> Void
    
    // アニメーション制御用の状態変数
    @State private var showCharacter = false
    @State private var showText = false
    @State private var showButton = false
    
    var body: some View {
        ZStack {
            // 背景グラデーション
            LinearGradient(
                colors: [Color(red: 0.6, green: 0.7, blue: 0.85), Color(red: 0.45, green: 0.5, blue: 0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // メインコンテンツ
            VStack(spacing: 40) {
                // 敗北テキスト
                Text("YOU LOSE...")
                    .font(.system(size: 60, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .purple.opacity(0.8), radius: 5, x: 0, y: 5)
                    .scaleEffect(showText ? 1.0 : 0.1)
                    .opacity(showText ? 1.0 : 0.0)

                // キャラクターLottie
                LottieView(animation: .named("Rainyicon.json"))
                    .playing(loopMode: .loop) //
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250)
                    .offset(y: showCharacter ? 0 : 200)
                    .scaleEffect(showCharacter ? 1.0 : 0.5)
                    .opacity(showCharacter ? 1.0 : 0.0)
                    .padding()
                
                // ボタン
                if showButton {
                    Button {
                        onBack()
                    } label: {
                        Text("ホームに戻る")
                            .font(.title2.bold())
                            .foregroundColor(.gray)
                            .frame(width: 200, height: 55)
                            .background(Color.white)
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.3), radius: 5)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            //ipadように修正
            .padding(.horizontal, 32)
            .padding(.vertical, 40)
            .frame(maxWidth: 500)
        }
        .onAppear {
            startLoseAnimation()
            SoundPlayerComponent.shared.play(.defeat)
        }
    }
    
    private func startLoseAnimation() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) { showCharacter = true }
        withAnimation(.bouncy(duration: 0.5, extraBounce: 0.2).delay(0.4)) { showText = true }
        withAnimation(.easeOut(duration: 0.3).delay(1.8)) { showButton = true }
    }
}

#Preview {
    DefeatComponent(
        onBack: { print("ホームに戻る") }
    )
    .preferredColorScheme(.dark)
}
