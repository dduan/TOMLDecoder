// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "TOMLDecoder",
    platforms: [.iOS(.v12), .tvOS(.v12), .watchOS(.v4), .macOS(.v13)],
    products: [
        .executable(name: "compliance", targets: ["compliance"]),
        .library(name: "TOMLDecoder", targets: ["TOMLDecoder"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/ordo-one/package-benchmark",
            .upToNextMajor(from: "1.4.0")
        ),
    ],
    targets: [
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
    ],
    cxxLanguageStandard: .cxx20
)
