import SwiftUI

struct HomeView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("ぴくめい")
                .font(.system(size: 48, weight: .bold, design: .rounded))
            
            Text("物を\n戦わせよう！")
                .font(.title2)
                .multilineTextAlignment(.center)
                .lineSpacing(8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}
