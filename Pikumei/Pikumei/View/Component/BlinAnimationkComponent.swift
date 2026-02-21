//
//  BlinkAnimationComponent.swift
//  Pikumei
//
//  Created by 西川雷朔 on 2026/02/21.
//
import SwiftUI

struct BlinkAnimationComponent: View {
    let imageName: String
    
    // アニメーションの引き金（トリガー）になる変数
    @State private var blinking = Double.zero

    var body: some View {
        // 🌟 ボタンを消して、画像だけのスッキリした構成にしました
        Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(width: 100, height: 100)
            // phaseAnimator: [1, 0, 1, 0] の順番で不透明度を変化させて点滅させる
            .phaseAnimator([1, 0, 1, 0], trigger: blinking) { content, phase in
                            content
                                .opacity(phase)
                        } animation: { phase in
                            .linear(duration: 0.1)
                        }
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
        // トリガーの数値を変更することで phaseAnimator が動きます
        blinking += 1.0
    }
}

// MARK: - Preview

#Preview {
    // プレビューが表示された瞬間に自動でチカチカッと点滅します！
    BlinkAnimationComponent(imageName: "button_1") // 手持ちの画像名に変えてみてください
}
