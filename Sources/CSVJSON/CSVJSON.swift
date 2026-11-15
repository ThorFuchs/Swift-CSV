// SPDX-License-Identifier: Apache-2.0
import CSV
import JSON

/// What an empty cell becomes when a record is converted to a JSON object.
///
/// A cell is empty when its value is the empty string, whether it was written as nothing
/// (`a,,b`) or as `""`. CSV itself does not distinguish the two.
public enum CSVEmptyCell: String, Sendable, Equatable, CaseIterable {
    /// The key is left out of the object, so the property is missing. The default.
    case missing
    /// The key is present with the value `null`.
    case null
    /// The key is present with the value `""`.
    case emptyString
}

extension CSVTable {
    /// Converts every record to a JSON object of strings, keyed by the header.
    ///
    /// Members follow header order. Every value is a `.string`, or `.null` for an empty cell
    /// with ``CSVEmptyCell/null``. No other types are produced. The object at index `i`
    /// belongs to `records[i]`, whose ``CSVRecord/line`` locates it in the source.
    ///
    /// - Parameters:
    ///   - emptyCell: What an empty cell becomes. Default: ``CSVEmptyCell/missing``.
    ///   - limits: Swift-JSON limits for building each object. `nil` (the default) uses
    ///     `JSONLimits.offline`, raised where needed so that any table the parser accepts
    ///     converts.
    /// - Throws: ``CSVError`` with ``CSVError/Code-swift.enum/missingHeader`` for a table
    ///   without a header, ``CSVError/Code-swift.enum/jsonLimitExceeded`` when explicit
    ///   `limits` are too small, or ``CSVError/Code-swift.enum/cancelled``.
    public func jsonObjects(emptyCell: CSVEmptyCell = .missing, limits: JSONLimits? = nil) throws(CSVError) -> [JSONObject] {
        guard let header else {
            throw CSVError(.missingHeader, "converting records to objects needs a header", line: 1, column: 1)
        }
        let jsonLimits = limits ?? fittingLimits(header: header)
        let keys = header.map { JSONKey($0) }
        var objects: [JSONObject] = []
        objects.reserveCapacity(records.count)
        for (position, record) in records.enumerated() {
            if position % 1_024 == 0, Task.isCancelled {
                throw CSVError(.cancelled, "conversion was cancelled", line: record.line, column: 1)
            }
            var members: [JSONMember] = []
            members.reserveCapacity(keys.count)
            for (key, field) in zip(keys, record.fields) {
                if field.isEmpty {
                    switch emptyCell {
                    case .missing: continue
                    case .null: members.append(JSONMember(key, value: .null))
                    case .emptyString: members.append(JSONMember(key, value: .string("")))
                    }
                } else {
                    members.append(JSONMember(key, value: .string(field)))
                }
            }
            do {
                objects.append(try JSONObject(members: members, limits: jsonLimits))
            } catch {
                if Task.isCancelled {
                    throw CSVError(.cancelled, "conversion was cancelled", line: record.line, column: 1)
                }
                throw CSVError(.jsonLimitExceeded, "Swift-JSON rejected the object for this record: \(error)", line: record.line, column: 1)
            }
        }
        return objects
    }

    /// `JSONLimits.offline`, raised to fit the largest key, value and member count here.
    private func fittingLimits(header: [String]) -> JSONLimits {
        var keyBytes = 0
        for name in header { keyBytes = max(keyBytes, name.utf8.count) }
        var valueBytes = 0
        var recordBytes = 0
        for record in records {
            var total = 0
            for field in record.fields {
                valueBytes = max(valueBytes, field.utf8.count)
                total += field.utf8.count
            }
            recordBytes = max(recordBytes, total)
        }
        let textBytes = UInt64(recordBytes + header.count * keyBytes)
        var limits = JSONLimits.offline
        func raise(_ metric: JSONResourceMetric, to value: UInt64) {
            limits[metric] = max(limits[metric], value)
        }
        raise(.objectMembers, to: UInt64(header.count))
        raise(.nodes, to: UInt64(header.count) + 1)
        raise(.keyBytes, to: UInt64(keyBytes))
        raise(.stringBytes, to: UInt64(valueBytes))
        raise(.aggregateTextBytes, to: textBytes)
        // Generous headroom for Swift-JSON's per-member bookkeeping and work accounting.
        raise(.retainedBytes, to: textBytes * 4 + UInt64(header.count) * 256)
        raise(.workUnits, to: textBytes * 8 + UInt64(header.count) * 64)
        return limits
    }
}

extension CSVParser {
    /// Parses UTF-8 bytes and converts every record to a JSON object of strings.
    ///
    /// Equivalent to `parse(bytes).jsonObjects(emptyCell:)`. Requires
    /// ``CSVHeaderMode/required``; with ``CSVHeaderMode/absent`` it throws
    /// ``CSVError/Code-swift.enum/missingHeader``.
    public func parseObjects(_ bytes: [UInt8], emptyCell: CSVEmptyCell = .missing) throws(CSVError) -> [JSONObject] {
        try parse(bytes).jsonObjects(emptyCell: emptyCell)
    }

    /// Parses text and converts every record to a JSON object of strings.
    public func parseObjects(_ text: String, emptyCell: CSVEmptyCell = .missing) throws(CSVError) -> [JSONObject] {
        try parseObjects(Array(text.utf8), emptyCell: emptyCell)
    }
}
