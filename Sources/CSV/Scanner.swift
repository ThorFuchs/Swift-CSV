// SPDX-License-Identifier: Apache-2.0

private let quote: UInt8 = 0x22
private let lineFeed: UInt8 = 0x0A
private let carriageReturn: UInt8 = 0x0D

/// A single left-to-right pass over validated UTF-8 bytes.
struct Scanner {
    let bytes: [UInt8]
    let start: Int
    let delimiter: UInt8
    let headerMode: CSVHeaderMode
    let limits: CSVLimits
    var index: Int
    var line = 1

    init(bytes: [UInt8], start: Int, options: CSVOptions, limits: CSVLimits) {
        self.bytes = bytes
        self.start = start
        self.delimiter = options.delimiter.byte
        self.headerMode = options.header
        self.limits = limits
        self.index = start
    }

    /// A record as read, with the byte offset of each field for error positions.
    struct RawRecord {
        var fields: [String] = []
        var offsets: [Int] = []
        var line: Int
        var startIndex: Int
        /// The offset of the line break that ends the record, or of the end of the input.
        var endIndex: Int
    }

    func error(_ code: CSVError.Code, _ message: String, at index: Int) -> CSVError {
        CSVError(code, message, at: index, in: bytes, from: start)
    }

    mutating func table() throws(CSVError) -> CSVTable {
        var header: [String]?
        var expectedCount: Int?
        var records: [CSVRecord] = []
        if headerMode == .required {
            guard let first = try nextRecord() else {
                throw CSVError(.missingHeader, "a header record is required, but the input is empty", line: 1, column: 1)
            }
            var seen = Set<String>()
            for (name, offset) in zip(first.fields, first.offsets) {
                if name.isEmpty {
                    throw error(.emptyHeaderName, "header name \(seen.count + 1) is empty", at: offset)
                }
                guard seen.insert(name).inserted else {
                    throw error(.duplicateHeaderName, "duplicate header name \"\(name)\"", at: offset)
                }
            }
            header = first.fields
            expectedCount = first.fields.count
        }
        while let record = try nextRecord() {
            if records.count == limits.maxRecords {
                throw error(.tooManyRecords, "more than \(limits.maxRecords) records", at: record.startIndex)
            }
            if let expected = expectedCount {
                guard record.fields.count == expected else {
                    throw mismatch(record, expected: expected)
                }
            } else {
                expectedCount = record.fields.count
            }
            records.append(CSVRecord(fields: record.fields, line: record.line))
            if records.count % 1_024 == 0, Task.isCancelled {
                throw error(.cancelled, "parsing was cancelled", at: record.startIndex)
            }
        }
        return CSVTable(header: header, records: records)
    }

    private func mismatch(_ record: RawRecord, expected: Int) -> CSVError {
        let what = headerMode == .required ? "the header has" : "the first record has"
        let found = record.fields.count
        let blank = found == 1 && record.fields[0].isEmpty && record.endIndex == record.startIndex
        if blank {
            return error(.fieldCountMismatch, "blank line is a record with 1 empty field; \(what) \(expected)", at: record.startIndex)
        }
        if found > expected {
            return error(.fieldCountMismatch, "record has \(found) fields; \(what) \(expected)", at: record.offsets[expected])
        }
        return error(.fieldCountMismatch, "record has \(found) field\(found == 1 ? "" : "s"); \(what) \(expected)", at: record.endIndex)
    }

    /// Reads the next record, or `nil` at the end of the input.
    mutating func nextRecord() throws(CSVError) -> RawRecord? {
        guard index < bytes.count else { return nil }
        var record = RawRecord(line: line, startIndex: index, endIndex: index)
        while true {
            if record.fields.count == limits.maxFieldsPerRecord {
                throw error(.tooManyFields, "record has more than \(limits.maxFieldsPerRecord) fields", at: index)
            }
            record.offsets.append(index)
            record.fields.append(try field())
            // After a field: delimiter, line break or end of input.
            guard index < bytes.count else {
                record.endIndex = index
                return record
            }
            switch bytes[index] {
            case delimiter:
                index += 1
            case lineFeed:
                record.endIndex = index
                index += 1
                line += 1
                return record
            case carriageReturn:
                guard index + 1 < bytes.count, bytes[index + 1] == lineFeed else {
                    throw error(.bareCarriageReturn, "carriage return without a following line feed", at: index)
                }
                record.endIndex = index
                index += 2
                line += 1
                return record
            default:
                // Only reachable after a closing quote; unquoted fields stop at the above.
                throw error(.unexpectedCharacterAfterQuote,
                            "unexpected character after a closing quote; expected a delimiter or a line break", at: index)
            }
        }
    }

    /// Reads one field starting at `index` and leaves `index` on the byte after it.
    private mutating func field() throws(CSVError) -> String {
        let fieldStart = index
        if index < bytes.count && bytes[index] == quote {
            index += 1
            var value: [UInt8] = []
            while true {
                guard index < bytes.count else {
                    throw error(.unterminatedQuotedField, "quoted field is not closed", at: fieldStart)
                }
                let byte = bytes[index]
                if byte == quote {
                    if index + 1 < bytes.count && bytes[index + 1] == quote {
                        value.append(quote)
                        index += 2
                    } else {
                        index += 1
                        break
                    }
                } else {
                    if byte == lineFeed { line += 1 }
                    value.append(byte)
                    index += 1
                }
                if value.count > limits.maxFieldBytes {
                    throw error(.fieldTooLarge, "field is larger than \(limits.maxFieldBytes) bytes", at: fieldStart)
                }
            }
            return String(decoding: value, as: UTF8.self)
        }
        while index < bytes.count {
            let byte = bytes[index]
            if byte == delimiter || byte == lineFeed || byte == carriageReturn { break }
            if byte == quote {
                throw error(.quoteInUnquotedField, "quote inside an unquoted field; quote the whole field and write \"\" for a quote", at: index)
            }
            index += 1
        }
        if index - fieldStart > limits.maxFieldBytes {
            throw error(.fieldTooLarge, "field is larger than \(limits.maxFieldBytes) bytes", at: fieldStart)
        }
        return String(decoding: bytes[fieldStart..<index], as: UTF8.self)
    }
}
