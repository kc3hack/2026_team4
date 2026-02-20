//
//  battleanimation.swift
//  Pikumei
//
//  Created by 西川雷朔 on 2026/02/18.
//


        import SwiftUI

        struct DriveInAnimations: View {
            // 画像の位置を管理する変数
            @State private var drivingInX: CGFloat = .zero
            @State private var drivingInY: CGFloat = .zero

            var body: some View {
                VStack(spacing: 32) {
                    Spacer()
                    
                    // アニメーションさせる対象（画像）
                    // ※元のコードの Image(.jello1) の代わりにシステムアイコンを使っています
                    Image("test_rufy")
                        .resizable()
                        .foregroundStyle(.red.gradient) // ゼリーっぽく赤色に
                        .scaledToFit()
                        .frame(width: 100, height: 64)
                        // X方向の移動に合わせて少し回転させる（画像と同じ処理）
                        .rotationEffect(.degrees(drivingInX / 12), anchor: .bottom)
                        .zIndex(4)
                        .offset(x: drivingInX)
                        .offset(y: drivingInY)
                    
                    Spacer()

                    // ボタン配置エリア
                    VStack(spacing: 16) {
                        // 上段：左右のボタン
                        HStack(spacing: 20) {
                            // 左から入ってくるアニメーション
                            Button {
                                runAnimation(x: -75, y: 0)
                            } label: {
                                ButtonLabel(text: "DriveInLeft")
                            }

                            // 右から入ってくるアニメーション
                            Button {
                                runAnimation(x: 75, y: 0)
                            } label: {
                                ButtonLabel(text: "DriveInRight")
                            }
                        }
                        
                        // 下段：上下のボタン
                        HStack(spacing: 20) {
                            // 上から入ってくるアニメーション
                            Button {
                                runAnimation(x: 0, y: -75)
                            } label: {
                                ButtonLabel(text: "DriveInTop")
                            }

                            // 下から入ってくるアニメーション
                            Button {
                                runAnimation(x: 0, y: 75)
                            } label: {
                                ButtonLabel(text: "DriveInBottom")
                            }
                        }
                    }
                    .padding(.bottom, 50)
                }
            }
            
            // アニメーションの共通ロジック
            // iOS 17以上で動作する completion ハンドラを使用しています
            func runAnimation(x: CGFloat, y: CGFloat) {
                // 1. 一瞬で画面外（指定した位置）へ移動させる
                // 画像のコードではトグルになっていますが、ここでは「外から中へ」を再現するため
                // 一度数値をセットしてから0に戻す動きにします
                
                // スタート位置にセット（アニメーションなし、またはバネで移動）
                withAnimation(.bouncy) {
                    drivingInX = x
                    drivingInY = y
                } completion: {
                    // 2. バネのような動きで中央(0,0)に戻す
                    withAnimation(.bouncy(duration: 0.25, extraBounce: 0.3)) {
                        drivingInX = .zero
                        drivingInY = .zero
                    }
                }
            }
        }

        // ボタンの見た目を共通化するビュー
        struct ButtonLabel: View {
            let text: String
            
            var body: some View {
                Text(text)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
        }

        #Preview {
            DriveInAnimations()
        }
