import XCTest
import TOMLDecoder
import Foundation

#if os(Windows)
private let kSeparator: Character = "\\"
#else
private let kSeparator: Character = "/"
#endif

final class TOMLInvalidationTests_: XCTestCase {
    private var directory: String {
        (
            (#filePath.first == "/" ? [""] : [])
                + #filePath.split(separator: kSeparator).dropLast()
                + ["invalid_fixtures"]
        )
            .joined(separator: "\(kSeparator)")
    }

    func invalidate(name: String, file: StaticString = #filePath, line: UInt = #line) throws {
        let tomlURL = URL(fileURLWithPath: "\(self.directory)\(kSeparator)\(name).toml", isDirectory: false)
        let tomlData = try Data(contentsOf: tomlURL)
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: tomlData), file: file, line: line)
    }

    func test_array_of_tables_1() throws {
        try invalidate(name: "array-of-tables-1")
    }

    func test_array_of_tables_2() throws {
        try invalidate(name: "array-of-tables-2")
    }

    func test_bare_key_1() throws {
        try invalidate(name: "bare-key-1")
    }

    func test_bare_key_2() throws {
        try invalidate(name: "bare-key-2")
    }

    func test_bare_key_3() throws {
        try invalidate(name: "bare-key-3")
    }

    func test_datetime_malformed_no_leads() throws {
        try invalidate(name: "datetime-malformed-no-leads")
    }

    func test_datetime_malformed_no_secs() throws {
        try invalidate(name: "datetime-malformed-no-secs")
    }

    func test_datetime_malformed_no_t() throws {
        try invalidate(name: "datetime-malformed-no-t")
    }

    func test_datetime_malformed_with_milli() throws {
        try invalidate(name: "datetime-malformed-with-milli")
    }

    func test_duplicate_key_table() throws {
        try invalidate(name: "duplicate-key-table")
    }

    func test_duplicate_keys() throws {
        try invalidate(name: "duplicate-keys")
    }

    func test_duplicate_tables() throws {
        try invalidate(name: "duplicate-tables")
    }

    func test_empty_implicit_table() throws {
        try invalidate(name: "empty-implicit-table")
    }

    func test_empty_table() throws {
        try invalidate(name: "empty-table")
    }

    func test_float_leading_zero_neg() throws {
        try invalidate(name: "float-leading-zero-neg")
    }

    func test_float_leading_zero_pos() throws {
        try invalidate(name: "float-leading-zero-pos")
    }

    func test_float_leading_zero() throws {
        try invalidate(name: "float-leading-zero")
    }

    func test_float_no_leading_zero() throws {
        try invalidate(name: "float-no-leading-zero")
    }

    func test_float_no_trailing_digits() throws {
        try invalidate(name: "float-no-trailing-digits")
    }

    func test_float_underscore_after_point() throws {
        try invalidate(name: "float-underscore-after-point")
    }

    func test_float_underscore_after() throws {
        try invalidate(name: "float-underscore-after")
    }

    func test_float_underscore_before_point() throws {
        try invalidate(name: "float-underscore-before-point")
    }

    func test_float_underscore_before() throws {
        try invalidate(name: "float-underscore-before")
    }

    func test_inline_table_linebreak() throws {
        try invalidate(name: "inline-table-linebreak")
    }

    func test_int_0_padded() throws {
        try invalidate(name: "int-0-padded")
    }

    func test_integer_leading_zero_neg() throws {
        try invalidate(name: "integer-leading-zero-neg")
    }

    func test_integer_leading_zero_pos() throws {
        try invalidate(name: "integer-leading-zero-pos")
    }

    func test_integer_leading_zero() throws {
        try invalidate(name: "integer-leading-zero")
    }

    func test_integer_underscore_after() throws {
        try invalidate(name: "integer-underscore-after")
    }

    func test_integer_underscore_before() throws {
        try invalidate(name: "integer-underscore-before")
    }

    func test_integer_underscore_double() throws {
        try invalidate(name: "integer-underscore-double")
    }

    func test_key_after_array() throws {
        try invalidate(name: "key-after-array")
    }

    func test_key_after_table() throws {
        try invalidate(name: "key-after-table")
    }

    func test_key_empty() throws {
        try invalidate(name: "key-empty")
    }

    func test_key_hash() throws {
        try invalidate(name: "key-hash")
    }

    func test_key_newline() throws {
        try invalidate(name: "key-newline")
    }

    func test_key_no_eol() throws {
        try invalidate(name: "key-no-eol")
    }

    func test_key_open_bracket() throws {
        try invalidate(name: "key-open-bracket")
    }

    func test_key_single_open_bracket() throws {
        try invalidate(name: "key-single-open-bracket")
    }

    func test_key_space() throws {
        try invalidate(name: "key-space")
    }

    func test_key_start_bracket() throws {
        try invalidate(name: "key-start-bracket")
    }

    func test_key_two_equals() throws {
        try invalidate(name: "key-two-equals")
    }

    func test_key_value_pair_1() throws {
        try invalidate(name: "key-value-pair-1")
    }

    func test_llbrace() throws {
        try invalidate(name: "llbrace")
    }

    func test_multi_line_inline_table() throws {
        try invalidate(name: "multi-line-inline-table")
    }

    func test_multiple_dot_key() throws {
        try invalidate(name: "multiple-dot-key")
    }

    func test_multiple_key() throws {
        try invalidate(name: "multiple-key")
    }

    func test_no_key_name() throws {
        try invalidate(name: "no-key-name")
    }

    func test_non_dec_integers() throws {
        try invalidate(name: "non-dec-integers")
    }

    func test_rrbrace() throws {
        try invalidate(name: "rrbrace")
    }

    func test_string_bad_byte_escape() throws {
        try invalidate(name: "string-bad-byte-escape")
    }

    func test_string_bad_codepoint() throws {
        try invalidate(name: "string-bad-codepoint")
    }

    func test_string_bad_escape() throws {
        try invalidate(name: "string-bad-escape")
    }

    func test_string_bad_slash_escape() throws {
        try invalidate(name: "string-bad-slash-escape")
    }

    func test_string_bad_uni_esc() throws {
        try invalidate(name: "string-bad-uni-esc")
    }

    func test_string_basic_control_1() throws {
        try invalidate(name: "string-basic-control-1")
    }

    func test_string_basic_control_2() throws {
        try invalidate(name: "string-basic-control-2")
    }

    func test_string_basic_control_3() throws {
        try invalidate(name: "string-basic-control-3")
    }

    func test_string_basic_control_4() throws {
        try invalidate(name: "string-basic-control-4")
    }

    func test_string_basic_multiline_control_1() throws {
        try invalidate(name: "string-basic-multiline-control-1")
    }

    func test_string_basic_multiline_control_2() throws {
        try invalidate(name: "string-basic-multiline-control-2")
    }

    func test_string_basic_multiline_control_3() throws {
        try invalidate(name: "string-basic-multiline-control-3")
    }

    func test_string_basic_multiline_control_4() throws {
        try invalidate(name: "string-basic-multiline-control-4")
    }

    func test_string_basic_multiline_out_of_range_unicode_escape_1() throws {
        try invalidate(name: "string-basic-multiline-out-of-range-unicode-escape-1")
    }

    func test_string_basic_multiline_out_of_range_unicode_escape_2() throws {
        try invalidate(name: "string-basic-multiline-out-of-range-unicode-escape-2")
    }

    func test_string_basic_multiline_unknown_escape() throws {
        try invalidate(name: "string-basic-multiline-unknown-escape")
    }

    func test_string_basic_out_of_range_unicode_escape_1() throws {
        try invalidate(name: "string-basic-out-of-range-unicode-escape-1")
    }

    func test_string_basic_out_of_range_unicode_escape_2() throws {
        try invalidate(name: "string-basic-out-of-range-unicode-escape-2")
    }

    func test_string_basic_unknown_escape() throws {
        try invalidate(name: "string-basic-unknown-escape")
    }

    func test_string_byte_escapes() throws {
        try invalidate(name: "string-byte-escapes")
    }

    func test_string_literal_control_1() throws {
        try invalidate(name: "string-literal-control-1")
    }

    func test_string_literal_control_2() throws {
        try invalidate(name: "string-literal-control-2")
    }

    func test_string_literal_control_3() throws {
        try invalidate(name: "string-literal-control-3")
    }

    func test_string_literal_control_4() throws {
        try invalidate(name: "string-literal-control-4")
    }

    func test_string_literal_multiline_control_1() throws {
        try invalidate(name: "string-literal-multiline-control-1")
    }

    func test_string_literal_multiline_control_2() throws {
        try invalidate(name: "string-literal-multiline-control-2")
    }

    func test_string_literal_multiline_control_3() throws {
        try invalidate(name: "string-literal-multiline-control-3")
    }

    func test_string_literal_multiline_control_4() throws {
        try invalidate(name: "string-literal-multiline-control-4")
    }

    func test_string_no_close() throws {
        try invalidate(name: "string-no-close")
    }

    func test_table_1() throws {
        try invalidate(name: "table-1")
    }

    func test_table_2() throws {
        try invalidate(name: "table-2")
    }

    func test_table_array_implicit() throws {
        try invalidate(name: "table-array-implicit")
    }

    func test_table_array_malformed_bracket() throws {
        try invalidate(name: "table-array-malformed-bracket")
    }

    func test_table_array_malformed_empty() throws {
        try invalidate(name: "table-array-malformed-empty")
    }

    func test_table_empty() throws {
        try invalidate(name: "table-empty")
    }

    func test_table_nested_brackets_close() throws {
        try invalidate(name: "table-nested-brackets-close")
    }

    func test_table_nested_brackets_open() throws {
        try invalidate(name: "table-nested-brackets-open")
    }

    func test_table_whitespace() throws {
        try invalidate(name: "table-whitespace")
    }

    func test_table_with_pound() throws {
        try invalidate(name: "table-with-pound")
    }

    func test_text_after_array_entries() throws {
        try invalidate(name: "text-after-array-entries")
    }

    func test_text_after_integer() throws {
        try invalidate(name: "text-after-integer")
    }

    func test_text_after_string() throws {
        try invalidate(name: "text-after-string")
    }

    func test_text_after_table() throws {
        try invalidate(name: "text-after-table")
    }

    func test_text_before_array_separator() throws {
        try invalidate(name: "text-before-array-separator")
    }

    func test_text_in_array() throws {
        try invalidate(name: "text-in-array")
    }

    func test_multiline_escape_space() throws {
        try invalidate(name: "multiline-escape-space")
    }

    func test_bad_utf8_in_string() throws {
        try invalidate(name: "bad-utf8-in-string")
    }

    func test_date_trailing_t() throws {
        try invalidate(name: "trailing-t")
    }

    func test_mday_under() throws {
        try invalidate(name: "mday-under")
    }

    func test_append_with_dotted_keys_1() throws {
        try invalidate(name: "append-with-dotted-keys-1")
    }

    func test_bare_cr() throws {
        try invalidate(name: "bare-cr")
    }

    func test_inline_table_add() throws {
        try invalidate(name: "inline-table-add")
    }

    func test_array_extending_table() throws {
        try invalidate(name: "array-extending-table")
    }

    func test_comment_del() throws {
        try invalidate(name: "comment-del")
    }
}
