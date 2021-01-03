// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "TOMLDecoder",
    platforms: [.iOS(.v9), .tvOS(.v9), .watchOS(.v2), .macOS(.v10_10)],
    products: [
        .library(
            name: "TOMLDecoder",
            targets: ["TOMLDecoder"]),
    ],
    targets: [
        .target(
            name: "TOMLDecoder",
            dependencies: ["TOMLDeserializer"]),
        .target(name: "TOMLDeserializer"),
        .testTarget(
            name: "TOMLDecoderTests",
            dependencies: ["TOMLDecoder"]),
        .testTarget(
            name: "TOMLDeserializerTests",
            dependencies: ["TOMLDeserializer"],
            exclude: [
                "invalid_fixtures",
                "valid_fixtures",
            ]),
    ]
)
