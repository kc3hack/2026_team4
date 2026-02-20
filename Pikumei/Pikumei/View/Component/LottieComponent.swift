//
//  LottieComponent.swift
//  Pikumei
//
//  Created by hayata  on 2026/02/20.
//

import SwiftUI
import Lottie

struct LottieComponent: UIViewRepresentable {
    var fileName: String
    var loopMode: LottieLoopMode = .loop
    
    func makeUIView(context: Context) -> UIView {
        
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear

        let animationView = LottieAnimationView(name: fileName)
        animationView.loopMode = loopMode
        animationView.contentMode = .scaleAspectFit
        animationView.play()
        animationView.backgroundColor = .clear
        animationView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(animationView)
        
        NSLayoutConstraint.activate([
            animationView.widthAnchor.constraint(equalTo: view.widthAnchor),
            animationView.heightAnchor.constraint(equalTo: view.heightAnchor),
            animationView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            animationView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // 特に更新処理は不要
    }
}
