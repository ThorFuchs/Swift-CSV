// SPDX-License-Identifier: Apache-2.0
import CSV

func csv(_ text: String, _ options: CSVOptions = .default, limits: CSVLimits = .default) throws -> CSVTable {
    try CSVParser(options: options, limits: limits).parse(text)
}

func rows(_ text: String, delimiter: CSVDelimiter = .comma) throws -> [[String]] {
    try CSVParser(options: CSVOptions(delimiter: delimiter, header: .absent)).parse(text).records.map(\.fields)
}

func csvError(_ text: String, _ options: CSVOptions = .default, limits: CSVLimits = .default) -> CSVError? {
    csvError(Array(text.utf8), options, limits: limits)
}

func csvError(_ bytes: [UInt8], _ options: CSVOptions = .default, limits: CSVLimits = .default) -> CSVError? {
    do {
        _ = try CSVParser(options: options, limits: limits).parse(bytes)
        return nil
    } catch {
        return error
    }
}

let headerless = CSVOptions(header: .absent)
