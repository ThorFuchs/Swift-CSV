// swift-tools-version: 6.4
// SPDX-License-Identifier: Apache-2.0
import PackageDescription

let package = Package(
    name: "Swift-CSV",
    // Floors match Swift Content Collections, the first consumer.
    platforms: [.macOS("27.0"), .iOS("27.0")],
    products: [
        // The parser. Standard library only; it does not link Swift-JSON.
        .library(name: "CSV", targets: ["CSV"]),
        // Optional conversion of a parsed table to Swift-JSON objects.
        .library(name: "CSVJSON", targets: ["CSVJSON"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ThorFuchs/Swift-JSON.git", exact: "1.9.0"),
    ],
    targets: [
        .target(name: "CSV"),
        .target(
            name: "CSVJSON",
            dependencies: ["CSV", .product(name: "JSON", package: "Swift-JSON")]
        ),
        .testTarget(name: "CSVTests", dependencies: ["CSV"]),
        .testTarget(
            name: "CSVJSONTests",
            dependencies: ["CSV", "CSVJSON", .product(name: "JSON", package: "Swift-JSON")],
            resources: [.copy("Fixtures")]
        ),
    ],
    swiftLanguageModes: [.v6]
)
