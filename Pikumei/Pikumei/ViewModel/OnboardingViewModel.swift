//
//  OnboardingViewModel.swift
//  Pikumei
//

import Combine
import SwiftUI

/// オンボーディングの1ページ分のデータ
struct OnboardingPage {
    let images: [String]
    let title: String
    let description: String
}

/// オンボーディング画面の状態管理
@MainActor
class OnboardingViewModel: ObservableObject {

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Published var showOnboarding = false
    @Published var currentPage = 0

    let pages: [OnboardingPage] = [
        OnboardingPage(
            images: ["monster_meiti"],
            title: "自分だけのメイティを作ろう！",
            description: "身の回りのものからキミだけのメイティが生まれるよ！"
        ),
        OnboardingPage(
            images: ["monster_scan", "monster_vs"],
            title: "スキャンしてバトル！",
            description: "カメラでスキャンしてメイティを作ったら、バトルで最強を目指そう！"
        ),
        OnboardingPage(
            images: ["monster_exchange"],
            title: "交換して合体！",
            description: "誰かと交換したメイティと自分のメイティを合体させてもっと強くしよう！"
        ),
    ]

    /// 初回起動時のみオンボーディングを表示する
    func checkAndShow() {
        if !hasCompletedOnboarding {
            showOnboarding = true
        }
    }

    /// 次のページへ進む
    func nextPage() {
        if currentPage < pages.count - 1 {
            currentPage += 1
        }
    }

    /// オンボーディングを完了して閉じる
    func finish() {
        hasCompletedOnboarding = true
        showOnboarding = false
    }
}
