//
//  RadarChartComponent.swift
//  Pikumei
//
//  ステータスをレーダーチャート（多角形）で表示するコンポーネント
//

import SwiftUI

struct RadarChartComponent: View {
    /// 各軸のラベルと正規化済み値（0.0〜1.0）
    let axes: [(label: String, value: Double)]
    /// チャートの色
    var color: Color = .blue

    private var count: Int { axes.count }

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = min(geo.size.width, geo.size.height) / 2 * 0.7

            ZStack {
                // 背景のグリッド（25%, 50%, 75%, 100%）
                ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { scale in
                    polygonPath(center: center, radius: radius * scale)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                }

                // 軸線
                ForEach(0..<count, id: \.self) { i in
                    Path { path in
                        path.move(to: center)
                        path.addLine(to: point(index: i, radius: radius, center: center))
                    }
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                }

                // データの多角形（塗り）
                dataPath(center: center, radius: radius)
                    .fill(color.opacity(0.2))

                // データの多角形（線）
                dataPath(center: center, radius: radius)
                    .stroke(color, lineWidth: 2)

                // データ点
                ForEach(0..<count, id: \.self) { i in
                    let value = min(max(axes[i].value, 0), 1)
                    let pt = point(index: i, radius: radius * value, center: center)
                    Circle()
                        .fill(color)
                        .frame(width: 6, height: 6)
                        .position(pt)
                }

                // ラベル
                ForEach(0..<count, id: \.self) { i in
                    let labelPoint = point(index: i, radius: radius * 1.2, center: center)
                    Text(axes[i].label)
                        .font(.caption)
                        .bold()
                        .position(labelPoint)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: - Private

    /// 正多角形のパスを生成
    private func polygonPath(center: CGPoint, radius: Double) -> Path {
        Path { path in
            for i in 0..<count {
                let pt = point(index: i, radius: radius, center: center)
                if i == 0 { path.move(to: pt) }
                else { path.addLine(to: pt) }
            }
            path.closeSubpath()
        }
    }

    /// データ値に応じた多角形のパスを生成
    private func dataPath(center: CGPoint, radius: Double) -> Path {
        Path { path in
            for i in 0..<count {
                let value = min(max(axes[i].value, 0), 1)
                let pt = point(index: i, radius: radius * value, center: center)
                if i == 0 { path.move(to: pt) }
                else { path.addLine(to: pt) }
            }
            path.closeSubpath()
        }
    }

    /// 軸インデックスから座標を計算（上を0度起点に時計回り）
    private func point(index: Int, radius: Double, center: CGPoint) -> CGPoint {
        let angle = (2 * .pi / Double(count)) * Double(index) - .pi / 2
        return CGPoint(
            x: center.x + radius * cos(angle),
            y: center.y + radius * sin(angle)
        )
    }
}
