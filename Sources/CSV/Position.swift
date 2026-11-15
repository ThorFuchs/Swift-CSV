// SPDX-License-Identifier: Apache-2.0

/// 1-based line and column (in Unicode scalars) of the byte at `index`.
///
/// Only called when reporting an error, so it rescans the input; the bytes before
/// `index` are valid UTF-8 by then (or are being validated left to right).
func position(of index: Int, in bytes: [UInt8], from start: Int) -> (line: Int, column: Int) {
    var line = 1
    var column = 1
    var i = start
    while i < index && i < bytes.count {
        let byte = bytes[i]
        if byte == 0x0A {
            line += 1
            column = 1
        } else if byte & 0xC0 != 0x80 {
            column += 1
        }
        i += 1
    }
    return (line, column)
}

extension CSVError {
    init(_ code: Code, _ message: String, at index: Int, in bytes: [UInt8], from start: Int) {
        let (line, column) = position(of: index, in: bytes, from: start)
        self.init(code, message, line: line, column: column)
    }
}

/// Rejects anything that is not well-formed UTF-8: stray continuation bytes, truncated
/// sequences, overlong forms, surrogates and code points above U+10FFFF.
func validateUTF8(_ bytes: [UInt8], from start: Int) throws(CSVError) {
    var i = start
    let end = bytes.count
    while i < end {
        let lead = bytes[i]
        if lead < 0x80 { i += 1; continue }
        let length: Int
        var low: UInt8 = 0x80
        var high: UInt8 = 0xBF
        switch lead {
        case 0xC2...0xDF: length = 2
        case 0xE0: length = 3; low = 0xA0
        case 0xE1...0xEC, 0xEE...0xEF: length = 3
        case 0xED: length = 3; high = 0x9F
        case 0xF0: length = 4; low = 0x90
        case 0xF1...0xF3: length = 4
        case 0xF4: length = 4; high = 0x8F
        default:
            throw CSVError(.invalidEncoding, "invalid UTF-8 byte 0x\(hex(lead))", at: i, in: bytes, from: start)
        }
        for offset in 1..<length {
            let position = i + offset
            guard position < end else {
                throw CSVError(.invalidEncoding, "truncated UTF-8 sequence at the end of the input", at: i, in: bytes, from: start)
            }
            let byte = bytes[position]
            let range = offset == 1 ? low...high : 0x80...0xBF
            guard range.contains(byte) else {
                throw CSVError(.invalidEncoding, "invalid UTF-8 sequence starting with 0x\(hex(lead))", at: i, in: bytes, from: start)
            }
        }
        i += length
    }
}

private func hex(_ byte: UInt8) -> String {
    let digits = Array("0123456789ABCDEF")
    return String([digits[Int(byte >> 4)], digits[Int(byte & 0x0F)]])
}
