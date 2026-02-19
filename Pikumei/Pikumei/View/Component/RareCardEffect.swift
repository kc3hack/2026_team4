//
//  RareCardEffect.swift
//  Pikumei
//
//  Created by hayata  on 2026/02/18.
//
// RareCardEffect.swift
import SwiftUI
import CoreMotion

struct RareCardEffect: ViewModifier {
    @State private var motionManager = CMMotionManager()
    @State private var x: Double = 0
    @State private var y: Double = 0
    @State private var startTime = Date.now
    
    func body(content: Content) -> some View {
        TimelineView(.animation) { context in
            content
                .visualEffect { [x, y, startTime] content, proxy in
                    content.colorEffect(
                        ShaderLibrary.rareCard(
                            .float2(proxy.size),
                            .float2(x, y),
                            .float(context.date.timeIntervalSince(startTime))
                        )
                    )
                }
        }
        .onAppear {
            if motionManager.isDeviceMotionAvailable {
                motionManager.accelerometerUpdateInterval = 1.0 / 60.0
                motionManager.startAccelerometerUpdates(to: .main) { data, _ in
                    guard let acceleration = data?.acceleration else { return }
                    withAnimation(.linear(duration: 0.1)) {
                        x = acceleration.x
                        y = acceleration.y
                    }
                }
            }
        }
        .onDisappear {
            motionManager.stopAccelerometerUpdates()
        }
    }
}


extension View {
    func rareCardEffect() -> some View {
        self.modifier(RareCardEffect())
    }
}
