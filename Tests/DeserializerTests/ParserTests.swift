@testable import Deserializer
import XCTest
import Foundation


func runTest<T: Equatable>(_ run: (inout Substring) -> T, _ input: String) -> T {
    var input = input[...]
    return run(&input)
}

extension TOMLValue {
    var isNaN: Bool {
        switch self {
        case .float(let f):
            return f.isNaN
        default:
            return false
        }
    }

    var errorReason: Reason? {
        switch self {
        case .error(_, let e):
            return e
        default:
            return nil
        }
    }
}

extension TopLevel {
    var keyValue: RawKeyValuePair? {
        switch self {
        case .keyValue(let kv):
            return kv
        default:
            return nil
        }
    }

    var key: [Traced<String>] {
        switch self {
        case .table(let key):
            return key
        case .arrayTable(let key):
            return key
        default:
            return []
        }
    }
}

final class ParserTests: XCTestCase {
    func testParsingDecInt() {
        XCTAssertEqual(.integer(-42), runTest(integer, "-42"))
    }

    func testParsingHexInt() {
        XCTAssertEqual(.integer(0x4a), runTest(integer, "0x4a"))
    }

    func testParsingOctInt() {
        XCTAssertEqual(.integer(0o47), runTest(integer, "0o47"))
    }

    func testParsingBinInt() {
        XCTAssertEqual(.integer(0b1101), runTest(integer, "0b1101"))
    }

    func testParsingNormalFloat0() {
        XCTAssertEqual(.float(200), runTest(float, "2e2"))
    }

    func testParsingNormalFloat1() {
        XCTAssertEqual(.float(2.2), runTest(float, "2.2"))
    }

    func testParsingNormalFloat2() {
        XCTAssertEqual(.float(220), runTest(float, "2.2e2"))
    }

    func testParsingNormalFloat3() {
        XCTAssertEqual(.float(22), runTest(float, "2200e-2"))
    }

    func testParsingNormalFloat4() {
        XCTAssertEqual(.float(-2.2), runTest(float, "-2.2"))
    }

    func testParsingNormalFloat5() {
        XCTAssertEqual(.float(-2.2), runTest(float, "-220e-2"))
    }
    
    func testParsingNormalFloat6() {
        XCTAssertEqual(.float(-225.03255), runTest(float, "-225.03255"))
    }

    func testParsingNaN() {
        XCTAssertTrue(runTest(float, "nan")?.isNaN == true)
    }

    func testParsingNaNPlus() {
        XCTAssertTrue(runTest(float, "+nan")?.isNaN == true)
    }

    func testParsingNaNMinus() {
        XCTAssertTrue(runTest(float, "-nan")?.isNaN == true)
    }

    func testParsingInfinity() {
        XCTAssertEqual(.float(Double.infinity), runTest(float, "inf"))
    }

    func testParsingInfinityPlus() {
        XCTAssertEqual(.float(Double.infinity), runTest(float, "+inf"))
    }

    func testParsingInfinityMinus() {
        XCTAssertEqual(.float(-Double.infinity), runTest(float, "-inf"))
    }

    func testBooleanTrue() {
        XCTAssertEqual(runTest(boolean, "true"), .boolean(true))
    }

    func testBooleanFalse() {
        XCTAssertEqual(runTest(boolean, "false"), .boolean(false))
    }

    func testParseComment() {
        XCTAssertNotNil(runTest(comment, "# this is a comment!"))
    }

    func testLiteralString() throws {
        let content = "hello world!"
        XCTAssertEqual(
            try runTest(literalString, "'\(content)'")?.normalize(reference: content) as? String,
            content
        )
    }

//    func testLiteralStringWithoutClosing() {
//        let content = "hello world!"
//        XCTAssertEqual(
//            runTest(literalString, "'\(content)")?.errorReason,
//            .literalStringMissingClosing
//        )
//    }

    func testMultilineLiteralString() {
        let content = "\nhello \n world!\r\n"
        let expected = "hello \n world!\r\n"
        XCTAssertEqual(
            try runTest(multilineLiteralString, "'''\(content)'''")?.normalize(reference: content) as? String,
            expected
        )
    }

//    func testMultilineLiteralStringWithoutClosing() {
//        let content = "\nhello \n world!\r\n"
//        XCTAssertEqual(
//            runTest(multilineLiteralString, "'''\(content)")?.errorReason,
//            .multilineLiteralStringMissingClosing
//        )
//    }

    func testEscapedQuote() {
        let input = #"\""#[...].unicodeScalars
        var index = input.startIndex
        XCTAssertEqual(escaped(&index, input), .init(0x22))
    }

    func testEscapedBackslash() {
        let input = #"\\"#[...].unicodeScalars
        var index = input.startIndex
        XCTAssertEqual(escaped(&index, input), .init(0x5C))
    }

    func testEscapedBackspace() {
        let input = #"\b"#[...].unicodeScalars
        var index = input.startIndex
        XCTAssertEqual(escaped(&index, input), .init(0x08))
    }

    func testEscapedFormFeed() {
        let input = #"\f"#[...].unicodeScalars
        var index = input.startIndex
        XCTAssertEqual(escaped(&index, input), .init(0x0C))
    }

    func testEscapedLineFeed() {
        let input = #"\n"#[...].unicodeScalars
        var index = input.startIndex
        XCTAssertEqual(escaped(&index, input), .init(0x0A))
    }

    func testEscapedCarriageReturn() {
        let input = #"\r"#[...].unicodeScalars
        var index = input.startIndex
        XCTAssertEqual(escaped(&index, input), .init(0x0D))
    }

    func testEscapedCarriageTab() {
        let input = #"\t"#[...].unicodeScalars
        var index = input.startIndex
        XCTAssertEqual(escaped(&index, input), .init(0x09))
    }

    func testEscapedSequence4() {
        let input = #"\uBEEF"#[...].unicodeScalars
        var index = input.startIndex
        XCTAssertEqual(escaped(&index, input), UnicodeScalar(0xBEEF))
    }

    func testEscapedSequence8() {
        let input = #"\U0000c0de"#[...].unicodeScalars
        var index = input.startIndex
        XCTAssertEqual(escaped(&index, input), UnicodeScalar(0x0000C0DE))
    }

    func testMultilineBasicString() {
        let content = "\nhello \n world!\r\n"
        let expected = "hello \n world!\r\n"
        XCTAssertEqual(
            try runTest(multilineBasicString, "\"\"\"\(content)\"\"\"")?.normalize(reference: content) as? String,
            expected
        )
    }

    func testBasicString() {
        let input = "hello  world!"
        XCTAssertEqual(
            try runTest(basicString, "\"\(input)\"")?.normalize(reference: input) as? String,
            input
        )
    }

//    func testBasicStringWithoutClosing() {
//        let content = "hello  world!"
//        XCTAssertEqual(
//            TOMLParser.basicString.testRun("\"\(content)")?.errorReason,
//            .basicStringMissingClosing
//        )
//    }

    func testBasicStringWithEscape() {
        let input = #"hello  \" world!"#
        let expected = #"hello  " world!"#
        XCTAssertEqual(
            try runTest(basicString, "\"\(input)\"")?.normalize(reference: input) as? String,
            expected
        )
    }

    func testLocalTime() {
        let content = "05:05:05"
        XCTAssertEqual(
            runTest(dateTime, content),
            .dateComponents(DateComponents(hour: 5, minute: 5, second: 5))
        )
    }

    func testInvalidLocalTime() {
        let content = "25:05:05"
        XCTAssertEqual(
            runTest(dateTime, content)?.errorReason,
            .invalidTime
        )
    }

    func testLocalDate() {
        let content = "2005-05-05"
        XCTAssertEqual(
            runTest(dateTime, content),
            .dateComponents(DateComponents(year: 2005, month: 5, day: 5))
        )
    }

    func testInvalidLocalDate() {
        let content = "2005-15-05"
        XCTAssertEqual(
            runTest(dateTime, content)?.errorReason,
            .invalidDate
        )
    }

    func testLocalDateTime() {
        let content = "2005-05-05T05:05:05"
        XCTAssertEqual(
            runTest(dateTime, content),
            .dateComponents(
                DateComponents(year: 2005, month: 5, day: 5, hour: 5, minute: 5, second: 5)
            )
        )
    }

    func testInvalidLocalDateTime1() {
        let content = "2005-15-05T05:05:05"
        XCTAssertEqual(
            runTest(dateTime, content)?.errorReason,
            .invalidDate
        )
    }

    func testInvalidLocalDateTime2() {
        let content = "2005-05-05T25:05:05"
        XCTAssertEqual(
            runTest(dateTime, content)?.errorReason,
            .invalidTime
        )
    }

    func testOffsetDateTime() throws {
        let content = "2005-05-05T05:05:05-08:00"
        XCTAssertEqual(
            runTest(dateTime, content),
            .date(
                try XCTUnwrap(
                    Calendar(identifier: .gregorian)
                    .date(
                        from: DateComponents(
                            timeZone: TimeZone(secondsFromGMT: -(8 * 3600)),
                            year: 2005, month: 5, day: 5,
                            hour: 5, minute: 5, second: 5
                        )
                    )
                )
            )
        )
    }

    func testArray1() throws {
        let content = "[1, '2', [3], 4]"
        let result = try XCTUnwrap(runTest(array, content))
        switch result {
        case .array(let a):
            XCTAssertEqual(a.count, 4)
        default:
            print(result)
            XCTFail()
        }
    }

    func testWhitespaceCommentNewline() throws {
        var input = "   #  \n"[...]
        try whitespaceCommentSkip(&input)
        XCTAssertEqual(Array(input), [])
    }

    func testKeyValue() {
        var input = "my.key  = 0xdead"[...]
        let result = keyValue(&input)
        XCTAssertEqual(
            result?.keyValue?.key.map { $0.value },
            ["my", "key"]
        )
        XCTAssertEqual(
            result?.keyValue?.value,
            .integer(0xdead)
        )
    }

    func testStandardTable() {
        var input = "[ my.key ]"[...]
        XCTAssertEqual(
            table(&input)?.key.map { $0.value },
            ["my", "key"]
        )
    }

    func testArrayTable() {
        var input = "[[ my.key ]]"[...]
        XCTAssertEqual(
            arrayTable(&input)?.key.map { $0.value },
            ["my", "key"]
        )
    }

    func testInlineTable() {
        var input = "{my.key  = 0xdead}"[...]
        guard let result = inlineTable(&input) else {
            XCTFail()
            return
        }

        switch result {
        case .inlineTable(let table):
            XCTAssertEqual(table.map { $0.key.map { $0.value } }, [["my", "key"]])
            XCTAssertEqual(table.map { $0.value }, [.integer(0xdead)])
        default:
            XCTFail()
        }
    }

    func testKeyEmptyArrayValue() {
        var input = "a = []"[...]
        let result = keyValue(&input)
        XCTAssertEqual(
            result?.keyValue?.key.map { $0.value },
            ["a"]
        )
        XCTAssertEqual(
            result?.keyValue?.value,
            .array([])
        )
    }

    func testParseArbitraryStuff() throws {
        let input = """
        [a.b]
        c.d = false
        e = "hello"
        f = { g.h = 'hello', f = { f = true } }
        g = [ [true], ["a"] ]
        [[x.y]]
        z = 0b0101
        a = 0.162E3
        [[x.y]]
        z = 0b0101
        a = 2001-02-14T23:59:60-00:01
        """

        _ = try TOMLDeserializer.tomlTable(with: input)
    }

    func testFruit() throws {
        let input = """
        [[fruit.blah]]
          name = "apple"
          [fruit.blah.physical]
            color = "red"
            shape = "round"
        [[fruit.blah]]
          name = "banana"
          [fruit.blah.physical]
            color = "yellow"
            shape = "bent"
        """

        _ = try TOMLDeserializer.tomlTable(with: input)
    }

    func testExample() throws {
        let input = """
        # This is a TOML document. Boom.

        title = "TOML Example"

        [owner]
        name = "Tom Preston-Werner"
        organization = "GitHub"
        bio = "GitHub Cofounder & CEO\\nLikes tater tots and beer."

        [database]
        server = "192.168.1.1"
        ports = [ 8001, 8001, 8002 ]
        connection_max = 5000
        enabled = true

        [servers]

          # You can indent as you please. Tabs or spaces. TOML don't care.
          [servers.alpha]
          ip = "10.0.0.1"
          dc = "eqdc10"

          [servers.beta]
          ip = "10.0.0.2"
          dc = "eqdc10"
          country = "中国" # This should be parsed as UTF-8

        [clients]
        data = [ ["gamma", "delta"], [1, 2] ] # just an update to make sure parsers support it

        # Line breaks are OK when inside arrays
        hosts = [
          "alpha",
          "omega"
        ]

        # Products

          [[products]]
          name = "Hammer"
          sku = 738594937

          [[products]]
          name = "Nail"
          sku = 284758393
          color = "gray"
        """

        _ = try TOMLDeserializer.tomlTable(with: input)
    }

    func testHardExample() throws {
        let input = """
        # Test file for TOML
        # Only this one tries to emulate a TOML file written by a user of the kind of parser writers probably hate
        # This part you'll really hate
        [the]
        test_string = "You'll hate me after this - #"          # " Annoying, isn't it?
            [the.hard]
            test_array = [ "] ", " # "]      # ] There you go, parse this!
            test_array2 = [ "Test #11 ]proved that", "Experiment #9 was a success" ]
            # You didn't think it'd as easy as chucking out the last #, did you?
            another_test_string = " Same thing, but with a string #"
            harder_test_string = " And when \\"'s are in the string, along with # \\""   # "and comments are there too"
            # Things will get harder
                [the.hard."bit#"]
                "what?" = "You don't think some user won't do that?"
                multi_line_array = [
                    "]",
                    # ] Oh yes I did
                    ]
        """

        _ = try TOMLDeserializer.tomlTable(with: input)
    }

    func testHardUnicodeExample() throws {
        let input = """
        # Tèƨƭ ƒïℓè ƒôř TÓM£
        # Óñℓ¥ ƭλïƨ ôñè ƭřïèƨ ƭô è₥úℓáƭè á TÓM£ ƒïℓè ωřïƭƭèñ β¥ á úƨèř ôƒ ƭλè ƙïñδ ôƒ ƥářƨèř ωřïƭèřƨ ƥřôβáβℓ¥ λáƭè
        # Tλïƨ ƥářƭ ¥ôú'ℓℓ řèáℓℓ¥ λáƭè
        [the]
        test_string = "Ýôú'ℓℓ λáƭè ₥è áƒƭèř ƭλïƨ - #"          # " Âññô¥ïñϱ, ïƨñ'ƭ ïƭ?
            [the.hard]
            test_array = [ "] ", " # "]      # ] Tλèřè ¥ôú ϱô, ƥářƨè ƭλïƨ!
            test_array2 = [ "Tèƨƭ #11 ]ƥřôƲèδ ƭλáƭ", "Éжƥèřï₥èñƭ #9 ωáƨ á ƨúççèƨƨ" ]
            # Ýôú δïδñ'ƭ ƭλïñƙ ïƭ'δ áƨ èáƨ¥ áƨ çλúçƙïñϱ ôúƭ ƭλè ℓáƨƭ #, δïδ ¥ôú?
            another_test_string = "§á₥è ƭλïñϱ, βúƭ ωïƭλ á ƨƭřïñϱ #"
            harder_test_string = " Âñδ ωλèñ \\"'ƨ ářè ïñ ƭλè ƨƭřïñϱ, áℓôñϱ ωïƭλ # \\""   # "áñδ çô₥₥èñƭƨ ářè ƭλèřè ƭôô"
            # Tλïñϱƨ ωïℓℓ ϱèƭ λářδèř
                [the.hard."βïƭ#"]
                "ωλáƭ?" = "Ýôú δôñ'ƭ ƭλïñƙ ƨô₥è úƨèř ωôñ'ƭ δô ƭλáƭ?"
                multi_line_array = [
                    "]",
                    # ] Óλ ¥èƨ Ì δïδ
                    ]
        """

        _ = try TOMLDeserializer.tomlTable(with: input)
    }

    func testDateExample() throws {
        let input = """
        best-day-ever = 1987-07-05T17:45:00Z
        [numtheory]
        boring = false
        perfection = [6, 28, 496]
        """

        _ = try TOMLDeserializer.tomlTable(with: input)
    }

    func testInfinityAndNan() throws {
        let input = """
        nan = nan
        nan_neg = -nan
        nan_plus = +nan
        infinity = inf
        infinity_neg = -inf
        infinity_plus = +inf

        """

        _ = try TOMLDeserializer.tomlTable(with: input)
    }

    func testNestedArrayTable() throws {
        let input = """
        [[albums]]
        name = "Born to Run"
          [[albums.songs]]
          name = "Jungleland"
          [[albums.songs]]
          name = "Meeting Across the River"
        [[albums]]
        name = "Born in the USA"
          [[albums.songs]]
          name = "Glory Days"
          [[albums.songs]]
          name = "Dancing in the Dark"
        """

        _ = try TOMLDeserializer.tomlTable(with: input)
    }

    func testRawMultilineString() throws {
        let input = """
        oneline = '''This string has a ' quote character.'''
        firstnl = '''
        This string has a ' quote character.'''
        multiline = '''
        This string
        has ' a quote character
        and more than
        one newline
        in it.'''
        """

        _ = try TOMLDeserializer.tomlTable(with: input)
    }

    func testMultilineString() throws {
        let input = """
        oneline = \"\"\"This string has a \\" quote character.\"\"\"
        firstnl = \"\"\"
        This string has a \\" quote character.\"\"\"
        multiline = \"\"\"
        This string
        has \\" a quote character
        and more than
        one newline
        in it.\"\"\"
        """
        _ = try TOMLDeserializer.tomlTable(with: input)
    }

    func testTableArrayTableArray() throws {
        let input = """
        [[a]]
            [[a.b]]
                [a.b.c]
                    d = "val0"
            [[a.b]]
                [a.b.c]
                    d = "val1"
        """

        _ = try TOMLDeserializer.tomlTable(with: input)
    }

    func testValidKey() throws {
        let input = """
        ['a']
        [a.'b']
        [a.'b'.c]
        answer = 42
        """
        _ = try TOMLDeserializer.tomlTable(with: input)
    }

    func testInteger() throws {
        let input = """
        answer = 42
        posanswer = +42
        neganswer = -42
        zero = 0\n
        """
        _ = try TOMLDeserializer.tomlTable(with: input)
    }

    func testNestedInlineTableArray() throws {
        let input = "a = [ { b = {} } ]"
        _ = try TOMLDeserializer.tomlTable(with: input)
    }

    func testLongString() throws {
        let longString = """
        s = \"\"\"
        # This is a TOML document.

        title = "TOML Example"

        [owner]
        name = "Tom Preston-Werner"
        dob = 1979-05-27T07:32:00-08:00 # First class dates

        [database]
        server = "192.168.1.1"
        ports = [ 8001, 8001, 8002 ]
        connection_max = 5000
        enabled = true

        [servers]

          # Indentation (tabs and/or spaces) is allowed but not required
          [servers.alpha]
          ip = "10.0.0.1"
          dc = "eqdc10"

          [servers.beta]
          ip = "10.0.0.2"
          dc = "eqdc10"

        # Line breaks are OK when inside arrays
        hosts = [
          "alpha",
          "omega"
        ]
        \"\"\"
        """
        _ = try TOMLDeserializer.tomlTable(with: longString)
    }

    func testDateTimeLowercase() throws {
        let input = """
        space = 1987-07-05 17:45:00Z
        lower = 1987-07-05t17:45:00z
        """
        _ = try TOMLDeserializer.tomlTable(with: input)
    }

    func testSpaceIsNotValidEscape() throws {
        let input = #"k = """t\ t""""#
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: input))
    }

    func testInvalidBinNumber() throws {
        let input = "a = 0b_1"
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: input))
    }

    func testInvalidOctalNumber() throws {
        let input = "a = 0o_1"
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: input))
    }

    func testInvalidHexNumber() throws {
        let input = "a = 0x_1"
        XCTAssertThrowsError(try TOMLDeserializer.tomlTable(with: input))
    }
}
