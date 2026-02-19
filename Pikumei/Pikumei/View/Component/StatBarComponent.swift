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

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray.opacity(0.2))
                RoundedRectangle(cornerRadius: 3)
                    .fill(color)
                    .frame(width: geo.size.width * Double(value) / Double(maxValue))
            }
        }
        .frame(height: 12)
    }
}
