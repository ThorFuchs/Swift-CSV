# Test Plan

All tests use Swift Testing and live in `Tests/CSVTests` (the `CSV` module alone) and
`Tests/CSVJSONTests` (the JSON conversion, the corpus and error-code coverage). Each test
name describes a behavior. There are no skipped tests, no placeholder tests and no tests
that only check that code compiles.

## How to run

```sh
swift test                                         # debug
swift test -c release                              # release
swift test --swift-sdk swift-6.4.2-RELEASE_wasm    # WebAssembly, run under WasmKit
```

CI runs all of these on every push and pull request:

- macOS on Xcode 27.2, plus an iOS build
- Linux x86_64 and Linux arm64 in the `swift:6.4.2` container
- WebAssembly with the Swift 6.4.2 WASM SDK

CI also builds the DocC documentation with warnings treated as errors.

## What is tested where

| Area | Test suite (file) | What it guarantees |
|---|---|---|
| RFC 4180 | `RFC4180Tests` (`RFC4180Tests.swift`) | Each rule of section 2 with the RFC's examples: CRLF records, optional final break, header line, spaces kept, quoting, quoted line breaks, `""` escapes, stray quotes rejected. |
| Line breaks | `LineBreakTests` | LF, CRLF and mixed; quoted breaks kept byte for byte; blank lines are records; trailing breaks. |
| Encoding | `EncodingTests` | BOM skipped once; Unicode and control characters kept; invalid UTF-8 (stray, overlong, surrogate, out of range, truncated) rejected with positions; UTF-16 rejected. |
| Delimiters | `DelimiterTests` | Comma default; semicolon, tab and pipe; delimiters inside quotes. |
| Values | `ValueTests` | No type guessing; empty quoted and unquoted fields; whitespace inside quotes. |
| Header | `HeaderTests` | Required by default; header-only tables; empty, duplicate and canonically equivalent names; short and long records with positions. |
| Header-less | `HeaderlessTests` | `header == nil`; first record unchecked; field count fixed by the first record. |
| Positions | `LineNumberTests` | Record lines across quoted breaks; error lines and scalar columns; `shifted(byLines:)`. |
| Syntax errors | `SyntaxErrorTests` | Each syntax code with several inputs and exact positions. |
| Limits | `LimitTests` | Each limit at and beyond its ceiling, with positions; cancellation; default values. |
| Error codes | `ErrorCodeCoverageTests` (`CSVJSONTests`) | Each `CSVError.Code` case has a minimal reproducer that yields exactly that code with a valid position and a message without paths. Parameterized over `Code.allCases`, so a new code without a reproducer fails. |
| JSON conversion | `JSONConversionTests` | Header-ordered string objects; the three empty-cell policies stay distinct; no typing; header-less tables rejected; explicit JSON limits; default limits fit 1,024 columns and 1 MiB fields; cancellation. |
| Corpus | `CSVSpectrumTests` | All 12 csv-spectrum cases: 11 match their JSON, `location_coordinates` is the one documented rejection. |

## Rules for changes

1. **Every behavior change comes with a test.** Change README.md and the DocC articles
   in the same pull request.
2. **Every new `CSVError.Code` gets a reproducer** in `ErrorCodeCoverageTests` and a
   behavior test in the matching suite.
3. **Keep the corpus green.** A new deliberate rejection goes into
   `deliberateRejections` with its code and into the README.
4. **Test inputs are small strings written in the test.** Only csv-spectrum lives in
   `Fixtures/`. Its files are copied unmodified.
5. **Limit tests use tiny limits** so that they run fast on every platform, including
   WebAssembly.
