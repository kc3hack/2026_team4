//
//  JumpInLeftAnimationComponent.swift
//  Pikumei
//
//  Created by 西川雷朔 on 2026/02/21.
//

import SwiftUI

struct JumpInLeftAnimationComponent: View {
    // 🌟 外から自由に画像の名前を受け取れるように変数を用意
    let imageName: String
    
    @State private var isJumpingInLeft = false

    var body: some View {
        // 🌟 ボタンを消して、画像だけのスッキリした構成にしました
        Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(width: 100, height: 100)
            .zIndex(1)
            .rotationEffect(.degrees(isJumpingInLeft ? -30 : 0),
                           anchor: isJumpingInLeft ? .bottomTrailing : .center)
            .scaleEffect(isJumpingInLeft ? 1.4 : 1)
            .offset(y: isJumpingInLeft ? 5 : 0)
            // 🌟 1. 画面に表示された瞬間にアニメーションを実行
            .onAppear {
                runAnimation()
            }
            // 🌟 2. 途中で「別の画像名」に変更された時にも、もう一度アニメーションを実行
            .onChange(of: imageName) { oldValue, newValue in
                runAnimation()
            }
    }
    
    // アニメーションを発動する処理
    func runAnimation() {
        withAnimation(.timingCurve(0.68, -0.6, 0.32, 1.6, duration: 0.6)) {
            isJumpingInLeft = true
        } completion: {
            withAnimation(.bouncy(duration: 0.5, extraBounce: 0.3)) {
                isJumpingInLeft = false
            }
        }
    }
}

// MARK: - Preview

#Preview {
    // 🌟 プレビューが表示された瞬間に自動でピョコッ！と動きます
    JumpInLeftAnimationComponent(imageName: "button_1") // 手持ちの画像名に変えてみてください
}
