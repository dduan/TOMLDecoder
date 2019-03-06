@testable import TOMLDecoder
import NetTime
import XCTest

final class TOMLDecoderTests: XCTestCase {
    func testBasicGeneratedCodables() throws {
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

        XCTAssertEqual(result, expectation)
    }

    func testDecodingContainerKeyed() throws {
        struct Player: Decodable, Equatable {
            let id: String
            let health: Int64

            enum PlayerKeys: String, CodingKey {
                case id
                case health
            }

            init(id: String, health: Int64) {
                self.id = id
                self.health = health
            }

            init(from decoder: Decoder) throws {
                let values = try decoder.container(keyedBy: PlayerKeys.self)
                self.id = try values.decode(String.self, forKey: .id)
                self.health = try values.decode(Int64.self, forKey: .health)
            }
        }

        let expectation = Player(id: "abc", health: 123)
        let toml = """
        id = "abc"
        health = 123
        """

        let result = try TOMLDecoder().decode(Player.self, from: toml)

        XCTAssertEqual(result, expectation)
    }

    func testNestedUnkeyedDecodingContainer() throws {
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

        XCTAssertEqual(result, expectation)
    }
}
