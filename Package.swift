// swift-tools-version: 6.2

import Foundation
import PackageDescription

let env = ProcessInfo.processInfo.environment
let includeBenchmarks = env["TOMLDECODER_BENCHMARKS"] == "1"
let includeDocs = env["TOMLDECODER_DOCS"] == "1"
let includeFormatting = env["TOMLDECODER_FORMATTING"] == "1"

var benchmarksDeps: [Package.Dependency] = includeBenchmarks ? [
    .package(
        url: "https://github.com/ordo-one/package-benchmark",
        exact: "1.29.6",
    ),
] : []

var docsDeps: [Package.Dependency] = includeDocs ? [
    .package(
        url: "https://github.com/apple/swift-docc-plugin",
        exact: "1.4.5",
    ),
] : []

var formattingDeps: [Package.Dependency] = includeFormatting ? [
    .package(url: "https://github.com/nicklockwood/SwiftFormat", from: "0.58.6"),
] : []

var targets: [Target] = [
    .executableTarget(
        name: "compliance",
        dependencies: ["TOMLDecoder"],
    ),
    .target(
        name: "TOMLDecoder",
        exclude: ["gyb"],
    ),
]

var testTargets: [Target] = [
    .target(
        name: "Resources",
        exclude: ["fixtures"],
    ),
    .target(
        name: "ProlepticGregorianTestHelpers",
        publicHeadersPath: "include",
    ),
    .testTarget(
        name: "TOMLDecoderTests",
        dependencies: [
            "ProlepticGregorianTestHelpers",
            "Resources",
            "TOMLDecoder",
        ],
        exclude: [
            "gyb",
            "invalid_fixtures",
            "valid_fixtures",
        ],
    ),
]

var benchmarkTargets: [Target] = includeBenchmarks ? [
    .executableTarget(
        name: "TOMLDecoderBenchmarks",
        dependencies: [
            "TOMLDecoder",
            "Resources",
            .product(name: "Benchmark", package: "package-benchmark"),
        ],
        path: "Benchmarks/TOMLDecoderBenchmarks",
        plugins: [
            .plugin(name: "BenchmarkPlugin", package: "package-benchmark"),
        ],
    ),
] : []

let package = Package(
    name: "TOMLDecoder",
    platforms: [.iOS(.v12), .tvOS(.v12), .watchOS(.v4), .macOS(.v13), .visionOS(.v1)],
    products: [
        .executable(name: "compliance", targets: ["compliance"]),
        .library(name: "TOMLDecoder", targets: ["TOMLDecoder"]),
    ],
    dependencies: benchmarksDeps + docsDeps + formattingDeps,
    targets: targets + testTargets + benchmarkTargets,
    cxxLanguageStandard: .cxx20,
)
