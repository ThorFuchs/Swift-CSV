// SPDX-License-Identifier: Apache-2.0
import CSV
import CSVJSON
import JSON
import Testing

/// One minimal reproducer per error code. Adding a `CSVError.Code` case without a
/// reproducer here fails the test run, not just a review checklist.
struct ErrorCodeCoverageTests {
    static func reproduce(_ code: CSVError.Code) async -> CSVError? {
        func parse(_ bytes: [UInt8], _ options: CSVOptions = .default, _ limits: CSVLimits = .default) -> CSVError? {
            do { _ = try CSVParser(options: options, limits: limits).parse(bytes); return nil } catch { return error }
        }
        func parse(_ text: String, _ options: CSVOptions = .default, _ limits: CSVLimits = .default) -> CSVError? {
            parse(Array(text.utf8), options, limits)
        }
        switch code {
        case .invalidEncoding: return parse([0x61, 0xFF])
        case .quoteInUnquotedField: return parse("a\"b\n")
        case .unterminatedQuotedField: return parse("\"a\n")
        case .unexpectedCharacterAfterQuote: return parse("\"a\"b\n")
        case .bareCarriageReturn: return parse("a\rb\n")
        case .missingHeader: return parse("")
        case .emptyHeaderName: return parse("a,,c\n")
        case .duplicateHeaderName: return parse("a,a\n")
        case .fieldCountMismatch: return parse("a,b\n1\n")
        case .inputTooLarge: return parse("a\n", .default, CSVLimits(maxInputBytes: 1))
        case .tooManyRecords: return parse("a\n1\n2\n", .default, CSVLimits(maxRecords: 1))
        case .tooManyFields: return parse("a,b\n", .default, CSVLimits(maxFieldsPerRecord: 1))
        case .fieldTooLarge: return parse("abc\n", .default, CSVLimits(maxFieldBytes: 2))
        case .cancelled:
            return await Task {
                withUnsafeCurrentTask { $0?.cancel() }
                return parse("a\n1\n")
            }.value
        case .jsonLimitExceeded:
            var limits = JSONLimits.offline
            limits[.objectMembers] = 1
            do {
                _ = try CSVParser().parse("a,b\n1,2\n").jsonObjects(limits: limits)
                return nil
            } catch {
                return error
            }
        }
    }

    @Test("every error code has a minimal input that produces exactly that code", arguments: CSVError.Code.allCases)
    func everyCodeIsReproducible(_ code: CSVError.Code) async throws {
        let error = try #require(await Self.reproduce(code), "no error for \(code)")
        #expect(error.code == code)
        #expect(error.line >= 1 && error.column >= 1)
        #expect(!error.message.isEmpty)
        #expect(!error.message.contains("/Users/") && !error.message.contains("/home/"))
    }
}
