//
//  StatBarComponent.swift
//  Pikumei
//
//  ステータス値をバーで表示するコンポーネント
//

import SwiftUI

struct StatBarComponent: View {
    let value: Int
    let maxValue: Int
    var color: Color = .blue.opacity(0.6)

    /// べき乗で差を強調（ratio^2 で低い値はより短く、高い値はそのまま）
    private var ratio: CGFloat {
        guard maxValue > 0 else { return 0 }
        let raw = CGFloat(value) / CGFloat(maxValue)
        return min(pow(raw, 2), 1.0)
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color.gray.opacity(0.2))
            .frame(height: 12)
            .overlay(alignment: .leading) {
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: geo.size.width * ratio)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 3))
    }
}

#Preview {
    VStack(spacing: 8) {
        // 攻撃: 28 → (28/55)^2 = 26%
        HStack { Text("攻撃 28").font(.caption).frame(width: 60); StatBarComponent(value: 28, maxValue: 55) }
        // 攻撃: 45 → (45/55)^2 = 67%
        HStack { Text("攻撃 45").font(.caption).frame(width: 60); StatBarComponent(value: 45, maxValue: 55) }
        // HP: 90 → (90/180)^2 = 25%
        HStack { Text("HP 90").font(.caption).frame(width: 60); StatBarComponent(value: 90, maxValue: 180) }
        // HP: 160 → (160/180)^2 = 79%
        HStack { Text("HP 160").font(.caption).frame(width: 60); StatBarComponent(value: 160, maxValue: 180) }
    }
    .padding()
}
