import SwiftUI

struct HomeView: View {
    var body: some View {
        ZStack {
            Image("back_butai")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 20) {
                
                Text("Taro Yamada")
                    .font(Font.custom("RocknRollOne-Regular", size: 48))
                Text("ぴくめい")
                    .font(.system(size: 48, weight: .bold, design: .rounded))

                Text("物を\n戦わせよう！")
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)

                // テスト用：タイプアイコン一覧
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 12) {
                    ForEach(MonsterType.allCases, id: \.self) { type in
                        TypeIconComponent(type: type)
                    }
                }
                .padding(.horizontal)

                // テスト用：GIFアニメーション
                GifImageComponent(name: "explosion", repeatCount: 1)
                    .frame(width: 200, height: 200)

                // テスト用：効果音ボタン
                Button("効果音テスト") {
                    SoundPlayerComponent.shared.play(.honou)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}
