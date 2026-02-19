import SwiftUI

struct HomeView: View {
    // カラーコードをSwiftのColorに定義
    let mintBlue = Color(red: 0.878, green: 0.988, blue: 1.0) // #E0FCFF
    let softPink = Color(red: 0.980, green: 0.882, blue: 1.0) // #FAE1FF
    
    var body: some View {
        ZStack {
            // 背景：魔法のような高揚感のあるグラデーション
            LinearGradient(
                gradient: Gradient(colors: [mintBlue, softPink]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // コンテンツレイヤー
            VStack(spacing: 30) {
                Text("ぴくめい")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundColor(Color.black.opacity(0.7)) // 少し透過させて馴染ませる
                    .shadow(color: .white.opacity(0.5), radius: 10, x: 0, y: 5)
                
                Text("物を\n戦わせよう！")
                    .font(.title2)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                    .foregroundColor(Color.black.opacity(0.6))
                
                // テスト用：GIFアニメーション
                GifImageComponent(name: "flash-effect", repeatCount: 1)
                    .aspectRatio(1, contentMode: .fit)
                    .padding(.horizontal, 40)
                    .background(
                        // GIFの背後に光の輪を置いて「魔法感」を演出
                        Circle()
                            .fill(Color.white.opacity(0.3))
                            .blur(radius: 40)
                    )
                
                Spacer()
                
                // テスト用：効果音ボタン
                Button(action: {
                    SoundPlayerComponent.shared.play(.honou)
                }) {
                    Text("効果音テスト")
                        .fontWeight(.bold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(15)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
                }
                .padding(.horizontal, 60)
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    HomeView()
}
