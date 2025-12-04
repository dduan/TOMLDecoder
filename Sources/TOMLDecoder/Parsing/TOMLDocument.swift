import Foundation

struct TOMLDocument: Equatable, @unchecked Sendable {
    let tables: [InternalTOMLTable]
    let arrays: [InternalTOMLArray]
    let keyValues: [KeyValuePair]

    let source: String

    init(source: String, keyTransform: (@Sendable (String) -> String)?) throws(TOMLError) {
        var source = source
        var parser = Parser(keyTransform: keyTransform)
        if #available(iOS 26, macOS 26, watchOS 26, tvOS 26, visionOS 26, *) {
            let bytes = source.utf8Span.span
            try parser.parse(bytes: bytes)
        } else {
            do {
                try source.withUTF8 { try parser.parse(bytes: $0) }
            } catch {
                throw error as! TOMLError
            }
        }

        self.source = source
        tables = parser.tables
        arrays = parser.arrays
        keyValues = parser.keyValues
    }
}

struct InternalTOMLArray: Equatable, Sendable {
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

struct InternalTOMLTable: Equatable, Sendable {
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

    func allKeys(_ document: TOMLDocument) -> [String] {
        var keys = [String]()
        for kv in keyValues {
            keys.append(document.keyValues[kv].key)
        }
        for arr in arrays {
            if let key = document.arrays[arr].key {
                keys.append(key)
            }
        }
        for table in tables {
            if let key = document.tables[table].key {
                keys.append(key)
            }
        }
        return keys
    }

    func contains(source: TOMLDocument, key: String) -> Bool {
        for kv in keyValues {
            if source.keyValues[kv].key == key {
                return true
            }
        }
        for arr in arrays {
            if source.arrays[arr].key == key {
                return true
            }
        }
        for table in tables {
            if source.tables[table].key == key {
                return true
            }
        }
        return false
    }
}

struct DateTimeComponents: Equatable {
    let date: LocalDate?
    let time: LocalTime?
    let offset: Int16?
    let features: OffsetDateTime.Features

    @inline(__always)
    func localDate(exactMatch: Bool = true) -> LocalDate? {
        switch (date, time, offset) {
        case let (.some(date), .none, .none):
            date
        case let (.some(date), _, _) where !exactMatch:
            date
        default:
            nil
        }
    }

    @inline(__always)
    func localTime(exactMatch: Bool = true) -> LocalTime? {
        switch (date, time, offset) {
        case let (.none, .some(time), .none):
            time
        case let (_, .some(time), _) where !exactMatch:
            time
        default:
            nil
        }
    }

    @inline(__always)
    func localDateTime(exactMatch: Bool = true) -> LocalDateTime? {
        switch (date, time, offset) {
        case let (.some(date), .some(time), .none):
            LocalDateTime(date: date, time: time)
        case let (.some(date), .some(time), .some) where !exactMatch:
            LocalDateTime(date: date, time: time)
        default:
            nil
        }
    }
}

extension InternalTOMLTable {
    func dictionary(source: TOMLDocument) throws(TOMLError) -> [String: Any] {
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
            result[pair.key] = try pair.value.unpackAnyValue(source: source.source, context: .string(pair.key))
        }

        return result
    }
}

extension InternalTOMLArray {
    func array(source: TOMLDocument) throws(TOMLError) -> [Any] {
        var result = [Any]()

        for (index, element) in zip(0..., elements) {
            switch element {
            case let .array(_, arrayIndex):
                try result.append(source.arrays[arrayIndex].array(source: source))
            case let .table(_, tableIndex):
                try result.append(source.tables[tableIndex].dictionary(source: source))
            case let .leaf(token):
                try result.append(token.unpackAnyValue(source: source.source, context: .int(index)))
            }
        }

        return result
    }
}
