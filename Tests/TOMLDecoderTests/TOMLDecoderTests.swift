import Testing
@testable import TOMLDecoder
import Foundation

@Suite
struct TOMLDecoderTests {
    @Test func `basic generated codables`() throws {
        struct Player: Codable, Equatable {
            let id: String
            let health: Int64
        }

        struct Team: Codable, Equatable {
            let players: [Player]
        }

        let expectation = Team(players: [
            Player(id: "abc", health: 123),
            Player(id: "cde", health: 456),
        ])
        let toml = """
        [[players]]

        id = "abc"
        health = 123

        [[players]]

        id = "cde"
        health = 456
        """

        let result = try TOMLDecoder().decode(Team.self, from: toml)

        #expect(result == expectation)
    }

    @Test func `decoding container keyed`() throws {
        struct Player: Decodable, Equatable {
            let id: String
            let health: Int64
            let pi: Double

            enum PlayerKeys: String, CodingKey {
                case id
                case health
                case pi
            }

            init(id: String, health: Int64, pi: Double) {
                self.id = id
                self.health = health
                self.pi = pi
            }

            init(from decoder: Decoder) throws {
                let values = try decoder.container(keyedBy: PlayerKeys.self)
                self.id = try values.decode(String.self, forKey: .id)
                self.health = try values.decode(Int64.self, forKey: .health)
                self.pi = try values.decode(Double.self, forKey: .pi)
            }
        }

        let expectation = Player(id: "abc", health: 123, pi: 3.14)
        let toml = """
        id = "abc"
        health = 123
        pi = 3.14
        """

        let result = try TOMLDecoder().decode(Player.self, from: toml)

        #expect(result == expectation)
    }

    @Test func `nested unkeyed decoding container`() throws {
        struct Player: Decodable, Equatable {
            let id: String
            let health: Int64
        }

        struct Team: Decodable, Equatable {
            let players: [Player]

            enum Keys: String, CodingKey {
                case players
            }

            init(from decoder: Decoder) throws {
                var values = try decoder.container(keyedBy: Keys.self)
                    .nestedUnkeyedContainer(forKey: .players)

                var players = [Player]()
                while !values.isAtEnd {
                    try players.append(values.decode(Player.self))
                }

                self.players = players
            }

            init(players: [Player]) {
                self.players = players
            }
        }

        let expectation = Team(players: [
            Player(id: "abc", health: 123),
            Player(id: "cde", health: 456),
        ])

        let toml = """
        [[players]]

        id = "abc"
        health = 123

        [[players]]

        id = "cde"
        health = 456
        """

        let result = try TOMLDecoder().decode(Team.self, from: toml)

        #expect(result == expectation)
    }

    @Test func `lenient integer decoding strategy`() throws {
        struct Player: Codable, Equatable {
            let id: String
            let health: Int
        }

        let toml = """
        id = "abc"
        health = 123
        """

        var decoder = TOMLDecoder()
        decoder.isLenient = false
        #expect(throws: (any Error).self) {
            try decoder.decode(Player.self, from: toml)
        }
    }

    @Test
    func `foundation date decoding`() throws {
        struct Player: Codable, Equatable {
            let id: String
            let signUpDate: Date
        }

        let expectation = Player(id: "abc", signUpDate: Date(timeIntervalSinceReferenceDate: 0))

        let toml = """
        id = "abc"
        signUpDate = 2001-01-01 00:00:00Z
        """

        let decoder = TOMLDecoder()
        let result = try decoder.decode(Player.self, from: toml)

        #expect(result == expectation)
    }

    @Test
    func `foundation date components from local date decoding`() throws {
        struct Player: Codable, Equatable {
            let id: String
            let signUpDate: DateComponents
        }

        let expectation = Player(id: "abc", signUpDate: DateComponents(year: 2001, month: 1, day: 1))

        let toml = """
        id = "abc"
        signUpDate = 2001-01-01
        """

        let decoder = TOMLDecoder()
        let result = try decoder.decode(Player.self, from: toml)

        #expect(result == expectation)
    }

    @Test
    func `foundation date components from local time decoding`() throws {
        struct Player: Codable, Equatable {
            let id: String
            let signUpTime: DateComponents
        }

        let expectation = Player(id: "abc", signUpTime: DateComponents(hour: 1, minute: 2, second: 3))

        let toml = """
        id = "abc"
        signUpTime = 01:02:03
        """

        let decoder = TOMLDecoder()
        let result = try decoder.decode(Player.self, from: toml)

        #expect(result == expectation)
    }

    @Test
    func `foundation date components from local datetime decoding`() throws {
        struct Player: Codable, Equatable {
            let id: String
            let signUpTime: DateComponents
        }

        let expectation = Player(id: "abc", signUpTime: DateComponents(year: 2001, month: 1, day: 1, hour: 1,
                                                                       minute: 2, second: 3))

        let toml = """
        id = "abc"
        signUpTime = 2001-01-01 01:02:03
        """

        let decoder = TOMLDecoder()
        let result = try decoder.decode(Player.self, from: toml)

        #expect(result == expectation)
    }

    @Test func `decoding snake case key strategy`() throws {
        struct Player: Codable, Equatable {
            let id: String
            let firstProfession: String
        }

        let expectation = Player(id: "abc", firstProfession: "Cook")

        let toml = """
        id = "abc"
        first_profession = "Cook"
        """

        var decoder = TOMLDecoder()
        decoder.strategy.key = .convertFromSnakeCase
        let result = try decoder.decode(Player.self, from: toml)

        #expect(result == expectation)
    }

    @Test func `decoding custom key strategy`() throws {
        struct Player: Codable, Equatable {
            let id: String
            let profession: String
        }

        let expectation = Player(id: "abc", profession: "Cook")

        let toml = """
        id = "abc"
        PROFESSION = "Cook"
        """

        var decoder = TOMLDecoder()
        decoder.strategy.key = .custom { $0.lowercased() }

        let result = try decoder.decode(Player.self, from: toml)

        #expect(result == expectation)
    }

    @Test func `array of strings parsing`() throws {
        struct AppConfig: Codable, Equatable {
            let name: String
            let version: String
            let features: [String]
            let database: DatabaseConfig

            struct DatabaseConfig: Codable, Equatable {
                let host: String
                let port: Int
                let username: String
            }
        }

        let expectation = AppConfig(
            name: "Sample App",
            version: "1.0.0",
            features: ["logging", "monitoring", "caching"],
            database: AppConfig.DatabaseConfig(
                host: "localhost",
                port: 5432,
                username: "admin"
            )
        )

        let toml = """
        name = "Sample App"
        version = "1.0.0"
        features = ["logging", "monitoring", "caching"]

        [database]
        host = "localhost"
        port = 5432
        username = "admin"
        """

        let result = try TOMLDecoder().decode(AppConfig.self, from: toml)

        #expect(result == expectation)
    }

    @Test func `super decoder`() throws {
        class Player: Codable {
            let id: String
            let health: Int
        }

        final class LocalPlayer: Player {
            let ip: String

            private enum CodingKeys: String, CodingKey {
                case ip
            }

            required init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.ip = try container.decode(String.self, forKey: .ip)
                let superDecoder = try container.superDecoder()
                try super.init(from: superDecoder)
            }
        }

        let toml = """
        id = "abc"
        health = 123
        ip = "127.0.0.1"
        """

        let decoder = TOMLDecoder()
        _ = try decoder.decode(LocalPlayer.self, from: toml)
    }

    @Test func `toml.io example`() throws {
        let toml = """
            # This is a TOML document

            title = "TOML Example"

            [owner]
            name = "Tom Preston-Werner"
            dob = 1979-05-27T07:32:00-08:00

            [database]
            enabled = true
            ports = [ 8000, 8001, 8002 ]
            temp_targets = { cpu = 79.5, case = 72.0 }

            [servers]

            [servers.alpha]
            ip = "10.0.0.1"
            role = "frontend"

            [servers.beta]
            ip = "10.0.0.2"
            role = "backend"
            """

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

        let expectation = Config(
            title: "TOML Example",
            owner: .init(
                name: "Tom Preston-Werner",
                dob: OffsetDateTime(
                    date: LocalDate(year: 1979, month: 5, day: 27),
                    time: LocalTime(hour: 7, minute: 32, second: 0, nanosecond: 0),
                    offset: -480,
                    features: [.uppercaseT]
                ),
            ),
            database: .init(
                enabled: true,
                ports: [8000, 8001, 8002],
                tempTargets: ["cpu": 79.5, "case": 72.0]
            ),
            servers: .init(
                alpha: .init(ip: "10.0.0.1", role: "frontend"),
                beta: .init(ip: "10.0.0.2", role: "backend")
            )
        )

        var decoder = TOMLDecoder()
        decoder.strategy.key = .convertFromSnakeCase
        let result = try decoder.decode(Config.self, from: toml)

        #expect(result == expectation)
    }

    @Test func `mixing containers`() throws {
        struct Test: Decodable, Equatable {
            let numbers: [[Int64]]
            let strings: TOMLArray
            let doubles: [TOMLArray]
            let tableInArray: [TOMLTable]
            let tableInTable: [String: TOMLTable]
        }

        let toml = """
            numbers = [[1, 2], [3, 4]]
            strings = [["a", "b"], ["c", "d"]]
            doubles = [[1.2]]
            tableInArray = [{a = 1}]
            tableInTable = { b = { c = "yo" } }
            """

        let result = try TOMLDecoder().decode(Test.self, from: toml)

        #expect(result.numbers == [[1, 2], [3, 4]])
    }
}
