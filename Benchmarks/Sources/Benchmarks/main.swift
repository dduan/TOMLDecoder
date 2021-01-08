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
  ip = '10.0.0.2'
  dc = 'eqdc10'

# Line breaks are OK when inside arrays
hosts = [
  "alpha",
  "omega"
]
"""

struct LongString: Codable {
    let s: String
}

let longBasicString = #"s = "1979-05-27T07:32:00-08:00 # First class dates""#
let longMultilineString = """
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

let float = "f = 314.15926e-2"
struct AFloat: Codable {
    let f: Double
}

let decoder = TOMLDecoder()

let exampleBenchmarks = BenchmarkSuite(name: "example-toml") { suite in
    suite.benchmark("decoder") {
        precondition((try? decoder.decode(Doc.self, from: toml))?.title == "TOML Example")
    }

    suite.benchmark("combinator") {
        precondition(((try? TOMLDecoder.tomlTable(with: toml))?["title"] as? String) == "TOML Example")
    }

    suite.benchmark("scanner") {
        precondition(((try? TOMLDeserializer.tomlTable(with: toml))?["title"] as? String) == "TOML Example")
    }

    suite.benchmark("c") {
        precondition(
          toml.withCString { ptr in
              toml_parse(UnsafeMutablePointer(mutating: ptr), nil, 0)
          } != nil
        )
    }
}

let longMultilineStringBenchmarks = BenchmarkSuite(name: "long-multiline-string") { suite in
    suite.benchmark("decoder") {
        precondition((try? decoder.decode(LongString.self, from: longMultilineString))?.s.isEmpty == false)
    }

    suite.benchmark("combinator") {
        precondition(((try? TOMLDecoder.tomlTable(with: longMultilineString))?["s"] as? String)?.isEmpty == false)
    }

    suite.benchmark("scanner") {
        precondition(((try? TOMLDeserializer.tomlTable(with: longMultilineString))?["s"] as? String)?.isEmpty == false)
    }

    suite.benchmark("c") {
        precondition(
          longMultilineString.withCString { ptr in
              toml_parse(UnsafeMutablePointer(mutating: ptr), nil, 0)
          } != nil
        )
    }
}

let longBasicStringBenchmarks = BenchmarkSuite(name: "long-basic-string") { suite in
    suite.benchmark("decoder") {
        precondition((try? decoder.decode(LongString.self, from: longBasicString))?.s.isEmpty == false)
    }

    suite.benchmark("combinator") {
        precondition(((try? TOMLDecoder.tomlTable(with: longBasicString))?["s"] as? String)?.isEmpty == false)
    }

    suite.benchmark("scanner") {
        precondition(((try? TOMLDeserializer.tomlTable(with: longBasicString))?["s"] as? String)?.isEmpty == false)
    }

    suite.benchmark("c") {
        precondition(
          longBasicString.withCString { ptr in
              toml_parse(UnsafeMutablePointer(mutating: ptr), nil, 0)
          } != nil
        )
    }
}

let floatBenchmarks = BenchmarkSuite(name: "float") { suite in
    suite.benchmark("decoder") {
        precondition((try? decoder.decode(AFloat.self, from: float)) != nil)
    }

    suite.benchmark("combinator") {
        precondition(((try? TOMLDecoder.tomlTable(with: float))?["f"] as? Double) != nil)
    }

    suite.benchmark("scanner") {
        precondition(((try? TOMLDeserializer.tomlTable(with: float))?["f"] as? Double) != nil)
    }

    suite.benchmark("c") {
        precondition(
          longBasicString.withCString { ptr in
              toml_parse(UnsafeMutablePointer(mutating: ptr), nil, 0)
          } != nil
        )
    }
}

Benchmark.main([
    exampleBenchmarks,
    longMultilineStringBenchmarks,
    longBasicStringBenchmarks,
    floatBenchmarks,
])
