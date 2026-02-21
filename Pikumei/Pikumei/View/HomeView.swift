import SwiftUI

struct HomeView: View {
    @State private var showFusion = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Image("back_siro")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                VStack {
                    VStack {
                        Text("2体のメイティを合体させてより強いメイティを作れます")
                            .font(.custom("RocknRollOne-Regular", size: 16))
                            .foregroundStyle(Color.black)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 280)
                        Image("monster_gattai")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 320)
                            .padding(.bottom, 45)
                    }
                    BlueButtonComponent(title: "合体") {
                        showFusion = true
                    }
                }
            }
            .navigationDestination(isPresented: $showFusion) {
                FusionView()
            }
        }
    }
}
