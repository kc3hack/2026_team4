//
//  TypeLabelComponent.swift
//  Pikumei
//

import SwiftUI

/// タイプアイコン + テキストを横並びで表示するコンポーネント
struct TypeLabelComponent: View {
    let type: MonsterType
    let text: String
    var iconSize: CGFloat = 18
    var fontSize: CGFloat = 13
    var spacing: CGFloat = 4

    var body: some View {
        HStack(spacing: spacing) {
            TypeIconComponent(type: type, size: iconSize)
            Text(text)
                .font(.custom("RocknRollOne-Regular", size: fontSize))
                .foregroundStyle(type.color)
                .lineLimit(1)
        }
    }
}

#Preview("各タイプ") {
    VStack(spacing: 12) {
        ForEach(MonsterType.allCases, id: \.self) { type in
            TypeLabelComponent(type: type, text: type.displayName)
        }
    }
    .padding()
}
