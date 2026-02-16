//
//  CameraPreviewView.swift
//  Pikumei
//

import SwiftUI
import AVFoundation

/// AVCaptureVideoPreviewLayer をラップする UIViewRepresentable
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {}
}

/// PreviewLayer のフレームを自動追従させるカスタム UIView
class PreviewUIView: UIView {
    nonisolated override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}
