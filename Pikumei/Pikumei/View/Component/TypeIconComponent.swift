//
//  TypeIconComponent.swift
//  Pikumei
//

import SwiftUI

struct TypeIconComponent: View {
    let type: MonsterType
    var size: CGFloat = 60
    var color: Color?

    var body: some View {
        Image(type.imageName)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .foregroundStyle(color ?? type.color)
    }
}

#Preview("全タイプ一覧") {
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 16) {
        ForEach(MonsterType.allCases, id: \.self) { type in
            VStack(spacing: 8) {
                TypeIconComponent(type: type)
                Text(type.displayName)
                    .font(.caption)
            }
        }
    }
    .padding()
}

#Preview("fire") {
    TypeIconComponent(type: .fire, size: 100)
}

#Preview("water") {
    TypeIconComponent(type: .water, size: 100)
}

#Preview("leaf") {
    TypeIconComponent(type: .leaf, size: 100)
}

#Preview("ghost") {
    TypeIconComponent(type: .ghost, size: 100)
}

#Preview("human") {
    TypeIconComponent(type: .human, size: 100)
}

#Preview("fish") {
    TypeIconComponent(type: .fish, size: 100)
}

#Preview("bird") {
    TypeIconComponent(type: .bird, size: 100)
}
