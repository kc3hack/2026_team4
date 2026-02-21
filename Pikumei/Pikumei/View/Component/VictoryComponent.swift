//
//  VictoryComponent.swift
//  Pikumei
//

import SwiftUI
import Lottie

// 🌟 名前を VictoryComponent に変更
struct VictoryComponent: View {
    let onBack: () -> Void

    @State private var showCharacter = false
    @State private var showText = false
    @State private var showButton = false
    @State private var isAnimatingBg = false
    
    let winningCharacterImage = "star.fill"

    var body: some View {
        ZStack {
            // 背景
            LinearGradient(
                colors: [.yellow, .orange],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Lottieアニメーション
            LottieView(animation: .named("win_animation"))
                .playing(loopMode: .loop)
                .resizable()
                .ignoresSafeArea()
            
            // 既存の勝利画面UI
            VStack(spacing: 40) {
                Text("YOU WIN!!")
                    .font(.system(size: 60, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .orange.opacity(0.8), radius: 5, x: 0, y: 5)
                    .scaleEffect(showText ? 1.0 : 0.1)
                    .opacity(showText ? 1.0 : 0.0)
                
                Image(systemName: winningCharacterImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 180)
                    .foregroundColor(.white)
                    .offset(y: showCharacter ? 0 : 200)
                    .scaleEffect(showCharacter ? 1.0 : 0.5)
                    .opacity(showCharacter ? 1.0 : 0.0)
                
                Spacer().frame(height: 20)
                
                if showButton {
                    Button {
                        // 🌟 固定の print文 ではなく、受け取った処理（onBack）を実行する
                        onBack()
                    } label: {
                        Text("次へ")
                            .font(.title2.bold())
                            .foregroundColor(.orange)
                            .frame(width: 200, height: 55)
                            .background(Color.white)
                            .clipShape(Capsule())
                            .shadow(radius: 5)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .onAppear {
            startWinAnimation()
        }
    }
    
    private func startWinAnimation() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { showCharacter = true }
        withAnimation(.bouncy(duration: 0.5, extraBounce: 0.3).delay(0.3)) { showText = true }
        withAnimation(.easeOut(duration: 0.3).delay(1.5)) { showButton = true }
    }
}

// プレビュー用
#Preview {
    VictoryComponent(
        onBack: {
            print("プレビュー：次へボタンが押されました")
        }
    )
}
