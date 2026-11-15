# ``CSV``

Parse RFC 4180 CSV into UTF-8 string fields, strictly.

## Overview

Swift-CSV reads CSV files into a header and records of string fields. Every cell is a
UTF-8 string exactly as written. Types are never guessed, whitespace is never trimmed and
malformed input is never repaired: it fails with a ``CSVError`` that has a stable code
and a line and column.

The package is pure Swift, with no C code and no Foundation in the library. It runs on
macOS, iOS, Linux and WebAssembly (WASI). The `CSV` module uses only the standard library;
the optional `CSVJSON` module converts tables to Swift-JSON objects.

```swift
import CSV

let table = try CSVParser().parse("sku,price\nA-1,1.50\n")
table.header              // ["sku", "price"]
table.records[0].fields   // ["A-1", "1.50"]
```

## Topics

### Essentials

- <doc:GettingStarted>
- ``CSVParser``
- ``CSVTable``
- ``CSVRecord``

### Reading rules

- <doc:ParsingRules>
- ``CSVOptions``
- ``CSVDelimiter``
- ``CSVHeaderMode``

### JSON objects

- <doc:JSONConversion>

### Limits and errors

- <doc:LimitsAndErrors>
- ``CSVLimits``
- ``CSVError``

### Quality

- <doc:PlatformSupport>
- <doc:Conformance>
