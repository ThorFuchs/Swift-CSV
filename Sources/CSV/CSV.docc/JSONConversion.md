# JSON Conversion

Turn records into Swift-JSON objects with the optional `CSVJSON` module.

## Overview

The `CSVJSON` product depends on [Swift-JSON](https://github.com/ThorFuchs/Swift-JSON)
1.9.0..<1.11.0 (tested with 1.9.0 and 1.10.0). SwiftPM resolves it at the package level, even for a consumer that uses only `CSV`. It adds two entry points:

```swift
import CSV
import CSVJSON

// Parse and convert in one step
let objects = try CSVParser().parseObjects(bytes)                 // [JSONObject]

// Or convert a table you already have
let table = try CSVParser().parse(bytes)
let objects = try table.jsonObjects(emptyCell: .null)
```

Each record becomes one `JSONObject`. Its members follow header order and every value is
a `.string`: no numbers, booleans or nulls are guessed. The object at index `i` belongs to
`table.records[i]`, so `records[i].line` locates it in the source.

A table without a header has no keys, so converting it fails with `missingHeader` rather
than inventing names.

## Empty cells

A cell is empty when its value is `""`, whether written as nothing or as `""`. The
`emptyCell` parameter decides what it becomes:

| `CSVEmptyCell` | `a,b` / `1,` becomes |
|---|---|
| `.missing` (default) | `{"a": "1"}`: the key is left out |
| `.null` | `{"a": "1", "b": null}` |
| `.emptyString` | `{"a": "1", "b": ""}` |

## Limits

By default each object is built under `JSONLimits.offline`, raised where needed so that
any table the parser accepted converts. Pass explicit `limits:` to `jsonObjects` to apply
tighter Swift-JSON limits; an object that exceeds them fails with
``CSVError/Code-swift.enum/jsonLimitExceeded`` on that record's line. Cancellation is
checked every 1,024 records.
