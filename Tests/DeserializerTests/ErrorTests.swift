import Deserializer
import XCTest
import Testing

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

    func testMissingFloatFraction() {
        let toml = """
        a = 1.
        b = 2
        """

        do {
            _ = try TOMLDeserializer.tomlTable(with: toml)
        } catch let error as DeserializationError {
            guard case .value(let description) = error else {
                XCTFail("Unexpected error type")
                return
            }

            XCTAssertEqual(description.line, 1)
            XCTAssertEqual(description.text, "Floating number missing fraction")
        } catch {
            XCTFail("Unexpected error type")
        }
    }

    func testTableMissingClosing() {
        let toml = """
        [a
        b = 2
        """

        do {
            _ = try TOMLDeserializer.tomlTable(with: toml)
        } catch let error as DeserializationError {
            guard case .structural(let description) = error else {
                XCTFail("Unexpected error type")
                return
            }

            XCTAssertEqual(description.line, 1)
            XCTAssertEqual(description.text, "Missing closing character `]` in table")
        } catch {
            XCTFail("Unexpected error type")
        }
    }

    func testArrayTableMissingClosing() {
        let toml = """
        [[a
        b = 2
        """

        do {
            _ = try TOMLDeserializer.tomlTable(with: toml)
        } catch let error as DeserializationError {
            guard case .structural(let description) = error else {
                XCTFail("Unexpected error type")
                return
            }

            XCTAssertEqual(description.line, 1)
            XCTAssertEqual(description.text, "Missing closing character `]]` in array table")
        } catch {
            XCTFail("Unexpected error type")
        }
    }

    func testLiteralStringMissingClosing() {
        let toml = """
        a = '1
        b = '2'
        """

        do {
            _ = try TOMLDeserializer.tomlTable(with: toml)
        } catch let error as DeserializationError {
            guard case .value(let description) = error else {
                XCTFail("Unexpected error type")
                return
            }

            XCTAssertEqual(description.line, 1)
            XCTAssertEqual(description.text, "Missing closing character `'` in literal string")
        } catch {
            XCTFail("Unexpected error type")
        }
    }

    func testBasicStringMissingClosing() {
        let toml = """
        a = "1
        b = "2"
        """

        do {
            _ = try TOMLDeserializer.tomlTable(with: toml)
        } catch let error as DeserializationError {
            print(error)
            guard case .value(let description) = error else {
                XCTFail("Unexpected error type")
                return
            }

            XCTAssertEqual(description.line, 1)
            XCTAssertEqual(description.text, "Missing closing character `\"` in string")
        } catch {
            XCTFail("Unexpected error type")
        }
    }

    func testMultilineBasicStringMissingClosing() {
        let toml = #"""
        a = """1
        b = "2"
        """#

        do {
            _ = try TOMLDeserializer.tomlTable(with: toml)
        } catch let error as DeserializationError {
            print(error)
            guard case .value(let description) = error else {
                XCTFail("Unexpected error type")
                return
            }

            XCTAssertEqual(description.line, 1)
            XCTAssertEqual(description.text, #"Missing closing character `"""` in multiline string"#)
        } catch {
            XCTFail("Unexpected error type")
        }
    }

    func testMultilineLiteralStringMissingClosing() {
        let toml = #"""
        a = '''1'
        b = "2"
        """#

        do {
            _ = try TOMLDeserializer.tomlTable(with: toml)
        } catch let error as DeserializationError {
            print(error)
            guard case .value(let description) = error else {
                XCTFail("Unexpected error type")
                return
            }

            XCTAssertEqual(description.line, 1)
            XCTAssertEqual(description.text, "Missing closing character `'''` in multiline literal string")
        } catch {
            XCTFail("Unexpected error type")
        }
    }
}
