# Changelog

This project follows [Semantic Versioning](https://semver.org). Before 1.0.0, minor
releases may change the public API.

## 0.1.1

- Admit Swift-JSON 1.9.0..<1.11.0; qualify 1.9.0 and 1.10.0.
- Preserve the public API, format semantics and deployment floors.

## 0.1.0

First public release.

- `CSVParser` parses RFC 4180 CSV into a `CSVTable` of UTF-8 string fields:
  - LF and CRLF records, an optional final line break and a skipped UTF-8 BOM;
  - quoted fields with delimiters, line breaks and `""` escapes;
  - comma, semicolon, tab or pipe delimiters;
  - a required header by default (non-empty, unique names, exact field counts), or
    header-less records;
  - each record's 1-based starting line.
- No type guessing, trimming, padding or repair: malformed input fails.
- `CSVLimits` bounds input bytes, records, fields per record and field bytes.
  Cancellation is supported.
- `CSVError` reports 15 stable codes with a 1-based line and column.
- `CSVJSON` (optional product, Swift-JSON 1.9.0) converts records to header-keyed
  `JSONObject`s of strings with an explicit `CSVEmptyCell` policy: `missing`, `null` or
  `emptyString`.
- All 12 csv-spectrum 2.0.0 cases are run: 11 match, 1 documented rejection.
- Tested on macOS, Linux x86_64 and arm64, and WebAssembly (WASI).
