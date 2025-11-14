// swift-tools-version: 6.2

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
        .target(
            name: "TOMLDecoder",
        ),
        .testTarget(
            name: "TOMLDecoderTests",
            dependencies: ["TOMLDecoder"],
            exclude: [
                "invalid_fixtures",
                "valid_fixtures",
            ]
        ),
    ]
)
