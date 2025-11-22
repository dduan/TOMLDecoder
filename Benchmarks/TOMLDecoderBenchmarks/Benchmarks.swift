import Benchmark
import Foundation
import Resources
import TOMLDecoder

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [
        .cpuTotal,
        .instructions,
        .retainCount,
    ]

    Benchmark("Parse one field") { _ in
        try blackHole(TOMLTable(source: oneFieldTOML))
    }

    Benchmark("Decode one field") { benchmark in
        let decoder = TOMLDecoder()
        benchmark.startMeasurement()
        try blackHole(decoder.decode(OneField.self, from: oneFieldTOML))
    }

    Benchmark("Parse toml.io example") { _ in
        try blackHole(TOMLTable(source: tomlIOTOML))
    }

    Benchmark("Decode toml.io example") { benchmark in
        var decoder = TOMLDecoder()
        decoder.strategy.key = .convertFromSnakeCase
        benchmark.startMeasurement()
        try blackHole(decoder.decode(Config.self, from: tomlIOTOML))
    }

    Benchmark("parse big string") { benchmark in
        let decoder = TOMLDecoder()
        benchmark.startMeasurement()
        try blackHole(TOMLTable(source: bigStringTOML))
    }

    Benchmark("parse canada.toml") { _ in
        try blackHole(TOMLTable(source: Resources.canadaTOMLString))
    }

    Benchmark("decode canada.toml") { benchmark in
        let decoder = TOMLDecoder()
        benchmark.startMeasurement()
        try blackHole(decoder.decode(CanadaFeatureCollection.self, from: Resources.canadaTOMLString))
    }

    Benchmark("parse twitter.toml") { _ in
        try blackHole(TOMLTable(source: Resources.twitterTOMLString))
    }

    Benchmark("decode twitter.toml") { benchmark in
        let decoder = TOMLDecoder()
        benchmark.startMeasurement()
        try blackHole(decoder.decode(TwitterArchive.self, from: Resources.twitterTOMLString))
    }
}

let oneFieldTOML = """
a = 2
"""

let tomlIOTOML = """
# This is a TOML document

title = "TOML Example"

[owner]
name = "Tom Preston-Werner"
dob = 1979-05-27T07:32:00-08:00

[database]
enabled = true
ports = [ 8000, 8001, 8002 ]
data = [ ["delta", "phi"], [3.14] ]
temp_targets = { cpu = 79.5, case = 72.0 }

[servers]

[servers.alpha]
ip = "10.0.0.1"
role = "frontend"

[servers.beta]
ip = "10.0.0.2"
role = "backend"
"""

let bigStringTOML = #"""
big = """
Lorem ipsum dolor sit amet consectetur adipiscing elit. Quisque faucibus ex sapien vitae pellentesque sem placerat. In id cursus mi pretium tellus duis convallis. Tempus leo eu aenean sed diam urna tempor. Pulvinar vivamus fringilla lacus nec metus bibendum egestas. Iaculis massa nisl malesuada lacinia integer nunc posuere. Ut hendrerit semper vel class aptent taciti sociosqu. Ad litora torquent per conubia nostra inceptos himenaeos.

Lorem ipsum dolor sit amet consectetur adipiscing elit. Quisque faucibus ex sapien vitae pellentesque sem placerat. In id cursus mi pretium tellus duis convallis. Tempus leo eu aenean sed diam urna tempor. Pulvinar vivamus fringilla lacus nec metus bibendum egestas. Iaculis massa nisl malesuada lacinia integer nunc posuere. Ut hendrerit semper vel class aptent taciti sociosqu. Ad litora torquent per conubia nostra inceptos himenaeos.

Lorem ipsum dolor sit amet consectetur adipiscing elit. Quisque faucibus ex sapien vitae pellentesque sem placerat. In id cursus mi pretium tellus duis convallis. Tempus leo eu aenean sed diam urna tempor. Pulvinar vivamus fringilla lacus nec metus bibendum egestas. Iaculis massa nisl malesuada lacinia integer nunc posuere. Ut hendrerit semper vel class aptent taciti sociosqu. Ad litora torquent per conubia nostra inceptos himenaeos.

Lorem ipsum dolor sit amet consectetur adipiscing elit. Quisque faucibus ex sapien vitae pellentesque sem placerat. In id cursus mi pretium tellus duis convallis. Tempus leo eu aenean sed diam urna tempor. Pulvinar vivamus fringilla lacus nec metus bibendum egestas. Iaculis massa nisl malesuada lacinia integer nunc posuere. Ut hendrerit semper vel class aptent taciti sociosqu. Ad litora torquent per conubia nostra inceptos himenaeos.

Lorem ipsum dolor sit amet consectetur adipiscing elit. Quisque faucibus ex sapien vitae pellentesque sem placerat. In id cursus mi pretium tellus duis convallis. Tempus leo eu aenean sed diam urna tempor. Pulvinar vivamus fringilla lacus nec metus bibendum egestas. Iaculis massa nisl malesuada lacinia integer nunc posuere. Ut hendrerit semper vel class aptent taciti sociosqu. Ad litora torquent per conubia nostra inceptos himenaeos.

Lorem ipsum dolor sit amet consectetur adipiscing elit. Quisque faucibus ex sapien vitae pellentesque sem placerat. In id cursus mi pretium tellus duis convallis. Tempus leo eu aenean sed diam urna tempor. Pulvinar vivamus fringilla lacus nec metus bibendum egestas. Iaculis massa nisl malesuada lacinia integer nunc posuere. Ut hendrerit semper vel class aptent taciti sociosqu. Ad litora torquent per conubia nostra inceptos himenaeos.

Lorem ipsum dolor sit amet consectetur adipiscing elit. Quisque faucibus ex sapien vitae pellentesque sem placerat. In id cursus mi pretium tellus duis convallis. Tempus leo eu aenean sed diam urna tempor. Pulvinar vivamus fringilla lacus nec metus bibendum egestas. Iaculis massa nisl malesuada lacinia integer nunc posuere. Ut hendrerit semper vel class aptent taciti sociosqu. Ad litora torquent per conubia nostra inceptos himenaeos.

Lorem ipsum dolor sit amet consectetur adipiscing elit. Quisque faucibus ex sapien vitae pellentesque sem placerat. In id cursus mi pretium tellus duis convallis. Tempus leo eu aenean sed diam urna tempor. Pulvinar vivamus fringilla lacus nec metus bibendum egestas. Iaculis massa nisl malesuada lacinia integer nunc posuere. Ut hendrerit semper vel class aptent taciti sociosqu. Ad litora torquent per conubia nostra inceptos himenaeos.

Lorem ipsum dolor sit amet consectetur adipiscing elit. Quisque faucibus ex sapien vitae pellentesque sem placerat. In id cursus mi pretium tellus duis convallis. Tempus leo eu aenean sed diam urna tempor. Pulvinar vivamus fringilla lacus nec metus bibendum egestas. Iaculis massa nisl malesuada lacinia integer nunc posuere. Ut hendrerit semper vel class aptent taciti sociosqu. Ad litora torquent per conubia nostra inceptos himenaeos.

Lorem ipsum dolor sit amet consectetur adipiscing elit. Quisque faucibus ex sapien vitae pellentesque sem placerat. In id cursus mi pretium tellus duis convallis. Tempus leo eu aenean sed diam urna tempor. Pulvinar vivamus fringillalacus nec metus bibendum egestas. Iaculis massa nisl malesuada lacinia integer nunc posuere. Ut hendrerit semper vel class aptent taciti sociosqu. Ad litora torquent per conubia nostra inceptos himenaeos.
"""
"""#

struct OneField: Decodable {
    let a: Int
}

struct Config: Codable, Equatable {
    let title: String
    let owner: Owner
    let database: Database
    let servers: Servers

    struct Owner: Codable, Equatable {
        let name: String
        let dob: OffsetDateTime
    }

    struct Database: Codable, Equatable {
        let enabled: Bool
        let ports: [Int]
        let tempTargets: [String: Double]
    }

    struct Servers: Codable, Equatable {
        let alpha: Server
        let beta: Server

        struct Server: Codable, Equatable {
            let ip: String
            let role: String
        }
    }
}
