//
//  RotatingCardComponent.swift
//  Pikumei
//

import SwiftUI

struct RotatingCardComponent: View {
    let frontImage: Image
    var stats: MonsterStats?
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
    }

    private var backFace: some View {
        ZStack {
            LinearGradient(
                colors: [.purple, .indigo],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            if let stats {
                VStack(spacing: 12) {
                    Text(stats.typeName)
                        .font(.title2)
                        .fontWeight(.bold)

                    Divider()
                        .background(.white.opacity(0.5))
                        .padding(.horizontal, 24)

                    VStack(spacing: 8) {
                        statsRow(label: "HP", value: stats.hp, max: 100)
                        statsRow(label: "ATK", value: stats.attack, max: 70)
                        statsRow(label: "DEF", value: stats.defense, max: 70)
                        statsRow(label: "SPD", value: stats.speed, max: 70)
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 4)

                    Text("タップして表へ戻す")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .foregroundStyle(.white)
                .padding(.vertical, 24)
            } else {
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

    private func statsRow(label: String, value: Int, max: Int) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .frame(width: 36, alignment: .leading)
            Text("\(value)")
                .font(.callout)
                .fontWeight(.bold)
                .frame(width: 32, alignment: .trailing)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white.opacity(0.2))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white.opacity(0.8))
                        .frame(width: geo.size.width * CGFloat(value) / CGFloat(max))
                }
            }
            .frame(height: 8)
        }
    }
}

#Preview {
    RotatingCardComponent(frontImage: Image(systemName: "photo.fill"))
        .padding()
}
