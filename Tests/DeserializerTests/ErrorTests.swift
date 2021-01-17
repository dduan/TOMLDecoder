import Deserializer
import XCTest

final class ErrorTests: XCTestCase {
    func testSynchronization() {
        let toml = """
        [a
        [b]
        [c
        [d]
        """

        do {
            _ = try TOMLDeserializer.tomlTable(with: toml)
        } catch let error as DeserializationError {
            switch error {
            case .compound(let details):
                XCTAssertEqual(details.count, 2)
            default:
                XCTFail("Unexpected error type")
            }
        } catch {
            XCTFail("Unexpected error type")
        }
    }
}
