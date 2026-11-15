// SPDX-License-Identifier: Apache-2.0
import CSV
import Testing

struct LineBreakTests {
    @Test("LF and CRLF record terminators are both accepted and may be mixed")
    func lfAndCRLF() throws {
        #expect(try rows("a,b\n1,2\n") == [["a", "b"], ["1", "2"]])
        #expect(try rows("a,b\r\n1,2\n3,4\r\n") == [["a", "b"], ["1", "2"], ["3", "4"]])
    }

    @Test("line breaks inside quoted fields are kept byte for byte, not normalized")
    func quotedLineBreaksAreExact() throws {
        #expect(try rows("\"x\ny\",\"x\r\ny\",\"x\ry\"") == [["x\ny", "x\r\ny", "x\ry"]])
    }

    @Test("a blank line in the middle is a record with one empty field")
    func blankLineIsARecord() throws {
        #expect(try rows("a\n\nb\n") == [["a"], [""], ["b"]])
    }

    @Test("a single trailing line break does not create a record; a second one does")
    func trailingLineBreaks() throws {
        #expect(try rows("a\n") == [["a"]])
        #expect(try rows("a\n\n") == [["a"], [""]])
        #expect(try rows("a\r\n\r\n") == [["a"], [""]])
    }

    @Test("a blank line in a multi-column file is a field-count error that says it is blank")
    func blankLineInWideFile() throws {
        let error = try #require(csvError("a,b\n1,2\n\n"))
        #expect(error.code == .fieldCountMismatch)
        #expect(error.line == 3 && error.column == 1)
        #expect(error.message.contains("blank line"))
    }
}

struct EncodingTests {
    @Test("a UTF-8 byte order mark is skipped and does not reach the first header name")
    func byteOrderMark() throws {
        let table = try CSVParser().parse([0xEF, 0xBB, 0xBF] + Array("id,name\n1,x\n".utf8))
        #expect(table.header == ["id", "name"])
        #expect(table.records == [CSVRecord(fields: ["1", "x"], line: 2)])
    }

    @Test("a byte order mark alone is an empty input")
    func byteOrderMarkOnly() throws {
        #expect(try CSVParser(options: headerless).parse([0xEF, 0xBB, 0xBF]).records.isEmpty)
        #expect(csvError([0xEF, 0xBB, 0xBF])?.code == .missingHeader)
    }

    @Test("a second byte order mark is ordinary text")
    func secondByteOrderMark() throws {
        #expect(try CSVParser(options: headerless).parse([0xEF, 0xBB, 0xBF, 0xEF, 0xBB, 0xBF, 0x61]).records[0].fields == ["\u{FEFF}a"])
    }

    @Test("non-ASCII text, combining marks and emoji are kept exactly")
    func unicodeText() throws {
        #expect(try rows("Zürich,\"日本, 東京\",e\u{301},👩‍👩‍👧") == [["Zürich", "日本, 東京", "e\u{301}", "👩‍👩‍👧"]])
    }

    @Test("control characters and NUL in fields are kept, not stripped")
    func controlCharacters() throws {
        #expect(try rows("a\u{0}b,\u{7}") == [["a\u{0}b", "\u{7}"]])
    }

    @Test("invalid UTF-8 is rejected with the position of the bad byte",
          arguments: [
              ([0x61, 0x2C, 0xFF] as [UInt8], 1, 3),            // invalid byte
              ([0x61, 0x0A, 0x62, 0xC3, 0x28], 2, 2),             // bad continuation
              ([0xC0, 0xAF], 1, 1),                               // overlong
              ([0xED, 0xA0, 0x80], 1, 1),                         // surrogate
              ([0xF4, 0x90, 0x80, 0x80], 1, 1),                   // above U+10FFFF
              ([0xC3, 0xA9, 0xE2, 0x82], 1, 2),                   // truncated at end
              ([0x22, 0x0A, 0x80, 0x22], 2, 1),                   // inside a quoted field
          ])
    func invalidUTF8(bytes: [UInt8], line: Int, column: Int) throws {
        let error = try #require(csvError(bytes, headerless))
        #expect(error.code == .invalidEncoding)
        #expect(error.line == line && error.column == column)
    }

    @Test("UTF-16 input is invalid UTF-8, not guessed")
    func utf16IsRejected() {
        #expect(csvError([0xFF, 0xFE, 0x61, 0x00])?.code == .invalidEncoding)
    }
}

struct DelimiterTests {
    @Test("semicolon, tab and pipe delimiters split fields; commas are then ordinary text")
    func alternativeDelimiters() throws {
        #expect(try rows("a;b,c;\"d;e\"", delimiter: .semicolon) == [["a", "b,c", "d;e"]])
        #expect(try rows("a\tb,c\t\"d\te\"\n", delimiter: .tab) == [["a", "b,c", "d\te"]])
        #expect(try rows("a|b|", delimiter: .pipe) == [["a", "b", ""]])
    }

    @Test("the default delimiter is a comma, so a semicolon file is one column")
    func defaultDelimiter() throws {
        #expect(try rows("a;b\n1;2") == [["a;b"], ["1;2"]])
    }

    @Test("each delimiter has its documented character", arguments: CSVDelimiter.allCases)
    func delimiterCharacters(_ delimiter: CSVDelimiter) throws {
        let text = ["x", "y"].joined(separator: delimiter.rawValue)
        #expect(try rows(text, delimiter: delimiter) == [["x", "y"]])
    }
}

struct ValueTests {
    @Test("cells are always strings: numbers, booleans, dates and null-like text are not typed")
    func noTypeGuessing() throws {
        #expect(try rows("007,1.50,1e3,true,FALSE,null,NULL,2026-11-15,-0,NaN,") ==
                [["007", "1.50", "1e3", "true", "FALSE", "null", "NULL", "2026-11-15", "-0", "NaN", ""]])
    }

    @Test("an empty quoted field and an empty unquoted field are both the empty string")
    func emptyFields() throws {
        #expect(try rows("\"\",,\"\"") == [["", "", ""]])
    }

    @Test("a single empty quoted field is a record with one empty field")
    func onlyEmptyQuotedField() throws {
        #expect(try rows("\"\"\n") == [[""]])
    }

    @Test("leading and trailing whitespace around quoted content stays inside the quotes")
    func whitespaceInQuotes() throws {
        #expect(try rows("\"  a  \",\"\t\"") == [["  a  ", "\t"]])
    }
}

struct HeaderTests {
    @Test("the header is required by default and names the columns in source order")
    func headerRequiredByDefault() throws {
        let table = try csv("sku,name,price\nA-1,Pen,1.50\nB-2,Ink,4\n")
        #expect(table.header == ["sku", "name", "price"])
        #expect(table.records == [
            CSVRecord(fields: ["A-1", "Pen", "1.50"], line: 2),
            CSVRecord(fields: ["B-2", "Ink", "4"], line: 3),
        ])
    }

    @Test("a header without records is a valid, empty table")
    func headerOnly() throws {
        #expect(try csv("a,b") == CSVTable(header: ["a", "b"], records: []))
        #expect(try csv("a,b\r\n") == CSVTable(header: ["a", "b"], records: []))
    }

    @Test("header names may be quoted and keep their whitespace and case")
    func quotedHeaderNames() throws {
        #expect(try csv("\"a,b\",\" c \",C,c\n1,2,3,4").header == ["a,b", " c ", "C", "c"])
    }

    @Test("an empty input has no header and is an error in header mode")
    func emptyInputNeedsHeader() throws {
        let error = try #require(csvError(""))
        #expect(error.code == .missingHeader)
        #expect(error.line == 1 && error.column == 1)
    }

    @Test("an empty header name is an error at its position", arguments: ["a,,c\n", "a,b,\n", ",b\n", "a,\"\"\n", "\n"])
    func emptyHeaderName(_ text: String) {
        #expect(csvError(text)?.code == .emptyHeaderName)
    }

    @Test("an empty header name reports the column of the empty field")
    func emptyHeaderNamePosition() throws {
        let error = try #require(csvError("id,,name\n"))
        #expect(error.line == 1 && error.column == 4)
    }

    @Test("a duplicate header name is an error at the second occurrence")
    func duplicateHeaderName() throws {
        let error = try #require(csvError("id,name,id\n1,a,2\n"))
        #expect(error.code == .duplicateHeaderName)
        #expect(error.line == 1 && error.column == 9)
        #expect(error.message.contains("\"id\""))
    }

    @Test("header names that are canonically equivalent Unicode count as duplicates")
    func canonicallyEquivalentHeaderNames() {
        #expect(csvError("caf\u{E9},cafe\u{301}\n")?.code == .duplicateHeaderName)
    }

    @Test("a quoted and an unquoted spelling of the same name are duplicates")
    func quotedDuplicate() {
        #expect(csvError("a,\"a\"\n")?.code == .duplicateHeaderName)
    }

    @Test("a record with fewer fields than the header is an error, not padded")
    func shortRecord() throws {
        let error = try #require(csvError("a,b,c\n1,2\n"))
        #expect(error.code == .fieldCountMismatch)
        #expect(error.line == 2 && error.column == 4)
        #expect(error.message.contains("2 fields") && error.message.contains("header has 3"))
    }

    @Test("a record with more fields than the header is an error at the first extra field")
    func longRecord() throws {
        let error = try #require(csvError("a,b\n1,2\n3,4,5\n"))
        #expect(error.code == .fieldCountMismatch)
        #expect(error.line == 3 && error.column == 5)
    }
}

struct HeaderlessTests {
    @Test("without a header every record is data and the header is nil")
    func rowsOnly() throws {
        let table = try csv("a,b\n1,2\n", headerless)
        #expect(table.header == nil)
        #expect(table.records.map(\.fields) == [["a", "b"], ["1", "2"]])
    }

    @Test("without a header, duplicate and empty values in the first record are fine")
    func firstRecordIsNotChecked() throws {
        #expect(try rows("a,a,\n1,2,3") == [["a", "a", ""], ["1", "2", "3"]])
    }

    @Test("without a header every record must match the first record's field count")
    func raggedWithoutHeader() throws {
        let error = try #require(csvError("a,b\n1\n", headerless))
        #expect(error.code == .fieldCountMismatch)
        #expect(error.message.contains("first record has 2"))
    }

    @Test("an empty input without a header is an empty table")
    func emptyInput() throws {
        #expect(try csv("", headerless) == CSVTable(header: nil, records: []))
    }
}

struct LineNumberTests {
    @Test("each record reports the 1-based line it starts on, counting quoted line breaks")
    func recordLines() throws {
        let table = try csv("a,b\n1,\"x\ny\nz\"\n2,3\r\n\"4\r\n\",5")
        #expect(table.records.map(\.line) == [2, 5, 6])
    }

    @Test("error lines after multi-line quoted fields are physical lines")
    func errorLineAfterQuotedBreaks() throws {
        let error = try #require(csvError("a,b\n\"1\n2\",x\nbad\"quote,y\n"))
        #expect(error.code == .quoteInUnquotedField)
        #expect(error.line == 4 && error.column == 4)
    }

    @Test("error columns count Unicode scalars, not bytes")
    func columnsCountScalars() throws {
        let error = try #require(csvError("äöü,x\"", headerless))
        #expect(error.line == 1 && error.column == 6)
    }

    @Test("shifted(byLines:) moves an error down for embedded CSV")
    func shifted() throws {
        let error = try #require(csvError("a\n\"x"))
        #expect(error.shifted(byLines: 10).line == error.line + 10)
        #expect(error.description == "2:1: \(error.message)")
    }
}

struct SyntaxErrorTests {
    @Test("a quote inside an unquoted field is reported at the quote",
          arguments: [("a\"b", 1, 2), ("x, \"y\"", 1, 4), ("x\ny\"", 2, 2)])
    func quoteInUnquoted(text: String, line: Int, column: Int) throws {
        let error = try #require(csvError(text, headerless))
        #expect(error.code == .quoteInUnquotedField)
        #expect(error.line == line && error.column == column)
    }

    @Test("an unterminated quoted field is reported at its opening quote",
          arguments: [("\"abc", 1, 1), ("a,\"b\nc\n", 1, 3), ("a\n\"x\"\"", 2, 1)])
    func unterminated(text: String, line: Int, column: Int) throws {
        let error = try #require(csvError(text, headerless))
        #expect(error.code == .unterminatedQuotedField)
        #expect(error.line == line && error.column == column)
    }

    @Test("characters after a closing quote are reported at the first such character",
          arguments: [("\"a\"b", 1, 4), ("\"a\" ,b", 1, 4), ("x\n\"a\"\"\"c", 2, 6)])
    func afterClosingQuote(text: String, line: Int, column: Int) throws {
        let error = try #require(csvError(text, headerless))
        #expect(error.code == .unexpectedCharacterAfterQuote)
        #expect(error.line == line && error.column == column)
    }

    @Test("a carriage return without a line feed outside quotes is an error",
          arguments: [("a\rb", 1, 2), ("a,b\r", 1, 4), ("\"a\"\r1", 1, 4), ("x\ny\r\r\n", 2, 2)])
    func bareCarriageReturn(text: String, line: Int, column: Int) throws {
        let error = try #require(csvError(text, headerless))
        #expect(error.code == .bareCarriageReturn)
        #expect(error.line == line && error.column == column)
    }

    @Test("a quote that only looks escaped at the end of the input is unterminated")
    func escapedQuoteAtEnd() {
        #expect(csvError("\"a\"\"", headerless)?.code == .unterminatedQuotedField)
    }
}
