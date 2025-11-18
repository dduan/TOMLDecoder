import Benchmark
import TOMLDecoder

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration = .init(
        metrics: [.wallClock, .cpuTotal, .instructions, .retainCount],
        timeUnits: .nanoseconds,
    )

    Benchmark("Parse one field") { benchmark in
        let toml = """
        a = 2
        """
        benchmark.startMeasurement()
        blackHole(try TOMLTable(source: toml))
    }

    Benchmark("Decode one field") { benchmark in
        struct OneField: Decodable {
            let a: Int
        }

        let toml = """
        a = 2
        """
        let decoder = TOMLDecoder()
        benchmark.startMeasurement()
        blackHole(try decoder.decode(OneField.self, from: toml))
    }

    Benchmark("Parse toml.io example") { benchmark in
        let toml = """
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
        benchmark.startMeasurement()
        let result = try TOMLTable(source: toml)
        blackHole(result)
    }

    Benchmark("Decode toml.io example") { benchmark in
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

        let toml = """
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
        var decoder = TOMLDecoder()
        decoder.strategy.key = .convertFromSnakeCase
        benchmark.startMeasurement()
        blackHole(try decoder.decode(Config.self, from: toml))
    }
}
