// swift-tools-version: 6.0

import PackageDescription

let codableSupportEnabled: [SwiftSetting] = [.define("CodableSupport")]

let package = Package(
    name: "TOMLDecoder",
    platforms: [.iOS(.v13), .tvOS(.v13), .watchOS(.v6), .macOS(.v10_15), .visionOS(.v1)],
    products: [
        .executable(name: "compliance", targets: ["compliance"]),
        .library(name: "TOMLDecoder", targets: ["TOMLDecoder"]),
    ],
    targets: [
        .executableTarget(
            name: "compliance",
            dependencies: ["TOMLDecoder"]
        ),
        .target(
            name: "TOMLDecoder",
            exclude: ["gyb"],
            swiftSettings: codableSupportEnabled + [
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
                .enableUpcomingFeature("MemberImportVisibility"),
            ]
        ),
        .target(
            name: "Resources",
            exclude: ["fixtures"]
        ),
        .target(
            name: "ProlepticGregorianTestHelpers",
            publicHeadersPath: "include"
        ),
        .testTarget(
            name: "TOMLDecoderTests",
            dependencies: [
                "ProlepticGregorianTestHelpers",
                "Resources",
                "TOMLDecoder",
            ],
            exclude: [
                "gyb",
                "invalid_fixtures",
                "valid_fixtures",
            ],
            swiftSettings: codableSupportEnabled
        ),
    ],
    cxxLanguageStandard: .cxx20
)
