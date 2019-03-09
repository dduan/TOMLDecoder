// swift-tools-version:4.2

import PackageDescription

let package = Package(
    name: "TOMLDecoder",
    products: [
        .library(
            name: "TOMLDecoder",
            targets: ["TOMLDecoder"]),
    ],
    dependencies: [
        .package(url: "https://github.com/dduan/TOMLDeserializer", from: "0.1.0"),
        .package(url: "https://github.com/dduan/NetTime", from: "0.1.1"),
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
