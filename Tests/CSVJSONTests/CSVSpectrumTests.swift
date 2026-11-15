// SPDX-License-Identifier: Apache-2.0
import CSV
import CSVJSON
import Foundation
import JSON
import Testing

/// Runs the vendored csv-spectrum corpus (v2.0.0) through the parser and the JSON conversion.
///
/// Each `csvs/NAME.csv` must convert, with `emptyCell: .emptyString`, to `json/NAME.json`.
/// Cases rejected on purpose are listed in `deliberateRejections` with the expected code and
/// in the README; anything else fails.
struct CSVSpectrumTests {
    /// `location_coordinates` has unquoted fields containing `"` (and U+FFFD), which RFC 4180
    /// does not allow; its expected JSON is also a bare object rather than an array.
    static let deliberateRejections: [String: CSVError.Code] = [
        "location_coordinates": .quoteInUnquotedField,
    ]

    static func directory() throws -> URL {
        let fixtures = try #require(Bundle.module.url(forResource: "Fixtures", withExtension: nil))
        return fixtures.appendingPathComponent("csv-spectrum")
    }

    static func caseNames() throws -> [String] {
        try FileManager.default.contentsOfDirectory(atPath: directory().appendingPathComponent("csvs").path)
            .filter { $0.hasSuffix(".csv") }
            .map { String($0.dropLast(4)) }
            .sorted()
    }

    @Test("the corpus has all 12 cases")
    func corpusIsComplete() throws {
        #expect(try Self.caseNames().count == 12)
    }

    @Test("every csv-spectrum case matches its JSON or is a documented rejection", arguments: try caseNames())
    func spectrumCase(_ name: String) throws {
        let dir = try Self.directory()
        let csv = try [UInt8](Data(contentsOf: dir.appendingPathComponent("csvs/\(name).csv")))
        if let expectedCode = Self.deliberateRejections[name] {
            #expect(throws: CSVError.self) { try CSVParser().parse(csv) }
            do { _ = try CSVParser().parse(csv) } catch { #expect(error.code == expectedCode) }
            return
        }
        let expected = try JSON.parse([UInt8](Data(contentsOf: dir.appendingPathComponent("json/\(name).json"))))
        let actual = JSON.array(try CSVParser().parseObjects(csv, emptyCell: .emptyString).map(JSON.object))
        #expect(actual == expected)
    }
}
