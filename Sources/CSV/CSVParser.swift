// SPDX-License-Identifier: Apache-2.0

/// Parses RFC 4180 CSV into string fields.
///
/// - Fields are separated by the configured delimiter; records end with LF or CRLF. The
///   last record may end with or without a line break. A UTF-8 byte order mark is skipped.
/// - A field that starts with `"` is quoted: it may contain delimiters, quotes written as
///   `""`, and line breaks. A field that does not start with `"` must not contain one.
/// - Every value is a UTF-8 string. Nothing is trimmed, typed, padded or repaired.
/// - With a header (the default) names must be non-empty and unique, and every record
///   must have exactly as many fields as the header.
public struct CSVParser: Sendable {
    /// How the input is read.
    public var options: CSVOptions
    /// The limits applied to every call.
    public var limits: CSVLimits

    /// Creates a parser with the given options and limits.
    public init(options: CSVOptions = .default, limits: CSVLimits = .default) {
        self.options = options
        self.limits = limits
    }

    /// Parses UTF-8 bytes into a table.
    ///
    /// - Throws: ``CSVError`` with the code, line and column of the first problem.
    public func parse(_ bytes: [UInt8]) throws(CSVError) -> CSVTable {
        guard bytes.count <= limits.maxInputBytes else {
            throw CSVError(.inputTooLarge, "input is larger than \(limits.maxInputBytes) bytes", line: 1, column: 1)
        }
        if Task.isCancelled { throw CSVError(.cancelled, "parsing was cancelled", line: 1, column: 1) }
        let start = bytes.starts(with: [0xEF, 0xBB, 0xBF]) ? 3 : 0
        try validateUTF8(bytes, from: start)
        var scanner = Scanner(bytes: bytes, start: start, options: options, limits: limits)
        return try scanner.table()
    }

    /// Parses text into a table. See ``parse(_:)-([UInt8])`` for bytes.
    public func parse(_ text: String) throws(CSVError) -> CSVTable {
        try parse(Array(text.utf8))
    }
}
