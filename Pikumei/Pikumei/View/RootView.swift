//
//  RootView.swift
//  Pikumei
//

import PopupView
import SwiftUI

/// アプリのルートビュー
struct RootView: View {
    @StateObject private var onboardingVM = OnboardingViewModel()

    var body: some View {
        MainView()
            .popup(isPresented: $onboardingVM.showOnboarding) {
                OnboardingPopupComponent(viewModel: onboardingVM)
            } customize: {
                $0
                    .displayMode(.overlay)
                    .appearFrom(.centerScale)
                    .closeOnTap(false)
                    .closeOnTapOutside(false)
                    .allowTapThroughBG(false)
                    .dragToDismiss(false)
                    .backgroundColor(.black.opacity(0.4))
            }
            .onAppear {
                onboardingVM.checkAndShow()
            }
    }
}

#Preview {
    RootView()
}
