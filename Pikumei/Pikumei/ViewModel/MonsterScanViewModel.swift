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
    @Published var showPreview = false

    let cameraManager = CameraManager()
    private var isConfigured = false

    func startCamera() {
        if !isConfigured {
            cameraManager.configure()
            isConfigured = true
        }
        cameraManager.startSession()
    }

    func stopCamera() {
        cameraManager.stopSession()
    }

    /// 撮影 → 前景検出 → 切り抜き
    func captureAndProcess() {
        Task {
            phase = .processing
            errorMessage = nil

            do {
                let photo = try await cameraManager.capturePhoto()
                let cutout = try await SubjectDetector.detectAndCutout(from: photo)
                cutoutImage = cutout
                showPreview = true
            } catch {
                print("⚠️ スキャンエラー: \(error)")
                errorMessage = error.localizedDescription
                phase = .result
            }
        }
    }

    func retry() {
        showPreview = false
        cutoutImage = nil
        errorMessage = nil
        phase = .camera
    }
}
