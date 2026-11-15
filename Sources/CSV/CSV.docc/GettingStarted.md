# Getting Started

Add the package, parse a file and handle errors.

## Add the dependency

```swift
dependencies: [
    .package(url: "https://github.com/ThorFuchs/Swift-CSV.git", from: "0.1.0"),
],
targets: [
    .target(name: "App", dependencies: [
        .product(name: "CSV", package: "Swift-CSV"),
    ]),
]
```

## Parse a table

``CSVParser/parse(_:)-(String)`` and ``CSVParser/parse(_:)-([UInt8])`` return a
``CSVTable``. By default the first record is the header:

```swift
import CSV

let table = try CSVParser().parse(bytes)
for record in table.records {
    // record.fields.count == table.header!.count
    // record.line is the 1-based line where the record starts
}
```

For files without a header, or with another delimiter, pass ``CSVOptions``:

```swift
let parser = CSVParser(options: CSVOptions(delimiter: .tab, header: .absent))
let rows = try parser.parse(bytes).records.map(\.fields)
```

## Handle errors

Every failure is a ``CSVError``. Its ``CSVError/code-swift.property`` is stable and its
``CSVError/line`` and ``CSVError/column`` point at the problem:

```swift
do {
    _ = try CSVParser().parse("id,name\n1\n")
} catch {
    error.code      // .fieldCountMismatch
    error.line      // 2
    error.message   // "record has 1 field; the header has 2"
}
```

Messages never contain file paths, so add your own context when reporting them.
