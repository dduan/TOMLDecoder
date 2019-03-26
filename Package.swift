// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "TOMLDecoder",
    products: [
        .library(
            name: "TOMLDecoder",
            targets: ["TOMLDecoder"]),
    ],
    dependencies: [
        .package(url: "https://github.com/dduan/TOMLDeserializer", from: "0.2.3"),
        .package(url: "https://github.com/dduan/NetTime", from: "0.2.1"),
    ],
    targets: [
        .target(
            name: "TOMLDecoder",
            dependencies: ["TOMLDeserializer", "NetTime"]),
        .testTarget(
            name: "TOMLDecoderTests",
            dependencies: ["TOMLDecoder"]),
    ]
)
