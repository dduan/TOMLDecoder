import struct Foundation.DateComponents
import struct Foundation.Date

typealias DottedKey = [Traced<String>]

struct RawKeyValuePair: Equatable {
    let key: DottedKey

    let value: TOMLValue
}

struct _KeyValuePair: Equatable {
    let key: TOMLValue
    let value: TOMLValue
}

enum TopLevel: Equatable {
    case keyValue(RawKeyValuePair)
    case table(DottedKey)
    case arrayTable(DottedKey)
    case error(Substring.Index, Reason)
    case valueError(Substring.Index, TOMLValue.Reason)

    enum Reason: Equatable {
        case missingKey
        case missingValue
        case standardTableMissingOpening
        case standardTableMissingClosing
        case arrayTableMissingClosing
        case invalidExpression
    }

    init(convertingKey key: TOMLValue, _ convert: @escaping (DottedKey) -> TopLevel) {
        switch key {
        case .key(let dottedKey):
            self = convert(dottedKey)
        case .error(let index, let reason):
            self = .valueError(index, reason)
        default:
            fatalError("Failed converting TOML key to TopLevel value")
        }
    }
}

extension TopLevel.Reason: CustomStringConvertible {
    var description: String {
        switch self {
        case .missingKey:
            return "Missing key in key-value pair"
        case .missingValue:
            return "Missing value in key-value pair"
        case .standardTableMissingOpening:
            return "Missing opening character `[` in table"
        case .standardTableMissingClosing:
            return "Missing closing character `]` in table"
        case .arrayTableMissingClosing:
            return "Missing closing character `]]` in array table"
        case .invalidExpression:
            return "Invalid TOML expression"
        }
    }
}

/// Explicitly declared array table. This is distinct from a array that happens
/// to have tables.
struct TOMLArrayTable {
    var storage: [_TOMLTable]

    subscript(_ index: Int) -> _TOMLTable {
        get { storage[index] }
        set { storage[index] = newValue }
    }

    init(storage: [_TOMLTable] = []) {
        self.storage = storage
    }
}

func stripInternal(_ value: Any) -> Any {
    if let valueTable = value as? _TOMLTable {
        var result = [String: Any]()
        for (key, value) in valueTable.storage {
            result[key] = stripInternal(value)
        }
        return result
    } else if let valueArray = value as? [Any] {
        return valueArray.map(stripInternal(_:))
    } else if let valueArrayTable = value as? TOMLArrayTable {
        return valueArrayTable.storage.map(stripInternal(_:))
    } else {
        return value
    }
}
struct _TOMLTable {
    var isMutable: Bool
    var storage: [String: Any]

    var stripped: [String: Any] {
        stripInternal(self) as! [String: Any]
    }

    subscript(_ key: String) -> Any? {
        get { storage[key] }
        set { storage[key] = newValue }
    }

    init() {
        isMutable = true
        storage = [:]
    }
}

indirect enum TOMLValue: Equatable {
    case string(Traced<String>)
    case boolean(Bool)
    case array([TOMLValue])
    case inlineTable([RawKeyValuePair])
    case date(Date)
    case dateComponents(DateComponents)
    case float(Double)
    case integer(Int64)
    case key(DottedKey)
    case error(Substring.Index, Reason)

    enum Reason: Equatable {
        case invalidUnicodeSequence
        case literalStringMissingOpening
        case literalStringMissingClosing
        case multilineLiteralStringMissingClosing
        case multilineLiteralStringHasTooManySingleQuote
        case basicStringMissingOpening
        case basicStringMissingClosing
        case multilineBasicStringMissingClosing
        case multilineLiteralStringHasTooManyDoubleQuote
        case invalidTime
        case invalidDate
        case invalidTimeOffset
        case inlineTableMissingClosing
        case incompleteDottedKey
        case invalidDecimal
        case invalidHexadecimal
        case invalidOctal
        case invalidBinary
        case invalidFloatMissingFraction
        case invalidNewline
        case invalidControlCharacterInComment
    }
}

extension TOMLValue.Reason: CustomStringConvertible {
    var description: String {
        switch self {
        case .invalidUnicodeSequence:
            return "Invalid unicode sequence"
        case .literalStringMissingClosing:
            return "Missing closing character `'` in literal string"
        case .literalStringMissingOpening:
            return "Missing opening character `'` in literal string"
        case .multilineLiteralStringMissingClosing:
            return "Missing closing character `'''` in multiline literal string"
        case .multilineLiteralStringHasTooManySingleQuote:
            return "Multiline literal string has more than 2 `'`s"
        case .multilineLiteralStringHasTooManyDoubleQuote:
            return "Multiline literal string has more than 2 `\"`s"
        case .basicStringMissingOpening:
            return "Missing opening character `\"` in string"
        case .basicStringMissingClosing:
            return "Missing closing character `\"` in string"
        case .multilineBasicStringMissingClosing:
            return "Missing closing character `\"\"\"` in multiline string"
        case .invalidTime:
            return "Ill-formatted time"
        case .invalidDate:
            return "Ill-formatted date"
        case .invalidTimeOffset:
            return "Ill-formatted time offset"
        case .inlineTableMissingClosing:
            return "Missing closing character `]` in table"
        case .incompleteDottedKey:
            return "Dotted key lacks a final part"
        case .invalidDecimal:
            return "Invalid decimal value: can't represent by 64-bit integer"
        case .invalidHexadecimal:
            return "Ill-formed hexadecimal"
        case .invalidOctal:
            return "Ill-formed octal"
        case .invalidBinary:
            return "Ill-formed binary integer"
        case .invalidFloatMissingFraction:
            return "Floating number missing fraction"
        case .invalidNewline:
            return "Carriage return alone is not a valid newline"
        case .invalidControlCharacterInComment:
            return "Invalid control character found in comment"
        }
    }
}

@discardableResult
func whitespace(_ input: inout Substring) -> Bool {
    if input.isEmpty {
        return false
    }

    let utf8 = input.utf8
    var index = utf8.startIndex
    while index < utf8.endIndex, (utf8[index] == 0x20 || utf8[index] == 0x09)  {
        utf8.formIndex(after: &index)
    }

    let detecetd = index != utf8.startIndex
    input = Substring(utf8[index...])

    return detecetd
}

@inline(__always)
func isAlpha(_ c: UTF8.CodeUnit) -> Bool {
    c >= 0x41 && c <= 0x5A || c >= 0x61 && c <= 0x7A
}

@inline(__always)
func isDigit(_ c: UTF8.CodeUnit) -> Bool {
    c >= 0x30 && c <= 0x39
}

@inline(__always)
func isHexDigit(_ c: UnicodeScalar) -> Bool {
    let v = c.value
    let isDigit = v >= 0x30 && v <= 0x39
    let isUpper = v >= 0x41 && v <= 0x46
    let isLower = v >= 0x61 && v <= 0x66
    return isDigit || isUpper || isLower
}

func unquotedKey(_ input: inout Substring) -> String? {
    let utf8 = input.utf8
    var index = utf8.startIndex
    while index < utf8.endIndex, case let c = utf8[index], isAlpha(c) || isDigit(c) || c == 0x2D || c == 0x5F {
        utf8.formIndex(after: &index)
    }

    guard utf8.startIndex != index else {
        return nil
    }

    input = Substring(utf8[index...])
    return String(utf8[utf8.startIndex ..< index])
}

enum _Constants {
    static let backslashScalar = "\\".unicodeScalars.first!
    static let lfScalar = "\n".unicodeScalars
    static let crlfScalar = "\r\n".unicodeScalars
    static let lfUTF8 = "\n".utf8.first!
    static let crUTF8 = "\r".utf8.first!
    static let doubleQuoteScalar = "\"".unicodeScalars.first!
    static let singleQuoteScalar = "'".unicodeScalars.first!
    static let singleQuoteUTF8 = "'".utf8.first!
    static let doubleQuoteUTF8 = "\"".utf8.first!
    static let periodUTF8 = ".".utf8.first!
    static let lowercaseUScalarValue = "u".unicodeScalars.first!.value
    static let uppercaseUScalarValue = "U".unicodeScalars.first!.value
    static let trueUTF8Sequence = "true".utf8
    static let falseUTF8Sequence = "false".utf8
    static let hexPrefixUTF8Sequence = "0x".utf8
    static let octPrefixUTF8Sequence = "0o".utf8
    static let binPrefixUTF8Sequence = "0b".utf8
    static let plusUTF8 = "+".utf8.first!
    static let minusUTF8 = "-".utf8.first!
    static let zeroUTF8 = "0".utf8.first!
    static let dashUTF8 = "-".utf8.first!
    static let lowerEUTF8 = "e".utf8.first!
    static let upperEUTF8 = "E".utf8.first!
    static let spaceUTF8 = " ".utf8.first!
    static let lowerTUTF8 = "t".utf8.first!
    static let upperTUTF8 = "T".utf8.first!
    static let underscoreUTF8 = "_".utf8.first!
    static let colonUTF8 = ":".utf8.first!
    static let nanUTF8Sequence = "nan".utf8
    static let infUTF8Sequence = "inf".utf8
    static let poundScalar = "#".unicodeScalars.first!
    static let tripleDoubleQuoteScalar = "\"\"\"".unicodeScalars
    static let tripleSingleQuoteScalar = "'''".unicodeScalars
    static let upperZUTF8 = "Z".utf8.first!
    static let lowerZUTF8 = "z".utf8.first!
    static let openBracketUTF8 = "[".utf8.first!
    static let openBraceUTF8 = "{".utf8.first!
}

@inline(__always)
func isUnescapedChar(_ c: UnicodeScalar) -> Bool {
    let value = c.value
    return value == 0x0A ||
        value == 0x0D ||
        isBasicUnescapedChar(c)
}

@inline(__always)
func isBasicUnescapedChar(_ c: UnicodeScalar) -> Bool {
    let value = c.value
    return value == 0x20 ||
        value == 0x09 ||
        value == 0x21 ||
        value >= 0x23 && value <= 0x5B ||
        value >= 0x5D && value <= 0x7E ||
        value >= 0x80 && value <= 0xD7FF ||
        value >= 0xE000 && value <= 0x10FFFF
}

func escaped(_ index: inout Substring.UnicodeScalarView.Index, _ input: Substring.UnicodeScalarView) -> UnicodeScalar?? {
    let originalIndex = index
    guard input[index] == _Constants.backslashScalar else {
        return nil
    }

    input.formIndex(after: &index)

    var result: UnicodeScalar?
    var is4Digit = true
    switch input[index].value {
    case 0x22: result = UnicodeScalar(0x22) // "    quotation mark  U+0022
    case 0x5C: result = UnicodeScalar(0x5C) // \    reverse solidus U+005C
    case 0x62: result = UnicodeScalar(0x08) // b    backspace       U+0008
    case 0x66: result = UnicodeScalar(0x0C) // f    form feed       U+000C
    case 0x6E: result = UnicodeScalar(0x0A) // n    line feed       U+000A
    case 0x72: result = UnicodeScalar(0x0D) // r    carriage return U+000D
    case 0x74: result = UnicodeScalar(0x09) // t    tab             U+0009
    case _Constants.lowercaseUScalarValue:
        is4Digit = true
    case _Constants.uppercaseUScalarValue:
        is4Digit = false
    case 0x20, 0x0A, 0x0D, 0x09:
        index = originalIndex
        return nil
    default:
        index = originalIndex
        return .some(nil)
    }

    input.formIndex(after: &index)

    if let result = result {
        return result
    }

    let seqStart = index
    let stoppingPoint = is4Digit ? 4 : 8

    for _ in 0 ..< stoppingPoint {
        if isHexDigit(input[index]) {
            input.formIndex(after: &index)
        } else {
            index = originalIndex
            return nil
        }
    }

    if let scalar = Int(String(input[seqStart ..< index]), radix: 16).flatMap(UnicodeScalar.init) {
        result = scalar
    } else {
        return .some(nil)
    }

    if let result = result {
        return result
    } else {
        index = originalIndex
        return nil
    }
}

func basicString(_ input: inout Substring) -> TOMLValue? {
    let scalars = input.unicodeScalars
    var result = [UTF32.CodeUnit]()
    var index = scalars.startIndex
    var hasEscaped = false
    guard scalars.first == _Constants.doubleQuoteScalar else {
        return nil
    }

    scalars.formIndex(after: &index)
    let contentBegin = index
    while index < input.endIndex {
        let c = scalars[index]
        let escapedValue = escaped(&index, scalars)
        switch escapedValue {
        case .some(.none):
            return .error(index, .invalidUnicodeSequence)
        case .some(.some(let scalar)):
            hasEscaped = true
            result.append(scalar.value)
            continue
        case .none:
            break
        }

        if c == _Constants.doubleQuoteScalar {
            let contentEnd = index
            scalars.formIndex(after: &index)
            input = Substring(scalars[index...])
            let result = hasEscaped ? String(decoding: result, as: UTF32.self) : String(scalars[contentBegin ..< contentEnd])
            return .string(.init(value: result, index: input.startIndex))
        }

        if isBasicUnescapedChar(c) {
            result.append(c.value)
            scalars.formIndex(after: &index)
        } else {
            input = Substring(scalars[index...])
            return .error(input.startIndex, .basicStringMissingClosing)
        }
    }

    return .error(input.startIndex, .basicStringMissingClosing)
}

func _toTimestamp(year: Int, month: Int, day: Int, hour: Int, minute: Int, seconds: Int, nanoseconds: Int, offsetInSeconds: Int) -> Double {
    var year = year
    year -= month <= 2 ? 1 : 0
    let era = (year >= 0 ? year : year - 399) / 400
    let yoe = year - era * 400
    let doy = (153*(month + (month > 2 ? -3 : 9)) + 2)/5 + day - 1
    let doe = yoe * 365 + yoe/4 - yoe/100 + doy
    let dayCounts = era * 146097 + doe - 719468
    let seconds = dayCounts * 86400 + hour * 3600 + minute * 60 + seconds - offsetInSeconds
    return Double(seconds) + Double(nanoseconds) / 1_000_000_000
}

@inline(__always)
func isNonASCII(_ c: UnicodeScalar) -> Bool {
    let v = c.value
    return v >= 0x80 && v <= 0xD7FF || v >= 0xE000 && v <= 0x10FFFF
}

func isNonEOL(_ c: UnicodeScalar) -> Bool {
    let v = c.value
    return v == 0x09 || v >= 0x20 && v <= 0x7F || isNonASCII(c)
}

@inline(__always)
func isLiteralChar(_ c: UnicodeScalar) -> Bool {
    let v = c.value
    return v == 0x09 ||
        v >= 0x20 && v <= 0x26 ||
        v >= 0x28 && v <= 0x7E ||
        isNonASCII(c)
}

func literalString(_ input: inout Substring) -> TOMLValue? {
    let scalars = input.unicodeScalars
    var index = scalars.startIndex
    guard scalars.first == _Constants.singleQuoteScalar else {
        return nil
    }

    scalars.formIndex(after: &index)
    let bodyIndexStart = index
    while index < input.endIndex {
        let c = scalars[index]

        if c == _Constants.singleQuoteScalar {
            let bodyEndIndex = index
            scalars.formIndex(after: &index)
            input = Substring(scalars[index...])
            return .string(.init(value: String(scalars[bodyIndexStart ..< bodyEndIndex]), index: input.startIndex))
        }

        if isLiteralChar(c) {
            scalars.formIndex(after: &index)
        } else {
            input = Substring(scalars[index...])
            return .error(input.startIndex, .literalStringMissingClosing)
        }
    }

    return .error(input.startIndex, .literalStringMissingClosing)
}

// Returns: .string or .error
func simpleKey(_ input: inout Substring) -> TOMLValue? {
    whitespace(&input)
    let utf8 = input.utf8
    if utf8.first == _Constants.singleQuoteUTF8 {
        return literalString(&input)
    }

    if utf8.first == _Constants.doubleQuoteUTF8 {
        return basicString(&input)
    }

    return unquotedKey(&input).map { TOMLValue.string(.init(value: $0, index: input.startIndex)) }
}

/// Returns: .key or .error
func key(_ input: inout Substring) -> TOMLValue? {
    guard let first = simpleKey(&input) else {
        return nil
    }

    var parts = [first]

    whitespace(&input)
    while input.first == "." {
        input.removeFirst()
        parts.append(simpleKey(&input) ?? .error(input.startIndex, .incompleteDottedKey))
        whitespace(&input)
    }

    var keyParts = DottedKey()
    for part in parts {
        switch part {
        case .error:
            return part // propagate the first error
        case .string(let s):
            keyParts.append(s)
        default:
            fatalError("\(#function) Expect simpleKey to return .error or .string")
        }
    }

    return .key(keyParts)
}

func boolean(_ input: inout Substring) -> TOMLValue? {
    var utf8 = input.utf8
    if utf8.starts(with: _Constants.trueUTF8Sequence) {
        utf8.removeFirst(4)
        input = Substring(utf8)

        return .boolean(true)
    }

    if utf8.starts(with: _Constants.falseUTF8Sequence) {
        utf8.removeFirst(5)
        input = Substring(utf8)

        return .boolean(false)
    }

    return nil
}

func decIntTextUTF8(_ utf8: inout Substring.UTF8View, afterDec: Bool = false) -> [UTF8.CodeUnit]? {
    var index = utf8.startIndex
    var result = [UTF8.CodeUnit]()

    if utf8.first == _Constants.plusUTF8 || utf8.first == _Constants.minusUTF8 {
        result.append(utf8.first!)
        utf8.formIndex(after: &index)
    }

    if !afterDec && index < utf8.endIndex && utf8[index] == _Constants.zeroUTF8 {
        utf8.formIndex(after: &index)
        utf8 = utf8[index...]
        result.append(_Constants.zeroUTF8)
        return result
    }

    var startUTF8NumRange = 0x31
    let endUTF8NumRange = 0x39
    if afterDec {
        startUTF8NumRange = 0x30
    }
    guard !utf8.isEmpty, utf8[index] >= startUTF8NumRange && utf8[index] <= endUTF8NumRange else {
        return nil
    }

    result.append(utf8[index])
    utf8.formIndex(after: &index)

    while index < utf8.endIndex {
        let value = utf8[index]
        if isDigit(value) {
            result.append(utf8[index])
        } else if value == _Constants.underscoreUTF8 { // TODO: report trailing '_' as value error
            utf8.formIndex(after: &index)
            if index >= utf8.endIndex || (utf8[index] < 0x30 || utf8[index] > 0x39) {
                return nil
            }

            continue
        } else {
            break
        }

        utf8.formIndex(after: &index)
    }

    utf8 = utf8[index...]
    return result
}

func decIntText(_ input: inout Substring) -> Substring? {
    var utf8 = input.utf8
    if let utf8Seq = decIntTextUTF8(&utf8) {
        input = Substring(utf8)
        return Substring(decoding: utf8Seq, as: UTF8.self)
    }

    return nil
}

/// Returns: .integer or .error
func decInt(_ input: inout Substring) -> TOMLValue? {
    switch decIntText(&input).map({ Int64($0) }) {
    case .some(.some(let result)):
        return .integer(result)
    case .some(nil):
        synchronizeUntilExpression(&input)
        return .error(input.startIndex, .invalidDecimal)
    case .none:
        return nil
    }
}

func hexInt(_ input: inout Substring) -> TOMLValue? {
    @inline(__always)
    func isHexDigit(_ c: UTF8.CodeUnit) -> Bool {
        let isDigit = c >= 0x30 && c <= 0x39
        let isUpper = c >= 0x41 && c <= 0x46
        let isLower = c >= 0x61 && c <= 0x66
        return isDigit || isUpper || isLower
    }

    let utf8 = input.utf8
    var index = utf8.startIndex
    var body = [UTF8.CodeUnit]()
    guard utf8.starts(with: _Constants.hexPrefixUTF8Sequence) else {
        return nil
    }

    index = utf8.index(index, offsetBy: 2)

    var previousWasDigit = false
    while index < utf8.endIndex {
        let c = utf8[index]
        if isHexDigit(c) {
            body.append(c)
            previousWasDigit = true
        } else if c == _Constants.underscoreUTF8 {
            guard previousWasDigit else {
                return TOMLValue.error(index, .invalidHexadecimal)
            }

            utf8.formIndex(after: &index)
            guard index < utf8.endIndex && isHexDigit(utf8[index]) else {
                return TOMLValue.error(index, .invalidHexadecimal)
            }

            previousWasDigit = false
            continue
        } else {
            break
        }

        input.formIndex(after: &index)
    }

    guard let n = Int64(String(decoding: body, as: UTF8.self), radix: 16) else {
        return TOMLValue.error(input.startIndex, .invalidHexadecimal)
    }

    input = Substring(utf8[index...])
    return .integer(n)
}

func octInt(_ input: inout Substring) -> TOMLValue? {
    @inline(__always)
    func isOctDigit(_ c: UTF8.CodeUnit) -> Bool {
        c >= 0x30 && c <= 0x37
    }

    let utf8 = input.utf8
    var index = utf8.startIndex
    var body = [UTF8.CodeUnit]()
    guard utf8.starts(with: _Constants.octPrefixUTF8Sequence) else {
        return nil
    }

    index = utf8.index(index, offsetBy: 2)

    var previousWasDigit = false

    while index < utf8.endIndex {
        let c = utf8[index]
        if isOctDigit(c) {
            body.append(c)
            previousWasDigit = true
        } else if c == _Constants.underscoreUTF8 {
            guard previousWasDigit else {
                return TOMLValue.error(index, .invalidOctal)
            }

            utf8.formIndex(after: &index)
            guard index < utf8.endIndex && isOctDigit(utf8[index]) else {
                return TOMLValue.error(index, .invalidOctal)
            }

            previousWasDigit = false
            continue
        } else {
            break
        }

        input.formIndex(after: &index)
    }

    guard let n = Int64(String(decoding: body, as: UTF8.self), radix: 8) else {
        return TOMLValue.error(input.startIndex, .invalidOctal)
    }

    input = Substring(utf8[index...])
    return .integer(n)
}

func binInt(_ input: inout Substring) -> TOMLValue? {
    @inline(__always)
    func isBinDigit(_ c: UTF8.CodeUnit) -> Bool {
        c == 0x30 || c == 0x31
    }

    let utf8 = input.utf8
    var index = utf8.startIndex
    var body = [UTF8.CodeUnit]()
    guard utf8.starts(with: _Constants.binPrefixUTF8Sequence) else {
        return nil
    }

    index = utf8.index(index, offsetBy: 2)

    var previousWasDigit = false

    while index < utf8.endIndex {
        let c = utf8[index]
        if isBinDigit(c) {
            body.append(c)
            previousWasDigit = true
        } else if c == _Constants.underscoreUTF8 {
            guard previousWasDigit else {
                return TOMLValue.error(index, .invalidBinary)
            }

            utf8.formIndex(after: &index)
            guard index < utf8.endIndex && isBinDigit(utf8[index]) else {
                return TOMLValue.error(index, .invalidBinary)
            }

            previousWasDigit = false
            continue
        } else {
            break
        }

        input.formIndex(after: &index)
    }

    guard let n = Int64(String(decoding: body, as: UTF8.self), radix: 2) else {
        return TOMLValue.error(input.startIndex, .invalidBinary)
    }

    input = Substring(utf8[index...])
    return .integer(n)
}

/// returns .error or .integer
func integer(_ input: inout Substring) -> TOMLValue? {
    hexInt(&input) ?? octInt(&input) ?? binInt(&input) ?? decInt(&input) // jump to decInt if input doesn't start with 0?
}

func value(_ input: inout Substring) -> TOMLValue? {
    let utf8 = input.utf8
    guard let first = utf8.first else {
        return nil
    }

    switch first {
    case _Constants.doubleQuoteUTF8:
        return multilineBasicString(&input) ?? basicString(&input)
    case _Constants.singleQuoteUTF8:
        return multilineLiteralString(&input) ?? literalString(&input)
    case _Constants.openBraceUTF8:
        return inlineTable(&input)
    case _Constants.openBracketUTF8:
        return array(&input)
    default:
        return dateTime(&input) ?? float(&input) ?? integer(&input) ?? boolean(&input)
    }
}

func keyValuePair(_ input: inout Substring) -> _KeyValuePair? {
    let originalInput = input
    guard let key = key(&input) else {
        return nil
    }

    whitespace(&input)
    guard input.first == "=" else {
        input = originalInput
        return nil
    }

    input.removeFirst()
    whitespace(&input)
    guard let value = value(&input) else {
        input = originalInput
        return nil
    }

    return .init(key: key, value: value)
}

/// returns .keyValue or .valueError
func keyValue(_ input: inout Substring) -> TopLevel? {
    guard let pair = keyValuePair(&input) else {
        return nil
    }

    if case let .error(index, reason) = pair.value {
        return .valueError(index, reason)
    }

    return .init(convertingKey: pair.key) { .keyValue(.init(key: $0, value: pair.value)) }
}

func inlineTableSep(_ input: inout Substring) -> Bool {
    let originalInput = input
    whitespace(&input)
    guard input.first == "," else {
        input = originalInput
        return false
    }

    input.removeFirst()
    whitespace(&input)
    return true
}

/// Returns: .inlineTable or .error
func inlineTableKeyValues(_ input: inout Substring) -> [_KeyValuePair]? {
    let originalInput = input
    guard let first = keyValuePair(&input) else {
        return nil
    }

    var pairs = [first]
    while !input.isEmpty && inlineTableSep(&input) {
        guard let next = keyValuePair(&input) else {
            input = originalInput
            return nil
        }

        pairs.append(next)
    }

    return pairs
}

func inlineTable(_ input: inout Substring) -> TOMLValue? {
    let originalInput = input
    whitespace(&input)
    guard input.first == "{" else {
        input = originalInput
        return nil
    }

    input.removeFirst()
    whitespace(&input)

    let pairs = inlineTableKeyValues(&input) ?? []

    whitespace(&input)
    guard input.first == "}" else {
        input = originalInput
        return nil
    }

    input.removeFirst()
    whitespace(&input)

    var result = [RawKeyValuePair]()
    for pair in pairs {
        if case .error = pair.key {
            return pair.key
        }

        if case .error = pair.value {
            return pair.value
        }

        guard case let .key(dotted) = pair.key else {
            fatalError("\(#function) expected key")
        }

        result.append(.init(key: dotted, value: pair.value))
    }

    return .inlineTable(result)
}

func zeroPrefixableInt(_ utf8: inout Substring.UTF8View) -> [UTF8.CodeUnit]? {
    var index = utf8.startIndex
    guard !utf8.isEmpty, isDigit(utf8[index]) else {
        return nil
    }

    var result = [utf8[index]]
    utf8.formIndex(after: &index)

    while index < utf8.endIndex {
        let c = utf8[index]
        if isDigit(c) {
            result.append(c)
        } else if c == _Constants.underscoreUTF8 {
            utf8.formIndex(after: &index)
            if index >= utf8.endIndex {
                return nil
            }

            if !isDigit(utf8[index]) {
                return nil
            }

            continue
        } else {
            break
        }

        utf8.formIndex(after: &index)
    }

    utf8 = utf8[index...]
    return result
}

func exp(_ utf8: inout Substring.UTF8View) -> [UTF8.CodeUnit]? {
    let originalInput = utf8
    guard let first = utf8.first, first == _Constants.lowerEUTF8 || first == _Constants.upperEUTF8 else {
        return nil
    }

    var result = [first]
    utf8.removeFirst()
    if let sign = utf8.first, (sign == _Constants.plusUTF8 || sign == _Constants.minusUTF8) {
        result.append(sign)
        utf8.removeFirst()
    }

    guard let expBody = zeroPrefixableInt(&utf8) else {
        utf8 = originalInput
        return nil
    }

    return result + expBody
}

func normalFloat(_ input: inout Substring) -> TOMLValue? {
    var utf8 = input.utf8
    guard var result = decIntTextUTF8(&utf8) else {
        return nil
    }

    if let exp = exp(&utf8) {
        result += exp
    } else {
        guard utf8.first == _Constants.periodUTF8 else {
            return nil
        }

        result.append(_Constants.periodUTF8)
        utf8.removeFirst()
        guard let frac = decIntTextUTF8(&utf8, afterDec: true) else {
            let location = input.startIndex
            synchronizeUntilExpression(&input)
            return .error(location, .invalidFloatMissingFraction)
        }

        result += frac

        if let exp = exp(&utf8) {
            result += exp
        }
    }

    input = Substring(decoding: utf8, as: UTF8.self)
    return .float(Double(String(decoding: result, as: UTF8.self))!)
}

func float(_ input: inout Substring) -> TOMLValue? {
    if let normal = normalFloat(&input) {
        return normal
    }

    var utf8 = input.utf8
    var sign = 1.0
    if let first = utf8.first, (first == _Constants.plusUTF8 || first == _Constants.minusUTF8) {
        if first == _Constants.minusUTF8 {
            sign = -1.0
        }

        utf8.removeFirst()
    }

    if utf8.starts(with: _Constants.nanUTF8Sequence) {
        utf8.removeFirst(3)
        input = Substring(utf8)
        return .float(Double.nan)
    }

    if utf8.starts(with: _Constants.infUTF8Sequence) {
        utf8.removeFirst(3)
        input = Substring(utf8)
        return .float(sign * Double.infinity)
    }

    return nil
}

func escapedScalar(_ index: inout Substring.UnicodeScalarView.Index, _ input: Substring.UnicodeScalarView) -> UnicodeScalar?? {
    let originalIndex = index
    guard input[index] == _Constants.backslashScalar else {
        return nil
    }

    input.formIndex(after: &index)

    var result: UnicodeScalar?
    var is4Digit = true
    switch input[index].value {
    case 0x22: result = UnicodeScalar(0x22) // "    quotation mark  U+0022
    case 0x5C: result = UnicodeScalar(0x5C) // \    reverse solidus U+005C
    case 0x62: result = UnicodeScalar(0x08) // b    backspace       U+0008
    case 0x66: result = UnicodeScalar(0x0C) // f    form feed       U+000C
    case 0x6E: result = UnicodeScalar(0x0A) // n    line feed       U+000A
    case 0x72: result = UnicodeScalar(0x0D) // r    carriage return U+000D
    case 0x74: result = UnicodeScalar(0x09) // t    tab             U+0009
    case _Constants.lowercaseUScalarValue:
        is4Digit = true
    case _Constants.uppercaseUScalarValue:
        is4Digit = false
    case 0x20, 0x0A, 0x0D, 0x09:
        index = originalIndex
        return nil
    default:
        index = originalIndex
        return .some(nil)
    }

    input.formIndex(after: &index)

    if let result = result {
        return result
    }

    let seqStart = index
    let stoppingPoint = is4Digit ? 4 : 8

    for _ in 0 ..< stoppingPoint {
        if isHexDigit(input[index]) {
            input.formIndex(after: &index)
        } else {
            index = originalIndex
            return nil
        }
    }

    if let scalar = Int(String(input[seqStart ..< index]), radix: 16).flatMap(UnicodeScalar.init) {
        result = scalar
    } else {
        return .some(nil)
    }

    if let result = result {
        return result
    } else {
        index = originalIndex
        return nil
    }
}

func multilineBasicString(_ input: inout Substring) -> TOMLValue? {
    let scalars = input.unicodeScalars
    var index = scalars.startIndex
    var hasEscaped = false
    guard scalars.starts(with: _Constants.tripleDoubleQuoteScalar) else {
        return nil
    }

    index = scalars.index(index, offsetBy: 3)

    if scalars[index...].starts(with: _Constants.lfScalar) {
        scalars.formIndex(after: &index)
    } else if scalars[index...].starts(with: _Constants.crlfScalar) {
        scalars.formIndex(after: &index)
        scalars.formIndex(after: &index)
    }

    let contentBegin = index
    var result = [UTF32.CodeUnit]()
    var escapingNewline = false
    var invalidNewlineEscapeResumePoint = index
    var seenNewlineSinceEscapingStarted = false
    while index < input.endIndex {
        let c = scalars[index]
        if escapingNewline {
            if scalars[index...].starts(with: _Constants.crlfScalar) {
                input.formIndex(after: &index)
                seenNewlineSinceEscapingStarted = true
            } else if scalars[index...].starts(with: _Constants.lfScalar) {
                input.formIndex(after: &index)
                seenNewlineSinceEscapingStarted = true
            } else if c.value == 0x20 || c.value == 0x0D || c.value == 0x09 {
                input.formIndex(after: &index)
            } else if seenNewlineSinceEscapingStarted {
                escapingNewline = false
            } else {
                index = invalidNewlineEscapeResumePoint
                return .error(index, .invalidUnicodeSequence)
            }

            continue
        }

        let escaped = escapedScalar(&index, scalars)
        switch escaped {
        case .some(.none):
            return .error(index, .invalidUnicodeSequence)
        case .some(.some(let scalar)):
            hasEscaped = true
            result.append(scalar.value)
            continue
        case .none:
            break
        }

        if c == _Constants.backslashScalar {
            input.formIndex(after: &index)
            escapingNewline = true
            hasEscaped = true
            invalidNewlineEscapeResumePoint = index
            seenNewlineSinceEscapingStarted = false
            continue
        }

        if c == _Constants.doubleQuoteScalar {
            let quotesStart = index
            var contentEnd = index
            var consecutiveQuotes = 0

            while index < scalars.endIndex, scalars[index] == _Constants.doubleQuoteScalar {
                consecutiveQuotes += 1
                scalars.formIndex(after: &index)
            }

            if index == scalars.endIndex && consecutiveQuotes < 3 {
                let location = input.startIndex
                input = Substring(scalars[index...])
                return .error(location, .multilineBasicStringMissingClosing)
            }

            if consecutiveQuotes > 2 && consecutiveQuotes <= 5 {
                scalars.formIndex(&contentEnd, offsetBy: consecutiveQuotes - 3)
                result.append(contentsOf: scalars[quotesStart ..< contentEnd].map { $0.value })

                let startIndex = input.startIndex
                input = Substring(Substring.UnicodeScalarView(scalars[index...]))
                let result = hasEscaped
                    ? String(decoding: result, as: UTF32.self)
                    : String(scalars[contentBegin ..< contentEnd])

                return .string(
                    .init(
                        value: result,
                        index: startIndex
                    )
                )
            } else if consecutiveQuotes > 5 {
                let location = input.startIndex
                input = Substring(scalars[index...])
                return .error(location, .multilineLiteralStringHasTooManyDoubleQuote)
            } else {
                result.append(contentsOf: scalars[quotesStart ..< index].map { $0.value })
            }

            continue
        }

        if isUnescapedChar(c) {
            result.append(c.value)
            scalars.formIndex(after: &index)
        } else {
            let location = input.startIndex
            input = Substring(scalars[index...])
            return .error(location, .multilineBasicStringMissingClosing)
        }
    }

    let location = input.startIndex
    input = Substring(scalars[index...])
    return .error(location, .multilineBasicStringMissingClosing)
}

func multilineLiteralString(_ input: inout Substring) -> TOMLValue? {
    func isMultilineChar(_ c: UnicodeScalar) -> Bool {
        let value = c.value
        return value == 0x09 ||
            value >= 0x20 && value <= 0x26 ||
            value >= 0x28 && value <= 0x7E ||
            value >= 0x80 && value <= 0xD7FF ||
            value >= 0xE000 && value <= 0x10FFFF ||
            value == 0x0A ||
            value == 0x0D
    }

    let scalars = input.unicodeScalars
    var index = scalars.startIndex
    guard scalars.starts(with: _Constants.tripleSingleQuoteScalar) else {
        return nil
    }

    index = scalars.index(index, offsetBy: 3)
    if scalars[index...].starts(with: _Constants.lfScalar) {
        scalars.formIndex(after: &index)
    } else if scalars[index...].starts(with: _Constants.crlfScalar) {
        scalars.formIndex(after: &index)
        scalars.formIndex(after: &index)
    }

    let startIndex = index
    var escapingNewline = false
    while index < scalars.endIndex {
        let c = scalars[index]
        if escapingNewline {
            if c.value == 0x0A || c.value == 0x0D {
                scalars.formIndex(after: &index)
            } else if scalars[index...].starts(with: _Constants.lfScalar) {
                scalars.formIndex(after: &index)
            } else if scalars[index...].starts(with: _Constants.crlfScalar) {
                scalars.formIndex(after: &index)
                scalars.formIndex(after: &index)
            } else {
                escapingNewline = false
            }

            continue
        }

        if c == _Constants.backslashScalar {
            scalars.formIndex(after: &index)
            escapingNewline = true
            continue
        }

        if c == _Constants.singleQuoteScalar {
            var contentEnd = index
            var consecutiveQuotes = 0

            while index < scalars.endIndex, scalars[index] == _Constants.singleQuoteScalar {
                consecutiveQuotes += 1
                scalars.formIndex(after: &index)
            }

            if index == scalars.endIndex && consecutiveQuotes < 3 {
                let location = input.startIndex
                input = Substring(scalars[index...])
                return .error(location, .multilineLiteralStringMissingClosing)
            }

            if consecutiveQuotes > 2 && consecutiveQuotes <= 5 {
                scalars.formIndex(&contentEnd, offsetBy: consecutiveQuotes - 3)
                input = Substring(scalars[index...])
                let output = scalars[startIndex ..< contentEnd]
                return .string(.init(value: String(output), index: input.startIndex))
            } else if consecutiveQuotes > 5 {
                let location = input.startIndex
                input = Substring(scalars[index...])
                return .error(location, .multilineLiteralStringHasTooManySingleQuote)
            }

            continue
        }

        if isMultilineChar(c) {
            scalars.formIndex(after: &index)
            continue
        } else {
            let location = input.startIndex
            input = Substring(scalars[index...])
            return .error(location, .multilineLiteralStringMissingClosing)
        }
    }

    let location = input.startIndex
    input = Substring(scalars[index...])
    return .error(location, .multilineLiteralStringMissingClosing)
}

func localDateUTF8(_ utf8: inout Substring.UTF8View) -> (Int, Int, Int)?? {
    var index = utf8.startIndex
    var year = 0
    for _ in 0 ..< 4 {
        guard index < utf8.endIndex, isDigit(utf8[index]) else {
            return nil
        }

        year = year * 10 + Int(utf8[index] - _Constants.zeroUTF8)
        utf8.formIndex(after: &index)
    }

    guard index < utf8.endIndex, utf8[index] == _Constants.dashUTF8 else {
        return nil
    }

    utf8.formIndex(after: &index)

    var month = 0
    for _ in 0 ..< 2 {
        guard index < utf8.endIndex, isDigit(utf8[index]) else {
            return nil
        }

        month = month * 10 + Int(utf8[index] - _Constants.zeroUTF8)
        utf8.formIndex(after: &index)
    }

    if month == 0 || month > 12 {
        return .some(nil)
    }

    guard index < utf8.endIndex, utf8[index] == _Constants.dashUTF8 else {
        return nil
    }

    utf8.formIndex(after: &index)

    var day = 0
    for _ in 0 ..< 2 {
        guard index < utf8.endIndex, isDigit(utf8[index]) else {
            return nil
        }

        day = day * 10 + Int(utf8[index] - _Constants.zeroUTF8)
        utf8.formIndex(after: &index)
    }

    if day == 0 || day > 31 {
        return .some(nil)
    }

    let isLeapYear = year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)
    if (month == 3 || month == 6 || month == 9 || month == 11) && day > 30 ||
        month == 2 && !isLeapYear && day > 28 ||
        month == 2 && isLeapYear && day > 29 ||
        day > 31
    {
        return .some(nil)
    }

    utf8 = utf8[index...]
    return (year, month, day)
}

func localTimeUTF8(_ utf8: inout Substring.UTF8View) -> (Int, Int, Int, Int?)?? {
    var index = utf8.startIndex
    var hour = 0
    for _ in 0 ..< 2 {
        guard index < utf8.endIndex, isDigit(utf8[index]) else {
            return nil
        }

        hour = hour * 10 + Int(utf8[index] - _Constants.zeroUTF8)
        utf8.formIndex(after: &index)
    }

    guard index < utf8.endIndex, utf8[index] == _Constants.colonUTF8 else {
        return nil
    }


    utf8.formIndex(after: &index)

    var minute = 0
    for _ in 0 ..< 2 {
        guard index < utf8.endIndex, isDigit(utf8[index]) else {
            return nil
        }

        minute = minute * 10 + Int(utf8[index] - _Constants.zeroUTF8)
        utf8.formIndex(after: &index)
    }


    guard index < utf8.endIndex, utf8[index] == _Constants.colonUTF8 else {
        return nil
    }

    utf8.formIndex(after: &index)

    var second = 0
    for _ in 0 ..< 2 {
        guard index < utf8.endIndex, isDigit(utf8[index]) else {
            return nil
        }

        second = second * 10 + Int(utf8[index] - _Constants.zeroUTF8)
        utf8.formIndex(after: &index)
    }

    if hour > 23  || minute > 59 || second > 60 {
        return .some(nil)
    }

    if index < utf8.endIndex, utf8[index] == _Constants.periodUTF8 {
        utf8.formIndex(after: &index)
    }

    var fractionText = [_Constants.zeroUTF8, _Constants.periodUTF8]
    while index < utf8.endIndex, isDigit(utf8[index]) {
        fractionText.append(utf8[index])
        utf8.formIndex(after: &index)
    }

    var fraction: Int?
    if fractionText.count > 2 {
        fraction = Int(Double(String(decoding: fractionText, as: UTF8.self))! * 1_000_000_000)
    }

    utf8 = utf8[index...]
    return (hour, minute, second, fraction)
}

/// Returns: seconds from GMT
func timeOffset(_ utf8: inout Substring.UTF8View) -> Int?? {
    if utf8.first == _Constants.upperZUTF8 || utf8.first == _Constants.lowerZUTF8 {
        utf8.removeFirst()
        return 0
    }

    var sign = 1
    switch utf8.first {
    case _Constants.plusUTF8:
        break
    case _Constants.minusUTF8:
        sign = -1
    default:
        return nil
    }

    var index = utf8.startIndex
    utf8.formIndex(after: &index)

    var hour = 0
    for _ in 0 ..< 2 {
        guard index < utf8.endIndex, isDigit(utf8[index]) else {
            return nil
        }

        hour = hour * 10 + Int(utf8[index] - _Constants.zeroUTF8)
        utf8.formIndex(after: &index)
    }

    guard index < utf8.endIndex, utf8[index] == _Constants.colonUTF8 else {
        return nil
    }

    utf8.formIndex(after: &index)

    var minute = 0
    for _ in 0 ..< 2 {
        guard index < utf8.endIndex, isDigit(utf8[index]) else {
            return nil
        }

        minute = minute * 10 + Int(utf8[index] - _Constants.zeroUTF8)
        utf8.formIndex(after: &index)
    }

    if hour > 23 || minute > 59 {
        return .some(nil)
    }

    utf8 = utf8[index...]
    return sign * (hour * 3600 + minute * 60)
}

func dateTime(_ input: inout Substring) -> TOMLValue? {
    let originalInput = input
    var utf8 = input.utf8
    let parsedDateParts = localDateUTF8(&utf8)
    var sep: String.UTF8View.Element?
    var dateParts: (Int, Int, Int)?

    switch parsedDateParts {
    case .some(.some(let parsed)):
        dateParts = parsed
        if (utf8.first == _Constants.lowerTUTF8 || utf8.first == _Constants.upperTUTF8 || utf8.first == _Constants.spaceUTF8) {
            sep = utf8.removeFirst()
        }
    case .some(.none):
        return .error(input.startIndex, .invalidDate)
    case .none:
        break
    }

    let parsedTimeParts = localTimeUTF8(&utf8)
    var timeParts: (Int, Int, Int, Int?)?
    switch parsedTimeParts {
    case .some(.some(let parsed)):
        timeParts = parsed
    case .some(.none):
        return .error(input.startIndex, .invalidTime)
    case .none:
        break
    }

    if dateParts != nil && timeParts == nil && sep != nil && sep != _Constants.spaceUTF8 {
        input = originalInput
        return nil
    }

    var offset: Int?
    if timeParts != nil {
        let parsed = timeOffset(&utf8)
        switch parsed {
        case .some(.none):
            return .error(input.startIndex, .invalidTimeOffset)
        case .some(.some(let parsedOffset)):
            offset = parsedOffset
        case .none:
            break
        }
    }


    if dateParts != nil && timeParts != nil && sep == nil {
        input = originalInput
        return nil
    }

    if let offset = offset {
        guard let dateParts = dateParts else
        {
            input = originalInput
            return nil
        }

        let secs = _toTimestamp(
            year: dateParts.0,
            month: dateParts.1,
            day: dateParts.2,
            hour: timeParts?.0 ?? 0,
            minute: timeParts?.1 ?? 0,
            seconds: timeParts?.2 ?? 0,
            nanoseconds: timeParts?.3 ?? 0,
            offsetInSeconds: offset
        )

        let date = TOMLValue.date(Date(timeIntervalSince1970: secs))

        input = Substring(decoding: utf8, as: UTF8.self)
        return date
    } else if dateParts == nil && timeParts == nil {
        input = originalInput
        return nil
    }

    input = Substring(decoding: utf8, as: UTF8.self)
    return .dateComponents(.init(
        year: dateParts?.0,
        month: dateParts?.1,
        day: dateParts?.2,
        hour: timeParts?.0,
        minute: timeParts?.1,
        second: timeParts?.2,
        nanosecond: timeParts?.3
    ))
}

func comment(_ input: inout Substring) throws -> Bool {
    let scalars = input.unicodeScalars
    guard scalars.first == _Constants.poundScalar else {
        return false
    }

    var index = scalars.startIndex
    scalars.formIndex(after: &index)
    while index < scalars.endIndex, case let c = scalars[index], isNonEOL(c) {
        if c.value >= 0 && c.value <= 0x8 || c.value >= 0xa && c.value <= 0x1f || c.value == 0x7f {
            throw DeserializationError.value(.init(input.base, index, "Control character found in comment"))
        }
        scalars.formIndex(after: &index)
    }

    input = Substring(scalars[index...])
    return true
}

struct NewlineError: Error {
    let index: String.Index
}

@discardableResult
func newline(_ input: inout Substring) throws -> Bool {
    let utf8 = input.utf8
    var index = utf8.startIndex

    while index < utf8.endIndex {
        let c = utf8[index]
        if c == _Constants.lfUTF8 {
          utf8.formIndex(after: &index)
          continue
        } else if c == _Constants.crUTF8 {
            let nextIndex = utf8.index(after: index)
            if nextIndex < utf8.endIndex, utf8[nextIndex] == _Constants.lfUTF8 {
                utf8.formIndex(after: &index)
                utf8.formIndex(after: &index)
                continue
            } else {
                throw NewlineError(index: index)
            }
        }
        break
    }

    let encountered = index != utf8.startIndex
    input = Substring(utf8[index...])
    return encountered
}

@discardableResult
func whitespaceCommentSkip(_ input: inout Substring) throws -> Bool {
    let start = input.startIndex
    while !input.isEmpty {
        if try !(whitespace(&input) || newline(&input) || comment(&input)) {
            break
        }
    }
    return start != input.startIndex
}

func arrayValues(_ input: inout Substring) -> [TOMLValue]? {
    let originalInput = input
    do {
        try whitespaceCommentSkip(&input)
    } catch let error as NewlineError {
        let result = [TOMLValue.error(error.index, .invalidNewline)]
        input.removeFirst()
        return result
    } catch {
        return nil
    }
    guard let first = value(&input) else {
        input = originalInput
        return nil
    }
    do {
        try whitespaceCommentSkip(&input)
    } catch let error as NewlineError {
        let result = [TOMLValue.error(error.index, .invalidNewline)]
        input.removeFirst()
        return result
    } catch {
        return nil
    }
    if input.first == "," {
        input.removeFirst()
        if let rest = arrayValues(&input) {
            return [first] + rest
        }
    }

    return [first]
}

func array(_ input: inout Substring) -> TOMLValue? {
    let originalInput = input
    guard input.first == "[" else {
        return nil
    }

    input.removeFirst()

    let values = arrayValues(&input)

    do {
        try whitespaceCommentSkip(&input)
    } catch let error as NewlineError {
        let result = TOMLValue.error(error.index, .invalidNewline)
        input.removeFirst()
        return result
    } catch {
        return nil
    }
    guard input.first == "]" else {
        input = originalInput
        return nil
    }

    input.removeFirst()

    for value in values ?? [] {
        if case .error = value {
            return value
        }
    }

    return .array(values ?? [])
}

func table(_ input: inout Substring) -> TopLevel? {
    let originalInput = input
    guard input.first == "[" else {
        return nil
    }

    input.removeFirst()
    whitespace(&input)
    guard let key = key(&input) else {
        input = originalInput
        return nil
    }

    whitespace(&input)
    guard input.first == "]" else {
        let location = input.startIndex
        synchronizeUntilExpression(&input)
        return .error(location, .standardTableMissingClosing)
    }
    input.removeFirst()
    return TopLevel(convertingKey: key) { TopLevel.table($0) }
}

func arrayTable(_ input: inout Substring) -> TopLevel? {
    let originalInput = input
    guard input.starts(with: "[[") else {
        return nil
    }
    input.removeFirst(2)
    whitespace(&input)
    guard let key = key(&input) else {
        input = originalInput
        return nil
    }
    whitespace(&input)
    guard input.starts(with: "]]") else {
        let location = input.startIndex
        synchronizeUntilExpression(&input)
        return .error(location, .arrayTableMissingClosing)
    }
    input.removeFirst(2)
    return TopLevel(convertingKey: key) { TopLevel.arrayTable($0) }
}

func expression(_ input: inout Substring) -> TopLevel?? {
    var parsed = false

    do {
        parsed = try whitespaceCommentSkip(&input)
    } catch let error as NewlineError {
        let result = TopLevel.valueError(error.index, .invalidNewline)
        input.removeFirst()
        return result
    } catch {
        return nil
    }

    if let v = keyValue(&input) ?? table(&input) ?? arrayTable(&input) {
        whitespace(&input)
        do {
            _ = try comment(&input)
        } catch {
            return .valueError(input.startIndex, .invalidControlCharacterInComment)
        }

        return v
    }

    do {
        let parsedComment = try comment(&input)
        parsed = parsedComment || parsed
        return parsed ? .some(nil) : nil
    } catch {
        return .valueError(input.startIndex, .invalidControlCharacterInComment)
    }

}

func synchronizeUntilNewLine(_ input: inout Substring) {
    while let first = input.first, first != "\n", first != "\r" {
        input.removeFirst()
    }
}

func synchronizeUntilExpression(_ input: inout Substring) {
    while !input.isEmpty && expression(&input) == nil {
        input.removeFirst()
    }
}

func topLevels(_ input: inout Substring) -> [TopLevel] {
    var result = [TopLevel?]()
    while !input.isEmpty {
        if let first = expression(&input) {
            result.append(first)
            break
        } else {
            if !input.isEmpty {
                result.append(.error(input.startIndex, .invalidExpression))
            }
            synchronizeUntilExpression(&input)
        }
    }

    while !input.isEmpty {
        var foundNewline = false
        do {
            foundNewline = try newline(&input)
        } catch let error as NewlineError {
            result.append(.valueError(error.index, .invalidNewline))
            input.removeFirst()
        } catch {
            continue
        }
        guard foundNewline, let next = expression(&input) else {
            if !input.isEmpty {
                result.append(.error(input.startIndex, .invalidExpression))
            }
            synchronizeUntilNewLine(&input)
            continue
        }

        result.append(next)
    }

    return result.compactMap { $0 }
}


extension TOMLValue {
    func normalize(reference: String) throws -> Any {
        switch self {
        case .error(let index, let reason):
            throw DeserializationError.value(.init(reference, index, reason.description))
        case .boolean(let value):
            return value
        case .string(let value):
            return value.value
        case .float(let value):
            return value
        case .integer(let value):
            return value
        case .dateComponents(let value):
            return value
        case .date(let value):
            return value
        case .array(let array):
            return try array.map { try $0.normalize(reference: reference) }
        case .inlineTable(let inlineTable):
            var table = try assembleTable(from: inlineTable.map(TopLevel.keyValue), referenceInput: reference)
            table.isMutable = false
            return table
        case .key(let dotted):
            fatalError("Normalizing key \(dotted)")
        }
    }
}

func assembleTable(from entries: [TopLevel], referenceInput: String) throws -> _TOMLTable {
    var result = _TOMLTable()
    var context = [Traced<String>]()
    var errors = [Error]()
    var headersSeen = Set<String>()

    func insert(
        table: inout _TOMLTable,
        reference: String,
        header: Array<Traced<String>>.SubSequence,
        key: Array<Traced<String>> = [],
        originalKeyDescription: String? = nil,
        context: [String],
        value: Any,
        isArrayTable: Bool = false,
        isTable: Bool = false
    ) throws {
        let keys = header + key
        assert(!keys.isEmpty)
        let keysDescription = keys.map { $0.value }.joined(separator: ".")
        let headerDescription = header.map { $0.value }.joined(separator: ".")
        let contextDescription = context.joined(separator: ".")
        let key = keys.first!
        if context.count > 1,
            originalKeyDescription != contextDescription,
            !(originalKeyDescription?.hasPrefix(contextDescription) == true),
            headersSeen.contains(contextDescription)
        {
            throw DeserializationError.value(
                .init(
                    reference,
                    key.index,
                    """
                    Using dotted keys to add to [\(contextDescription)] after \
                    explicitly defining it above is not allowed"
                    """
                )
            )
        }
        switch (keys.count, table[key.value]) {
        case (1, nil):
            table[key.value] = value
            if context.isEmpty && isTable {
                headersSeen.insert(keysDescription)
            }
        case (_, nil):
            var newTable = _TOMLTable()
            try insert(
                table: &newTable,
                reference: reference,
                header: keys.dropFirst(),
                originalKeyDescription: originalKeyDescription ?? headerDescription,
                context: context + [key.value],
                value: value,
                isArrayTable: isArrayTable,
                isTable: isTable
            )
            table[key.value] = newTable
            if context.isEmpty && isTable {
                headersSeen.insert(keysDescription)
            }
        case (1, var existing as TOMLArrayTable) where isArrayTable && !existing.storage.isEmpty:
            existing.storage.append(_TOMLTable())
            table[key.value] = existing

        case (_, var existing as _TOMLTable) where keys.count > 1:
            if !existing.isMutable {
                throw DeserializationError.structural(.init(reference, key.index, "Cannot mutate inline table"))
            }

            try insert(
                table: &existing,
                reference: reference,
                header: keys.dropFirst(),
                originalKeyDescription: originalKeyDescription ?? headerDescription,
                context: context + [key.value],
                value: value,
                isArrayTable: isArrayTable,
                isTable: isTable
            )
            table[key.value] = existing
        case (1, _ as _TOMLTable) where isTable && context.isEmpty:
            if headersSeen.contains(keysDescription) {
                throw DeserializationError.conflictingValue(
                    .init(
                        reference,
                        key.index,
                        "Cannot define table \(keysDescription) more than once"
                    )
                )
            }
        case (_, var existing as TOMLArrayTable) where keys.count > 1:
            try insert(
                table: &existing[existing.storage.count - 1],
                reference: reference,
                header: keys.dropFirst(),
                originalKeyDescription: originalKeyDescription ?? keysDescription,
                context: context + [key.value],
                value: value,
                isArrayTable: isArrayTable,
                isTable: isTable
            )
            table[key.value] = existing
        case (_, var existing as TOMLArrayTable) where keys.count > 1:
            try insert(
                table: &existing[existing.storage.count - 1],
                reference: reference,
                header: keys.dropFirst(),
                originalKeyDescription: originalKeyDescription ?? keysDescription,
                context: context + [key.value],
                value: value,
                isArrayTable: isArrayTable,
                isTable: isTable
            )
            table[key.value] = existing
        case (_, let .some(existing)):
            let path = context.isEmpty ? "\(key.value)" : "\(context.joined(separator: ".")).\(key.value)"
            throw DeserializationError.conflictingValue(
                .init(
                    reference,
                    key.index,
                    "Conflicting value at [\(path)] Existing value is \(existing)"
                )
            )
        }
    }

    for entry in entries {
        switch entry {
        case .error(let index, let reason):
            errors.append(DeserializationError.structural(.init(referenceInput, index, reason.description)))
        case .valueError(let index, let reason):
            errors.append(DeserializationError.value(.init(referenceInput, index, reason.description)))
        case .keyValue(let pair):
            do {
                try insert(
                    table: &result,
                    reference: referenceInput,
                    header: context[...],
                    key: pair.key,
                    context: [],
                    value: try pair.value.normalize(reference: referenceInput)
                )
            } catch {
                errors.append(error)
            }
        case .table(let tableKey):
            do {
                try insert(
                    table: &result,
                    reference: referenceInput,
                    header: tableKey[...],
                    context: [],
                    value: _TOMLTable(),
                    isTable: true
                )
            } catch {
                errors.append(error)
            }

            context = tableKey
        case .arrayTable(let arrayTableKey):
            do {
                try insert(
                    table: &result,
                    reference: referenceInput,
                    header: arrayTableKey[...],
                    context: [],
                    value: TOMLArrayTable(storage: [_TOMLTable()]),
                    isArrayTable: true
                )
            } catch {
                errors.append(error)
            }

            context = arrayTableKey
        }
    }

    if !errors.isEmpty {
        if errors.count == 1 {
            throw errors[0]
        }

        throw DeserializationError.compound(errors)
    }

    return result
}
