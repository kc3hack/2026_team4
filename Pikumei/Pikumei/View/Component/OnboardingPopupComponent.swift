//
//  OnboardingPopupComponent.swift
//  Pikumei
//

import SwiftUI

/// オンボーディング用のカード型ポップアップ
struct OnboardingPopupComponent: View {
    @ObservedObject var viewModel: OnboardingViewModel

    private var page: OnboardingPage {
        viewModel.pages[viewModel.currentPage]
    }

    private var isLastPage: Bool {
        viewModel.currentPage == viewModel.pages.count - 1
    }

    var body: some View {
        VStack(spacing: 16) {
            // ページインジケータ（ドット）
            HStack(spacing: 8) {
                ForEach(0..<viewModel.pages.count, id: \.self) { index in
                    Circle()
                        .fill(index == viewModel.currentPage ? Color.pikumeiNavy : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 20)

            // 画像
            HStack(spacing: 12) {
                ForEach(page.images, id: \.self) { imageName in
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 140)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color(.systemGray5))
            .cornerRadius(12)
            .padding(.horizontal, 10)

            // タイトル
            Text(page.title)
                .font(.custom("RocknRollOne-Regular", size: 20))
                .foregroundStyle(Color.pikumeiNavy)

            // 説明文
            Text(page.description)
                .font(.custom("DotGothic16-Regular", size: 15))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)

            // ボタン
            BlueButtonComponent(title: isLastPage ? "はじめる" : "次へ") {
                if isLastPage {
                    viewModel.finish()
                } else {
                    viewModel.nextPage()
                }
            }
            .padding(.bottom, 20)
        }
        .frame(width: 320)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()
        OnboardingPopupComponent(viewModel: OnboardingViewModel())
    }
}
