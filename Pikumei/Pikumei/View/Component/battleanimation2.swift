//
//  battleanimation2.swift
//  Pikumei
//
//  Created by 西川雷朔 on 2026/02/19.
//

import SwiftUI

struct BattleAnimationsView: View {
    // MARK: - 状態管理用の変数
    
    // 1. アイドル状態（フワフワ動く）
    @State private var isIdling = false
    
    // 2. 攻撃アニメーション用（プレイヤーの位置）
    @State private var playerAttackOffset: CGFloat = 0
    
    // 3. ダメージアニメーション用（敵の色と揺れ）
    @State private var enemyIsHurt = false
    @State private var enemyShakeOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 50) {
            Spacer()
            
            // --- バトルフィールド ---
            HStack(spacing: 40) {
                // MARK: プレイヤーキャラクター (左側：青)
                VStack {
                    Image(systemName: "figure.boxing")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.blue)
                    Text("Player")
                }
                // アイドル状態の動き（上下にフワフワ）
                .offset(y: isIdling ? -10 : 0)
                // 攻撃時の動き（右へ突撃）
                .offset(x: playerAttackOffset)
                
                
                // VSの文字
                Text("VS")
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                    .foregroundColor(.gray)

                
                // MARK: 敵キャラクター (右側：赤)
                VStack {
                    Image(systemName: "figure.fencing")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        // ダメージ時に赤く点滅させる
                        .foregroundColor(enemyIsHurt ? .red : .black)
                        // ダメージ時に少し透明にする
                        .opacity(enemyIsHurt ? 0.5 : 1.0)
                    Text("Enemy")
                }
                // アイドル状態の動き（上下にフワフワ、プレイヤーとタイミングをずらす）
                .offset(y: isIdling ? 8 : -2)
                // ダメージ時の揺れ
                .offset(x: enemyShakeOffset)
            }
            // 画面が表示されたらアイドルアニメーションを開始
            .onAppear {
                // 永遠に繰り返すアニメーション
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    isIdling = true
                }
            }
            
            Spacer()
            
            Divider()

            // --- 操作ボタンエリア ---
            VStack(spacing: 20) {
                Text("アニメーションを試す")
                    .font(.headline)
                
                HStack {
                    // ボタン1: 攻撃アクション
                    Button("① 攻撃する") {
                        runAttackAnimation()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    // ボタン2: ダメージを受ける
                    Button("② ダメージを受ける") {
                        runDamageAnimation()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
            }
            .padding(.bottom, 30)
        }
    }
    
    // MARK: - アニメーションのロジック
    
    /// ① 攻撃アニメーション（突撃して戻る）
    func runAttackAnimation() {
        // 1. 素早く前に出る (duration: 0.1)
        withAnimation(.easeOut(duration: 0.1)) {
            playerAttackOffset = 60 // 右へ60移動
        } completion: {
            // 2. 少しゆっくり元の位置に戻る (duration: 0.3)
            // バネのような動き(.bouncy)をつけて反動を表現
            withAnimation(.bouncy(duration: 0.3, extraBounce: 0.2)) {
                playerAttackOffset = 0
            }
        }
    }
    
    /// ② ダメージアニメーション（赤く点滅して揺れる）
    func runDamageAnimation() {
        // 1. 衝撃！赤くなって少し後ろに下がる
        withAnimation(.easeOut(duration: 0.05)) {
            enemyIsHurt = true
            enemyShakeOffset = 20 // 右（後ろ）へ下がる
        } completion: {
            // 2. ビヨンビヨンと揺れながら元の色・位置に戻る
            // 激しいバネの動きで「痛っ！」という感じを出す
            withAnimation(.spring(response: 0.3, dampingFraction: 0.2, blendDuration: 0)) {
                enemyIsHurt = false
                enemyShakeOffset = 0
            }
        }
    }
}

#Preview {
    BattleAnimationsView()
}
