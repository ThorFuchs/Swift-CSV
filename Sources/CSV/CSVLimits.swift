// SPDX-License-Identifier: Apache-2.0

/// Explicit resource ceilings. Exceeding any of them fails the parse; nothing is truncated.
public struct CSVLimits: Sendable, Equatable {
    /// Maximum input size in bytes, including a byte order mark.
    public var maxInputBytes: Int
    /// Maximum number of data records. The header record does not count.
    public var maxRecords: Int
    /// Maximum number of fields in any record, including the header.
    public var maxFieldsPerRecord: Int
    /// Maximum size of one field's value in UTF-8 bytes, after `""` unescaping.
    public var maxFieldBytes: Int

    /// Creates limits; every value must be positive.
    public init(
        maxInputBytes: Int = 8 * 1024 * 1024,
        maxRecords: Int = 1_000_000,
        maxFieldsPerRecord: Int = 1_024,
        maxFieldBytes: Int = 1024 * 1024
    ) {
        self.maxInputBytes = maxInputBytes
        self.maxRecords = maxRecords
        self.maxFieldsPerRecord = maxFieldsPerRecord
        self.maxFieldBytes = maxFieldBytes
    }

    /// 8 MiB input, 1,000,000 records, 1,024 fields per record, 1 MiB per field.
    public static let `default` = CSVLimits()
}
