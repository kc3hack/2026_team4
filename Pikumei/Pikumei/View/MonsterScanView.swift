//
//  MonsterScanView.swift
//  Pikumei
//

import SwiftUI

/// モンスタースキャン画面（カメラ → 輪郭検出 → 切り抜き結果）
struct MonsterScanView: View {
    @StateObject private var viewModel = MonsterScanViewModel()

    var body: some View {
        ZStack {
            switch viewModel.phase {
            case .camera:
                cameraView
            case .processing:
                processingView
            case .result:
                resultView
            }
        }
        .onAppear {
            viewModel.startCamera()
        }
        .onDisappear {
            viewModel.stopCamera()
        }
        .fullScreenCover(isPresented: $viewModel.showPreview) {
            if let image = viewModel.cutoutImage {
                MonsterPreview(image: image) {
                    viewModel.retry()
                }
            }
        }
    }

    // MARK: - カメラプレビュー + 撮影ボタン

    private var cameraView: some View {
        ZStack {
            CameraPreviewView(session: viewModel.cameraManager.session)
                .ignoresSafeArea()

            VStack {
                Spacer()

                // 撮影ボタン
                Button(action: {
                    viewModel.captureAndProcess()
                }) {
                    Circle()
                        .fill(.white)
                        .frame(width: 72, height: 72)
                        .overlay(
                            Circle()
                                .stroke(.white.opacity(0.5), lineWidth: 4)
                                .frame(width: 82, height: 82)
                        )
                }
                .padding(.bottom, 32)
            }
        }
    }

    // MARK: - 処理中表示

    private var processingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("スキャン中...")
                .font(.headline)
        }
    }

    // MARK: - 切り抜き結果表示

    private var resultView: some View {
        VStack(spacing: 24) {
            // エラーがあれば表示
            if let error = viewModel.errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }

            Button("もう一度スキャン") {
                viewModel.retry()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    MonsterScanView()
}
