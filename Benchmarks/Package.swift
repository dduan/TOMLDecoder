// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Benchmarks",
    dependencies: [
        .package(name: "TOMLDecoder", path: "../"),
        .package(name: "Benchmark", url: "https://github.com/google/swift-benchmark", .exact("0.1.1")),
        .package(name: "TOMLDeserializer", url: "https://github.com/dduan/TOMLDeserializer", .exact("0.2.5")),
    ],
    targets: [
        .target(name: "Benchmarks", dependencies: ["Benchmark", "TOMLDecoder", "Ctomlc99", "TOMLDeserializer"]),
        .target(name: "Ctomlc99"),
    ]
)
