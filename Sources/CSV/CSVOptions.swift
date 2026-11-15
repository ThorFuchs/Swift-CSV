// SPDX-License-Identifier: Apache-2.0

/// The character that separates fields within a record.
public enum CSVDelimiter: String, Sendable, Equatable, CaseIterable {
    /// `,` (U+002C), the RFC 4180 delimiter.
    case comma = ","
    /// `;` (U+003B), common in locales that use a decimal comma.
    case semicolon = ";"
    /// Horizontal tab (U+0009), for tab-separated values.
    case tab = "\t"
    /// `|` (U+007C).
    case pipe = "|"

    var byte: UInt8 {
        switch self {
        case .comma: 0x2C
        case .semicolon: 0x3B
        case .tab: 0x09
        case .pipe: 0x7C
        }
    }
}

/// Whether the first record names the columns.
public enum CSVHeaderMode: Sendable, Equatable, CaseIterable {
    /// The first record is the header. It must exist, its names must be non-empty and
    /// unique, and every data record must have exactly as many fields.
    case required
    /// There is no header. Every record is data and must have as many fields as the first.
    case absent
}

/// How the input is read.
public struct CSVOptions: Sendable, Equatable {
    /// The field delimiter. Default: ``CSVDelimiter/comma``.
    public var delimiter: CSVDelimiter
    /// Whether the first record is a header. Default: ``CSVHeaderMode/required``.
    public var header: CSVHeaderMode

    /// Creates options.
    public init(delimiter: CSVDelimiter = .comma, header: CSVHeaderMode = .required) {
        self.delimiter = delimiter
        self.header = header
    }

    /// Comma-delimited with a required header.
    public static let `default` = CSVOptions()
}
