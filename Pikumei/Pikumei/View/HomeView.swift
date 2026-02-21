import SwiftUI

struct HomeView: View {
    @State private var showFusion = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Image("back_butai")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                BlueButtonComponent(title: "合体") {
                    showFusion = true
                }
            }
            .navigationDestination(isPresented: $showFusion) {
                FusionView()
            }
        }
    }
}
