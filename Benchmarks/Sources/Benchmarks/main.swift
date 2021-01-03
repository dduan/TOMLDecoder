import Benchmark
import TOMLDecoder
import Foundation
import Ctomlc99
import TOMLDeserializer

struct Doc: Codable {
    let title: String
    let owner: Owner
    let database: Database
    let servers: Servers

    struct Owner: Codable {
        let name: String
        let dob: Date
    }

    struct Database: Codable {
        let server: String
        let ports: [Int]
        let connection_max: Int
        let enabled: Bool
    }

    struct Server: Codable {
        let ip: String
        let dc: String
        let hosts: [String]?
    }

    struct Servers: Codable {
        let alpha: Server
        let beta: Server
    }
}

var toml = """
# This is a TOML document.

title = "TOML Example"

[owner]
name = "Tom Preston-Werner"
dob = 1979-05-27T07:32:00-08:00

[database]
server = "192.168.1.1"
ports = [ 8001, 8001, 8002 ]
connection_max = 5000
enabled = true

[servers]

  # Indentation (tabs and/or spaces) is allowed but not required
  [servers.alpha]
  ip = "10.0.0.1"
  dc = "eqdc10"

  [servers.beta]
  ip = "10.0.0.2"
  dc = "eqdc10"

# Line breaks are OK when inside arrays
hosts = [
  "alpha",
  "omega"
]
"""

struct LongString: Codable {
    let s: String
}

let longString = """
s = \"\"\"
# This is a TOML document.

title = "TOML Example"

[owner]
name = "Tom Preston-Werner"
dob = 1979-05-27T07:32:00-08:00 # First class dates

[database]
server = "192.168.1.1"
ports = [ 8001, 8001, 8002 ]
connection_max = 5000
enabled = true

[servers]

  # Indentation (tabs and/or spaces) is allowed but not required
  [servers.alpha]
  ip = "10.0.0.1"
  dc = "eqdc10"

  [servers.beta]
  ip = "10.0.0.2"
  dc = "eqdc10"

# Line breaks are OK when inside arrays
hosts = [
  "alpha",
  "omega"
]
\"\"\"
"""

let deserializationBenchmarks = BenchmarkSuite(name: "deserialing") { suite in
    let decoder = TOMLDecoder()
    suite.benchmark("example-toml") {
        precondition((try? decoder.decode(Doc.self, from: toml))?.title == "TOML Example")
    }

    suite.benchmark("long-string") {
        precondition((try? decoder.decode(LongString.self, from: longString))?.s.isEmpty == false)
    }
}

let decodingBenchmarks = BenchmarkSuite(name: "decoding") { suite in
    suite.benchmark("example-toml") {
        precondition(((try? TOMLDecoder.tomlTable(with: toml))?["title"] as? String) == "TOML Example")
    }

    suite.benchmark("long-string") {
        precondition(((try? TOMLDecoder.tomlTable(with: longString))?["s"] as? String)?.isEmpty == false)
    }
}

let scannerDecodingBenchmarks = BenchmarkSuite(name: "decoding-scanner") { suite in
    suite.benchmark("example-toml") {
        precondition(((try? TOMLDeserializer.tomlTable(with: toml))?["title"] as? String) == "TOML Example")
    }

    suite.benchmark("long-string") {
        precondition(((try? TOMLDeserializer.tomlTable(with: longString))?["s"] as? String)?.isEmpty == false)
    }
}

let libtomlDecodingBenchmarks = BenchmarkSuite(name: "decoding-libtoml") { suite in
    suite.benchmark("example-toml") {
        precondition(
          toml.withCString { ptr in
              toml_parse(UnsafeMutablePointer(mutating: ptr), nil, 0)
          } != nil
        )
    }

    suite.benchmark("long-string") {
        precondition(
          longString.withCString { ptr in
              toml_parse(UnsafeMutablePointer(mutating: ptr), nil, 0)
          } != nil
        )
    }
}

Benchmark.main([
    deserializationBenchmarks,
    decodingBenchmarks,
    scannerDecodingBenchmarks,
    libtomlDecodingBenchmarks,
])
