//
//  MonsterResultView.swift
//  Pikumei
//

import SwiftUI

/// 切り抜き結果のプレビュー画面
struct MonsterResultView: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss
    
    // 紙吹雪のトリガー
    @State private var showConfetti = false
    
    var body: some View {
        ZStack {
            // --- 紙吹雪エフェクト層（背景へ移動）---
            if showConfetti {
                ConfettiEffect()
                // .allowsHitTesting(false) // 背景に回ったので、これはなくてもボタンは押せますが一応残してもOK
                    .zIndex(0) // 最背面へ
            }
            
            // --- メインコンテンツ（前面へ移動）---
            VStack(spacing: 24) {
                Spacer()
                
                // カードコンポーネント
                RotatingCardComponent(frontImage: Image(uiImage: image))
                
                Spacer()
                
                Button("閉じる") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom, 32)
            }
            .zIndex(1) // 最前面へ
        }
        .onAppear {
            // 画面が表示されたら紙吹雪スタート
            showConfetti = true
        }
    }
}

// MARK: - 紙吹雪コンポーネント (コピペ用)
// ※ここは前回と同じで大丈夫ですが、念のため載せておきます
struct ConfettiEffect: View {
    @State private var isAnimating = false
    let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 1000個の紙吹雪を生成
                ForEach(0..<1000, id: \.self) { index in
                    ConfettiParticle(
                        color: colors.randomElement()!,
                        screenSize: geometry.size
                    )
                }
            }
        }
        .ignoresSafeArea()
    }
}

// 個別の紙吹雪パーティクル
struct ConfettiParticle: View {
    let color: Color
    let screenSize: CGSize
    
    @State private var isAnimating = false
    
    // ランダムなパラメータを初期化時に決定
    @State private var randomX: CGFloat = CGFloat.random(in: -300...300)
    @State private var randomY: CGFloat = CGFloat.random(in: -600...600)
    @State private var randomRotation: Double = Double.random(in: 360...720)
    @State private var randomDuration: Double = Double.random(in: 0.8...1.5)
    @State private var randomScale: CGFloat = CGFloat.random(in: 0.4...1.0)
    
    // 形をランダムにするためのフラグ
    let isCircle = Bool.random()
    
    var body: some View {
        Group {
            if isCircle {
                Circle()
                    .fill(color)
            } else {
                Rectangle()
                    .fill(color)
            }
        }
        .frame(
            width: CGFloat.random(in: 20...40),
            height: CGFloat.random(in: 20...40)
        )
        // アニメーション前の位置（画面中央）
        .scaleEffect(isAnimating ? randomScale : 0.1)
        .offset(
            x: isAnimating ? randomX : 0,
            y: isAnimating ? randomY : 0
        )
        .rotationEffect(.degrees(isAnimating ? randomRotation : 0))
        .opacity(isAnimating ? 0 : 1) // 最後はフェードアウト
        .animation(
            .easeOut(duration: randomDuration),
            value: isAnimating
        )
        .position(x: screenSize.width / 2, y: screenSize.height / 2)
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    MonsterResultView(
        image: UIImage(systemName: "photo")!
    )
}
