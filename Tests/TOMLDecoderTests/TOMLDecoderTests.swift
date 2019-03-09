@testable import TOMLDecoder
import Foundation
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

    func testnormalIntegerDecodingStrategy() throws {
        struct Player: Codable, Equatable {
            let id: String
            let health: Int
        }

        let toml = """
        id = "abc"
        health = 123
        """

        let decoder = TOMLDecoder()
        decoder.numberDecodingStrategy = .strict
        XCTAssertThrowsError(try decoder.decode(Player.self, from: toml))
    }

    func testNetTimeDateDecoding() throws {
        struct Player: Codable, Equatable {
            let id: String
            let health: Int64
            let signUpDate: DateTime
            let favoriteDate: LocalDate
            let favoriteTime: LocalTime
            let favoriteLocalDateTime: LocalDateTime
        }

        let date = LocalDate(year: 2019, month: 3, day: 08)!
        let time = LocalTime(hour: 21, minute: 57, second: 0)!
        let offset = TimeOffset(sign: .plus, hour: 0, minute: 0)!
        let dateTime = DateTime(date: date, time: time, utcOffset: offset)
        let localDateTime = LocalDateTime(date: date, time: time)
        let expectation = Player(id: "abc", health: 123, signUpDate: dateTime, favoriteDate: date,
                                 favoriteTime: time, favoriteLocalDateTime: localDateTime)

        let toml = """
        id = "abc"
        health = 123
        signUpDate = 2019-03-08 21:57:00Z
        favoriteDate = 2019-03-08
        favoriteTime = 21:57:00
        favoriteLocalDateTime = 2019-03-08 21:57:00
        """

        let decoder = TOMLDecoder()
        let result = try decoder.decode(Player.self, from: toml)

        XCTAssertEqual(result, expectation)
    }

    func testFoundationDateDecoding() throws {
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

        XCTAssertEqual(result, expectation)
    }

    func testFoundationDateComponentsFromLocalDateDecoding() throws {
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

        XCTAssertEqual(result, expectation)
    }

    func testFoundationDateComponentsFromLocalTimeDecoding() throws {
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

        XCTAssertEqual(result, expectation)
    }

    func testFoundationDateComponentsFromLocalDateTimeDecoding() throws {
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

        XCTAssertEqual(result, expectation)
    }

    func testFoundationDateDecodingWithStrictStrategy() throws {
        struct Player: Codable, Equatable {
            let id: String
            let signUpDate: Date
        }

        let toml = """
        id = "abc"
        signUpDate = 2001-01-01 00:00:00Z
        """

        let decoder = TOMLDecoder()
        decoder.dateDecodingStrategy = .strict
        XCTAssertThrowsError(try decoder.decode(Player.self, from: toml))
    }

    func testDecodingFoundationDataWithCustom() throws {
        struct Payload: Codable, Equatable {
            let id: String
            let body: Data
        }

        let expectation = Payload(id: "abc", body: "def".data(using: .utf8)!)
        let toml = """
        id = 'abc'
        body = 'def'
        """

        let decoder = TOMLDecoder()
        decoder.dataDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            return try container.decode(String.self).data(using: .utf8)!
        }

        let result = try decoder.decode(Payload.self, from: toml)

        XCTAssertEqual(result, expectation)
    }

    func testDecodingFoundationDataWithBase64() throws {
        struct Payload: Codable, Equatable {
            let id: String
            let body: Data
        }

        let base64Data = "aGVsbG8sIHdvcmxkIQ=="
        let body = Data(base64Encoded: base64Data)!
        let expectation = Payload(id: "abc", body: body)
        let toml = """
        id = 'abc'
        body = '\(base64Data)'
        """

        let decoder = TOMLDecoder()
        let result = try decoder.decode(Payload.self, from: toml)

        XCTAssertEqual(result, expectation)
    }

    func testDecodingSnakeCaseKeyStrategy() throws {
        struct Player: Codable, Equatable {
            let id: String
            let firstProfession: String
        }

        let expectation = Player(id: "abc", firstProfession: "Cook")

        let toml = """
        id = "abc"
        first_profession = "Cook"
        """

        let decoder = TOMLDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let result = try decoder.decode(Player.self, from: toml)

        XCTAssertEqual(result, expectation)
    }

    func testDecodingCustomKeyStrategy() throws {
        struct Player: Codable, Equatable {
            let id: String
            let profession: String
        }

        let expectation = Player(id: "abc", profession: "Cook")

        let toml = """
        id = "abc"
        PROFESSION = "Cook"
        """

        let decoder = TOMLDecoder()
        decoder.keyDecodingStrategy = .custom { codingPath in
            let key = codingPath.last!
            return type(of: key).init(stringValue: key.stringValue.lowercased())!
        }

        let result = try decoder.decode(Player.self, from: toml)

        XCTAssertEqual(result, expectation)
    }
}
