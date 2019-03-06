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
        .package(url: "https://github.com/dduan/TOMLDeserialization", from: "0.1.0"),
    ],
    targets: [
        .target(
            name: "TOMLDecoder",
            dependencies: ["TOMLDeserializer"]),
        .testTarget(
            name: "TOMLDecoderTests",
            dependencies: ["TOMLDecoder"]),
    ]
)
