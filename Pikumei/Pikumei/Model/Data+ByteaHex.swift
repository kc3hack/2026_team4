//
//  Data+ByteaHex.swift
//  Pikumei
//
//  Supabase の BYTEA カラムは hex 文字列（"\x2f396a..."）で返り、
//  中身は JSONEncoder が生成した base64 文字列なので二段階デコードが必要。
//

import Foundation

extension Data {
    /// Supabase BYTEA hex 文字列 → Data に変換
    init?(byteaHex hex: String) {
        var str = hex
        if str.hasPrefix("\\x") { str = String(str.dropFirst(2)) }
        guard str.count % 2 == 0 else { return nil }

        // hex → UTF-8 バイト列
        var bytes = [UInt8]()
        var index = str.startIndex
        while index < str.endIndex {
            let nextIndex = str.index(index, offsetBy: 2)
            guard let byte = UInt8(str[index..<nextIndex], radix: 16) else { return nil }
            bytes.append(byte)
            index = nextIndex
        }

        // UTF-8 バイト列 → base64 文字列 → Data
        guard let base64String = String(bytes: bytes, encoding: .utf8),
              let data = Data(base64Encoded: base64String) else { return nil }
        self = data
    }
}
