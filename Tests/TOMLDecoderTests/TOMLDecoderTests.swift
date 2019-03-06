@testable import TOMLDecoder
import NetTime
import XCTest


final class TOMLDecoderTests: XCTestCase {
    func testExample() throws {
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


    static var allTests = [
        ("testExample", testExample),
    ]
}
