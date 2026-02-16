//
//  ScanPhase.swift
//  Pikumei
//

import Foundation

/// スキャン画面の状態を管理する enum
enum ScanPhase {
    case camera      // カメラプレビュー中
    case processing  // 画像処理中
    case result      // 切り抜き結果表示
}
