//
//  ImageFusion.swift
//  Pikumei
//
//  2枚の画像を左右半分ずつ結合する
//

import UIKit

enum ImageFusion {

    /// 2枚の UIImage を左右半分で結合して1枚にする
    /// - Parameters:
    ///   - left: 左半分に使う画像
    ///   - right: 右半分に使う画像
    ///   - size: 出力サイズ（デフォルト 512x512）
    /// - Returns: 合成済みの UIImage（失敗時は nil）
    static func mergeLeftRight(_ left: UIImage, _ right: UIImage, size: CGSize = CGSize(width: 512, height: 512)) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let halfWidth = size.width / 2

            // 左半分: left 画像の左半分を描画
            context.cgContext.saveGState()
            context.cgContext.clip(to: CGRect(x: 0, y: 0, width: halfWidth, height: size.height))
            left.draw(in: CGRect(origin: .zero, size: size))
            context.cgContext.restoreGState()

            // 右半分: right 画像の右半分を描画
            context.cgContext.saveGState()
            context.cgContext.clip(to: CGRect(x: halfWidth, y: 0, width: halfWidth, height: size.height))
            right.draw(in: CGRect(origin: .zero, size: size))
            context.cgContext.restoreGState()
        }
    }
}
