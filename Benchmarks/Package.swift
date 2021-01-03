// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Benchmarks",
    dependencies: [
        .package(name: "TOMLDecoder", path: "../"),
        .package(name: "Benchmark", url: "https://github.com/google/swift-benchmark", .exact("0.1.0")),
    ],
    targets: [
        .target(name: "Benchmarks", dependencies: ["Benchmark", "TOMLDecoder", "Ctomlc99"]),
        .target(name: "Ctomlc99"),
    ]
)
