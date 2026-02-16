//
//  MockMonsterFactory.swift
//  Pikumei
//

import SwiftData
import UIKit

/// テスト用のモンスターを生成する（ML 分類の代替）
enum MockMonsterFactory {

    /// ラベル付きのモンスターを SwiftData に追加する
    @MainActor
    static func insertSamples(into modelContext: ModelContext) {
        let samples: [(label: String, color: UIColor)] = [
            ("dog", .systemOrange),
            ("cat", .systemPurple),
            ("bird", .systemCyan),
            ("fish", .systemBlue),
            ("flower", .systemPink),
        ]

        for sample in samples {
            let image = generatePlaceholderImage(label: sample.label, color: sample.color)
            guard let data = image.pngData() else { continue }

            let monster = Monster(
                imageData: data,
                classificationLabel: sample.label,
                classificationConfidence: 0.95
            )
            modelContext.insert(monster)
        }

        try? modelContext.save()
    }

    /// ラベル名入りのプレースホルダー画像を生成
    private static func generatePlaceholderImage(label: String, color: UIColor) -> UIImage {
        let size = CGSize(width: 200, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 32),
                .foregroundColor: UIColor.white,
            ]
            let text = label as NSString
            let textSize = text.size(withAttributes: attrs)
            let point = CGPoint(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2
            )
            text.draw(at: point, withAttributes: attrs)
        }
    }
}
