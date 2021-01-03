import Foundation
import Deserializer
import XCTest

final class TOMLDeserializerTests: XCTestCase {
    private var directory: String {
        return "/" + #file.split(separator: "/").dropLast().joined(separator: "/")
    }
    func formatDateComponent(_ dc: DateComponents) -> String {
        func pad(_ i: Int) -> String {
            i < 10 ? "0\(i)" : "\(i)"
        }
        var datePart = ""
        if dc.year != nil {
            datePart = "\(dc.year!)-\(pad(dc.month!))-\(pad(dc.day!))"
        }

        var timePart = ""
        if dc.hour != nil {
            timePart = "\(pad(dc.hour!)):\(pad(dc.minute!)):\(pad(dc.second!))"
        }

        if dc.nanosecond != nil {
            timePart += ".\(String(Double(dc.nanosecond!) / 1_000_000_000).dropFirst(2))"
        }

        switch (datePart.isEmpty, timePart.isEmpty) {
        case (false, false):
            return "\(datePart)T\(timePart)"
        case (true, false):
            return timePart
        default:
            return datePart
        }
    }
    private let dateFormatter = ISO8601DateFormatter()
    private func doctor(_ table: [String: Any]) -> [String: Any] {
        func stringify(_ value: Any) -> Any {
            if let table = value as? [String: Any] {
                return table.reduce(into: [String: Any]()) { $0[$1.key] = stringify($1.value) }
            }

            if let array = value as? [Any] {
                return array.reduce(into: [Any]()) { $0.append(stringify($1)) }
            }

            if let date = value as? Date {
                return dateFormatter.string(from: date)
            }

            if let components = value as? DateComponents {
                return formatDateComponent(components)
            }

            return "\(value)"
        }

        return stringify(table) as! [String: Any]
    }

    private func equate(_ a: Any, _ b: Any) -> Bool {
        if let a = a as? [String: Any], let b = b as? [String: Any] {
            for (k, v) in a {
                guard let bV = b[k] else {
                    return false
                }

                if !self.equate(v, bV) {
                    return false
                }
            }

            return true
        } else if let a = a as? [Any], let b = b as? [Any] {
            if a.count != b.count {
                return false
            }

            for (aV, bV) in zip(a, b) {
                if !self.equate(aV, bV) {
                    return false
                }
            }

            return true
        } else if let a = a as? String, let b = b as? String {
            if a != b {
                print("\(a) != \(b)")
                return false
            }
            return true
        } else {
            return false
        }
    }

    func test_array_empty() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/array-empty.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/array-empty.toml", isDirectory: false)
        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_array_nospaces() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/array-nospaces.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/array-nospaces.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_array_string_quote_comma_2() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/array-string-quote-comma-2.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/array-string-quote-comma-2.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_array_string_quote_comma() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/array-string-quote-comma.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/array-string-quote-comma.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_array_string_with_comma() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/array-string-with-comma.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/array-string-with-comma.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_array_table_array_string_backslash() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/array-table-array-string-backslash.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/array-table-array-string-backslash.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_arrays_hetergeneous() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/arrays-hetergeneous.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/arrays-hetergeneous.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_arrays_nested() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/arrays-nested.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/arrays-nested.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_arrays() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/arrays.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/arrays.toml", isDirectory: false)
        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_bool() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/bool.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/bool.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_comments_at_eof() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/comments-at-eof.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/comments-at-eof.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_comments_at_eof2() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/comments-at-eof2.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/comments-at-eof2.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_comments_everywhere() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/comments-everywhere.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/comments-everywhere.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_datetime_timezone() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/datetime-timezone.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/datetime-timezone.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_datetime() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/datetime.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/datetime.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_dotted_keys() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/dotted-keys.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/dotted-keys.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_double_quote_escape() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/double-quote-escape.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/double-quote-escape.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_empty() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/empty.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/empty.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_escaped_escape() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/escaped-escape.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/escaped-escape.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_example() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/example.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/example.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_exponent_part_float() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/exponent-part-float.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/exponent-part-float.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_float_exponent() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/float-exponent.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/float-exponent.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_float_underscore() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/float-underscore.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/float-underscore.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_float() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/float.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/float.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_implicit_and_explicit_before() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/implicit-and-explicit-before.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/implicit-and-explicit-before.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_implicit_groups() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/implicit-groups.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/implicit-groups.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    /* the '-' in -nan only prints in Swift 5, re-enable it when migrate
    func test_infinity_and_nan() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/infinity-and-nan.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/infinity-and-nan.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }
    */

    func test_inline_table_array() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/inline-table-array.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/inline-table-array.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_inline_table() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/inline-table.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/inline-table.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_integer_underscore() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/integer-underscore.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/integer-underscore.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_integer() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/integer.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/integer.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_key_equals_nospace() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/key-equals-nospace.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/key-equals-nospace.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_key_numeric() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/key-numeric.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/key-numeric.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_key_space() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/key-space.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/key-space.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_key_special_chars() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/key-special-chars.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/key-special-chars.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_keys_with_dots() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/keys-with-dots.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/keys-with-dots.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_local_date() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/local-date.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/local-date.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_local_datetime() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/local-datetime.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/local-datetime.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_local_time() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/local-time.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/local-time.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_long_float() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/long-float.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/long-float.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_long_integer() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/long-integer.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/long-integer.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_multiline_string() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/multiline-string.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/multiline-string.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_newline_crlf() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/newline-crlf.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/newline-crlf.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_newline_lf() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/newline-lf.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/newline-lf.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_non_dec_integers() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/non-dec-integers.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/non-dec-integers.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        do {
            let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
            let doctoredTOMLTable = self.doctor(tomlTable)
            XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
        } catch let error {
            print(error)
        }

    }

    func test_raw_multiline_string() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/raw-multiline-string.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/raw-multiline-string.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_raw_string() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/raw-string.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/raw-string.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_string_empty() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/string-empty.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/string-empty.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_string_escapes() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/string-escapes.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/string-escapes.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_string_nl() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/string-nl.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/string-nl.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_string_simple() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/string-simple.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/string-simple.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_string_with_pound() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/string-with-pound.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/string-with-pound.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_table_array_implicit() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/table-array-implicit.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/table-array-implicit.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_table_array_many() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/table-array-many.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/table-array-many.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_table_array_nest() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/table-array-nest.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/table-array-nest.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_table_array_one() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/table-array-one.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/table-array-one.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_table_array_table_array() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/table-array-table-array.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/table-array-table-array.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_table_empty() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/table-empty.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/table-empty.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_table_no_eol() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/table-no-eol.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/table-no-eol.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_table_sub_empty() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/table-sub-empty.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/table-sub-empty.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_table_whitespace() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/table-whitespace.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/table-whitespace.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_table_with_literal_string() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/table-with-literal-string.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/table-with-literal-string.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_table_with_pound() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/table-with-pound.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/table-with-pound.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_table_with_single_quotes() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/table-with-single-quotes.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/table-with-single-quotes.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_underscored_float() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/underscored-float.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/underscored-float.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_underscored_integer() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/underscored-integer.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/underscored-integer.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_unicode_escape() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/unicode-escape.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/unicode-escape.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_unicode_literal() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/unicode-literal.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/valid_fixtures/unicode-literal.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }
}
