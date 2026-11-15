// SPDX-License-Identifier: Apache-2.0

/// A CSV failure with a stable code and the 1-based source position where it was detected.
///
/// Messages never contain file paths; callers add their own context.
public struct CSVError: Error, Sendable, Equatable, CustomStringConvertible {
    /// What went wrong. New cases may be added in minor releases; switch with `default`.
    public enum Code: String, Sendable, Equatable, CaseIterable {
        /// The input is not valid UTF-8.
        case invalidEncoding
        /// A `"` appears inside a field that does not start with a quote, such as `a"b`.
        case quoteInUnquotedField
        /// A quoted field is still open at the end of the input.
        case unterminatedQuotedField
        /// A closing quote is followed by something other than a delimiter, a line break or
        /// the end of the input, such as `"a"b`.
        case unexpectedCharacterAfterQuote
        /// A carriage return outside a quoted field is not followed by a line feed.
        case bareCarriageReturn
        /// Header mode is `.required` but the input has no records at all.
        case missingHeader
        /// A header name is the empty string.
        case emptyHeaderName
        /// Two header names are equal.
        case duplicateHeaderName
        /// A record has a different number of fields than the header (or, without a header,
        /// than the first record).
        case fieldCountMismatch
        /// The input is larger than ``CSVLimits/maxInputBytes``.
        case inputTooLarge
        /// The input has more data records than ``CSVLimits/maxRecords``.
        case tooManyRecords
        /// A record has more fields than ``CSVLimits/maxFieldsPerRecord``.
        case tooManyFields
        /// A field's decoded value is longer than ``CSVLimits/maxFieldBytes``.
        case fieldTooLarge
        /// The surrounding task was cancelled.
        case cancelled
        /// Swift-JSON refused to build an object under the `JSONLimits` passed to the
        /// `CSVJSON` conversion. The core parser never throws this code.
        case jsonLimitExceeded
    }

    /// The failure category.
    public let code: Code
    /// A short human-readable explanation.
    public let message: String
    /// The 1-based line of the failure.
    public let line: Int
    /// The 1-based column of the failure, counted in Unicode scalars.
    public let column: Int

    /// Creates an error value.
    public init(_ code: Code, _ message: String, line: Int, column: Int) {
        self.code = code
        self.message = message
        self.line = line
        self.column = column
    }

    /// `line:column: message`.
    public var description: String { "\(line):\(column): \(message)" }

    /// The same error moved down by `lines`, used when CSV is embedded in a larger file.
    public func shifted(byLines lines: Int) -> CSVError {
        CSVError(code, message, line: line + lines, column: column)
    }
}
