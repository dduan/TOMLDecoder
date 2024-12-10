// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "TOMLDecoder",
    platforms: [.iOS(.v12), .tvOS(.v12), .watchOS(.v4), .macOS(.v13)],
    products: [
        .executable(name: "compliance", targets: ["compliance"]),
        .library(name: "TOMLDecoder", targets: ["TOMLDecoder"]),
    ],
    targets: [
        .executableTarget(name: "compliance", dependencies: ["TOMLDecoder"]),
        .target(name: "TOMLDecoder", dependencies: ["Deserializer"]),
        .target(name: "Deserializer"),
        .testTarget(name: "TOMLDecoderTests", dependencies: ["TOMLDecoder"]),
        .testTarget(
            name: "DeserializerTests",
            dependencies: ["Deserializer"],
            exclude: [
                "invalid_fixtures",
                "valid_fixtures",
            ]
        ),
    ]
)
