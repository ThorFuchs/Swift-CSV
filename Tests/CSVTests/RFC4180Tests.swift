// SPDX-License-Identifier: Apache-2.0
import CSV
import Testing

/// The rules of RFC 4180 section 2, one test per rule, using the RFC's own examples.
struct RFC4180Tests {
    @Test("2.1: each record is on its own line, delimited by CRLF")
    func crlfRecords() throws {
        #expect(try rows("aaa,bbb,ccc\r\nzzz,yyy,xxx\r\n") == [["aaa", "bbb", "ccc"], ["zzz", "yyy", "xxx"]])
    }

    @Test("2.2: the last record may or may not end with a line break")
    func optionalFinalLineBreak() throws {
        #expect(try rows("aaa,bbb,ccc\r\nzzz,yyy,xxx") == [["aaa", "bbb", "ccc"], ["zzz", "yyy", "xxx"]])
        #expect(try rows("aaa,bbb,ccc\r\nzzz,yyy,xxx\r\n") == rows("aaa,bbb,ccc\r\nzzz,yyy,xxx"))
    }

    @Test("2.3: an optional header line has the same format as records")
    func headerLine() throws {
        let table = try csv("field_name,field_name2,field_name3\r\naaa,bbb,ccc\r\nzzz,yyy,xxx\r\n")
        #expect(table.header == ["field_name", "field_name2", "field_name3"])
        #expect(table.records.map(\.fields) == [["aaa", "bbb", "ccc"], ["zzz", "yyy", "xxx"]])
    }

    @Test("2.4: spaces are part of a field and are not trimmed; no trailing comma means no extra field")
    func spacesArePartOfField() throws {
        #expect(try rows(" aaa , bbb ,ccc ") == [[" aaa ", " bbb ", "ccc "]])
        #expect(try rows("aaa,bbb,ccc") == [["aaa", "bbb", "ccc"]])
    }

    @Test("2.4: a trailing delimiter adds an empty last field")
    func trailingDelimiter() throws {
        #expect(try rows("a,b,\n") == [["a", "b", ""]])
    }

    @Test("2.5: fields may be enclosed in double quotes")
    func quotedFields() throws {
        #expect(try rows("\"aaa\",\"bbb\",\"ccc\"\r\nzzz,yyy,xxx") == [["aaa", "bbb", "ccc"], ["zzz", "yyy", "xxx"]])
    }

    @Test("2.6: quoted fields may contain line breaks, quotes and commas")
    func quotedSpecialCharacters() throws {
        #expect(try rows("\"aaa\",\"b\r\nbb\",\"ccc\"\r\nzzz,yyy,xxx") == [["aaa", "b\r\nbb", "ccc"], ["zzz", "yyy", "xxx"]])
        #expect(try rows("\"a,b\",c") == [["a,b", "c"]])
    }

    @Test("2.7: a quote inside a quoted field is written as two quotes")
    func escapedQuotes() throws {
        #expect(try rows("\"aaa\",\"b\"\"bb\",\"ccc\"") == [["aaa", "b\"bb", "ccc"]])
        #expect(try rows("\"\"\"\"") == [["\""]])
        #expect(try rows("\"\"\"quoted\"\"\"") == [["\"quoted\""]])
    }

    @Test("2.7: a quote inside an unquoted field is an error, not repaired")
    func strayQuoteIsAnError() {
        #expect(csvError("aaa,b\"bb,ccc", headerless)?.code == .quoteInUnquotedField)
    }
}
