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
}
