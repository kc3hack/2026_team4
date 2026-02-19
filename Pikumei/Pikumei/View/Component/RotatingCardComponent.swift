//
//  RotatingCardComponent.swift
//  Pikumei
//

import SwiftUI

struct RotatingCardComponent: View {
    let frontImage: Image
    var onAnimationDone: (() -> Void)?
    @State private var rotationDegrees: Double = -720
    @State private var isFlipped = false
    @State private var isInitialAnimationDone = false

    private var showingBack: Bool {
        let normalized = rotationDegrees.truncatingRemainder(dividingBy: 360)
        let absolute = abs(normalized)
        return absolute > 90 && absolute < 270
    }

    var body: some View {
        ZStack {
            ZStack {
                frontFace
                    .opacity(showingBack ? 0 : 1)

                backFace
                    .opacity(showingBack ? 1 : 0)
                    .scaleEffect(x: -1, y: 1)
            }
        }
        .frame(width: 260, height: 380)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 8)
        .rotation3DEffect(
            .degrees(rotationDegrees),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.6
        )
        .onTapGesture {
            guard isInitialAnimationDone else { return }
            isFlipped.toggle()
            withAnimation(.easeInOut(duration: 0.3)) {
                rotationDegrees += isFlipped ? 180 : -180
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.1)) {
                rotationDegrees = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                isInitialAnimationDone = true
                onAnimationDone?()
            }
        }
    }

    private var frontFace: some View {
        ZStack {
            LinearGradient(
                colors: [.purple, .indigo],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            frontImage
                .resizable()
                .scaledToFill()
                .frame(width: 260, height: 380)
                .clipped()
        }
        .rareCardEffect()
    }

    private var backFace: some View {
        ZStack {
            LinearGradient(
                colors: [.purple, .indigo],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 16) {
                Text("???")
                    .font(.system(size: 48, weight: .bold))
                Text("モンスター情報")
                    .font(.title3)
                    .fontWeight(.semibold)
                Text("タップして表へ戻す")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .foregroundStyle(.white)
        }
    }
}

#Preview {
    RotatingCardComponent(frontImage: Image(systemName: "photo.fill"))
        .padding()
}
