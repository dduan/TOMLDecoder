// swift-tools-version: 6.1

import PackageDescription
import class Foundation.ProcessInfo

var dependencies: [Package.Dependency] = []
let env = ProcessInfo.processInfo.environment
let useExperimental = env["BUILD_DOCS"] == "1"

if useExperimental {
    dependencies.append(
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0")
    )
}

let package = Package(
    name: "TOMLDecoder",
    platforms: [.iOS(.v12), .tvOS(.v12), .watchOS(.v4), .macOS(.v13)],
    products: [
        .executable(name: "compliance", targets: ["compliance"]),
        .library(name: "TOMLDecoder", targets: ["TOMLDecoder"]),
    ],
    traits: [
        "docs",
    ],
    dependencies: dependencies,
    targets: [
        .executableTarget(name: "compliance", dependencies: ["TOMLDecoder"]),
        .target(
            name: "TOMLDecoder",
            exclude: [
                "gyb",
            ]
        ),
        .target(
            name: "ProlepticGregorianTestHelpers",
            publicHeadersPath: "include"
        ),
        .testTarget(
            name: "TOMLDecoderTests",
            dependencies: [
                "TOMLDecoder",
                "ProlepticGregorianTestHelpers",
            ],
            exclude: [
                "invalid_fixtures",
                "valid_fixtures",
            ]
        ),
    ],
    cxxLanguageStandard: .cxx20
)
