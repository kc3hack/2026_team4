//
//  BlinkAnimationModifier.swift
//  Pikumei
//
//  Created by Daichi Sakai on 2026/02/21.
//

import SwiftUI

// 任意のViewにBlinkアニメーションを付加するViewModifier
struct BlinkAnimationModifier: ViewModifier {
    var trigger: Bool
    
    func body(content: Content) -> some View {
        // phaseAnimator: [1, 0, 1, 0] の順番で不透明度を変化させて点滅させる
        content
            .phaseAnimator([1, 0, 1, 0], trigger: trigger) { content, phase in
                content
                    .opacity(phase)
            } animation: { phase in
                    .linear(duration: 0.1)
            }
    }
}

extension View {
    func blinkAnimation(trigger: Bool) -> some View {
        self.modifier(BlinkAnimationModifier(trigger: trigger))
    }
}

// MARK - Preview

#Preview {
    @Previewable @State var trigger: Bool = false
    
    VStack(spacing: 20) {
        Image(systemName: "star.fill")
            .font(.system(size: 100))
            .foregroundColor(.yellow)
            .blinkAnimation(trigger: trigger)
        
        Button("Blink") {
            trigger.toggle()
        }
    }
}
