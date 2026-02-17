//
//  CameraManager.swift
//  Pikumei
//

import AVFoundation
import Combine
import UIKit

/// AVCaptureSession を管理し、写真撮影を行うマネージャ
class CameraManager: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "com.pikumei.camera.session")
    private var photoContinuation: CheckedContinuation<UIImage, Error>?

    /// カメラのセットアップ（背面カメラ、.photo プリセット）
    func configure() {
        session.beginConfiguration()
        session.sessionPreset = .photo

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            session.commitConfiguration()
            return
        }

        if session.canAddInput(input) {
            session.addInput(input)
        }
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }

        session.commitConfiguration()
    }

    func startSession() {
        sessionQueue.async { [session] in
            guard !session.isRunning else { return }
            session.startRunning()
        }
    }

    func stopSession() {
        sessionQueue.async { [session] in
            guard session.isRunning else { return }
            session.stopRunning()
        }
    }

    /// 写真を撮影して UIImage を返す（連打防止付き）
    func capturePhoto() async throws -> UIImage {
        guard photoContinuation == nil else {
            throw CameraError.captureFailed
        }
        return try await withCheckedThrowingContinuation { continuation in
            self.photoContinuation = continuation
            let settings = AVCapturePhotoSettings()
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraManager: AVCapturePhotoCaptureDelegate {
    // AVFoundation がバックグラウンドスレッドから呼ぶため nonisolated が必要
    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        Task { @MainActor in
            if let error = error {
                photoContinuation?.resume(throwing: error)
                photoContinuation = nil
                return
            }

            guard let data = photo.fileDataRepresentation(),
                  let image = UIImage(data: data) else {
                photoContinuation?.resume(throwing: CameraError.captureFailed)
                photoContinuation = nil
                return
            }

            photoContinuation?.resume(returning: image)
            photoContinuation = nil
        }
    }
}

/// カメラ関連のエラー
enum CameraError: LocalizedError {
    case captureFailed

    var errorDescription: String? {
        switch self {
        case .captureFailed:
            return "写真の撮影に失敗しました"
        }
    }
}
