//
//  BattleAnimation.swift
//  Pikumei
//
//  Created by 西川雷朔 on 2026/02/21.
//
import SwiftUI

struct DriveInAnimationComponent: View {
    let imageName: String

    // 画像の位置を管理する変数
    @State private var drivingInX: CGFloat = .zero
    @State private var drivingInY: CGFloat = .zero

    var body: some View {
        // 🌟 ボタンを削除し、画像単体のコンポーネントにしました
        Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(width: 100, height: 100)
            .rotationEffect(.degrees(drivingInX / 12), anchor: .bottom)
            .zIndex(4)
            .offset(x: drivingInX)
            .offset(y: drivingInY)
            // 🌟 1. 画面に表示された瞬間にアニメーションを実行
            .onAppear {
                // 例として左（-150）からスライドインさせます
                runAnimation(x: -150, y: 0)
            }
            // 🌟 2. 画像が切り替わった時にも自動で実行
            .onChange(of: imageName) { oldValue, newValue in
                runAnimation(x: -150, y: 0)
            }
    }
    
    // アニメーションの共通ロジック
    func runAnimation(x: CGFloat, y: CGFloat) {
        // まずは一瞬で画面外に配置
        drivingInX = x
        drivingInY = y
        
        // その後、バネの動きで中央に戻る
        withAnimation(.bouncy(duration: 0.5, extraBounce: 0.3)) {
            drivingInX = .zero
            drivingInY = .zero
        }
    }
}

// MARK: - Preview

#Preview {
    // プレビューが表示されると、左からシュッとスライドして登場します！
    DriveInAnimationComponent(imageName: "button_2")
}
