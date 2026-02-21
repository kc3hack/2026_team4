//
//  ShakeAnimationComponent.swift
//  Pikumei
//
//  Created by 西川雷朔 on 2026/02/21.
//

import SwiftUI

struct ShakeAnimationComponent: View {
    let imageName: String
    
    // アニメーションの引き金（トリガー）になる変数
    @State private var isShaking = Double.zero

    var body: some View {
        // 🌟 ボタンを消して、画像単体のコンポーネントにしました
        Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(width: 100, height: 100)
            // phaseAnimator: trigger の値が変わるたびに [false -> true] と切り替わって揺れます
            .phaseAnimator([false, true], trigger: isShaking) { content, phase in
                content
                    .rotationEffect(.degrees(phase ? -15 : 0), anchor: .bottom)
                    .offset(x: phase ? 15 : 0)
            } animation: { phase in
                .bouncy(duration: 0.15, extraBounce: 0.6)
            }
            // 🌟 1. 画面に表示された瞬間にアニメーションを実行
            .onAppear {
                runAnimation()
            }
            // 🌟 2. 画像が切り替わった時にも自動で実行
            .onChange(of: imageName) { oldValue, newValue in
                runAnimation()
            }
    }
    
    // アニメーションを発動する処理
    func runAnimation() {
        isShaking += 1.0
    }
}

// MARK: - Preview

#Preview {
    // プレビューが表示されると、自動でブルブルッと揺れます！
    ShakeAnimationComponent(imageName: "button_1")
}
