import Foundation

enum Constants {
    static let tripleSingleQuote = "'''".utf8
    static let tripleDoubleQuote = #"""""#.utf8
    static let anonymousArryKey = "3b60b623-fab0-4045-b091-dc33c08e4126"
    static let nan = "nan".utf8
    static let inf = "inf".utf8
    static let `true` = "true".utf8
    static let `false` = "false".utf8
}

enum CodeUnits {
    static let equal: UTF8.CodeUnit = 61
    static let comma: UTF8.CodeUnit = 44
    static let lbrace: UTF8.CodeUnit = 123
    static let rbrace: UTF8.CodeUnit = 125
    static let lbracket: UTF8.CodeUnit = 91
    static let rbracket: UTF8.CodeUnit = 93
    static let pound: UTF8.CodeUnit = 35
    static let backslash: UTF8.CodeUnit = 92
    static let backspace: UTF8.CodeUnit = 8
    static let cr: UTF8.CodeUnit = 13
    static let colon: UTF8.CodeUnit = 58
    static let dot: UTF8.CodeUnit = 46
    static let doubleQuote: UTF8.CodeUnit = 34
    static let formfeed: UTF8.CodeUnit = 12
    static let lf: UTF8.CodeUnit = 10
    static let minus: UTF8.CodeUnit = 45
    static let plus: UTF8.CodeUnit = 43
    static let singleQuote: UTF8.CodeUnit = 39
    static let space: UTF8.CodeUnit = 32
    static let tab: UTF8.CodeUnit = 9
    static let underscore: UTF8.CodeUnit = 95

    static let number0: UTF8.CodeUnit = 48
    static let number1: UTF8.CodeUnit = 49
    static let number7: UTF8.CodeUnit = 55
    static let number9: UTF8.CodeUnit = 57

    static let lowerA: UTF8.CodeUnit = 97
    static let lowerB: UTF8.CodeUnit = 98
    static let lowerE: UTF8.CodeUnit = 101
    static let lowerF: UTF8.CodeUnit = 102
    static let lowerN: UTF8.CodeUnit = 110
    static let lowerO: UTF8.CodeUnit = 111
    static let lowerR: UTF8.CodeUnit = 114
    static let lowerT: UTF8.CodeUnit = 116
    static let lowerU: UTF8.CodeUnit = 117
    static let lowerX: UTF8.CodeUnit = 120
    static let lowerZ: UTF8.CodeUnit = 122
    static let upperA: UTF8.CodeUnit = 65
    static let upperE: UTF8.CodeUnit = 69
    static let upperF: UTF8.CodeUnit = 70
    static let upperT: UTF8.CodeUnit = 84
    static let upperU: UTF8.CodeUnit = 85
    static let upperZ: UTF8.CodeUnit = 90

    static let null: UTF8.CodeUnit = 0x00
    static let unitSeparator: UTF8.CodeUnit = 0x1F
    static let delete: UTF8.CodeUnit = 0x7F
}

extension UTF8.CodeUnit {
    @_transparent
    var isDecimalDigit: Bool {
        CodeUnits.number0 <= self && self <= CodeUnits.number9
    }

    @_transparent
    var isHexDigit: Bool {
        isDecimalDigit
            || CodeUnits.lowerA <= self && self <= CodeUnits.lowerF
            || CodeUnits.upperA <= self && self <= CodeUnits.upperF
    }
}

struct Token: Equatable {
    enum Kind {
        case dot
        case comma
        case equal
        case lbrace
        case rbrace
        case newline
        case lbracket
        case rbracket
        case string
    }

    let kind: Kind
    let lineNumber: Int
    let text: String.UTF8View.SubSequence
    let eof: Bool

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.kind == rhs.kind &&
            lhs.lineNumber == rhs.lineNumber &&
            lhs.text.startIndex == rhs.text.startIndex && lhs.text.endIndex == rhs.text.endIndex &&
            lhs.eof == rhs.eof
    }

    static let empty = Token(kind: .newline, lineNumber: 1, text: "".utf8[...], eof: false)
}

extension Token: CustomDebugStringConvertible {
    var debugDescription: String {
        "text [\(String(Substring(text)))], eof: \(eof), kind: \(kind)"
    }
}

struct TOMLArrayImplementation: Equatable, Sendable {
    enum Element: Equatable {
        case leaf(Token)
        case array(lineNumber: Int, Int)
        case table(lineNumber: Int, Int)

        var lineNumber: Int {
            switch self {
            case let .leaf(token):
                token.lineNumber
            case let .array(lineNumber, _):
                lineNumber
            case let .table(lineNumber, _):
                lineNumber
            }
        }

        static func == (lhs: Element, rhs: Element) -> Bool {
            switch (lhs, rhs) {
            case let (.leaf(lhsToken), .leaf(rhsToken)):
                lhsToken == rhsToken
            case let (.array(lhsLineNumber, lhsIndex), .array(rhsLineNumber, rhsIndex)):
                lhsLineNumber == rhsLineNumber && lhsIndex == rhsIndex
            case let (.table(lhsLineNumber, lhsIndex), .table(rhsLineNumber, rhsIndex)):
                lhsLineNumber == rhsLineNumber && lhsIndex == rhsIndex
            default:
                false
            }
        }
    }

    enum Kind {
        case value
        case array
        case table
        case mixed
    }

    var key: String?
    var kind: Kind?
    var elements: [Element]

    init(key: String? = nil, kind: Kind? = nil, elements: [Element] = []) {
        self.key = key
        self.kind = kind
        self.elements = elements
    }
}

struct KeyValuePair: Equatable {
    let key: String
    var value: Token

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.key == rhs.key && lhs.value == rhs.value
    }
}

struct TOMLTableImplementation: Equatable, Sendable {
    enum Value {
        case keyValue(Int)
        case array(Int)
        case table(Int)
    }

    var key: String?
    var implicit: Bool = false
    var readOnly: Bool = false
    var definedByDottedKey: Bool = false
    var keyValues: [Int] = []
    var arrays: [Int] = []
    var tables: [Int] = []

    init(key: String? = nil) {
        self.key = key
    }

    subscript(parser: Deserializer, key: String) -> Value? {
        for kv in keyValues {
            if parser.keyValues[kv].key == key {
                return .keyValue(kv)
            }
        }

        for arr in arrays {
            if parser.arrays[arr].key == key {
                return .array(arr)
            }
        }

        for table in tables {
            if parser.tables[table].key == key {
                return .table(table)
            }
        }

        return nil
    }

    func allKeys(parser: Deserializer) -> [String] {
        var keys = [String]()
        for kv in keyValues {
            keys.append(parser.keyValues[kv].key)
        }
        for arr in arrays {
            if let key = parser.arrays[arr].key {
                keys.append(key)
            }
        }
        for table in tables {
            if let key = parser.tables[table].key {
                keys.append(key)
            }
        }
        return keys
    }

    func contains(parser: Deserializer, key: String) -> Bool {
        for kv in keyValues {
            if parser.keyValues[kv].key == key {
                return true
            }
        }
        for arr in arrays {
            if parser.arrays[arr].key == key {
                return true
            }
        }
        for table in tables {
            if parser.tables[table].key == key {
                return true
            }
        }
        return false
    }
}

final class Deserializer: Equatable, @unchecked Sendable {
    static func == (lhs: Deserializer, rhs: Deserializer) -> Bool {
        lhs === rhs
    }

    var tables: [TOMLTableImplementation]
    var arrays: [TOMLArrayImplementation] = []
    var keyValues: [KeyValuePair] = []

    let originalSource: String
    let sourceUTF8: String.UTF8View
    var token: Token
    var currentTable: Int
    var tablePath: [(String, Token)] = []
    var keyTransform: (@Sendable (String) -> String)?

    init(source: String, keyTransform: (@Sendable (String) -> String)?) {
        tables = [TOMLTableImplementation()]
        originalSource = source
        sourceUTF8 = source.utf8
        token = Token(kind: .newline, lineNumber: 1, text: "".utf8[...], eof: false)
        currentTable = 0
        self.keyTransform = keyTransform
    }
}

#if DEBUG
extension Deserializer {
    func dump() {
        for (i, table) in zip(0..., tables) {
            print(i, table)
        }

        for (i, array) in zip(0..., arrays) {
            print(i, array)
        }

        for (i, kv) in zip(0..., keyValues) {
            print(i, kv)
        }
    }
}
#endif

func literalString(source: String.UTF8View.SubSequence, multiline: Bool) throws(TOMLError) -> String {
    var resultCodeUnits: [UTF8.CodeUnit] = []
    var consecutiveQuotes = 0

    for index in source.indices {
        let codeUnit = source[index]
        if codeUnit >= CodeUnits.null && codeUnit <= CodeUnits.backspace || codeUnit >= CodeUnits.lf && codeUnit <= CodeUnits.unitSeparator || codeUnit == CodeUnits.delete {
            if multiline, codeUnit == CodeUnits.lf {
                // Allow LF in multiline literal strings
            } else if multiline, codeUnit == CodeUnits.cr {
                // Only allow CR if followed by LF (CRLF sequence)
                let nextIndex = source.index(after: index)
                if nextIndex < source.endIndex, source[nextIndex] == CodeUnits.lf {
                    // Allow CRLF sequence - will be processed as separate characters
                } else {
                    throw TOMLError.invalidCharacter(codeUnit)
                }
            } else {
                throw TOMLError.invalidCharacter(codeUnit)
            }
        }

        if multiline, codeUnit == CodeUnits.singleQuote {
            consecutiveQuotes += 1
            if consecutiveQuotes > 2 {
                throw TOMLError.syntax(lineNumber: 0, message: "literal multiline strings cannot contain more than 2 consecutive single quotes")
            }
        } else {
            consecutiveQuotes = 0
        }

        resultCodeUnits.append(codeUnit)
    }
    return String(decoding: resultCodeUnits, as: UTF8.self)
}

extension String.UTF8View.SubSequence {
    func indexAfterSkippingCharacters(start: Index, characters: [UTF8.CodeUnit]) -> Index {
        var index = start
        while index < endIndex {
            if characters.contains(self[index]) {
                index = self.index(after: index)
            } else {
                break
            }
        }
        return index
    }
}

func basicString(source: String.UTF8View.SubSequence, multiline: Bool) throws(TOMLError) -> String {
    var resultCodeUnits: [UTF8.CodeUnit] = []
    var consecutiveQuotes = 0
    var index = source.startIndex
    while true {
        if index >= source.endIndex {
            break
        }

        var ch = source[index]
        index = source.index(after: index)
        if ch != CodeUnits.backslash {
            if ch >= CodeUnits.null && ch <= CodeUnits.backspace || ch >= CodeUnits.lf && ch <= CodeUnits.unitSeparator || ch == CodeUnits.delete {
                if multiline, ch == CodeUnits.lf {
                    // Allow LF in multiline basic strings
                } else if multiline, ch == CodeUnits.cr {
                    // Only allow CR if followed by LF (CRLF sequence)
                    if index < source.endIndex, source[index] == CodeUnits.lf {
                        // Allow CRLF sequence - will be processed as separate characters
                    } else {
                        throw TOMLError.invalidCharacter(ch)
                    }
                } else {
                    throw TOMLError.invalidCharacter(ch)
                }
            }

            if multiline, ch == CodeUnits.doubleQuote {
                consecutiveQuotes += 1
                if consecutiveQuotes > 2 {
                    throw TOMLError.syntax(lineNumber: 0, message: "basic multiline strings cannot contain more than 2 consecutive double quotes")
                }
            } else {
                consecutiveQuotes = 0
            }

            resultCodeUnits.append(ch)
            continue
        }

        if index >= source.endIndex {
            throw TOMLError.invalidCharacter(CodeUnits.backslash)
        }

        if multiline {
            let afterWhitespace = source.indexAfterSkippingCharacters(start: index, characters: [CodeUnits.space, CodeUnits.tab, CodeUnits.cr])
            if afterWhitespace < source.endIndex, source[afterWhitespace] == CodeUnits.lf {
                index = source.indexAfterSkippingCharacters(start: index, characters: [CodeUnits.space, CodeUnits.tab, CodeUnits.cr, CodeUnits.lf])
                continue
            }
        }

        ch = source[index]
        index = source.index(after: index)

        if ch == CodeUnits.lowerU || ch == CodeUnits.upperU {
            let hexCount = (ch == CodeUnits.lowerU ? 4 : 8)
            var ucs: UInt32 = 0
            for _ in 0 ..< hexCount {
                if index >= source.endIndex {
                    throw TOMLError.expectedHexCharacters(ch, hexCount)
                }
                ch = source[index]
                index = source.index(after: index)
                let v: Int32 = ch.isDecimalDigit
                    ? Int32(ch - CodeUnits.number0)
                    : (ch >= CodeUnits.upperA && ch <= CodeUnits.upperF)
                    ? Int32(ch - CodeUnits.upperA + 10)
                    : (ch >= CodeUnits.lowerA && ch <= CodeUnits.lowerF)
                    ? Int32(ch - CodeUnits.lowerA + 10)
                    : -1
                if v == -1 {
                    throw TOMLError.invalidHexCharacters(ch)
                }
                ucs = ucs * 16 + UInt32(v)
            }
            guard let scalar = Unicode.Scalar(ucs) else {
                throw TOMLError.illegalUCSCode(ucs)
            }
            resultCodeUnits.append(contentsOf: scalar.utf8)
            continue
        } else if ch == CodeUnits.lowerB {
            ch = CodeUnits.backspace
        } else if ch == CodeUnits.lowerT {
            ch = CodeUnits.tab
        } else if ch == CodeUnits.lowerF {
            ch = CodeUnits.formfeed
        } else if ch == CodeUnits.lowerR {
            ch = CodeUnits.cr
        } else if ch == CodeUnits.lowerN {
            ch = CodeUnits.lf
        } else if ch != CodeUnits.doubleQuote, ch != CodeUnits.backslash {
            throw TOMLError.illegalEscapeCharacter(ch)
        }

        consecutiveQuotes = 0 // Reset count after escape sequence
        resultCodeUnits.append(ch)
    }
    return String(decoding: resultCodeUnits, as: UTF8.self)
}

func scanDigits(source: String.UTF8View.SubSequence, n: Int) -> Int? {
    var result = 0
    var n = n
    var index = source.startIndex
    while n > 0, index < source.endIndex, isdigit(Int32(source[index])) != 0 {
        result = 10 * result + Int(source[index]) - Int(CodeUnits.number0)
        index = source.index(after: index)
        n -= 1
    }
    return n != 0 ? nil : result
}

func scanDate(source: String.UTF8View.SubSequence) -> (Int, Int, Int, String.UTF8View.SubSequence.Index)? {
    guard let year = scanDigits(source: source, n: 4) else {
        return nil
    }

    var index = source.startIndex
    source.formIndex(&index, offsetBy: 4)

    guard index < source.endIndex, source[index] == CodeUnits.minus else {
        return nil
    }

    source.formIndex(&index, offsetBy: 1)
    guard let month = scanDigits(source: source[index...], n: 2) else {
        return nil
    }

    source.formIndex(&index, offsetBy: 2)
    guard source[index] == CodeUnits.minus else {
        return nil
    }

    source.formIndex(&index, offsetBy: 1)
    guard let day = scanDigits(source: source[index...], n: 2) else {
        return nil
    }

    source.formIndex(&index, offsetBy: 2)
    return (year, month, day, index)
}

func scanTimezoneOffset(source: String.UTF8View.SubSequence) -> String.UTF8View.SubSequence.Index? {
    var index = source.startIndex
    guard index < source.endIndex, source[index] == CodeUnits.plus || source[index] == CodeUnits.minus else {
        return nil
    }

    source.formIndex(&index, offsetBy: 1)
    guard let _ = scanDigits(source: source[index...], n: 2) else {
        return nil
    }

    source.formIndex(&index, offsetBy: 2)
    guard index < source.endIndex, source[index] == CodeUnits.colon else {
        return nil
    }

    source.formIndex(&index, offsetBy: 1)
    guard let _ = scanDigits(source: source[index...], n: 2) else {
        return nil
    }
    source.formIndex(&index, offsetBy: 2)
    return index
}

func scanTime(source: String.UTF8View.SubSequence) -> (Int, Int, Int, String.UTF8View.SubSequence.Index)? {
    guard let hour = scanDigits(source: source, n: 2) else {
        return nil
    }

    var index = source.startIndex

    source.formIndex(&index, offsetBy: 2)
    guard index < source.endIndex, source[index] == CodeUnits.colon else {
        return nil
    }

    source.formIndex(&index, offsetBy: 1)
    guard let minute = scanDigits(source: source[index...], n: 2) else {
        return nil
    }

    source.formIndex(&index, offsetBy: 2)
    guard index < source.endIndex, source[index] == CodeUnits.colon else {
        return nil
    }

    source.formIndex(&index, offsetBy: 1)
    guard let second = scanDigits(source: source[index...], n: 2) else {
        return nil
    }

    source.formIndex(&index, offsetBy: 2)
    return (hour, minute, second, index)
}

struct DateTimeComponents: Equatable {
    let date: LocalDate?
    let time: LocalTime?
    let offset: Int16?
    let features: OffsetDateTime.Features

    var crystalized: Any {
        switch (date, time, offset) {
        case let (.some(date), .some(time), .some(offset)):
            OffsetDateTime(date: date, time: time, offset: offset, features: features)
        case let (.some(date), .some(time), .none):
            LocalDateTime(date: date, time: time)
        case let (.some(date), .none, .none):
            date
        case let (.none, .some(time), .none):
            time
        default:
            fatalError("unreachable")
        }
    }

    @inline(__always)
    func localDate(exactMatch: Bool = true, error: @autoclosure () -> TOMLError) throws(TOMLError) -> LocalDate {
        switch (date, time, offset) {
        case let (.some(date), .none, .none):
            return date
        case let (.some(date), _, _) where !exactMatch:
            return date
        default:
            throw error()
        }
    }

    @inline(__always)
    func localTime(exactMatch: Bool = true, error: @autoclosure () -> TOMLError) throws(TOMLError) -> LocalTime {
        switch (date, time, offset) {
        case let (.none, .some(time), .none):
            return time
        case let (_, .some(time), _) where !exactMatch:
            return time
        default:
            throw error()
        }
    }

    @inline(__always)
    func localDateTime(exactMatch: Bool = true, error: @autoclosure () -> TOMLError) throws(TOMLError) -> LocalDateTime {
        switch (date, time, offset) {
        case let (.some(date), .some(time), .none):
            return LocalDateTime(date: date, time: time)
        case let (.some(date), .some(time), .some) where !exactMatch:
            return LocalDateTime(date: date, time: time)
        default:
            throw error()
        }
    }
}

func parseNanoSeconds(source: String.UTF8View.SubSequence, updatedIndex: inout String.UTF8View.Index) -> UInt32 {
    var unit: Double = 100_000_000
    var result: Double = 0
    var index = source.startIndex
    while index < source.endIndex, source[index].isHexDigit {
        result += Double(source[index] - CodeUnits.number0) * unit
        index = source.index(after: index)
        unit /= 10
    }
    updatedIndex = index
    return UInt32(result)
}

// `nil` signals this isn't a string. Errors indicates ill-formed strings
func stringMaybe(_ text: String.UTF8View.SubSequence) throws(TOMLError) -> String? {
    var multiline = false

    if text.isEmpty {
        return nil
    }

    let quoteChar = text[text.startIndex]
    var index = text.startIndex
    var endIndex = text.endIndex
    guard quoteChar == CodeUnits.doubleQuote || quoteChar == CodeUnits.singleQuote else {
        return nil
    }

    if text.starts(with: Constants.tripleDoubleQuote) || text.starts(with: Constants.tripleSingleQuote) {
        multiline = true
        index = text.index(index, offsetBy: 3)
        endIndex = text.index(endIndex, offsetBy: -3)

        if index < endIndex, text[index] == CodeUnits.lf {
            index = text.index(after: index)
        } else if text[index...].starts(with: [CodeUnits.cr, CodeUnits.lf]) {
            index = text.index(index, offsetBy: 2)
        }
    } else {
        index = text.index(after: index)
        endIndex = text.index(before: endIndex)
        guard text[endIndex] == quoteChar else {
            throw TOMLError.stringMissingClosingQuote(single: quoteChar == CodeUnits.singleQuote)
        }
    }

    if quoteChar == CodeUnits.singleQuote {
        return try literalString(source: text[index ..< endIndex], multiline: multiline)
    } else {
        return try basicString(source: text[index ..< endIndex], multiline: multiline)
    }
}

func boolMaybe(_ text: String.UTF8View.SubSequence) throws(TOMLError) -> Bool {
    if text.count == 4, text.starts(with: Constants.true) {
        return true
    } else if text.count == 5, text.starts(with: Constants.false) {
        return false
    }

    throw TOMLError.invalidBool(text)
}

func intMaybe(_ text: String.UTF8View.SubSequence, mustBeInt: Bool) throws(TOMLError) -> Int64 {
    @_transparent
    func isValidDigit(_ codeUnit: UTF8.CodeUnit, base: Int) -> Bool {
        switch base {
        case 10:
            codeUnit.isDecimalDigit
        case 16:
            codeUnit.isHexDigit
        case 2:
            codeUnit == CodeUnits.number0 || codeUnit == CodeUnits.number1
        case 8:
            CodeUnits.number0 <= codeUnit && codeUnit <= CodeUnits.number7
        default:
            false
        }
    }

    @_transparent
    func error(_ mustBeInt: Bool, _ reason: String) -> TOMLError {
        mustBeInt ? .invalidInteger(reason: reason) : .invalidNumber(reason: reason)
    }

    var mustBeInt = mustBeInt
    var resultCodeUnits: [UTF8.CodeUnit] = []
    var index = text.startIndex
    var base = 10
    var hasSign = false
    if text[index] == CodeUnits.plus || text[index] == CodeUnits.minus {
        hasSign = true
        resultCodeUnits.append(text[index])
        index = text.index(after: index)
    }

    if text[index] == CodeUnits.underscore {
        throw error(mustBeInt, "cannot start with a '_'")
    }

    if text[index] == CodeUnits.number0 {
        let nextIndex = text.index(after: index)
        if nextIndex < text.endIndex {
            if text[nextIndex] == CodeUnits.lowerX {
                if hasSign {
                    throw TOMLError.invalidInteger(reason: "hexadecimal integers cannot have explicit signs")
                }
                base = 16
                text.formIndex(&index, offsetBy: 2)
                mustBeInt = true
            } else if text[nextIndex] == CodeUnits.lowerO {
                if hasSign {
                    throw TOMLError.invalidInteger(reason: "octal integers cannot have explicit signs")
                }
                base = 8
                text.formIndex(&index, offsetBy: 2)
                mustBeInt = true
            } else if text[nextIndex] == CodeUnits.lowerB {
                if hasSign {
                    throw TOMLError.invalidInteger(reason: "binary integers cannot have explicit signs")
                }
                base = 2
                text.formIndex(&index, offsetBy: 2)
                mustBeInt = true
            } else if text[nextIndex].isDecimalDigit || text[nextIndex] == CodeUnits.underscore {
                throw error(mustBeInt, "decimal integers cannot have leading zeros")
            }
        }
        // Single zero is allowed to continue to the main loop
    }

    while index < text.endIndex {
        let ch = text[index]
        index = text.index(after: index)

        if ch == CodeUnits.underscore {
            guard
                let last = resultCodeUnits.last,
                isValidDigit(last, base: base)
            else {
                throw error(mustBeInt, "cannot use '_' adjacent to a non-digit")
            }

            if index >= text.endIndex {
                throw error(mustBeInt, "cannot end with a '_'")
            }

            let next = text[index]
            if next == CodeUnits.underscore {
                throw error(mustBeInt, "cannot contain consecutive '_'")
            }
            guard isValidDigit(next, base: base) else {
                throw error(mustBeInt, "cannot use '_' adjacent to a non-digit")
            }
            continue
        }

        guard isValidDigit(ch, base: base) else {
            throw error(mustBeInt, "invalid digit for base \(base)")
        }

        resultCodeUnits.append(ch)
    }

    let s = String(decoding: resultCodeUnits, as: UTF8.self)
    guard let i = Int64(s, radix: base) else {
        throw error(mustBeInt, "\(s) is a invalid integer of base \(base)")
    }
    return i
}

func floatMaybe(_ text: String.UTF8View.SubSequence, mustBeFloat: Bool) throws(TOMLError) -> Double {
    @_transparent
    func error(_ mustBeFloat: Bool, _ reason: String) -> TOMLError {
        mustBeFloat ? .invalidFloat(reason: reason) : .invalidNumber(reason: reason)
    }

    var mustBeFloat = mustBeFloat
    var resultCodeUnits: [UTF8.CodeUnit] = []
    var index = text.startIndex
    if text[index] == CodeUnits.plus || text[index] == CodeUnits.minus {
        resultCodeUnits.append(text[index])
        index = text.index(after: index)
    }

    if isdigit(Int32(text[index])) == 0 {
        guard text[index...].starts(with: Constants.nan) || text[index...].starts(with: Constants.inf) else {
            throw error(mustBeFloat, "Expected 0-9, nan or inf, found \(text[index])")
        }
        resultCodeUnits.append(contentsOf: text[index ..< text.index(index, offsetBy: 3)])
    } else {
        if text[index] == CodeUnits.number0,
           index < text.endIndex,
           case let next = text[text.index(after: index)],
           next != CodeUnits.dot, next != CodeUnits.lowerE, next != CodeUnits.upperE
        {
            throw error(mustBeFloat, "Float begins with 0 must be followed by a '.', 'e' or 'E'")
        }

        while index < text.endIndex {
            let ch = text[index]
            index = text.index(after: index)

            if ch == CodeUnits.underscore {
                guard
                    let last = resultCodeUnits.last,
                    isdigit(Int32(last)) != 0
                else {
                    throw error(mustBeFloat, "'_' must be preceded by a digit")
                }

                guard
                    index < text.endIndex,
                    case let next = text[index],
                    isdigit(Int32(next)) != 0
                else {
                    throw error(mustBeFloat, "'_' must be follewed by a digit")
                }

                continue
            } else if ch == CodeUnits.dot {
                if resultCodeUnits.isEmpty {
                    throw error(mustBeFloat, "First digit of floats cannot be '.'")
                }

                if !resultCodeUnits.last!.isDecimalDigit {
                    throw error(mustBeFloat, "'.' must be preceded by a decimal digit")
                }

                guard index < text.endIndex, isdigit(Int32(text[index])) != 0 else {
                    throw error(mustBeFloat, "A digit must follow '.'")
                }

                mustBeFloat = true
            } else if ch == CodeUnits.upperE || ch == CodeUnits.lowerE {
                mustBeFloat = true
            } else if !ch.isDecimalDigit, ch != CodeUnits.plus, ch != CodeUnits.minus {
                throw error(mustBeFloat, "invalid character for float")
            }

            resultCodeUnits.append(ch)
        }
    }

    guard let double = Double(String(decoding: resultCodeUnits, as: UTF8.self)) else {
        throw error(mustBeFloat, "not a float")
    }

    return double
}

func datetimeMaybe(lineNumber: Int?, _ text: String.UTF8View.SubSequence) throws(TOMLError) -> DateTimeComponents {
    var mustParseTime = false
    var date: (year: Int, month: Int, day: Int)?
    var time: (hour: Int, minute: Int, second: Int)?

    var index = text.startIndex
    if let (year, month, day, _) = scanDate(source: text) {
        // Validate date components
        if month < 1 || month > 12 {
            throw TOMLError.invalidDateTime(lineNumber: lineNumber, reason: "month must be between 01 and 12")
        }
        if day < 1 {
            throw TOMLError.invalidDateTime(lineNumber: lineNumber, reason: "day must be between 01 and 31")
        }

        // Validate days per month and leap years
        let isLeapYear = year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)
        let maxDaysInMonth: Int = switch month {
        case 2:
            isLeapYear ? 29 : 28
        case 4, 6, 9, 11:
            30
        default:
            31
        }

        if day > maxDaysInMonth {
            if month == 2, !isLeapYear {
                throw TOMLError.invalidDateTime(lineNumber: lineNumber, reason: "February only has 28 days in non-leap years")
            } else if month == 2, isLeapYear {
                throw TOMLError.invalidDateTime(lineNumber: lineNumber, reason: "February only has 29 days in leap years")
            } else {
                throw TOMLError.invalidDateTime(lineNumber: lineNumber, reason: "day \(day) is invalid for month \(month)")
            }
        }

        date = (year, month, day)
        text.formIndex(&index, offsetBy: 10)
    }

    var features: OffsetDateTime.Features = []
    if index < text.endIndex {
        if date != nil {
            let isSeparatorLowerT = text[index] == CodeUnits.lowerT
            let isSeparatorUpperT = text[index] == CodeUnits.upperT
            guard isSeparatorLowerT || isSeparatorUpperT || text[index] == CodeUnits.space else {
                throw TOMLError.invalidDateTime(lineNumber: lineNumber, reason: "expected 'T' or 't' or space to separate date and time")
            }
            if isSeparatorLowerT {
                features.insert(.lowercaseT)
            } else if isSeparatorUpperT {
                features.insert(.uppercaseT)
            }
            mustParseTime = true
            text.formIndex(&index, offsetBy: 1)
        } else {
            // For standalone time values, don't advance index
            mustParseTime = true
        }
    }
    var nanoseconds: UInt32?
    var timeOffset: Int16?

    if index < text.endIndex, let (hour, minute, second, _) = scanTime(source: text[index...]) {
        // Validate time components
        if hour > 23 {
            throw TOMLError.invalidDateTime(lineNumber: lineNumber, reason: "hour must be between 00 and 23")
        }
        if minute > 59 {
            throw TOMLError.invalidDateTime(lineNumber: lineNumber, reason: "minute must be between 00 and 59")
        }
        if second > 59 {
            throw TOMLError.invalidDateTime(lineNumber: lineNumber, reason: "second must be between 00 and 59")
        }

        time = (hour, minute, second)

        text.formIndex(&index, offsetBy: 8)
        if index < text.endIndex, text[index] == CodeUnits.dot {
            text.formIndex(&index, offsetBy: 1)
            let beforeNanoIndex = index
            nanoseconds = parseNanoSeconds(source: text[index...], updatedIndex: &index)
            // Must have at least one digit after decimal point
            if index == beforeNanoIndex {
                throw TOMLError.invalidDateTime(lineNumber: lineNumber, reason: "decimal point must be followed by digits")
            }
        }
    }

    if mustParseTime, time == nil {
        throw TOMLError.invalidDateTime(lineNumber: lineNumber, reason: "expected valid time")
    }

    if index < text.endIndex {
        if text[index] == CodeUnits.lowerZ {
            features.insert(.lowercaseZ)
            text.formIndex(&index, offsetBy: 1)
            timeOffset = 0
        } else if text[index] == CodeUnits.upperZ {
            features.insert(.uppercaseZ)
            text.formIndex(&index, offsetBy: 1)
            timeOffset = 0
        } else if text[index] == CodeUnits.plus || text[index] == CodeUnits.minus {
            let offsetIsNegative = text[index] == CodeUnits.minus
            text.formIndex(&index, offsetBy: 1)

            // Scan ahead to find the end of the timezone offset
            var endIndex = index
            while endIndex < text.endIndex {
                let ch = text[endIndex]
                if isdigit(Int32(ch)) != 0 || ch == CodeUnits.colon {
                    endIndex = text.index(after: endIndex)
                } else {
                    break
                }
            }

            // Extract and validate the complete offset string
            let offsetString = text[index ..< endIndex]
            let (offsetHour, offsetMinute, consumedLength) = try parseTimezoneOffset(offsetString, lineNumber: lineNumber ?? 0)

            // Validate timezone offset ranges
            if offsetHour > 24 {
                throw TOMLError.invalidDateTime(lineNumber: lineNumber, reason: "timezone offset hour must be between 00 and 24")
            }
            if offsetMinute > 59 {
                throw TOMLError.invalidDateTime(lineNumber: lineNumber, reason: "timezone offset minute must be between 00 and 59")
            }

            // Advance index by actual consumed length
            text.formIndex(&index, offsetBy: consumedLength)

            let offset = Int16(offsetHour * 60 + offsetMinute)
            timeOffset = offsetIsNegative ? -offset : offset
        }
    }

    if index < text.endIndex {
        throw TOMLError.invalidDateTime(lineNumber: lineNumber, reason: "extra character after date time")
    }
    return DateTimeComponents(
        date: date.map { LocalDate(year: .init($0.year), month: .init($0.month), day: .init($0.day)) },
        time: time.map { LocalTime(hour: .init($0.hour), minute: .init($0.minute), second: .init($0.second), nanosecond: nanoseconds ?? 0) },
        offset: timeOffset,
        features: features,
    )
}

func parseTimezoneOffset(_ text: String.UTF8View.SubSequence, lineNumber: Int) throws(TOMLError) -> (hour: Int, minute: Int, consumedLength: Int) {
    guard text.count >= 2 else {
        throw TOMLError.invalidDateTime(lineNumber: lineNumber, reason: "timezone offset must have at least 2 digits for hour")
    }

    var index = text.startIndex

    // Parse hour digits (exactly 2 required)
    guard
        index < text.endIndex,
        isdigit(Int32(text[index])) != 0,
        case let firstHourDigit = text[index],
        case let nextIndex = text.index(after: index),
        nextIndex < text.endIndex,
        isdigit(Int32(text[nextIndex])) != 0,
        case let secondHourDigit = text[nextIndex]
    else {
        throw TOMLError.invalidDateTime(lineNumber: lineNumber, reason: "timezone offset hour must be exactly 2 digits")
    }

    let offsetHour = Int(firstHourDigit - CodeUnits.number0) * 10 + Int(secondHourDigit - CodeUnits.number0)
    index = text.index(nextIndex, offsetBy: 1)
    var consumedLength = 2

    // Parse required minute digits (timezone offset must include minutes)
    guard index < text.endIndex, text[index] == CodeUnits.colon else {
        throw TOMLError.invalidDateTime(lineNumber: lineNumber, reason: "timezone offset must include minutes (format: ±HH:MM)")
    }

    index = text.index(after: index)
    consumedLength += 1

    guard
        index < text.endIndex,
        isdigit(Int32(text[index])) != 0,
        case let firstMinuteDigit = text[index],
        case let nextMinuteIndex = text.index(after: index),
        nextMinuteIndex < text.endIndex,
        isdigit(Int32(text[nextMinuteIndex])) != 0,
        case let secondMinuteDigit = text[nextMinuteIndex]
    else {
        throw TOMLError.invalidDateTime(lineNumber: lineNumber, reason: "timezone offset minute must be exactly 2 digits")
    }

    let offsetMinute = Int(firstMinuteDigit - CodeUnits.number0) * 10 + Int(secondMinuteDigit - CodeUnits.number0)
    consumedLength += 2

    return (offsetHour, offsetMinute, consumedLength)
}

extension Deserializer {
    func normalizeKey(token: Token) throws(TOMLError) -> String {
        var start = token.text.startIndex
        var end = sourceUTF8.index(start, offsetBy: token.text.count)
        let ch = sourceUTF8[start]
        var result = ""
        if ch == CodeUnits.doubleQuote || ch == CodeUnits.singleQuote {
            if sourceUTF8[sourceUTF8.index(start, offsetBy: 1)] == ch, sourceUTF8[sourceUTF8.index(start, offsetBy: 2)] == ch {
                // Keys cannot be multiline
                throw TOMLError.badKey(lineNumber: token.lineNumber)
            } else {
                start = sourceUTF8.index(start, offsetBy: 1)
                end = sourceUTF8.index(end, offsetBy: -1)
            }
            if ch == CodeUnits.singleQuote {
                result = String(Substring(sourceUTF8[start ..< end]))
            } else {
                result = try basicString(source: sourceUTF8[start ..< end], multiline: false)
            }

            return result
        }

        guard sourceUTF8[start ..< end].allSatisfy({ byte in
            (byte >= CodeUnits.number0 && byte <= CodeUnits.number9) || // 0-9
                (byte >= CodeUnits.upperA && byte <= CodeUnits.upperZ) || // A-Z
                (byte >= CodeUnits.lowerA && byte <= CodeUnits.lowerZ) || // a-z
                byte == CodeUnits.underscore || // _
                byte == CodeUnits.minus // -
        }) else {
            throw TOMLError.badKey(lineNumber: token.lineNumber)
        }

        if let keyTransform {
            return keyTransform(String(Substring(sourceUTF8[start ..< end])))
        }

        return String(Substring(sourceUTF8[start ..< end]))
    }

    func createKeyValue(token: Token, inTable tableIndex: Int) throws(TOMLError) -> Int {
        let key = try normalizeKey(token: token)
        if tables[tableIndex][self, key] != nil {
            throw TOMLError.badKey(lineNumber: token.lineNumber)
        }
        let kv = KeyValuePair(key: key, value: .empty)
        let index = keyValues.count
        keyValues.append(kv)

        tables[tableIndex].keyValues.append(index)
        return index
    }

    func createKeyTable(token: Token, inTable tableIndex: Int, implicit: Bool = false) throws(TOMLError) -> Int {
        let key = try normalizeKey(token: token)

        // Check if parent table is readOnly (inline table)
        if tables[tableIndex].readOnly {
            throw TOMLError.syntax(lineNumber: token.lineNumber, message: "cannot add to inline table")
        }

        switch tables[tableIndex][self, key] {
        case let .table(existingTableIndex):
            if tables[existingTableIndex].implicit {
                if tables[existingTableIndex].definedByDottedKey {
                    throw TOMLError.keyExists(lineNumber: token.lineNumber)
                }
                tables[existingTableIndex].implicit = false
                return existingTableIndex
            }
            throw TOMLError.keyExists(lineNumber: token.lineNumber)
        case .keyValue, .array:
            throw TOMLError.keyExists(lineNumber: token.lineNumber)
        case nil:
            break
        }
        let index = tables.count
        var newTable = TOMLTableImplementation(key: key)
        newTable.implicit = implicit
        newTable.definedByDottedKey = implicit
        tables.append(newTable)

        tables[tableIndex].tables.append(index)
        return index
    }

    func createKeyArray(token: Token, inTable tableIndex: Int, kind: TOMLArrayImplementation.Kind? = nil) throws(TOMLError) -> Int {
        let key = try normalizeKey(token: token)
        if tables[tableIndex][self, key] != nil {
            throw TOMLError.keyExists(lineNumber: token.lineNumber)
        }

        let index = arrays.count
        arrays.append(TOMLArrayImplementation(key: key, kind: kind))
        tables[tableIndex].arrays.append(index)
        return index
    }

    func nextToken(isDotSpecial: Bool) throws(TOMLError) {
        var lineNumber = token.lineNumber
        var position = token.text.startIndex

        while position < token.text.endIndex {
            let ch = token.text[position]
            if ch == CodeUnits.lf {
                lineNumber += 1
            }
            token.text.formIndex(after: &position)
        }

        while position < sourceUTF8.endIndex {
            let ch = sourceUTF8[position]
            if ch == CodeUnits.pound {
                // skip comment, stop just before the \n.
                position = sourceUTF8.index(after: position)
                while position < sourceUTF8.endIndex, sourceUTF8[position] != CodeUnits.lf {
                    let commentChar = sourceUTF8[position]
                    // Validate comment characters - control characters are not allowed except CR when followed by LF (CRLF)
                    if (commentChar >= CodeUnits.null && commentChar <= CodeUnits.backspace)
                        || (commentChar >= CodeUnits.lf && commentChar <= CodeUnits.unitSeparator)
                        || commentChar == CodeUnits.delete
                    {
                        if commentChar == CodeUnits.cr {
                            let nextPosition = sourceUTF8.index(after: position)
                            if nextPosition < sourceUTF8.endIndex, sourceUTF8[nextPosition] == CodeUnits.lf {
                                // Allow CRLF sequence
                            } else {
                                throw TOMLError.syntax(lineNumber: lineNumber, message: "control characters are not allowed in comments")
                            }
                        } else {
                            throw TOMLError.syntax(lineNumber: lineNumber, message: "control characters are not allowed in comments")
                        }
                    }
                    position = sourceUTF8.index(after: position)
                }
                continue
            }

            if ch == CodeUnits.dot && isDotSpecial {
                token = Token(
                    kind: .dot,
                    lineNumber: lineNumber,
                    text: sourceUTF8[position ..< sourceUTF8.index(after: position)],
                    eof: false,
                )
                return
            }

            if ch == CodeUnits.comma {
                token = Token(
                    kind: .comma,
                    lineNumber: lineNumber,
                    text: sourceUTF8[position ..< sourceUTF8.index(after: position)],
                    eof: false,
                )
                return
            } else if ch == CodeUnits.equal {
                token = Token(
                    kind: .equal,
                    lineNumber: lineNumber,
                    text: sourceUTF8[position ..< sourceUTF8.index(after: position)],
                    eof: false,
                )
                return
            } else if ch == CodeUnits.lbrace {
                token = Token(
                    kind: .lbrace,
                    lineNumber: lineNumber,
                    text: sourceUTF8[position ..< sourceUTF8.index(after: position)],
                    eof: false,
                )
                return
            } else if ch == CodeUnits.rbrace {
                token = Token(
                    kind: .rbrace,
                    lineNumber: lineNumber,
                    text: sourceUTF8[position ..< sourceUTF8.index(after: position)],
                    eof: false,
                )
                return
            } else if ch == CodeUnits.lbracket {
                token = Token(
                    kind: .lbracket,
                    lineNumber: lineNumber,
                    text: sourceUTF8[position ..< sourceUTF8.index(after: position)],
                    eof: false,
                )
                return
            } else if ch == CodeUnits.rbracket {
                token = Token(
                    kind: .rbracket,
                    lineNumber: lineNumber,
                    text: sourceUTF8[position ..< sourceUTF8.index(after: position)],
                    eof: false,
                )
                return
            } else if ch == CodeUnits.lf {
                token = Token(
                    kind: .newline,
                    lineNumber: lineNumber,
                    text: sourceUTF8[position ..< sourceUTF8.index(after: position)],
                    eof: false,
                )
                return
            } else if ch == CodeUnits.cr {
                // Check if this is part of a CRLF sequence
                let nextPosition = sourceUTF8.index(after: position)
                if nextPosition < sourceUTF8.endIndex, sourceUTF8[nextPosition] == CodeUnits.lf {
                    // This is CRLF, treat as newline
                    token = Token(
                        kind: .newline,
                        lineNumber: lineNumber,
                        text: sourceUTF8[position ..< sourceUTF8.index(nextPosition, offsetBy: 1)],
                        eof: false,
                    )
                    return
                } else {
                    // Bare CR is invalid
                    throw TOMLError.syntax(lineNumber: lineNumber, message: "bare carriage return is not allowed")
                }
            } else if ch == CodeUnits.space || ch == CodeUnits.tab {
                // ignore white spaces
                position = sourceUTF8.index(after: position)
                continue
            }

            try scanString(text: sourceUTF8[position...], lineNumber: lineNumber, dotIsSpecial: isDotSpecial)
            return
        }

        token = Token(
            kind: .newline,
            lineNumber: lineNumber,
            text: sourceUTF8[position...],
            eof: true,
        )
    }

    func scanString(text: String.UTF8View.SubSequence, lineNumber: Int, dotIsSpecial: Bool) throws(TOMLError) {
        let start = text.startIndex

        if text.starts(with: Constants.tripleSingleQuote) {
            var i = text.index(start, offsetBy: 3)
            while i < text.endIndex {
                if text[i...].starts(with: Constants.tripleSingleQuote) {
                    // Check if this is exactly 3 quotes (not part of a longer sequence)
                    let afterTriple = text.index(i, offsetBy: 3)
                    if afterTriple >= text.endIndex || text[afterTriple] != CodeUnits.singleQuote {
                        break
                    }
                }
                i = text.index(after: i)
            }

            guard i < text.endIndex else {
                throw TOMLError.syntax(lineNumber: lineNumber, message: "unterminated triple-s-quote")
            }

            let end = text.index(i, offsetBy: 3)
            token = Token(
                kind: .string,
                lineNumber: lineNumber,
                text: text[start ..< end],
                eof: false,
            )
            return
        }

        if text.starts(with: Constants.tripleDoubleQuote) {
            var i = text.index(start, offsetBy: 3)
            while i < text.endIndex {
                if text[i...].starts(with: Constants.tripleDoubleQuote) {
                    // Check if this is exactly 3 quotes (not part of a longer sequence)
                    let afterTriple = text.index(i, offsetBy: 3)
                    if afterTriple >= text.endIndex || text[afterTriple] != CodeUnits.doubleQuote {
                        // Also check if this quote sequence is escaped
                        if i > start, text[text.index(before: i)] == CodeUnits.backslash {
                            i = text.index(after: i)
                            continue
                        }
                        break
                    }
                }
                i = text.index(after: i)
            }

            guard i < text.endIndex else {
                throw TOMLError.syntax(lineNumber: lineNumber, message: "unterminated triple-d-quote")
            }

            let end = text.index(i, offsetBy: 3)
            token = Token(
                kind: .string,
                lineNumber: lineNumber,
                text: text[start ..< end],
                eof: false,
            )
            return
        }

        let ch = text[start]
        if ch == CodeUnits.singleQuote {
            var i = text.index(after: start)
            while i < text.endIndex {
                let ch = text[i]
                if ch == CodeUnits.singleQuote || ch == CodeUnits.lf {
                    break
                }
                i = text.index(after: i)
            }

            if i >= text.endIndex || text[i] != CodeUnits.singleQuote {
                throw TOMLError.syntax(lineNumber: lineNumber, message: "unterminated s-quote")
            }

            token = Token(
                kind: .string,
                lineNumber: lineNumber,
                text: text[start ... i],
                eof: false,
            )
            return
        }

        if ch == CodeUnits.doubleQuote {
            var i = text.index(after: start)
            var expectedHexDigit = 0
            var escape = false

            while i < text.endIndex {
                let ch = text[i]
                if escape {
                    escape = false
                    if ch == CodeUnits.lowerB || ch == CodeUnits.lowerT || ch == CodeUnits.lowerN || ch == CodeUnits.lowerF || ch == CodeUnits.lowerR || ch == CodeUnits.doubleQuote || ch == CodeUnits.backslash {
                        text.formIndex(after: &i)
                        continue
                    }

                    if ch == CodeUnits.lowerU {
                        expectedHexDigit = 4
                        text.formIndex(after: &i)
                        continue
                    }

                    if ch == CodeUnits.upperU {
                        expectedHexDigit = 8
                        text.formIndex(after: &i)
                        continue
                    }

                    throw TOMLError.syntax(lineNumber: lineNumber, message: "expected escape char")
                }

                if expectedHexDigit > 0 {
                    expectedHexDigit -= 1
                    if ch.isHexDigit {
                        text.formIndex(after: &i)
                        continue
                    }
                    throw TOMLError.syntax(lineNumber: lineNumber, message: "expect hex char")
                }

                if ch == CodeUnits.backslash {
                    escape = true
                    text.formIndex(after: &i)
                    continue
                }

                if ch == CodeUnits.singleQuote {
                    text.formIndex(after: &i)
                    continue
                }

                if ch == CodeUnits.lf || ch == CodeUnits.doubleQuote {
                    break
                }
                text.formIndex(after: &i)
            }

            if i >= text.endIndex || text[i] != CodeUnits.doubleQuote {
                throw TOMLError.syntax(lineNumber: lineNumber, message: "unterminated quote")
            }

            token = Token(
                kind: .string,
                lineNumber: lineNumber,
                text: text[start ... i],
                eof: false,
            )
            return
        }

        if !dotIsSpecial {
            var index = text.startIndex
            let dateEnder = scanDate(source: text)?.3
            if let dateEnder, dateEnder < text.endIndex, text[dateEnder] == CodeUnits.upperT || text[dateEnder] == CodeUnits.lowerT || text[dateEnder] == CodeUnits.space {
                let timeStarter = text.index(after: dateEnder)
                if let timeEnder = scanTime(source: text[timeStarter...])?.3 {
                    index = timeEnder
                }
            } else if let dateEnder {
                index = dateEnder
            } else if let timeEnder = scanTime(source: text)?.3 {
                index = timeEnder
            }
            if index > text.startIndex {
                if index < text.endIndex {
                    if text[index] == CodeUnits.dot {
                        text.formIndex(after: &index)
                        while index < text.endIndex, text[index] >= CodeUnits.number0, text[index] <= CodeUnits.number9 {
                            text.formIndex(after: &index)
                        }
                    }
                    if text[index] == CodeUnits.upperZ || text[index] == CodeUnits.lowerZ {
                        text.formIndex(after: &index)
                    } else if let timzoneEnder = scanTimezoneOffset(source: text[index...]) {
                        index = timzoneEnder
                    }
                }
                // squeeze out any spaces at end of string
                while index >= text.startIndex, text[text.index(before: index)] == CodeUnits.space {
                    text.formIndex(before: &index)
                }
                // tokenize
                token = Token(
                    kind: .string,
                    lineNumber: lineNumber,
                    text: text[start ..< index],
                    eof: false,
                )
                return
            }
        }

        var index = text.startIndex
        while index < text.endIndex {
            let ch = text[index]
            if ch == CodeUnits.lf {
                break
            }

            if ch == CodeUnits.dot && dotIsSpecial {
                break
            }

            if CodeUnits.upperA <= ch && ch <= CodeUnits.upperZ {
                text.formIndex(after: &index)
                continue
            }

            if CodeUnits.lowerA <= ch && ch <= CodeUnits.lowerZ {
                text.formIndex(after: &index)
                continue
            }

            if ch.isDecimalDigit
                || ch == CodeUnits.dot
                || ch == CodeUnits.plus
                || ch == CodeUnits.minus
                || ch == CodeUnits.underscore
            {
                text.formIndex(after: &index)
                continue
            }

            break
        }

        token = Token(
            kind: .string,
            lineNumber: lineNumber,
            text: text[start ..< index],
            eof: false,
        )
    }

    func skipNewlines(isDotSpecial: Bool) throws(TOMLError) {
        while token.kind == .newline {
            try nextToken(isDotSpecial: isDotSpecial)
            if token.eof {
                break
            }
        }
    }

    func eatToken(type: Token.Kind, isDotSpecial: Bool) throws(TOMLError) {
        if token.kind != type {
            throw TOMLError.internalError(lineNumber: token.lineNumber)
        }
        try nextToken(isDotSpecial: isDotSpecial)
    }

    func parseInlineTable(tableIndex: Int) throws(TOMLError) {
        try eatToken(type: .lbrace, isDotSpecial: true)

        while true {
            if token.kind == .newline {
                throw TOMLError.syntax(lineNumber: token.lineNumber, message: "newline not allowed in inline table")
            }

            if token.kind == .rbrace {
                break
            }

            if token.kind != .string {
                throw TOMLError.syntax(lineNumber: token.lineNumber, message: "expect a string")
            }

            try parseKeyValue(tableIndex: tableIndex)

            if token.kind == .newline {
                throw TOMLError.syntax(lineNumber: token.lineNumber, message: "newline not allowed in inline table")
            }

            if token.kind == .comma {
                try eatToken(type: .comma, isDotSpecial: true)
                // Check for trailing comma - if next token is rbrace, it's a trailing comma error
                if token.kind == .rbrace {
                    throw TOMLError.syntax(lineNumber: token.lineNumber, message: "trailing comma not allowed in inline table")
                }
                continue
            }
            break
        }

        try eatToken(type: .rbrace, isDotSpecial: true)

        tables[tableIndex].readOnly = true
    }

    func parseArray(arrayIndex: Int) throws(TOMLError) {
        try eatToken(type: .lbracket, isDotSpecial: false)

        var array = arrays[arrayIndex]
        while true {
            try skipNewlines(isDotSpecial: false)

            if token.kind == .rbracket {
                break
            }

            switch token.kind {
            case .string:
                if array.kind == nil {
                    array.kind = .value
                } else if array.kind != .value {
                    array.kind = .mixed
                }

                array.elements.append(.leaf(token))

                try eatToken(type: .string, isDotSpecial: true)

            case .lbracket: // Nested array
                if array.kind == nil {
                    array.kind = .array
                } else if array.kind != .array {
                    array.kind = .mixed
                }

                let newArrayIndex = arrays.count
                arrays.append(TOMLArrayImplementation())
                array.elements.append(.array(lineNumber: token.lineNumber, newArrayIndex))

                try parseArray(arrayIndex: newArrayIndex)

            case .lbrace: // Nested table
                if array.kind == nil {
                    array.kind = .table
                } else if array.kind != .table {
                    array.kind = .mixed
                }

                let newTableIndex = tables.count
                tables.append(TOMLTableImplementation())
                array.elements.append(.table(lineNumber: token.lineNumber, newTableIndex))

                try parseInlineTable(tableIndex: newTableIndex)

            default:
                throw TOMLError.syntax(lineNumber: token.lineNumber, message: "syntax error")
            }

            try skipNewlines(isDotSpecial: false)

            if token.kind == .comma {
                try eatToken(type: .comma, isDotSpecial: false)
                continue
            }
            break
        }

        try eatToken(type: .rbracket, isDotSpecial: true)

        arrays[arrayIndex] = array
    }

    func parseKeyValue(tableIndex: Int) throws(TOMLError) {
        let table = tables[tableIndex]
        if table.readOnly {
            throw TOMLError.syntax(lineNumber: token.lineNumber, message: "cannot insert new entry into existing table")
        }

        let key = token
        try eatToken(type: .string, isDotSpecial: true)

        if token.kind == .dot {
            let subTableKey = try normalizeKey(token: key)
            let subTableIndex: Int

            if let existingTableIndex = lookupTable(in: table, key: subTableKey) {
                // Check if the existing table is explicitly defined (not implicit)
                if !tables[existingTableIndex].implicit {
                    throw TOMLError.syntax(lineNumber: token.lineNumber, message: "cannot add to explicitly defined table using dotted keys")
                }
                subTableIndex = existingTableIndex
            } else {
                subTableIndex = try createKeyTable(token: key, inTable: tableIndex, implicit: true)
            }

            try nextToken(isDotSpecial: true)
            try parseKeyValue(tableIndex: subTableIndex)
            return
        }

        if token.kind != .equal {
            throw TOMLError.syntax(lineNumber: token.lineNumber, message: "missing =")
        }

        try nextToken(isDotSpecial: false)

        if token.kind == .string {
            let index = try createKeyValue(token: key, inTable: tableIndex)
            let value = token

            // Check if this looks like a datetime but fails to parse
            if scanDate(source: value.text) != nil {
                _ = try datetimeMaybe(lineNumber: token.lineNumber, value.text)
            }

            keyValues[index].value = value
            try nextToken(isDotSpecial: false)
            return
        }

        if token.kind == .lbracket {
            let index = try createKeyArray(token: key, inTable: tableIndex)
            try parseArray(arrayIndex: index)
            return
        }

        if token.kind == .lbrace {
            let index = try createKeyTable(token: key, inTable: tableIndex)
            try parseInlineTable(tableIndex: index)
            return
        }

        throw TOMLError.syntax(lineNumber: token.lineNumber, message: "syntax error")
    }

    func lookupTable(in table: TOMLTableImplementation, key: String) -> Int? {
        for i in 0 ..< table.tables.count {
            if tables[table.tables[i]].key == key {
                return table.tables[i]
            }
        }
        return nil
    }

    func lookupArray(in table: TOMLTableImplementation, key: String) -> Int? {
        for i in 0 ..< table.arrays.count {
            if arrays[table.arrays[i]].key == key {
                return table.arrays[i]
            }
        }
        return nil
    }

    func fillTablePath() throws(TOMLError) {
        let lineNumber = token.lineNumber
        tablePath.removeAll(keepingCapacity: true)

        while true {
            if token.kind != .string {
                throw TOMLError.syntax(lineNumber: lineNumber, message: "invalid or missing key")
            }

            let key = try normalizeKey(token: token)
            tablePath.append((key, token))
            try nextToken(isDotSpecial: true)

            if token.kind == .rbracket {
                break
            }

            if token.kind != .dot {
                throw TOMLError.syntax(lineNumber: token.lineNumber, message: "invalid key")
            }

            try nextToken(isDotSpecial: true)
        }
        if tablePath.isEmpty {
            throw TOMLError.syntax(lineNumber: lineNumber, message: "empty table selector")
        }
    }

    func walkTablePath() throws(TOMLError) {
        var tableIndex = 0
        for (key, _) in tablePath {
            switch tables[tableIndex][self, key] {
            case let .table(index):
                tableIndex = index
            case let .array(arrayIndex):
                let array = arrays[arrayIndex]
                guard case .table = array.kind else {
                    throw TOMLError.syntax(lineNumber: token.lineNumber, message: "array element is not a table")
                }

                if array.elements.isEmpty {
                    throw TOMLError.syntax(lineNumber: token.lineNumber, message: "empty array")
                }

                guard case let .table(_, index) = array.elements.last else {
                    throw TOMLError.syntax(lineNumber: token.lineNumber, message: "array element is not a table")
                }

                tableIndex = index
            case .keyValue:
                throw TOMLError.syntax(lineNumber: token.lineNumber, message: "key-value already exists")
            default:
                let newTableAddress = tables.count
                var newTable = TOMLTableImplementation(key: key)
                newTable.implicit = true
                newTable.definedByDottedKey = false
                tables.append(newTable)

                tables[tableIndex].tables.append(newTableAddress)
                tableIndex = newTableAddress
            }
        }

        currentTable = tableIndex
    }

    func parseSelect() throws(TOMLError) {
        assert(token.kind == .lbracket)
        let index = token.text.startIndex
        let nextIndex = sourceUTF8.index(after: index)
        let llb = index < sourceUTF8.endIndex
            && sourceUTF8[index] == CodeUnits.lbracket
            && nextIndex < sourceUTF8.endIndex
            && sourceUTF8[nextIndex] == CodeUnits.lbracket

        try eatToken(type: .lbracket, isDotSpecial: true)
        if llb {
            try eatToken(type: .lbracket, isDotSpecial: true)
        }

        try fillTablePath()

        // For [x.y.z] or [[x.y.z]], remove z from tpath.
        let (_, z) = tablePath.removeLast()
        try walkTablePath()

        if !llb {
            // [x.y.z] -> create z = {} in x.y
            currentTable = try createKeyTable(token: z, inTable: currentTable)
        } else {
            // [[x.y.z]] -> create z = [] in x.y
            let key = try normalizeKey(token: z)
            var maybeArrayIndex = lookupArray(in: tables[currentTable], key: key)
            if maybeArrayIndex == nil {
                maybeArrayIndex = try createKeyArray(token: z, inTable: currentTable, kind: .table)
            }
            let arrayIndex = maybeArrayIndex!
            if arrays[arrayIndex].kind != .table {
                throw TOMLError.syntax(lineNumber: token.lineNumber, message: "array mismatch")
            }

            // add to z[]
            let newTableIndex = tables.count
            tables.append(TOMLTableImplementation(key: Constants.anonymousArryKey))
            arrays[arrayIndex].elements.append(.table(lineNumber: token.lineNumber, newTableIndex))
            currentTable = newTableIndex
        }

        if token.kind != .rbracket {
            throw TOMLError.syntax(lineNumber: token.lineNumber, message: "expects ]")
        }

        if llb {
            let nextIndex = token.text.index(after: token.text.startIndex)
            guard nextIndex < sourceUTF8.endIndex, sourceUTF8[nextIndex] == CodeUnits.rbracket else {
                throw TOMLError.syntax(lineNumber: token.lineNumber, message: "expects ]]")
            }
            try eatToken(type: .rbracket, isDotSpecial: true)
        }
        try eatToken(type: .rbracket, isDotSpecial: true)

        if token.kind != .newline {
            throw TOMLError.syntax(lineNumber: token.lineNumber, message: "extra chars after ] or ]]")
        }
    }

    func parse() throws(TOMLError) -> TOMLTable {
        while !token.eof {
            switch token.kind {
            case .newline:
                try nextToken(isDotSpecial: true)
            case .string:
                try parseKeyValue(tableIndex: currentTable)
                if token.kind != .newline {
                    throw TOMLError.syntax(lineNumber: token.lineNumber, message: "extra chars after value")
                }
                try eatToken(type: .newline, isDotSpecial: true)
            case .lbracket:
                try parseSelect()
            default:
                throw TOMLError.syntax(lineNumber: token.lineNumber, message: "syntax error")
            }
        }

        return TOMLTable(source: self, index: 0)
    }
}

extension TOMLTableImplementation {
    func dictionary(source: Deserializer) throws(TOMLError) -> [String: Any] {
        var result = [String: Any]()
        for tableIndex in tables {
            let table = source.tables[tableIndex]
            guard let key = table.key else { continue }
            result[key] = try table.dictionary(source: source)
        }

        for arrayIndex in arrays {
            let array = source.arrays[arrayIndex]
            guard let key = array.key else { continue }
            result[key] = try array.array(source: source)
        }

        for kvIndex in keyValues {
            let pair = source.keyValues[kvIndex]
            result[pair.key] = try pair.value.unpackValue(errorForInvalidValue: TOMLError.invalidValueInTable(lineNumber: pair.value.lineNumber, key: pair.key))
        }

        return result
    }
}

extension TOMLArrayImplementation {
    func array(source: Deserializer) throws(TOMLError) -> [Any] {
        var result = [Any]()

        for (index, element) in zip(0..., elements) {
            switch element {
            case let .array(_, arrayIndex):
                try result.append(source.arrays[arrayIndex].array(source: source))
            case let .table(_, tableIndex):
                try result.append(source.tables[tableIndex].dictionary(source: source))
            case let .leaf(token):
                let error = TOMLError.invalidValueInArray(lineNumber: token.lineNumber, index: index)
                try result.append(token.unpackValue(errorForInvalidValue: error))
            }
        }

        return result
    }
}

extension Token {
    func unpackValue(errorForInvalidValue: @autoclosure () -> TOMLError) throws(TOMLError) -> Any {
        let firstChar = text.first
        if firstChar == CodeUnits.singleQuote || firstChar == CodeUnits.doubleQuote {
            do {
                if let text = try stringMaybe(text) {
                    return text
                }
            } catch {
                throw error
            }
        }

        if let boolValue = try? boolMaybe(text) {
            return boolValue
        }

        do {
            return try intMaybe(text, mustBeInt: false)
        } catch {
            if case TOMLError.invalidInteger = error {
                throw error
            }
        }

        do {
            return try floatMaybe(text, mustBeFloat: false)
        } catch {
            if case TOMLError.invalidFloat = error {
                throw error
            }
        }

        guard firstChar?.isDecimalDigit == true else {
            throw errorForInvalidValue()
        }

        let datetime = try datetimeMaybe(lineNumber: nil, text)
        switch (datetime.date, datetime.time, datetime.offset) {
        case let (.some(date), .some(time), .some(offset)):
            return OffsetDateTime(date: date, time: time, offset: offset, features: datetime.features)
        case let (.some(date), .some(time), .none):
            return LocalDateTime(date: date, time: time)
        case let (.some(date), .none, .none):
            return date
        case let (.none, .some(time), .none):
            return time
        default:
            throw errorForInvalidValue()
        }
    }
}
