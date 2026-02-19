//
//  ByteaHexTests.swift
//  PikumeiTests
//

import Foundation
import Testing
@testable import Pikumei

struct ByteaHexTests {

    @Test func decodesHexWithBackslashXPrefix() {
        // "SGVsbG8=" は "Hello" の base64
        // UTF-8 hex: 53 47 56 73 62 47 38 3d (= は 0x3d)
        let hex = "\\x534756736247383d"
        let data = Data(byteaHex: hex)
        #expect(data != nil)
        #expect(data == Data("Hello".utf8))
    }

    @Test func decodesHexWithoutPrefix() {
        // prefix 無しでも変換可能
        let hex = "534756736247383d"
        let data = Data(byteaHex: hex)
        #expect(data != nil)
        #expect(data == Data("Hello".utf8))
    }

    @Test func returnsNilForOddLengthString() {
        let hex = "\\x534"
        let data = Data(byteaHex: hex)
        #expect(data == nil)
    }

    @Test func returnsNilForInvalidHexCharacters() {
        let hex = "\\xZZZZ"
        let data = Data(byteaHex: hex)
        #expect(data == nil)
    }
}
