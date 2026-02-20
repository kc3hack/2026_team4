////
////  LaunchingView.swift
////  Pikumei
////
//
//import SwiftUI
//
///// アプリ起動時に表示される Loading 画面
//struct LaunchingView: View {
//    var onFinish: () -> Void
//    
//    var body: some View {
//        // 共通コンポーネントを呼び出すだけ
//        GameLoadingView(loadingText: "読み込み中...")
//            .task {
//                try? await Task.sleep(for: .seconds(2.5))
//                onFinish()
//            }
//    }
//}
//
//#Preview {
//    LaunchingView(onFinish: {})
//}
