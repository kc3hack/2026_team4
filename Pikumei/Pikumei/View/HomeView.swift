import SwiftUI

struct HomeView: View {
    var body: some View {
        ZStack {
            Image("back_butai")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // --- メインタイトル「ぴくめい」 ---
                HStack(spacing: -2) { // 少し文字間を詰めるとロゴっぽくなります
                    OutlineText(text: "ぴ", mainColor: .pikumeiGreenMain, outlineColor: .pikumeiOutlineGreen, size: 80)
                    OutlineText(text: "くめい", mainColor: .pikumeiBlueMain, outlineColor: .pikumeiOutlineGreen, size: 80)
                }
                .rotationEffect(.degrees(-3)) // ほんの少し斜めにするとよりポップです
                
                // --- サブタイトル「☆もので戦おう☆」 ---
                OutlineText(text: "☆もので戦おう☆",
                            mainColor: .pikumeiSubBlueMain,
                            outlineColor: .pikumeiSubPurple,
                            size: 28)
                
                Spacer().frame(height: 20)
                
                // テスト用：GIFアニメーション
                GifImageComponent(name: "explosion", repeatCount: 1)
                    .frame(width: 200, height: 200)
                
                // テスト用：効果音ボタン
                Button(action: {
                    SoundPlayerComponent.shared.play(.honou)
                }) {
                    Text("効果音テスト")
                        .font(.headline)
                        .padding()
                        .background(Capsule().fill(Color.white.opacity(0.8)))
                        .foregroundColor(.black)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// 縁取り文字を作るコンポーネント
struct OutlineText: View {
    let text: String
    let mainColor: Color
    let outlineColor: Color
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // 八方向に文字をずらして重ねることで、太い縁取りを実現
            ForEach([(-2, -2), (2, -2), (-2, 2), (2, 2), (0, -3), (0, 3), (-3, 0), (3, 0)], id: \.0) { offset in
                Text(text)
                    .offset(x: CGFloat(offset.0), y: CGFloat(offset.1))
                    .foregroundColor(outlineColor)
            }
            // メインの文字
            Text(text)
                .foregroundColor(mainColor)
        }
        .font(.system(size: size, weight: .black, design: .rounded))
    }
}
