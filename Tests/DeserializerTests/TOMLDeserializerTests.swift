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

    func verifyByFixture(_ fixture: String, file: StaticString = #file, line: UInt = #line) throws {
        let jsonURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)\(fixture).json", isDirectory: false)
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)\(fixture).toml", isDirectory: false)

        do {
            let jsonData = try Data(contentsOf: jsonURL)
            let tomlData = try Data(contentsOf: tomlURL)
            let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
            let tomlTable = try TOMLDeserializer.tomlTable(with: tomlData)
            let doctoredTOMLTable = self.doctor(tomlTable)
            XCTAssert(self.equate(jsonObject, doctoredTOMLTable), file: file, line: line)
        } catch {
            XCTFail("\(error)", file: file, line: line)
        }
    }

    func test_array_empty() throws {
        try verifyByFixture("array-empty")
    }

    func test_array_nospaces() throws {
        try verifyByFixture("array-nospaces")
    }

    func test_array_string_quote_comma_2() throws {
        try verifyByFixture("array-string-quote-comma-2")
    }

    func test_array_string_quote_comma() throws {
        try verifyByFixture("array-string-quote-comma")
    }

    func test_array_string_with_comma() throws {
        try verifyByFixture("array-string-with-comma")
    }

    func test_array_table_array_string_backslash() throws {
        try verifyByFixture("array-table-array-string-backslash")
    }

    func test_arrays_hetergeneous() throws {
        try verifyByFixture("arrays-hetergeneous")
    }

    func test_arrays_nested() throws {
        try verifyByFixture("arrays-nested")
    }

    func test_arrays() throws {
        try verifyByFixture("arrays")
    }

    func test_bool() throws {
        try verifyByFixture("bool")
    }

    func test_comments_at_eof() throws {
        try verifyByFixture("comments-at-eof")
    }

    func test_comments_at_eof2() throws {
        try verifyByFixture("comments-at-eof2")
    }

    func test_comments_everywhere() throws {
        try verifyByFixture("comments-everywhere")
    }

    func test_datetime_timezone() throws {
        try verifyByFixture("datetime-timezone")
    }

    func test_datetime() throws {
        try verifyByFixture("datetime")
    }

    func test_dotted_keys() throws {
        try verifyByFixture("dotted-keys")
    }

    func test_double_quote_escape() throws {
        try verifyByFixture("double-quote-escape")
    }

    func test_empty() throws {
        try verifyByFixture("empty")
    }

    func test_escaped_escape() throws {
        try verifyByFixture("escaped-escape")
    }

    func test_example() throws {
        try verifyByFixture("example")
    }

    func test_exponent_part_float() throws {
        try verifyByFixture("exponent-part-float")
    }

    func test_float_exponent() throws {
        try verifyByFixture("float-exponent")
    }

    func test_float_underscore() throws {
        try verifyByFixture("float-underscore")
    }

    func test_float() throws {
        try verifyByFixture("float")
    }

    func test_implicit_and_explicit_before() throws {
        try verifyByFixture("implicit-and-explicit-before")
    }

    func test_implicit_groups() throws {
        try verifyByFixture("implicit-groups")
    }

    /* the '-' in -nan only prints in Swift 5, re-enable it when migrate
    func test_infinity_and_nan() throws {
        try verifyByFixture("infinity-and-nan")
    }
    */

    func test_inline_table_array() throws {
        try self.verifyByFixture("inline-table-array")
    }

    func test_inline_table() throws {
        try self.verifyByFixture("inline-table")
    }

    func test_integer_underscore() throws {
        try self.verifyByFixture("integer-underscore")
    }

    func test_integer() throws {
        try self.verifyByFixture("integer")
    }

    func test_key_equals_nospace() throws {
        try self.verifyByFixture("key-equals-nospace")
    }

    func test_key_numeric() throws {
        try self.verifyByFixture("key-numeric")
    }

    func test_key_space() throws {
        try self.verifyByFixture("key-space")
    }

    func test_key_special_chars() throws {
        try self.verifyByFixture("key-special-chars")
    }

    func test_keys_with_dots() throws {
        try self.verifyByFixture("keys-with-dots")
    }

    func test_local_date() throws {
        try self.verifyByFixture("local-date")
    }

    func test_local_datetime() throws {
        try self.verifyByFixture("local-datetime")
    }

    func test_local_time() throws {
        try self.verifyByFixture("local-time")
    }

    func test_long_float() throws {
        try self.verifyByFixture("long-float")
    }

    func test_long_integer() throws {
        try self.verifyByFixture("long-integer")
    }

    func test_multiline_string() throws {
        try self.verifyByFixture("multiline-string")
    }

    func test_newline_crlf() throws {
        try self.verifyByFixture("newline-crlf")
    }

    func test_newline_lf() throws {
        try self.verifyByFixture("newline-lf")
    }

    func test_non_dec_integers() throws {
        try self.verifyByFixture("non-dec-integers")
    }

    func test_raw_multiline_string() throws {
        try self.verifyByFixture("raw-multiline-string")
    }

    func test_raw_string() throws {
        try self.verifyByFixture("raw-string")
    }

    func test_string_empty() throws {
        try self.verifyByFixture("string-empty")
    }

    func test_string_escapes() throws {
        try self.verifyByFixture("string-escapes")
    }

    func test_string_nl() throws {
        try self.verifyByFixture("string-nl")
    }

    func test_string_simple() throws {
        try self.verifyByFixture("string-simple")
    }

    func test_string_with_pound() throws {
        try self.verifyByFixture("string-with-pound")
    }

    func test_table_array_implicit() throws {
        try self.verifyByFixture("table-array-implicit")
    }

    func test_table_array_many() throws {
        try self.verifyByFixture("table-array-many")
    }

    func test_table_array_nest() throws {
        try self.verifyByFixture("table-array-nest")
    }

    func test_table_array_one() throws {
        try self.verifyByFixture("table-array-one")
    }

    func test_table_array_table_array() throws {
        try self.verifyByFixture("table-array-table-array")
    }

    func test_table_empty() throws {
        try self.verifyByFixture("table-empty")
    }

    func test_table_no_eol() throws {
        try self.verifyByFixture("table-no-eol")
    }

    func test_table_sub_empty() throws {
        try self.verifyByFixture("table-sub-empty")
    }

    func test_table_whitespace() throws {
        try self.verifyByFixture("table-whitespace")
    }

    func test_table_with_literal_string() throws {
        try self.verifyByFixture("table-with-literal-string")
    }

    func test_table_with_pound() throws {
        try self.verifyByFixture("table-with-pound")
    }

    func test_table_with_single_quotes() throws {
        try self.verifyByFixture("table-with-single-quotes")
    }

    func test_underscored_float() throws {
        try self.verifyByFixture("underscored-float")
    }

    func test_underscored_integer() throws {
        try self.verifyByFixture("underscored-integer")
    }

    func test_unicode_escape() throws {
        try self.verifyByFixture("unicode-escape")
    }

    func test_unicode_literal() throws {
        try self.verifyByFixture("unicode-literal")
    }

    func test_without_super() throws {
        try self.verifyByFixture("without-super")
    }

    func test_table_names() throws {
        try self.verifyByFixture("table-names")
    }
}
