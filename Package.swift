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
            dependencies: ["Deserializer"]),
        .target(name: "Deserializer"),
        .testTarget(
            name: "TOMLDecoderTests",
            dependencies: ["TOMLDecoder"]),
        .testTarget(
            name: "DeserializerTests",
            dependencies: ["Deserializer"],
            exclude: [
                "invalid_fixtures",
                "valid_fixtures",
            ]),
    ]
)
