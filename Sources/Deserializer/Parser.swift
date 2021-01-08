import struct Foundation.DateComponents
import struct Foundation.Date
import struct Foundation.TimeZone

typealias Text = String.UnicodeScalarView.SubSequence

typealias DottedKey = [Traced<String, Text.Index>]

struct RawKeyValuePair: Equatable {
    let key: DottedKey
    let value: TOMLValue
}

struct KeyValuePair: Equatable {
    let key: TOMLValue
    let value: TOMLValue
}

enum TopLevel: Equatable {
    case keyValue(RawKeyValuePair)
    case table(DottedKey)
    case arrayTable(DottedKey)
    case error(Text.Index, Reason)
    case valueError(Text.Index, TOMLValue.Reason)

    enum Reason: Equatable {
        case missingKey
        case missingValue
        case standardTableMissingOpening
        case standardTableMissingClosing
        case arrayTableMissingClosing
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
        }
    }
}

indirect enum TOMLValue: Equatable {
    case string(String)
    case boolean(Bool)
    case array([TOMLValue])
    case inlineTable([RawKeyValuePair])
    case date(Date)
    case dateComponents(DateComponents)
    case float(Double)
    case integer(Int64)
    case key(DottedKey)
    case error(Text.Index, Reason)

    enum Reason: Equatable {
        case invalidUnicodeSequence
        case literalStringMissingOpening
        case literalStringMissingClosing
        case multilineLiteralStringMissingClosing
        case basicStringMissingOpening
        case basicStringMissingClosing
        case multilineBasicStringMissingClosing
        case invalidTime
        case invalidDate
        case invalidTimeOffset
        case inlineTableMissingClosing
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
        case .basicStringMissingOpening:
            return "Missing opening character `\"` in string"
        case .basicStringMissingClosing:
            return "Missing closing character `\"` in string"
        case .multilineBasicStringMissingClosing:
            return "Missing opening character `\"\"\"` in multiline string"
        case .invalidTime:
            return "Ill-formatted time"
        case .invalidDate:
            return "Ill-formatted date"
        case .invalidTimeOffset:
            return "Ill-formatted time offset"
        case .inlineTableMissingClosing:
            return "Missing closing character `]` in table"
        }
    }
}

// MARK: - generic stuff

extension String {
    init<S>(_ scalars: S) where S: Sequence, S.Element == UnicodeScalar {
        self.init(UnicodeScalarView(scalars))
    }
}

protocol Parser {
    associatedtype Input
    associatedtype Output

    func run(_ input: inout Input) -> Output?
}

struct AnyParser<Input, Output>: Parser {
    let actualRun: (inout Input) -> Output?

    init<P>(_ p: P) where P: Parser, P.Input == Input, P.Output == Output {
        actualRun = p.run
    }

    func run(_ input: inout Input) -> Output? {
        actualRun(&input)
    }
}

struct Unwrap<P, Value>: Parser where P: Parser, P.Output == Optional<Value> {
    let p: P
    func run(_ input: inout P.Input) -> Value? {
        let originalInput = input
        switch p.run(&input) {
        case .none:
            return nil
        case .some(.none):
            input = originalInput
            return nil
        case .some(.some(let value)):
            return value
        }
    }
}

struct Map<P, NewOutput>: Parser where P: Parser {
    let p: P
    let transform: (P.Output) -> NewOutput

    func run(_ input: inout P.Input) -> NewOutput? {
        p.run(&input).map(transform)
    }
}

struct Zip<P1, P2>: Parser
    where P1: Parser, P2: Parser, P1.Input == P2.Input
{
    let p1: P1
    let p2: P2

    func run(_ input: inout P1.Input) -> (P1.Output, P2.Output)? {
        let originalInput = input
        guard let output1 = p1.run(&input) else {
            return nil
        }

        guard let output2 = p2.run(&input) else {
            input = originalInput
            return nil
        }

        return (output1, output2)
    }
}

struct ZeroOrMore<P>: Parser where P: Parser {
    let p: P

    func run(_ input: inout P.Input) -> [P.Output]? {
        var rest = input
        var matches: [P.Output] = []
        while let match = p.run(&input) {
            rest = input
            matches.append(match)
        }
        input = rest
        return matches
    }
}

struct ZeroOrOne<P>: Parser where P: Parser {
    let p: P

    func run(_ input: inout P.Input) -> [P.Output]? {
        if let output = p.run(&input) {
            return [output]
        }

        return []
    }
}

struct NOrMore<P>: Parser where P: Parser {
    let p: P
    let count: Int

    func run(_ input: inout P.Input) -> [P.Output]? {
        let originalInput = input
        guard let output = ZeroOrMore(p: p).run(&input) else {
            return nil
        }

        if output.count < count {
            input = originalInput
            return nil
        }

        return output
    }
}

struct TracedParser<P>: Parser where P: Parser, P.Input: Collection {
    let p: P

    func run(_ input: inout P.Input) -> Traced<P.Output, P.Input.Index>? {
        let index = input.startIndex
        guard let result = p.run(&input) else {
            return nil
        }

        return .init(value: result, index: index)
    }
}

struct OneOf2<P1, P2>: Parser
    where P1: Parser, P2: Parser, P1.Input == P2.Input, P1.Output == P2.Output
{
    let p1: P1
    let p2: P2

    init(_ p1: P1, _ p2: P2) {
        self.p1 = p1
        self.p2 = p2
    }

    func run(_ input: inout P1.Input) -> P1.Output? {
        p1.run(&input) ?? p2.run(&input)
    }
}

struct OneOf3<P1, P2, P3>: Parser
    where
        P1: Parser,
        P2: Parser,
        P3: Parser,
        P1.Input == P2.Input, P1.Output == P2.Output,
        P1.Input == P3.Input, P1.Output == P3.Output
{
    let p1: P1
    let p2: P2
    let p3: P3

    init(
        _ p1: P1,
        _ p2: P2,
        _ p3: P3
    ) {
        self.p1 = p1
        self.p2 = p2
        self.p3 = p3
    }

    func run(_ input: inout P1.Input) -> P1.Output? {
        p1.run(&input) ?? p2.run(&input) ?? p3.run(&input)
    }
}

struct OneOf4<P1, P2, P3, P4>: Parser
    where
        P1: Parser,
        P2: Parser,
        P3: Parser,
        P4: Parser,
        P1.Input == P2.Input, P1.Output == P2.Output,
        P1.Input == P3.Input, P1.Output == P3.Output,
        P1.Input == P4.Input, P1.Output == P4.Output
{
    let p1: P1
    let p2: P2
    let p3: P3
    let p4: P4

    init(
        _ p1: P1,
        _ p2: P2,
        _ p3: P3,
        _ p4: P4
    ) {
        self.p1 = p1
        self.p2 = p2
        self.p3 = p3
        self.p4 = p4
    }

    func run(_ input: inout P1.Input) -> P1.Output? {
        p1.run(&input) ?? p2.run(&input) ?? p3.run(&input) ?? p4.run(&input)
    }
}

extension Parser {
    func map<NewOutput>(_ transform: @escaping (Output) -> NewOutput) -> Map<Self, NewOutput> {
        Map(p: self, transform: transform)
    }

    func skip<P>(_ p: P) -> AnyParser<Input, Output> where P: Parser, P.Input == Input {
        Zip(p1: self, p2: p)
            .map { x, _ in x }
            .eraseToAny()
    }

    func replace<P>(_ p: P) -> AnyParser<P.Input, P.Output> where P: Parser, P.Input == Input {
        Zip(p1: self, p2: p)
            .map { _, x in x }
            .eraseToAny()
    }

    func take<P>(_ p: P) -> Zip<Self, P> where P: Parser, P.Input == Input {
        Zip(p1: self, p2: p)
    }

    func zeroOrMore() -> ZeroOrMore<Self> {
        ZeroOrMore(p: self)
    }

    func zeroOrOne() -> ZeroOrOne<Self> {
        ZeroOrOne(p: self)
    }

    func eraseToAny() -> AnyParser<Self.Input, Self.Output> {
        AnyParser(self)
    }

    func repeated(_ count: Int) -> Repeat<Self> {
        Repeat(self, count)
    }

    func nOrMore(_ count: Int) -> NOrMore<Self> {
        NOrMore(p: self, count: count)
    }
}

extension Parser where Input: Sequence {
    func debug(line: Int = #line) -> Debug<Self> {
        Debug(p: self, line: line)
    }
}

struct Debug<P>: Parser where P: Parser, P.Input: Sequence {
    let p: P
    let line: Int
    func run(_ input: inout P.Input) -> P.Output? {
        print(line, "[debug] >", Array(input))
        let r = p.run(&input)
        dump(r)
        print(line, "[debug] <", Array(input))
        return r
    }
}

extension Parser where Input: Collection {
    func traced() -> TracedParser<Self> {
        TracedParser(p: self)
    }
}

struct FixedPrefix: Parser {
    let s: Text

    init(_ s: Text) { self.s = s }
    func run(_ input: inout Text) -> Text? {
        guard input.starts(with: s) else {
            return nil
        }

        input.removeFirst(s.count)
        return s
    }
}

struct RepeatingPrefix<C>: Parser where C: Collection, C.Element: Equatable, C == C.SubSequence {
    let target: C.Element
    let lowerBound: Int?
    let upperBound: Int

    init(_ target: C.Element, lowerBound: Int? = nil, upperBound: Int) {
        self.target = target
        self.lowerBound = lowerBound
        self.upperBound = upperBound
    }

    func run(_ input: inout C) -> C.SubSequence? {
        let lowerBound = self.lowerBound ?? upperBound
        let upperBound = min(self.upperBound, input.count)
        for count in stride(from: upperBound, through: lowerBound, by: -1) {
            let prefix = input.prefix(count)
            if prefix.allSatisfy({ $0 == target }) {
                input.removeFirst(count)
                return prefix
            }
        }

        return nil
    }
}

struct Repeat<P>: Parser where P: Parser {
    let p: P
    let count: Int

    init(_ p: P, _ count: Int) {
        self.p = p
        self.count = count
    }

    func run(_ input: inout P.Input) -> [P.Output]? {
        let originalInput = input
        var results = [P.Output]()
        for _ in 0 ..< count {
            guard let result = p.run(&input) else {
                input = originalInput
                return nil
            }

            results.append(result)
        }

        return results
    }
}

struct FixedChar: Parser {
    let target: UnicodeScalar

    init(_ target: UnicodeScalar) { self.target = target }

    func run(_ input: inout String.UnicodeScalarView.SubSequence) -> UnicodeScalar? {
        guard input.first == target else {
            return nil
        }

        input.removeFirst()
        return target
    }
}

extension FixedChar: ExpressibleByStringLiteral {
    init(stringLiteral value: String) {
        self.init(value.unicodeScalars.first!)
    }
}

struct PredicateChar: Parser {
    let predicate: (UnicodeScalar) -> Bool

    func run(_ input: inout String.UnicodeScalarView.SubSequence) -> UnicodeScalar? {
        guard let first = input.first, predicate(first) else {
            return nil
        }

        input.removeFirst()
        return first
    }
}

struct FlattenOneAndMany<P>: Parser
    where
        P: Parser,
        P.Input == String.UnicodeScalarView.SubSequence,
        P.Output == (UnicodeScalar, [UnicodeScalar])
{
    let p: P

    init(_ p: P) { self.p = p }
    func run(_ input: inout String.UnicodeScalarView.SubSequence) -> [UnicodeScalar]? {
        if let (one, many) = p.run(&input) {
            return [one] + many
        }

        return nil
    }
}

struct FlattenManyAndMany<P, C>: Parser
    where
        P: Parser,
        C: RangeReplaceableCollection,
        P.Output == (C, C)
{
    let p: P
    init(_ p: P) { self.p = p }
    func run(_ input: inout P.Input) -> C? {
        if let (many1, many2) = p.run(&input) {
            return many1 + many2
        }

        return nil
    }
}

extension Parser where Output == ([Text.Element], [Text.Element]), Input == Text {
    func flatten() -> FlattenManyAndMany<Self, [Text.Element]> {
        FlattenManyAndMany(self)
    }
}

extension Parser where Output == (Text.Element, [Text.Element]), Input == Text {
    func flatten() -> FlattenOneAndMany<Self> {
        FlattenOneAndMany(self)
    }
}

struct ArrayValues: Parser {
    func run(_ input: inout Text) -> [TOMLValue]? {
        return OneOf2(
            TOMLParser.arrayValues1,
            TOMLParser.arrayValues2
        )
        .run(&input)
    }
}

struct InlineTableKeyValues: Parser {
    func run(_ input: inout Text) -> TOMLValue? {
        TOMLParser.keyValueRaw
            .take(
                TOMLParser.inlineTableSep
                    .replace(InlineTableKeyValues())
                    .zeroOrOne()
                    .map { $0.first ?? .inlineTable([]) }
            )
            .run(&input)
            .map { one, many -> TOMLValue in
                switch one.key {
                case .error:
                    return one.key
                case .key(let dotted):
                    switch many {
                    case .error:
                        return many
                    case .inlineTable(let manyPairs):
                        return .inlineTable( [RawKeyValuePair(key: dotted, value: one.value)] + manyPairs)
                    default:
                        fatalError()
                    }
                default:
                    fatalError()
                }
            }
    }
}

struct EscapeChar: Parser {
    func run(_ input: inout Text) -> UnicodeScalar? {
        guard let char = input.first else {
            return nil
        }

        var result: UnicodeScalar?
        switch char.value {
        case 0x22: result = UnicodeScalar(0x22) // "    quotation mark  U+0022
        case 0x5C: result = UnicodeScalar(0x5C) // \    reverse solidus U+005C
        case 0x62: result = UnicodeScalar(0x08) // b    backspace       U+0008
        case 0x66: result = UnicodeScalar(0x0C) // f    form feed       U+000C
        case 0x6E: result = UnicodeScalar(0x0A) // n    line feed       U+000A
        case 0x72: result = UnicodeScalar(0x0D) // r    carriage return U+000D
        case 0x74: result = UnicodeScalar(0x09) // t    tab             U+0009
        default: break
        }

        if result != nil {
            input.removeFirst()
        }

        return result
    }
}

func isUnescapedChar(_ c: UnicodeScalar) -> Bool {
    let value = c.value
    return value == 0x20 ||
        value == 0x09 ||
        value == 0x21 ||
        value == 0x0A ||
        value == 0x0D ||
        value >= 0x23 && value <= 0x5B ||
        value >= 0x5D && value <= 0x7E ||
        value >= 0x80 && value <= 0xD7FF ||
        value >= 0xE000 && value <= 0x10FFFF
}

func isHexDigit(_ c: UnicodeScalar) -> Bool {
    let isDigit = c.value >= 0x30 && c.value <= 0x39
    let isUpper = c.value >= 0x41 && c.value <= 0x46
    let isLower = c.value >= 0x61 && c.value <= 0x66
    return isDigit || isUpper || isLower
}

enum Constants {
    static let lf = "\n".unicodeScalars
    static let lfcr = "\r\n".unicodeScalars
    static let backslash = "\\".unicodeScalars.first!
    static let lowercaseU = "u".unicodeScalars.first!
    static let uppercaseU = "U".unicodeScalars.first!
}

func getEscaped(_ index: inout Text.Index, _ input: Text) -> UnicodeScalar?? {
    let originalIndex = index
    guard input[index] == Constants.backslash else {
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
    case Constants.lowercaseU.value:
        is4Digit = true
    case Constants.uppercaseU.value:
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

struct BasicString: Parser {
    static let singleQuote = "\"".unicodeScalars.first!
    func run(_ input: inout Text) -> TOMLValue? {
        var result = [UnicodeScalar]()
        let originalInput = input
        guard input.first == Self.singleQuote else {
            return nil
        }

        input.removeFirst()

        var index = input.startIndex
        while index < input.endIndex {
            let c = input[index]
            let escaped = getEscaped(&index, input)
            switch escaped {
            case .some(.none):
                return .error(index, .invalidUnicodeSequence)
            case .some(.some(let scalar)):
                result.append(scalar)
                continue
            case .none:
                break
            }

            if c == Self.singleQuote {
                input.formIndex(after: &index)
                input = input[index...]
                return .string(String(result))
            }

            if isUnescapedChar(c) {
                result.append(c)
                input.formIndex(after: &index)
            } else {
                input = originalInput
                return nil
            }
        }

        input = originalInput
        return nil
    }
}

struct MultilineBasicString: Parser {
    static let quotes = "\"\"\"".unicodeScalars
    static let singleQuote = "\"".unicodeScalars.first!
    func run(_ input: inout Text) -> TOMLValue? {
        var result = [UnicodeScalar]()
        let originalInput = input
        guard input.starts(with: Self.quotes) else {
            return nil
        }

        input.removeFirst(3)

        if input.starts(with: Constants.lf) {
            input.removeFirst()
        } else if input.starts(with: Constants.lfcr) {
            input.removeFirst(2)
        }

        var escapingNewline = false
        var index = input.startIndex
        while index < input.endIndex {
            let c = input[index]
            let escaped = getEscaped(&index, input)
            switch escaped {
            case .some(.none):
                return .error(index, .invalidUnicodeSequence)
            case .some(.some(let scalar)):
                result.append(scalar)
                continue
            case .none:
                break
            }

            if escapingNewline {
                if c.value == 0x20 || c.value == 0x0A || c.value == 0x0D || c.value == 0x09 {
                    input.formIndex(after: &index)
                } else if input[index...].starts(with: Constants.lf) {
                    input.formIndex(after: &index)
                } else if input[index...].starts(with: Constants.lfcr) {
                    input.formIndex(after: &index)
                    input.formIndex(after: &index)
                } else {
                    escapingNewline = false
                }

                continue
            }

            if c == Constants.backslash {
                input.formIndex(after: &index)
                escapingNewline = true
                continue
            }


            if c == Self.singleQuote {
                result.append(Self.singleQuote)
                input.formIndex(after: &index)
                if index == input.endIndex {
                    input = originalInput
                    return nil
                }

                if input[index] == Self.singleQuote {
                    result.append(Self.singleQuote)
                    input.formIndex(after: &index)
                    if index == input.endIndex {
                        input = originalInput
                        return nil
                    }

                    if input[index] == Self.singleQuote {
                        input.formIndex(after: &index)
                        input = input[index...]
                        return .string(String(result.dropLast(2)))
                    }

                    continue
                }

                continue
            }

            if isUnescapedChar(c) {
                result.append(c)
                input.formIndex(after: &index)
            } else {
                input = originalInput
                return nil
            }
        }

        input = input[index...]
        return .string(String(result))
    }
}

struct MultilineLiteralString: Parser {
    static let quotes = "'''".unicodeScalars
    static let singleQuote = "'".unicodeScalars.first!
    static func isMultilineChar(_ c: UnicodeScalar) -> Bool {
        let value = c.value
        return value == 0x09 ||
            value >= 0x20 && value <= 0x26 ||
            value >= 0x28 && value <= 0x7E ||
            value >= 0x80 && value <= 0xD7FF ||
            value >= 0xE000 && value <= 0x10FFFF ||
            value == 0x0A ||
            value == 0x0D
    }

    func run(_ input: inout Text) -> String? {
        let originalInput = input
        guard input.starts(with: Self.quotes) else {
            return nil
        }

        input.removeFirst(3)

        if input.starts(with: Constants.lf) {
            input.removeFirst()
        } else if input.starts(with: Constants.lfcr) {
            input.removeFirst(2)
        }

        var escapingNewline = false

        var index = input.startIndex
        while index < input.endIndex {
            let c = input[index]

            if escapingNewline {
                if c.value == 0x0A || c.value == 0x0D {
                    input.formIndex(after: &index)
                } else if input[index...].starts(with: Constants.lf) {
                    input.formIndex(after: &index)
                } else if input[index...].starts(with: Constants.lfcr) {
                    input.formIndex(after: &index)
                    input.formIndex(after: &index)
                } else {
                    escapingNewline = false
                }

                continue
            }

            if c == Constants.backslash {
                input.formIndex(after: &index)
                escapingNewline = true
                continue
            }

            if c == Self.singleQuote {
                let endIndex = index
                input.formIndex(after: &index)
                if index == input.endIndex {
                    input = originalInput
                    return nil
                }

                if input[index] == Self.singleQuote {
                    input.formIndex(after: &index)
                    if index == input.endIndex {
                        input = originalInput
                        return nil
                    }

                    if input[index] == Self.singleQuote {
                        let output = input[input.startIndex ..< endIndex]
                        input.removeFirst(output.count + 3)
                        return String(output)
                    }

                    continue
                }

                continue
            }

            if Self.isMultilineChar(c) {
                input.formIndex(after: &index)
                continue
            } else {
                return nil
            }
        }

        input = originalInput
        return nil
    }
}

enum TOMLParser {
    static let boolean = OneOf2(
            FixedPrefix("true".unicodeScalars[...]),
            FixedPrefix("false".unicodeScalars[...])
        )
        .map { TOMLValue.boolean($0.first == .init(0x74)) }

    static let digit = PredicateChar { $0.value >= 0x30 && $0.value <= 0x39 }
    static let alpha = PredicateChar { c in
        let isUpper = c.value >= 0x41 && c.value <= 0x5A
        let isLower = c.value >= 0x61 && c.value <= 0x7A
        return isUpper || isLower
    }
    static let hexDigit = PredicateChar { c in
        let isDigit = c.value >= 0x30 && c.value <= 0x39
        let isUpper = c.value >= 0x41 && c.value <= 0x46
        let isLower = c.value >= 0x61 && c.value <= 0x66
        return isDigit || isUpper || isLower
    }
    static let minus: FixedChar = "-"
    static let plus: FixedChar = "+"
    static let underscore: FixedChar = "_"
    static let digit1to9 = PredicateChar { $0.value >= 0x31 && $0.value <= 0x39 }
    static let digit0to7 = PredicateChar { $0.value >= 0x30 && $0.value <= 0x37 }
    static let digit0to1 = PredicateChar { $0.value == 0x30 || $0.value == 0x31 }
    static let unsignedDecIntText =
        OneOf2(
            digit1to9
                .take(
                    OneOf2(
                        digit,
                        underscore
                            .take(digit)
                            .map { _, x in x }
                    )
                    .nOrMore(1)
                )
                .flatten(),
            digit
                .map { [$0] }
        )

    static let plusOrMinus =
        OneOf2(
            minus,
            plus
        )
        .zeroOrOne()

    static let decIntText =
        plusOrMinus
            .take(unsignedDecIntText)
            .flatten()

    static let decInt = decIntText.map { Int64(String($0))! }

    static func int(_ prefix: FixedPrefix, _ digit: PredicateChar, radix: Int) -> AnyParser<Text, Int64> {
        prefix
            .take(digit)
            .map { _, x in x }
            .take(
                OneOf2(
                    digit,
                    underscore
                        .take(digit)
                        .map { _, x in x }
                )
                .zeroOrMore()
            )
            .map { first, rest -> Int64 in
                Int64(String([first] + rest), radix: radix)!
            }
            .eraseToAny()
    }

    static let hexInt = int(FixedPrefix("0x".unicodeScalars[...]), hexDigit, radix: 16)
    static let octInt = int(FixedPrefix("0o".unicodeScalars[...]), digit0to7, radix: 8)
    static let binInt = int(FixedPrefix("0b".unicodeScalars[...]), digit0to1, radix: 2)
    static let integer =
        OneOf4(
            hexInt,
            octInt,
            binInt,
            decInt
        )
        .map(TOMLValue.integer)

    static let zeroPrefixableInt =
        digit
            .take(
                OneOf2(
                    digit,
                    underscore
                    .take(digit)
                    .map { _, x in x }
                )
                .zeroOrMore()
            )
            .flatten()

    static let exp =
        PredicateChar { $0.value == 0x45 || $0.value == 0x65 }
            .take(plusOrMinus)
            .flatten()
            .take(zeroPrefixableInt)
            .flatten()

    static let frac =
        ("." as FixedChar)
            .take(digit)
            .map { _, x in x }
            .take(
                OneOf2(
                    digit,
                    underscore
                        .take(digit)
                        .map { _, x in x }
                )
                .zeroOrMore()
            )
            .map { first, rest in
                [.init(0x2E), first] + rest
            }

    static let normalFloat =
        decIntText
            .take(
                OneOf2(
                    exp,
                    frac
                        .take(
                            exp.zeroOrOne()
                                .map { $0.flatMap { $0 } }
                        )
                        .flatten()
                )
            )
            .flatten()
            .map { Double(String($0))! }

    static let specialFloat =
        plusOrMinus
            .take(
                OneOf2(
                    FixedPrefix("nan".unicodeScalars[...]),
                    FixedPrefix("inf".unicodeScalars[...])
                )
            )
            .map { sign, value -> Double in
                let sign = sign.first?.value == 0x2d ? -1.0 : 1.0
                if value.first?.value == 0x6E { // 'n'
                    return Double.nan
                } else {
                    return sign * Double.infinity
                }
            }

    static let float = OneOf2(normalFloat, specialFloat).map(TOMLValue.float)
    static let nonascii =
        PredicateChar {
            $0.value >= 0x80 && $0.value <= 0xD7FF ||
            $0.value >= 0xE000 && $0.value <= 0x10FFFF
        }

    static let noneol =
        OneOf2(
            PredicateChar { $0.value == 0x09 || $0.value >= 0x20 && $0.value <= 0x7F },
            nonascii
        )

    static let comment =
        ("#" as FixedChar)
            .take(noneol.zeroOrMore())
            .map { _ in }

    static let apostrophe: FixedChar = "'"
    static let literalChar =
        OneOf2(
            PredicateChar {
                $0.value == 0x09 ||
                $0.value >= 0x20 && $0.value <= 0x26 ||
                $0.value >= 0x28 && $0.value <= 0x7E
            },
            nonascii
        )
    static let literalStringFullText =
        apostrophe
            .replace(literalChar.zeroOrMore())
            .skip(apostrophe)
    static let literalStringFull =
        literalStringFullText
            .map { TOMLValue.string(String($0)) }
    static let literalStringWithoutClosing =
        apostrophe
            .replace(literalChar.zeroOrMore())
            .traced()
            .map { TOMLValue.error($0.index, .literalStringMissingClosing) }
    static let literalString =
        OneOf2(
            literalStringFull,
            literalStringWithoutClosing
        )
    static let newlineChar = PredicateChar { $0.value == 0x0A || $0.value == 0x0D }
    static let newlineSeq =
        OneOf2(
            FixedPrefix("\n".unicodeScalars[...]),
            FixedPrefix("\r\n".unicodeScalars[...])
        )
        .map { Array($0) }
    static let multilineContent = OneOf2(literalChar, newlineChar)
    static let multilineQuote = RepeatingPrefix<Text>(.init(0x27), lowerBound: 1, upperBound: 2)
    static let multilineLiteralBody =
        multilineContent
            .zeroOrMore()
            .take(
                multilineQuote
                    .take(
                        multilineContent
                            .nOrMore(1)
                    )
                    .map { $0 + $1 }
                    .zeroOrMore()
                    .map { $0.flatMap { $0 }}
            )
            .flatten()
            .take(
                multilineQuote
                    .zeroOrOne()
                    .map { $0.flatMap { $0 } }
            )
            .flatten()

    static let multilineLiteralDelim = FixedPrefix("'''".unicodeScalars[...])
    static let multilineLiteralStringWithoutClosing =
        multilineLiteralDelim
            .take(newlineSeq.zeroOrOne())
            .replace(multilineLiteralBody)
            .traced()
            .map { TOMLValue.error($0.index, .multilineLiteralStringMissingClosing) }
    static let multilineLiteralString =
        OneOf2(
            MultilineLiteralString().map { TOMLValue.string(String($0)) },
            multilineLiteralStringWithoutClosing
        )

    static let escape: FixedChar = #"\"#
    static let escapeSeq =
        OneOf2(
            ("u" as FixedChar)
                .replace(
                    hexDigit.repeated(4)
                ),
            ("U" as FixedChar)
                .replace(
                    hexDigit.repeated(8)
                )
        )
    static let escaped =
        OneOf2(
            escape.replace(EscapeChar()),
            Unwrap(p: escape.replace(escapeSeq).map { UnicodeScalar(Int(String($0), radix: 16)!) })
        )

    static let whitespaceChar = PredicateChar { $0.value == 0x20 || $0.value == 0x09 }
    static let whitespace = whitespaceChar.zeroOrMore()
    static let multilineBasicEscapeNewline =
        escape
            .take(whitespace)
            .take(newlineSeq)
            .take(
                OneOf2(
                    whitespaceChar,
                    newlineChar
                )
                .zeroOrMore()
            )
            .map { _ in [UnicodeScalar]() }
    static let multilineBasicUnescaped =
        OneOf3(
            whitespaceChar,
            PredicateChar {
                $0.value == 0x21 ||
                $0.value >= 0x23 && $0.value <= 0x5B ||
                $0.value >= 0x5D && $0.value <= 0x7E
            },
            nonascii
        )
    static let basicChar = OneOf2(multilineBasicUnescaped, escaped)

    static let basicStringFullText =
        ("\"" as FixedChar)
            .replace(
                basicChar
                    .zeroOrMore()
            )
            .skip("\"" as FixedChar)
    static let basicStringWithoutClosing =
        ("\"" as FixedChar)
            .replace(
                basicChar
                    .zeroOrMore()
             )
            .traced()
            .map { TOMLValue.error($0.index, .basicStringMissingClosing) }
    static let basicString =
        OneOf2(
            BasicString(),
            basicStringWithoutClosing
        )
    static let string =
        OneOf4(
            multilineLiteralString,
            MultilineBasicString(),
            literalString,
            basicString
        )
    static let dateYear = digit.repeated(4)
    static let dateMonth = digit.repeated(2)
    static let dateDay = digit.repeated(2)
    static let timeDelim =
        OneOf3(
            "T" as FixedChar,
            "t" as FixedChar,
            " " as FixedChar
        )
    static let timeHour = digit.repeated(2)
    static let timeMinute = digit.repeated(2)
    static let timeSecond = digit.repeated(2)
    static let timeSecondFrac =
        ("." as FixedChar)
            .replace(digit.nOrMore(1))
    // sign, hour, minute
    static let timeNumOffset =
        OneOf2(
            "+" as FixedChar,
            "-" as FixedChar
        )
        .take(timeHour)
        .skip(":" as FixedChar)
        .take(timeMinute)
        .map { i -> TimeZone? in
            let (signText, hourText, minText) = (i.0.0, i.0.1, i.1)
            let sign: Int = signText.value == 0x2B ? 1 : -1
            let hour = Int(String(hourText))!
            let min = Int(String(minText))!
            return TimeZone(secondsFromGMT: sign * (hour * 3600 + min * 60))
        }
    static let timeOffset =
        OneOf2(
            PredicateChar { $0.value == 0x5A || $0.value == 0x7A }
                .map { _ in Optional.some(TimeZone(secondsFromGMT: 0)!) },
            timeNumOffset
        )
        .traced()
    static let localTime =
        timeHour
            .skip(":" as FixedChar)
            .take(timeMinute)
            .skip(":" as FixedChar)
            .take(timeSecond)
            .take(timeSecondFrac.zeroOrOne().map { $0.flatMap { $0 }})
            .traced()
            .map { i -> TOMLValue in
                let (((hourText, minuteText), secondText), secFrac) = i.value
                let hour = Int(String(hourText))!
                let minute = Int(String(minuteText))!
                let second = Int(String(secondText))!
                let fracs = secFrac.map { Int($0.value - 0x30) }
                if let time = DateComponents(validatingHour: hour, minute: minute, second: second, secondFraction: fracs) {
                    return .dateComponents(time)
                } else {
                    return .error(i.index, .invalidTime)
                }
            }
    static let localDate =
        dateYear
            .skip("-" as FixedChar)
            .take(dateMonth)
            .skip("-" as FixedChar)
            .take(dateDay)
            .traced()
            .map { i -> TOMLValue in
                let ((yearText, monthText), dayText) = i.value
                let year = Int(String(yearText))!
                let month = Int(String(monthText))!
                let day = Int(String(dayText))!
                if let date = DateComponents(validatingYear: year, month: month, day: day) {
                    return .dateComponents(date)
                } else {
                    return .error(i.index, .invalidDate)
                }
            }
    static let localDateTime =
        localDate
            .skip(timeDelim)
            .take(localTime)
            .map { date, time -> TOMLValue in
                switch (date, time) {
                case (.dateComponents(let date), .dateComponents(let time)):
                    return .dateComponents(DateComponents(date: date, time: time))
                case (.error, _):
                    return date
                default:
                    return time
                }
            }

    static let offsetLocalTime =
        localTime
            .take(timeOffset)

    static let offsetDateTime =
        localDate
            .skip(timeDelim)
            .take(offsetLocalTime)
            .map { i -> TOMLValue in
                let (date, (time, tracedOffset)) = i
                guard let timeZone = tracedOffset.value else {
                    return .error(tracedOffset.index, .invalidTimeOffset)
                }

                switch (date, time) {
                case (.dateComponents(let date), .dateComponents(let time)):
                    return .date(Date(date: date, time: time, timeZone: timeZone))
                case (.error, _):
                    return date
                default:
                    return time
                }
            }
    static let whitespaceCommentNewLine =
        OneOf2(
            whitespaceChar.map { _ in () },
            comment
                .zeroOrOne()
                .take(newlineSeq)
                .map { _ in () }
        )
        .zeroOrMore()
        .map { _ in }

    static let value = OneOf3(
        OneOf4(
            offsetDateTime,
            localDateTime,
            localDate,
            localTime
        ),
        OneOf4(
            boolean,
            float,
            integer,
            string
        ),
        OneOf2(
            array,
            inlineTable
        )
    )

    static let arraySep = "," as FixedChar

    static let arrayOneValue =
        whitespaceCommentNewLine
            .replace(value)
            .skip(whitespaceCommentNewLine)

    static let arrayValues1 =
        arrayOneValue
            .skip(TOMLParser.arraySep)
            .take(ArrayValues())
            .map { [$0] + $1 }

    static let arrayValues2 =
        arrayOneValue
            .skip(TOMLParser.arraySep.zeroOrOne())
            .map { [$0] }

    static let array =
        ("[" as FixedChar)
            .replace(
                ArrayValues()
                    .zeroOrOne()
                    .map { $0.flatMap { $0 }}
            )
            .skip(whitespaceCommentNewLine)
            .skip("]" as FixedChar)
            .map(TOMLValue.array)
    static let quotedKey = OneOf2(literalStringFull, BasicString())
        .traced()
        .map { traced -> TOMLValue in
            switch traced.value {
            case .string(let keyString):
                return TOMLValue.key([.init(value: keyString, index: traced.index)])
            case .error:
                return traced.value
            default:
                fatalError("Expect quoted key to be either TOMLValue.string or .error, got \(traced.value)")
            }
        }

    static let unquotedKey =
        OneOf4(
            alpha,
            digit,
            "-" as FixedChar,
            "_" as FixedChar
        )
        .nOrMore(1)
        .traced()
        .map { TOMLValue.key([.init(value: String($0.value), index: $0.index)]) }
    static let simpleKey = OneOf2(unquotedKey, quotedKey)
    static let dotSep = whitespace.replace("." as FixedChar).skip(whitespace)
    static let dottedKey =
        simpleKey
            .take(
                dotSep
                    .replace(simpleKey)
                    .nOrMore(1)
            )
            .map { one, many -> TOMLValue in
                var result = [Traced<String, Text.Index>]()
                for value in [one] + many {
                    switch value {
                    case .key(let key):
                        result += key
                    case .error:
                        return value
                    default:
                        fatalError("dottedKey segment should be either a TOMLValue.key or dot value, got \(value)")
                    }
                }

                return .key(result)
            }
    static let key = OneOf2(dottedKey, simpleKey)
    static let keyValueSep =
        whitespace
            .replace("=" as FixedChar)
            .skip(whitespace)

    static let keyValueRaw =
        key
            .skip(keyValueSep)
            .take(value)
            .map { KeyValuePair(key: $0, value: $1) }
    static let keyValueFull =
        keyValueRaw
            .map { kv in
                TopLevel(convertingKey: kv.key) { dottedKey in
                    .keyValue(.init(key: dottedKey, value: kv.value))
                }
            }
    static let keyValueMissingKey =
        keyValueSep
            .replace(value)
            .traced()
            .map { TopLevel.error($0.index, .missingKey) }
    static let keyValueMissingValue =
        key
            .skip(keyValueSep)
            .traced()
            .map { TopLevel.error($0.index, .missingValue) }
    static let keyValue =
        OneOf3(
            keyValueFull,
            keyValueMissingKey,
            keyValueMissingValue
        )

    static let standardTableOpening = ("[" as FixedChar).skip(whitespace)
    static let standardTableClosing = whitespace.replace("]" as FixedChar)
    static let standardTable =
        OneOf3(
            standardTableFull,
            standardTableWithoutClosing,
            standardTableWithoutOpening
        )
    static let standardTableFull =
        standardTableOpening
            .replace(key)
            .skip(standardTableClosing)
            .map { TopLevel(convertingKey: $0) { .table($0) } }
    static let standardTableWithoutOpening =
        key
            .skip(standardTableClosing)
            .traced()
            .map { TopLevel.error($0.index, .standardTableMissingOpening) }
    static let standardTableWithoutClosing =
        standardTableOpening
            .replace(key)
            .traced()
            .map { TopLevel.error($0.index, .standardTableMissingClosing) }
    static let inlineTableSep = whitespace.replace("," as FixedChar).skip(whitespace)
    static let inlineTableOpening = ("{" as FixedChar).take(whitespace).map { _ in }
    static let inlineTableClosing = whitespace.take("}" as FixedChar).map { _ in }
    static let inlineTable =
        OneOf2(
            inlineTableFull,
            inlineTableWithoutClosing
        )
    static let inlineTableFull =
        inlineTableOpening
            .replace(
                InlineTableKeyValues()
                    .zeroOrOne()
                    .map { $0.first ?? .inlineTable([]) }
            )
            .skip(inlineTableClosing)
    static let inlineTableWithoutClosing =
        inlineTableOpening
            .replace(InlineTableKeyValues())
            .traced()
            .map { TOMLValue.error($0.index, .inlineTableMissingClosing) }

    static let arrayTableOpening = ("[" as FixedChar).repeated(2).skip(whitespace).map { _ in }
    static let arrayTableClosing = whitespace.skip(("]" as FixedChar).repeated(2)).map { _ in }
    static let arrayTableFull =
        arrayTableOpening
            .replace(key)
            .skip(arrayTableClosing)
            .map { TopLevel(convertingKey: $0) { .arrayTable($0) }}

    static let arrayTableMissingClosing =
        arrayTableOpening
            .replace(key)
            .traced()
            .map { TopLevel.error($0.index, .arrayTableMissingClosing) }

    static let arrayTable =
        OneOf2(
            arrayTableFull,
            arrayTableMissingClosing
        )

    static let table =
        OneOf2(
            arrayTable,
            standardTable
        )
    static let expression =
        OneOf3(
            whitespace
                .replace(keyValue)
                .skip(whitespace)
                .skip(comment.zeroOrOne())
                .map { [$0] },
            whitespace
                .replace(table)
                .skip(whitespace)
                .skip(comment.zeroOrOne())
                .map { [$0] },
            whitespace
                .take(comment.zeroOrOne())
                .map { _ in [TopLevel]() }
        )
    static let root =
        expression
            .take(
                newlineSeq
                    .replace(expression)
                    .zeroOrMore()
                    .map { $0.flatMap { $0 }}
            )
            .map { $0 + $1 }
}

enum TOMLError: Error {
    case unknown
    case deserialization(details: [Error])
}

extension TOMLError: CustomStringConvertible {
    var description: String {
        switch self {
        case .unknown:
            return "Unknown error"
        case .deserialization(details: let details):
            let output = ["Deserialization failure:"]
            return details
                .reduce(into: output) { $0.append(String(describing: $1)) }
                .joined(separator: "\n    * ")
                + "\n"
        }
    }
}

enum DeserializationError: Error {
    case structural(Description)
    case value(Description)
    case conflictingValue(Description)
    case general(Description)

    struct Description {
        let line: Int
        let column: Int
        let text: String
    }
}

extension DeserializationError.Description: CustomStringConvertible {
    var description: String {
        "|\(line), \(column)| \(text)"
    }
}

extension DeserializationError: CustomStringConvertible {
    var description: String {
        switch self {
        case .structural(let error):
            return "Structure \(error)"
        case .value(let error):
            return "Value \(error)"
        case .conflictingValue(let error):
            return "Conflict \(error)"
        case .general(let error):
            return "\(error)"
        }
    }
}

extension DeserializationError.Description {
    static func locate(index: Text.Index, reference: String) -> (Int, Int) {
        let endIndex = index.samePosition(in: reference) ?? reference.startIndex
        var line = 1
        var column = 1
        var i = reference.startIndex
        while i < endIndex {
            if reference[i] == "\n" {
                line += 1
                column = 0
            }

            column += 1
            reference.formIndex(after: &i)
        }

        return (line, column)
    }

    init(_ reference: String, _ index: Text.Index, _ text: String) {
        (line, column) = Self.locate(index: index, reference: reference)
        self.text = text
    }
}

func insert(
    table: [String: Any],
    reference: String,
    keys: Array<Traced<String, Text.Index>>.SubSequence,
    context: [String],
    value: Any,
    isArrayTable: Bool = false,
    isTable: Bool = false
) throws -> [String: Any] {
    assert(!keys.isEmpty)
    let key = keys.first!
    var mutable = table
    switch (keys.count, table[key.value]) {
    case (1, nil):
        mutable[key.value] = value
    case (_, nil):
        mutable[key.value] = try insert(
            table: [:],
            reference: reference,
            keys: keys.dropFirst(),
            context: context + [key.value],
            value: value,
            isArrayTable: isArrayTable,
            isTable: isTable
        )
    case (1, let existing as [[String: Any]]) where isArrayTable && !existing.isEmpty:
        mutable[key.value] = existing + [[:]]
    case (_, let existing as [String: Any]) where keys.count > 1:
        mutable[key.value] = try insert(
            table: existing,
            reference: reference,
            keys: keys.dropFirst(),
            context: context + [key.value],
            value: value,
            isArrayTable: isArrayTable,
            isTable: isTable
        )
    case (_, let existing as [[String: Any]]) where keys.count > 1 && isTable:
        var mutableArray = existing
        mutableArray[mutableArray.count - 1] = try insert(
            table: mutableArray[mutableArray.count - 1],
            reference: reference,
            keys: keys.dropFirst(),
            context: context + [key.value],
            value: value,
            isArrayTable: isArrayTable,
            isTable: isTable
        )
        mutable[key.value] = mutableArray
    case (_, let existing as [[String: Any]]) where keys.count > 1:
        var mutableArray = existing
        mutableArray[mutableArray.count - 1] = try insert(
            table: mutableArray[mutableArray.count - 1],
            reference: reference,
            keys: keys.dropFirst(),
            context: context + [key.value],
            value: value,
            isArrayTable: isArrayTable,
            isTable: isTable
        )
        mutable[key.value] = mutableArray
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

    return mutable
}

extension TOMLValue {
    func normalize(reference: String) throws -> Any {
        switch self {
        case .error(let index, let reason):
            throw DeserializationError.value(.init(reference, index, reason.description))
        case .boolean(let value):
            return value
        case .string(let value):
            return value
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
            return try assembleTable(from: inlineTable.map(TopLevel.keyValue), referenceInput: reference)
        case .key(let dotted):
            fatalError("Normalizing key \(dotted)")
        }
    }
}

func assembleTable(from entries: [TopLevel], referenceInput: String) throws -> [String: Any] {
    var result = [String: Any]()
    var context = [Traced<String, Text.Index>]()
    var errors = [Error]()

    for entry in entries {
        switch entry {
        case .error(let index, let reason):
            errors.append(DeserializationError.structural(.init(referenceInput, index, reason.description)))
        case .valueError(let index, let reason):
            errors.append(DeserializationError.value(.init(referenceInput, index, reason.description)))
        case .keyValue(let pair):
            do {
                result = try insert(
                    table: result,
                    reference: referenceInput,
                    keys: (context + pair.key)[...],
                    context: [],
                    value: try pair.value.normalize(reference: referenceInput)
                )
            } catch {
                errors.append(error)
            }
        case .table(let tableKey):
            do {
                result = try insert(
                    table: result,
                    reference: referenceInput,
                    keys: tableKey[...],
                    context: [],
                    value: [String: Any](),
                    isTable: true
                )
            } catch {
                errors.append(error)
            }

            context = tableKey
        case .arrayTable(let arrayTableKey):
            do {
                result = try insert(
                    table: result,
                    reference: referenceInput,
                    keys: arrayTableKey[...],
                    context: [],
                    value: [[String: Any]()],
                    isArrayTable: true
                )
            } catch {
                errors.append(error)
            }

            context = arrayTableKey
        }
    }

    if !errors.isEmpty {
        throw TOMLError.deserialization(details: errors)
    }

    return result
}
