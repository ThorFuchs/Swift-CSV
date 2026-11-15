// SPDX-License-Identifier: Apache-2.0

/// One data record: its fields in source order and the line where it starts.
public struct CSVRecord: Sendable, Equatable {
    /// The field values, exactly as written after `""` unescaping. Always UTF-8 strings;
    /// no types are guessed, no whitespace is trimmed and line breaks inside quoted fields
    /// are kept byte for byte (`\n` or `\r\n`).
    public var fields: [String]
    /// The 1-based line on which the record starts.
    public var line: Int

    /// Creates a record.
    public init(fields: [String], line: Int) {
        self.fields = fields
        self.line = line
    }
}

/// A parsed CSV file.
public struct CSVTable: Sendable, Equatable {
    /// The column names with ``CSVHeaderMode/required``, in source order; `nil` with
    /// ``CSVHeaderMode/absent``. Names are non-empty and unique.
    public var header: [String]?
    /// The data records in source order. With a header, every record has exactly
    /// `header.count` fields; without one, every record has as many fields as the first.
    public var records: [CSVRecord]

    /// Creates a table.
    public init(header: [String]?, records: [CSVRecord]) {
        self.header = header
        self.records = records
    }
}
