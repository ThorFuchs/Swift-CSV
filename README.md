# Swift-CSV

**A strict, pure-Swift RFC 4180 CSV parser that returns UTF-8 strings and never guesses.**

[![CI](https://github.com/ThorFuchs/Swift-CSV/actions/workflows/ci.yml/badge.svg)](https://github.com/ThorFuchs/Swift-CSV/actions/workflows/ci.yml)
[![License: Apache-2.0](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)
![Platforms: macOS | iOS | Linux | WebAssembly](https://img.shields.io/badge/platforms-macOS%20%7C%20iOS%20%7C%20Linux%20%7C%20WebAssembly-lightgrey.svg)

[Read the documentation →](https://thorfuchs.github.io/Swift-CSV/documentation/csv/)

Swift-CSV reads CSV files into a header and records of string fields. Every cell is a
UTF-8 string exactly as written. Types are never guessed, whitespace is never trimmed and
malformed input is never repaired: it fails with a typed error and a line and column.

- **Strings only.** `007`, `1.50`, `true` and `null` stay strings. Typing belongs to the
  caller, for example a JSON Schema.
- **Strict headers.** A header is required by default. Empty and duplicate names are
  errors. Every record must have exactly as many fields as the header; short or long
  records are errors, not padded or cut.
- **No repairs.** A stray quote, an unclosed quote, text after a closing quote, a lone
  carriage return and invalid UTF-8 are errors.
- **Safe on untrusted input.** Explicit limits on input size, records, fields per record
  and field size. Cancellation is honored.
- **Portable.** Pure Swift: no C code and no Foundation in the library. It is tested on
  macOS, Linux (x86_64 and arm64) and WebAssembly (WASI).
- **Two products.** `CSV` uses only the standard library. `CSVJSON` adds an optional
  conversion to [Swift-JSON](https://github.com/ThorFuchs/Swift-JSON) objects.

## Installation

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/ThorFuchs/Swift-CSV.git", from: "0.1.0"),
],
targets: [
    .target(name: "App", dependencies: [
        .product(name: "CSV", package: "Swift-CSV"),
        .product(name: "CSVJSON", package: "Swift-CSV"),   // optional, for JSON objects
    ]),
]
```

| Requirement | Supported |
|---|---|
| Swift | 6.4 or later, Swift 6 language mode |
| Apple platforms | macOS 27, iOS 27 and later (the minimums of Swift-JSON 1.9.0); iOS is built in CI |
| Linux | x86_64 and arm64 |
| WebAssembly | `wasm32-unknown-wasip1` with the matching Swift.org WASM SDK |
| Dependencies | `CSV`: none. `CSVJSON`: [Swift-JSON](https://github.com/ThorFuchs/Swift-JSON) 1.9.0 |

The `CSV` target does not import or link Swift-JSON. SwiftPM still resolves Swift-JSON
for the package as a whole, because package dependencies are declared per package, not
per product. That keeps a single version for both products and avoids a second
repository for a 100-line conversion.

## Usage

```swift
import CSV

let table = try CSVParser().parse("sku,name,price\nA-1,Pen,1.50\nB-2,\"Ink, blue\",4\n")
table.header                    // ["sku", "name", "price"]
table.records[1].fields         // ["B-2", "Ink, blue", "4"]
table.records[1].line           // 3

// Semicolons, no header
let rows = try CSVParser(options: CSVOptions(delimiter: .semicolon, header: .absent))
    .parse(bytes)               // bytes: [UInt8]; rows.header == nil

// Errors are typed, positioned and stable
do {
    _ = try CSVParser().parse("a,b\n1,2,3\n")
} catch {
    print(error.code, error.line, error.column)   // fieldCountMismatch 2 5
}
```

With `CSVJSON`:

```swift
import CSV
import CSVJSON
import JSON

let objects = try CSVParser().parseObjects("sku,note\nA-1,\nB-2,new\n")
// [{"sku": "A-1"}, {"sku": "B-2", "note": "new"}]      emptyCell: .missing (default)

try table.jsonObjects(emptyCell: .null)                 // {"sku": "A-1", "note": null}
try table.jsonObjects(emptyCell: .emptyString)          // {"sku": "A-1", "note": ""}
```

## Public API

`CSV` module:

```swift
public struct CSVParser: Sendable {
    public var options: CSVOptions
    public var limits: CSVLimits
    public init(options: CSVOptions = .default, limits: CSVLimits = .default)
    public func parse(_ bytes: [UInt8]) throws(CSVError) -> CSVTable
    public func parse(_ text: String) throws(CSVError) -> CSVTable
}

public struct CSVOptions: Sendable, Equatable {
    public var delimiter: CSVDelimiter        // .comma
    public var header: CSVHeaderMode          // .required
    public init(delimiter: CSVDelimiter = .comma, header: CSVHeaderMode = .required)
    public static let `default`: CSVOptions
}
public enum CSVDelimiter: String, Sendable, CaseIterable { case comma, semicolon, tab, pipe }
public enum CSVHeaderMode: Sendable, CaseIterable { case required, absent }

public struct CSVLimits: Sendable, Equatable {
    public var maxInputBytes: Int             // 8 MiB
    public var maxRecords: Int                // 1,000,000 data records
    public var maxFieldsPerRecord: Int        // 1,024
    public var maxFieldBytes: Int             // 1 MiB
    public static let `default`: CSVLimits
}

public struct CSVTable: Sendable, Equatable {
    public var header: [String]?              // nil with .absent
    public var records: [CSVRecord]
}
public struct CSVRecord: Sendable, Equatable {
    public var fields: [String]
    public var line: Int                      // 1-based line where the record starts
}

public struct CSVError: Error, Sendable, Equatable, CustomStringConvertible {
    public enum Code: String, Sendable, CaseIterable { ... }   // see below
    public let code: Code
    public let message: String                // never contains paths
    public let line: Int                      // 1-based
    public let column: Int                    // 1-based, in Unicode scalars
    public func shifted(byLines: Int) -> CSVError
}
```

`CSVJSON` module:

```swift
public enum CSVEmptyCell: String, Sendable, CaseIterable { case missing, null, emptyString }

extension CSVTable {
    public func jsonObjects(emptyCell: CSVEmptyCell = .missing,
                            limits: JSONLimits? = nil) throws(CSVError) -> [JSONObject]
}
extension CSVParser {
    public func parseObjects(_ bytes: [UInt8], emptyCell: CSVEmptyCell = .missing) throws(CSVError) -> [JSONObject]
    public func parseObjects(_ text: String, emptyCell: CSVEmptyCell = .missing) throws(CSVError) -> [JSONObject]
}
```

## Rules

| Input | Result |
|---|---|
| `,` (or the configured `;`, tab, `\|`) | separates fields |
| LF or CRLF | ends a record; both may appear in one file |
| line break at the end of the input | optional; it does not add a record |
| empty line | a record with one empty field, so with a multi-column header an error |
| UTF-8 byte order mark at the start | skipped |
| `"…"` field | quoted: may contain delimiters, line breaks and `""` for a quote |
| line break inside quotes | kept byte for byte (`\n` or `\r\n`), and counted in line numbers |
| spaces around a field | part of the field, never trimmed |
| `a,` | two fields, the second empty |
| `""` and an empty unquoted field | both the empty string |
| any value | a UTF-8 string; no number, boolean, date or null detection |
| header (`.required`) | names must be non-empty and unique; canonically equivalent Unicode spellings count as duplicates |
| header-less (`.absent`) | every record must have as many fields as the first record |

Line numbers count line feeds. A record's `line` is where it starts; a quoted field that
spans lines moves later records down accordingly.

## Limits and errors

| Limit | Default | Error |
|---|---|---|
| `maxInputBytes` | 8 MiB | `inputTooLarge` |
| `maxRecords` (data records, not the header) | 1,000,000 | `tooManyRecords` |
| `maxFieldsPerRecord` | 1,024 | `tooManyFields` |
| `maxFieldBytes` (after `""` unescaping) | 1 MiB | `fieldTooLarge` |

| Code | Meaning |
|---|---|
| `invalidEncoding` | the input is not valid UTF-8 (including UTF-16 input) |
| `quoteInUnquotedField` | `a"b`, or a space before an opening quote: `a, "b"` |
| `unterminatedQuotedField` | a quoted field is still open at the end of the input |
| `unexpectedCharacterAfterQuote` | `"a"b`, or a space after a closing quote |
| `bareCarriageReturn` | a CR outside quotes that is not followed by LF |
| `missingHeader` | an empty input with `.required`, or `jsonObjects` on a header-less table |
| `emptyHeaderName` | a header name is `""` |
| `duplicateHeaderName` | a header name repeats |
| `fieldCountMismatch` | a record has more or fewer fields than the header (or first record) |
| `inputTooLarge`, `tooManyRecords`, `tooManyFields`, `fieldTooLarge` | a limit was exceeded |
| `cancelled` | the surrounding task was cancelled |
| `jsonLimitExceeded` | `CSVJSON` only: explicit `JSONLimits` were too small |

Every failure is a `CSVError` with a `code`, a `message` without file paths, and a
1-based `line` and `column` (columns count Unicode scalars). The parser checks for
cancellation on entry and every 1,024 records. A result is never partial: a call returns
the whole table or throws.

## Conformance

- **RFC 4180:** every rule of section 2 has a test built from the RFC's own examples.
- **[csv-spectrum](https://github.com/max-mapper/csv-spectrum) 2.0.0** (BSD-2-Clause,
  vendored unmodified in `Tests/CSVJSONTests/Fixtures`): 11 of 12 cases match their JSON
  exactly, with `emptyCell: .emptyString`. `location_coordinates` is rejected on purpose
  with `quoteInUnquotedField`: it has bare `"` characters in unquoted fields.

### Deliberate deviations from RFC 4180

RFC 4180 is an informational memo, and real files stretch it. Swift-CSV accepts these
common, unambiguous extensions:

- **UTF-8 text,** not only the ASCII `TEXTDATA` of the RFC grammar. Any valid UTF-8,
  including control characters, is field content.
- **LF line breaks,** as well as CRLF, and both in one file.
- **Delimiters** `;`, tab and `|` besides `,`, chosen explicitly (never detected).
- **A UTF-8 byte order mark** at the start of the input is skipped.
- **The header** is required by default (the RFC makes it optional), and its names must be
  non-empty and unique.

And it rejects what lenient parsers often accept:

- A `"` inside an unquoted field, and anything but a delimiter or line break after a
  closing quote (including spaces).
- A lone CR outside quotes (old Mac line endings).
- Records with a different number of fields, including a blank line or a trailing
  blank line in a multi-column file.

### Not supported, by design

- Type inference, trimming, comment lines, skipping blank lines, delimiter detection.
- Other quote or escape characters (such as `\"`), multi-character delimiters.
- Encodings other than UTF-8.
- Streaming parsing and writing (emitting) CSV.

## Documentation

- [API reference and guides](https://thorfuchs.github.io/Swift-CSV/documentation/csv/),
  built with DocC from `Sources/CSV/CSV.docc`
- [TESTING.md](TESTING.md): the test plan
- [CONTRIBUTING.md](CONTRIBUTING.md): how to build, test and propose changes
- [CHANGELOG.md](CHANGELOG.md): release history
- [SECURITY.md](SECURITY.md): how to report a vulnerability

## License

Apache-2.0. See [LICENSE](LICENSE) and [NOTICE](NOTICE). The vendored csv-spectrum
fixtures are BSD-2-Clause; see
[their license](Tests/CSVJSONTests/Fixtures/csv-spectrum/LICENSE).
