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
    dependencies: [
        .package(url: "https://github.com/dduan/TOMLDeserializer", from: "0.2.3"),
        .package(url: "https://github.com/dduan/NetTime", from: "0.2.2"),
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
