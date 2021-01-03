import XCTest
import TOMLDeserializer

final class TOMLInvalidationTests: XCTestCase {
    private var directory: String {
        return "/" + #file.split(separator: "/").dropLast().joined(separator: "/")
    }

    func test_array_of_tables_1() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/array-of-tables-1.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_array_of_tables_2() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/array-of-tables-2.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_bare_key_1() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/bare-key-1.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_bare_key_2() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/bare-key-2.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_bare_key_3() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/bare-key-3.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_datetime_malformed_no_leads() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/datetime-malformed-no-leads.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_datetime_malformed_no_secs() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/datetime-malformed-no-secs.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_datetime_malformed_no_t() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/datetime-malformed-no-t.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_datetime_malformed_with_milli() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/datetime-malformed-with-milli.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_duplicate_key_table() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/duplicate-key-table.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_duplicate_keys() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/duplicate-keys.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_duplicate_tables() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/duplicate-tables.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_empty_implicit_table() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/empty-implicit-table.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_empty_table() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/empty-table.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_float_leading_zero_neg() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/float-leading-zero-neg.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_float_leading_zero_pos() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/float-leading-zero-pos.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_float_leading_zero() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/float-leading-zero.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_float_no_leading_zero() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/float-no-leading-zero.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_float_no_trailing_digits() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/float-no-trailing-digits.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_float_underscore_after_point() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/float-underscore-after-point.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_float_underscore_after() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/float-underscore-after.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_float_underscore_before_point() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/float-underscore-before-point.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_float_underscore_before() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/float-underscore-before.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_inline_table_linebreak() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/inline-table-linebreak.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_int_0_padded() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/int-0-padded.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_integer_leading_zero_neg() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/integer-leading-zero-neg.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_integer_leading_zero_pos() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/integer-leading-zero-pos.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_integer_leading_zero() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/integer-leading-zero.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_integer_underscore_after() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/integer-underscore-after.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_integer_underscore_before() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/integer-underscore-before.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_integer_underscore_double() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/integer-underscore-double.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_key_after_array() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/key-after-array.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_key_after_table() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/key-after-table.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_key_empty() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/key-empty.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_key_hash() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/key-hash.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_key_newline() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/key-newline.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_key_no_eol() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/key-no-eol.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_key_open_bracket() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/key-open-bracket.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_key_single_open_bracket() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/key-single-open-bracket.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_key_space() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/key-space.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_key_start_bracket() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/key-start-bracket.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_key_two_equals() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/key-two-equals.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_key_value_pair_1() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/key-value-pair-1.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_llbrace() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/llbrace.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_multi_line_inline_table() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/multi-line-inline-table.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_multiple_dot_key() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/multiple-dot-key.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_multiple_key() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/multiple-key.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_no_key_name() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/no-key-name.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_non_dec_integers() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/non-dec-integers.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_rrbrace() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/rrbrace.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_string_bad_byte_escape() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/string-bad-byte-escape.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_string_bad_codepoint() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/string-bad-codepoint.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_string_bad_escape() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/string-bad-escape.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_string_bad_slash_escape() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/string-bad-slash-escape.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_string_bad_uni_esc() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/string-bad-uni-esc.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_string_basic_control_1() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/string-basic-control-1.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_string_basic_control_2() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/string-basic-control-2.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_string_basic_control_3() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/string-basic-control-3.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_string_basic_control_4() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/string-basic-control-4.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_string_basic_multiline_control_1() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/string-basic-multiline-control-1.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_string_basic_multiline_control_2() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/string-basic-multiline-control-2.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_string_basic_multiline_control_3() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/string-basic-multiline-control-3.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_string_basic_multiline_control_4() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/string-basic-multiline-control-4.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_string_basic_multiline_out_of_range_unicode_escape_1() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/string-basic-multiline-out-of-range-unicode-escape-1.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_string_basic_multiline_out_of_range_unicode_escape_2() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/string-basic-multiline-out-of-range-unicode-escape-2.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_string_basic_multiline_unknown_escape() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/string-basic-multiline-unknown-escape.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_string_basic_out_of_range_unicode_escape_1() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/string-basic-out-of-range-unicode-escape-1.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_string_basic_out_of_range_unicode_escape_2() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/string-basic-out-of-range-unicode-escape-2.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_string_basic_unknown_escape() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/string-basic-unknown-escape.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_string_byte_escapes() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/string-byte-escapes.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_string_literal_control_1() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/string-literal-control-1.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_string_literal_control_2() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/string-literal-control-2.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_string_literal_control_3() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/string-literal-control-3.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_string_literal_control_4() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/string-literal-control-4.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_string_literal_multiline_control_1() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/string-literal-multiline-control-1.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_string_literal_multiline_control_2() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/string-literal-multiline-control-2.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_string_literal_multiline_control_3() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/string-literal-multiline-control-3.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_string_literal_multiline_control_4() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/string-literal-multiline-control-4.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_string_no_close() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/string-no-close.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_table_1() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/table-1.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_table_2() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/table-2.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_table_array_implicit() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/table-array-implicit.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_table_array_malformed_bracket() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/table-array-malformed-bracket.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_table_array_malformed_empty() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/table-array-malformed-empty.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_table_empty() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/table-empty.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_table_nested_brackets_close() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/table-nested-brackets-close.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_table_nested_brackets_open() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/table-nested-brackets-open.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_table_whitespace() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/table-whitespace.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_table_with_pound() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/table-with-pound.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_text_after_array_entries() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/text-after-array-entries.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_text_after_integer() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/text-after-integer.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_text_after_string() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/text-after-string.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_text_after_table() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/text-after-table.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_text_before_array_separator() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/text-before-array-separator.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }

    func test_text_in_array() throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)/invalid_fixtures/text-in-array.toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData))
    }
}
