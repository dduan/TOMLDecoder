// swift-tools-version: 6.1

import PackageDescription
import Foundation

let env = ProcessInfo.processInfo.environment
let includeBenchmarks = env["TOMLDECODER_BENCHMARKS"] == "1"
let includeDocs = env["TOMLDECODER_DOCS"] == "1"

var benchmarksDeps: [Package.Dependency] = includeBenchmarks ? [
    .package(
        url: "https://github.com/ordo-one/package-benchmark",
        exact: "1.29.6"
    ),
] : []

var docsDeps: [Package.Dependency] = includeDocs ? [
    .package(
        url: "https://github.com/apple/swift-docc-plugin",
        exact: "1.4.5"
    ),
] : []

var targets: [Target] = [
    .executableTarget(
        name: "compliance",
        dependencies: ["TOMLDecoder"]
    ),
    .target(
        name: "TOMLDecoder",
        exclude: [
            "gyb",
        ]
    ),
]

var testTargets: [Target] = [
    .target(
        name: "ProlepticGregorianTestHelpers",
        publicHeadersPath: "include"
    ),
    .testTarget(
        name: "TOMLDecoderTests",
        dependencies: [
            "TOMLDecoder",
            "ProlepticGregorianTestHelpers",
        ],
        exclude: [
            "invalid_fixtures",
            "valid_fixtures",
        ]
    ),
]

var benchmarkTargets: [Target] = includeBenchmarks ? [
    .executableTarget(
        name: "TOMLDecoderBenchmarks",
        dependencies: [
            "TOMLDecoder",
            .product(name: "Benchmark", package: "package-benchmark"),
        ],
        path: "Benchmarks/TOMLDecoderBenchmarks",
        plugins: [
            .plugin(name: "BenchmarkPlugin", package: "package-benchmark"),
        ]
    ),
] : []

let package = Package(
    name: "TOMLDecoder",
    platforms: [.iOS(.v12), .tvOS(.v12), .watchOS(.v4), .macOS(.v13)],
    products: [
        .executable(name: "compliance", targets: ["compliance"]),
        .library(name: "TOMLDecoder", targets: ["TOMLDecoder"]),
    ],
    dependencies: benchmarksDeps + docsDeps,
    targets: targets + testTargets + benchmarkTargets,
    cxxLanguageStandard: .cxx20
)
