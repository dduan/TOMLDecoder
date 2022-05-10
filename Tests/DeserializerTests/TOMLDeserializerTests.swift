import Foundation
import Deserializer
import XCTest

#if os(Windows)
private let kSeparator: Character = "\\"
#else
private let kSeparator: Character = "/"
#endif

@available(iOS 10.0, *)
@available(macOS 10.12, *)
final class TOMLDeserializerTests: XCTestCase {
    private var directory: String {
        (
            (#file.first == "/" ? [""] : [])
                + #file.split(separator: kSeparator).dropLast()
                + ["valid_fixtures"]
        )
            .joined(separator: "\(kSeparator)")
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

            // On Windows, `\n` in a file will become '\r\n'. This is handled in our TOML parser correctly,
            // but here we need to handle it separately.
            return "\(value)".replacingOccurrences(of: "\r\n", with: "\n")
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
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)array-empty.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)array-empty.toml", isDirectory: false)
        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_array_nospaces() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)array-nospaces.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)array-nospaces.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_array_string_quote_comma_2() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)array-string-quote-comma-2.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)array-string-quote-comma-2.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_array_string_quote_comma() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)array-string-quote-comma.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)array-string-quote-comma.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_array_string_with_comma() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)array-string-with-comma.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)array-string-with-comma.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_array_table_array_string_backslash() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)array-table-array-string-backslash.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)array-table-array-string-backslash.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_arrays_hetergeneous() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)arrays-hetergeneous.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)arrays-hetergeneous.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_arrays_nested() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)arrays-nested.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)arrays-nested.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_arrays() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)arrays.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)arrays.toml", isDirectory: false)
        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_bool() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)bool.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)bool.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_comments_at_eof() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)comments-at-eof.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)comments-at-eof.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_comments_at_eof2() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)comments-at-eof2.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)comments-at-eof2.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_comments_everywhere() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)comments-everywhere.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)comments-everywhere.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_datetime_timezone() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)datetime-timezone.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)datetime-timezone.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_datetime() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)datetime.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)datetime.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_dotted_keys() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)dotted-keys.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)dotted-keys.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_double_quote_escape() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)double-quote-escape.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)double-quote-escape.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_empty() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)empty.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)empty.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_escaped_escape() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)escaped-escape.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)escaped-escape.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_example() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)example.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)example.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_exponent_part_float() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)exponent-part-float.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)exponent-part-float.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_float_exponent() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)float-exponent.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)float-exponent.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_float_underscore() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)float-underscore.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)float-underscore.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_float() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)float.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)float.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_implicit_and_explicit_before() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)implicit-and-explicit-before.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)implicit-and-explicit-before.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_implicit_groups() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)implicit-groups.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)implicit-groups.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    /* the '-' in -nan only prints in Swift 5, re-enable it when migrate
    func test_infinity_and_nan() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)infinity-and-nan.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)infinity-and-nan.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }
    */

    func test_inline_table_array() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)inline-table-array.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)inline-table-array.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_inline_table() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)inline-table.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)inline-table.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_integer_underscore() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)integer-underscore.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)integer-underscore.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_integer() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)integer.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)integer.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_key_equals_nospace() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)key-equals-nospace.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)key-equals-nospace.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_key_numeric() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)key-numeric.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)key-numeric.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_key_space() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)key-space.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)key-space.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_key_special_chars() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)key-special-chars.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)key-special-chars.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_keys_with_dots() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)keys-with-dots.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)keys-with-dots.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_local_date() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)local-date.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)local-date.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_local_datetime() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)local-datetime.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)local-datetime.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_local_time() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)local-time.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)local-time.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_long_float() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)long-float.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)long-float.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_long_integer() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)long-integer.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)long-integer.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_multiline_string() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)multiline-string.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)multiline-string.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_newline_crlf() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)newline-crlf.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)newline-crlf.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_newline_lf() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)newline-lf.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)newline-lf.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_non_dec_integers() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)non-dec-integers.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)non-dec-integers.toml", isDirectory: false)

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
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)raw-multiline-string.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)raw-multiline-string.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_raw_string() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)raw-string.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)raw-string.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_string_empty() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)string-empty.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)string-empty.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_string_escapes() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)string-escapes.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)string-escapes.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_string_nl() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)string-nl.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)string-nl.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_string_simple() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)string-simple.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)string-simple.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_string_with_pound() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)string-with-pound.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)string-with-pound.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_table_array_implicit() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)table-array-implicit.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)table-array-implicit.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_table_array_many() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)table-array-many.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)table-array-many.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_table_array_nest() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)table-array-nest.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)table-array-nest.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_table_array_one() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)table-array-one.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)table-array-one.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_table_array_table_array() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)table-array-table-array.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)table-array-table-array.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_table_empty() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)table-empty.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)table-empty.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_table_no_eol() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)table-no-eol.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)table-no-eol.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_table_sub_empty() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)table-sub-empty.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)table-sub-empty.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_table_whitespace() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)table-whitespace.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)table-whitespace.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_table_with_literal_string() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)table-with-literal-string.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)table-with-literal-string.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_table_with_pound() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)table-with-pound.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)table-with-pound.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_table_with_single_quotes() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)table-with-single-quotes.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)table-with-single-quotes.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_underscored_float() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)underscored-float.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)underscored-float.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_underscored_integer() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)underscored-integer.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)underscored-integer.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_unicode_escape() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)unicode-escape.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)unicode-escape.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }

    func test_unicode_literal() throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)unicode-literal.json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)unicode-literal.toml", isDirectory: false)

        let jsonData = try Data(contentsOf: jsonURL)
        let tomlData = try Data(contentsOf: tomlURL)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
        let doctoredTOMLTable = self.doctor(tomlTable)
        XCTAssert(self.equate(jsonObject, doctoredTOMLTable))
    }
}
