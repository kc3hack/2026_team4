//
//  MonsterScanViewModel.swift
//  Pikumei
//

import Combine
import SwiftUI

/// モンスタースキャン画面の状態管理と処理オーケストレーション
@MainActor
class MonsterScanViewModel: ObservableObject {
    @Published var phase: ScanPhase = .camera
    @Published var cutoutImage: UIImage?
    @Published var errorMessage: String?

    let cameraManager = CameraManager()

    /// カメラセットアップ＆開始
    func startCamera() {
        Task.detached { [cameraManager] in
            cameraManager.configure()
            cameraManager.startSession()
        }
    }

    /// カメラ停止
    func stopCamera() {
        Task.detached { [cameraManager] in
            cameraManager.stopSession()
        }
    }

    /// 撮影 → 輪郭検出 → 切り抜き
    func captureAndProcess() {
        Task {
            phase = .processing
            errorMessage = nil

            do {
                let photo = try await cameraManager.capturePhoto()
                let cutout = try await ContourDetector.detectAndCutout(from: photo)
                cutoutImage = cutout
                phase = .result
            } catch {
                print("⚠️ スキャンエラー: \(error)")
                errorMessage = error.localizedDescription
                // エラー時も result に遷移して、エラーを見せる
                phase = .result
            }
        }
    }

    /// カメラフェーズに戻す
    func retry() {
        cutoutImage = nil
        errorMessage = nil
        phase = .camera
    }
}
