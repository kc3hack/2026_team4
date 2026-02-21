//
//  FlipAnimationModifier.swift
//  Pikumei
//
//  Created by Daichi Sakai on 2026/02/21.
//

import SwiftUI

// 任意のViewにBlinkアニメーションを付加するViewModifier
struct FlipAnimationModifier: ViewModifier {
    var trigger: Bool
    @State private var flipY = Double.zero
    
    func body(content: Content) -> some View {
        content
            .phaseAnimator([0, 1], trigger: trigger) { content, phase in
                content
                    .rotation3DEffect(
                        .degrees(360 * phase),
                        axis: (x: 0.0, y: 1.0, z: 0.0) // Y軸（横）に回転
                    )
            } animation: { phase in
                phase == 0 ? .bouncy(duration: 0.7) : nil
            }
    }
}

extension View {
    func flipAnimation(trigger: Bool) -> some View {
        self.modifier(FlipAnimationModifier(trigger: trigger))
    }
}

// MARK - Preview

#Preview {
    @Previewable @State var trigger: Bool = false
    
    VStack(spacing: 20) {
        Image(systemName: "star.fill")
            .font(.system(size: 100))
            .foregroundColor(.yellow)
            .flipAnimation(trigger: trigger)
        
        Button("Flip") {
            trigger.toggle()
        }
    }
}
