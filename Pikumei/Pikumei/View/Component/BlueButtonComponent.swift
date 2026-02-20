//
//  CustomButton.swift
//  Pikumei
//
//  Created by 西川雷朔 on 2026/02/20.
//

import SwiftUI

// 共通で使うボタンのコンポーネント
struct BlueButtonComponent: View {
    // 外から自由に変更できるように変数を用意する
    let title: String

    let action: () -> Void // 👈 ここがポイント！「押された時の処理」も外から受け取る
    
    var body: some View {
        Button {
            action() // 渡された処理を実行
        } label: {
            ZStack{
                Image("button_1")
                    .resizable()
                    .frame(width:300, height: 50)
                Text(title)
                    .font(.custom("DotGothic16-Regular", size: 17))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    // プレビューでどんな見た目か確認用
    VStack(spacing: 20) {
        BlueButtonComponent(title: "次へ") {
            print("次へが押されました")
        }
        
        BlueButtonComponent(title: "ホームに戻る") {
            print("ホームに戻ります")
        }
    }
    .padding()
    .background(Color.gray.opacity(0.2)) // 白いボタンが見えるように背景をグレーに
}
