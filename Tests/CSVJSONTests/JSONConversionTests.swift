// SPDX-License-Identifier: Apache-2.0
import CSV
import CSVJSON
import JSON
import Testing

func objects(_ text: String, emptyCell: CSVEmptyCell = .missing, options: CSVOptions = .default) throws -> JSON {
    .array(try CSVParser(options: options).parseObjects(text, emptyCell: emptyCell).map(JSON.object))
}

func json(_ text: String) throws -> JSON {
    try JSON.parse(text)
}

struct JSONConversionTests {
    @Test("records become objects of strings keyed by the header, in header order")
    func objectsOfStrings() throws {
        let result = try objects("sku,name,price,active\nA-1,Pen,1.50,true\n")
        #expect(result == (try json(#"[{"sku":"A-1","name":"Pen","price":"1.50","active":"true"}]"#)))
        let members = try #require(result.arrayValue?.first?.objectValue).members
        #expect(members.map(\.key.string) == ["sku", "name", "price", "active"])
    }

    @Test("an empty cell is omitted by default, so the property is missing")
    func emptyCellMissing() throws {
        let result = try objects("a,b,c\n1,,\"\"\n")
        #expect(result == (try json(#"[{"a":"1"}]"#)))
        #expect(result.arrayValue?.first?.objectValue?["b"] == nil)
    }

    @Test("an empty cell becomes null with .null")
    func emptyCellNull() throws {
        #expect(try objects("a,b,c\n1,,\"\"\n", emptyCell: .null) == (try json(#"[{"a":"1","b":null,"c":null}]"#)))
    }

    @Test("an empty cell stays an empty string with .emptyString")
    func emptyCellEmptyString() throws {
        #expect(try objects("a,b\n,x\n", emptyCell: .emptyString) == (try json(#"[{"a":"","b":"x"}]"#)))
    }

    @Test("missing, null and empty string stay distinct across the three policies")
    func policiesAreDistinct() throws {
        let results = try CSVEmptyCell.allCases.map { try objects("a\n\"\"\n", emptyCell: $0) }
        #expect(Set(results).count == 3)
    }

    @Test("a record whose cells are all empty becomes an empty object with .missing")
    func allEmptyRecord() throws {
        #expect(try objects("a,b\n,\n") == (try json("[{}]")))
    }

    @Test("values that look like numbers, booleans or null stay strings")
    func noTyping() throws {
        #expect(try objects("n,b,z\n42,false,null\n") == (try json(#"[{"n":"42","b":"false","z":"null"}]"#)))
    }

    @Test("a header-only file converts to no objects")
    func headerOnly() throws {
        #expect(try objects("a,b\n") == .array([]))
    }

    @Test("object i belongs to record i, whose line locates it in the source")
    func objectsAlignWithRecords() throws {
        let table = try CSVParser().parse("id,text\n1,\"multi\nline\"\n2,x\n")
        let converted = try table.jsonObjects()
        #expect(converted.count == table.records.count)
        #expect(table.records.map(\.line) == [2, 4])
        #expect(converted[1]["id"] == .string("2"))
    }

    @Test("converting a headerless table is an error, not invented keys")
    func headerlessIsAnError() throws {
        let table = try CSVParser(options: CSVOptions(header: .absent)).parse("1,2\n")
        #expect(throws: CSVError.self) { try table.jsonObjects() }
        do {
            _ = try table.jsonObjects()
        } catch {
            #expect(error.code == .missingHeader)
        }
    }

    @Test("parse errors pass through parseObjects unchanged")
    func parseErrorsPassThrough() {
        do {
            _ = try CSVParser().parseObjects("a,b\n1\n")
            Issue.record("expected an error")
        } catch {
            #expect(error.code == .fieldCountMismatch)
            #expect(error.line == 2)
        }
    }

    @Test("explicit JSON limits that are too small fail with jsonLimitExceeded on the record's line")
    func explicitLimits() throws {
        var limits = JSONLimits.offline
        limits[.stringBytes] = 3
        let table = try CSVParser().parse("a\nabc\nabcd\n")
        do {
            _ = try table.jsonObjects(limits: limits)
            Issue.record("expected an error")
        } catch {
            #expect(error.code == .jsonLimitExceeded)
            #expect(error.line == 3)
        }
    }

    @Test("the default JSON limits fit wide, long records the parser accepts")
    func defaultLimitsFit() throws {
        let width = 1_024
        let header = (0..<width).map { "column\($0)" }.joined(separator: ",")
        let row = (0..<width).map { _ in String(repeating: "x", count: 600) }.joined(separator: ",")
        let big = String(repeating: "y", count: 1024 * 1024)
        let text = header + "\n" + row + "\n" + big + String(repeating: ",", count: width - 1) + "\n"
        let result = try CSVParser().parseObjects(text)
        #expect(result.count == 2)
        #expect(result[0].count == width)
        #expect(result[1].count == 1)
    }

    @Test("a cancelled task stops the conversion with cancelled")
    func cancellation() async throws {
        let table = try CSVParser().parse("a\n1\n")
        let code = await Task { () -> CSVError.Code? in
            withUnsafeCurrentTask { $0?.cancel() }
            do throws(CSVError) { _ = try table.jsonObjects(); return nil } catch { return error.code }
        }.value
        #expect(code == .cancelled)
    }
}
