# Working in Swift-CSV

A strict, pure-Swift RFC 4180 CSV parser that returns UTF-8 string fields. README.md and
the DocC articles in `Sources/CSV/CSV.docc` are the specification; update them in the same
commit when behavior changes. TESTING.md is the test plan; CONTRIBUTING.md has the code
rules.

- Swift 6 language mode, strict concurrency; public types are `Sendable`.
- No force unwraps or `fatalError` in library code. No Foundation in `Sources/`.
- The `CSV` target uses only the standard library. Only `CSVJSON` imports Swift-JSON.
- Cells are strings. No type guessing, trimming, padding or repair; malformed input fails.
- Errors are `CSVError` with code, line and column; messages contain no paths.
- Tests use Swift Testing with behavior-named tests. Every `CSVError.Code` has a
  negative test. The csv-spectrum test must stay green; update the README with it.
- Evidence is `swift test` (debug, release, WebAssembly) and `sh Tools/build-docc.sh`.
  No status or evidence files.
- Do not push, tag or publish without the owner's approval.
