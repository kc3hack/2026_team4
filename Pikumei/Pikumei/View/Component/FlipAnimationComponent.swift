//
//  FlipAnimationComponent.swift
//  Pikumei
//
//  Created by 西川雷朔 on 2026/02/21.
//

import SwiftUI

struct FlipAnimationComponent: View {
    let imageName: String
    
    // 回転を管理する変数（代表して横回転のY軸を使用）
    @State private var flipY = Double.zero

    var body: some View {
        // ボタン類を消し、画像だけのスッキリしたコンポーネントにしました
        Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(width: 100, height: 100)
            .rotation3DEffect(
                .degrees(flipY),
                axis: (x: 0.0, y: 1.0, z: 0.0) // Y軸（横）に回転
            )
            // 🌟 1. 画面に表示された瞬間にアニメーションを実行
            .onAppear {
                runAnimation()
            }
            // 🌟 2. 途中で「別の画像名」に変更された時にも、もう一度アニメーションを実行
            // iOS 17以降の書き方です
            .onChange(of: imageName) { oldValue, newValue in
                runAnimation()
            }
    }
    
    // アニメーションの処理
    func runAnimation() {
        withAnimation(.bouncy(duration: 1.0)) {
            // 毎回同じ方向にくるっと回るように、現在の角度に+360度します
            flipY += 360
        }
    }
}

// MARK: - Preview

#Preview {
    // プレビューが表示された瞬間に自動でくるっと回ります！
    FlipAnimationComponent(imageName: "button_1")
}
