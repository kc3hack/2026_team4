//
//  BrownButtonComponent.swift
//  Pikumei
//
//  Created by 西川雷朔 on 2026/02/20.
//

import SwiftUI

// 共通で使うボタンのコンポーネント
struct BrownButtonComponent: View {
    // 外から自由に変更できるように変数を用意する
    let title: String

    let action: () -> Void // 👈 ここがポイント！「押された時の処理」も外から受け取る
    
    var body: some View {
        Button {
            action() // 渡された処理を実行
        } label: {
            ZStack{
                Image("button_2")
                    .resizable()
                    .frame(width:300, height: 30)
                Text(title)
                    .font(.title2)
                    .foregroundColor(.white)
                    .font(.headline)
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 2)
            }
        }
        // 押した時に少し沈み込むようなアニメーションをつける（お好みで）
        .buttonStyle(.plain)
    }
}

#Preview {
    // プレビューでどんな見た目か確認用
    VStack(spacing: 20) {
        BrownButtonComponent(title: "次へ") {
            print("次へが押されました")
        }
        
        BrownButtonComponent(title: "ホームに戻る") {
            print("ホームに戻ります")
        }
    }
    .padding()
    .background(Color.gray.opacity(0.2)) // 白いボタンが見えるように背景をグレーに
}

