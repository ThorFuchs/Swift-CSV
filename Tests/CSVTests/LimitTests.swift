// SPDX-License-Identifier: Apache-2.0
import CSV
import Testing

struct LimitTests {
    @Test("input size is checked in bytes, including the byte order mark")
    func inputBytes() throws {
        let limits = CSVLimits(maxInputBytes: 6)
        #expect(try CSVParser(limits: limits).parse("ab\n12\n").records.count == 1)
        #expect(try CSVParser(options: headerless, limits: limits).parse([0xEF, 0xBB, 0xBF, 0x61, 0x0A, 0x62]).records.count == 2)
        let error = try #require(csvError([0xEF, 0xBB, 0xBF, 0x61, 0x0A, 0x62, 0x0A], headerless, limits: limits))
        #expect(error.code == .inputTooLarge)
        #expect(error.line == 1 && error.column == 1)
    }

    @Test("the record limit counts data records, not the header")
    func records() throws {
        let limits = CSVLimits(maxRecords: 2)
        #expect(try csv("h\n1\n2\n", limits: limits).records.count == 2)
        let error = try #require(csvError("h\n1\n2\n3\n", limits: limits))
        #expect(error.code == .tooManyRecords)
        #expect(error.line == 4 && error.column == 1)
        #expect(csvError("1\n2\n3\n", headerless, limits: limits)?.code == .tooManyRecords)
    }

    @Test("the field limit applies to every record, including the header")
    func fieldsPerRecord() throws {
        let limits = CSVLimits(maxFieldsPerRecord: 3)
        #expect(try csv("a,b,c\n1,2,3", limits: limits).records.count == 1)
        let error = try #require(csvError("a,b,c,d\n", limits: limits))
        #expect(error.code == .tooManyFields)
        #expect(error.line == 1 && error.column == 7)
        #expect(csvError("1,2,3\n1,2,3,4", headerless, limits: limits)?.code == .tooManyFields)
    }

    @Test("a trailing delimiter counts as a field for the field limit")
    func trailingDelimiterCounts() {
        #expect(csvError("a,b,c,", headerless, limits: CSVLimits(maxFieldsPerRecord: 3))?.code == .tooManyFields)
    }

    @Test("the field size limit applies to decoded bytes, so \"\" counts once")
    func fieldBytes() throws {
        let limits = CSVLimits(maxFieldBytes: 4)
        #expect(try rows4("abcd,\"ab\"\"c\",\"é\"\"\"", limits) == [["abcd", "ab\"c", "é\""]])
        for text in ["abcde", "\"abcde\"", "x,\"a\"\"\"\"bc\"", "ééé"] {
            let error = try #require(csvError(text, headerless, limits: limits), "\(text)")
            #expect(error.code == .fieldTooLarge)
        }
        let error = try #require(csvError("ok,\"abc\ndef\"", headerless, limits: limits))
        #expect(error.line == 1 && error.column == 4)
    }

    @Test("a field that would only exceed the limit after the end of input still fails")
    func fieldBytesAtEnd() {
        #expect(csvError("12345", headerless, limits: CSVLimits(maxFieldBytes: 4))?.code == .fieldTooLarge)
    }

    @Test("a parse in a cancelled task stops with cancelled")
    func cancellationOnEntry() async {
        let error = await Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return csvError("a\n1\n")
        }.value
        #expect(error?.code == .cancelled)
    }

    @Test("default limits are the documented values")
    func defaults() {
        let limits = CSVLimits.default
        #expect(limits.maxInputBytes == 8 * 1024 * 1024)
        #expect(limits.maxRecords == 1_000_000)
        #expect(limits.maxFieldsPerRecord == 1_024)
        #expect(limits.maxFieldBytes == 1024 * 1024)
    }

    private func rows4(_ text: String, _ limits: CSVLimits) throws -> [[String]] {
        try CSVParser(options: headerless, limits: limits).parse(text).records.map(\.fields)
    }
}
