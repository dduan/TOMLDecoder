import Foundation

struct TOMLDocument: Equatable, @unchecked Sendable {
    let tables: [InternalTOMLTable]
    let arrays: [InternalTOMLArray]
    let keyTables: [KeyTablePair]
    let keyArrays: [KeyArrayPair]
    let keyValues: [KeyValuePair]

    let source: String

    init(source: String, keyTransform: (@Sendable (String) -> String)?) throws(TOMLError) {
        var source = source
        var parser = Parser(keyTransform: keyTransform)
        #if swift(>=6.2)
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
        #else
        do {
            try source.withUTF8 { try parser.parse(bytes: $0) }
        } catch {
            throw error as! TOMLError
        }
        #endif

        self.source = source
        tables = parser.tables
        arrays = parser.arrays
        keyValues = parser.keyValues
        keyTables = zip(parser.keyTableKeys, parser.keyTables).map { KeyTablePair(key: $0.0, table: $0.1) }
        keyArrays = zip(parser.keyArrayKeys, parser.keyArrays).map { KeyArrayPair(key: $0.0, array: $0.1) }
    }
}

struct InternalTOMLArray: Equatable, Sendable {
    var kind: Kind?
    var elements: [Element]

    init(kind: Kind? = nil, elements: [Element] = []) {
        self.kind = kind
        self.elements = elements
    }

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
}

struct KeyTablePair: Equatable {
    let key: String
    var table: InternalTOMLTable
}

struct KeyArrayPair: Equatable {
    let key: String
    var array: InternalTOMLArray
}

struct KeyValuePair: Equatable {
    let key: String
    var value: Token

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.key == rhs.key && lhs.value == rhs.value
    }
}

struct InternalTOMLTable: Equatable, Sendable {
    var implicit: Bool = false
    var readOnly: Bool = false
    var definedByDottedKey: Bool = false
    var keyValues: [Int] = []
    var arrays: [Int] = []
    var tables: [Int] = []

    func allKeys(_ document: TOMLDocument) -> [String] {
        var keys = [String]()
        for kv in keyValues {
            keys.append(document.keyValues[kv].key)
        }
        for arr in arrays {
            keys.append(document.keyArrays[arr].key)
        }
        for table in tables {
            keys.append(document.keyTables[table].key)
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
            if source.keyArrays[arr].key == key {
                return true
            }
        }
        for table in tables {
            if source.keyTables[table].key == key {
                return true
            }
        }
        return false
    }

    enum Value {
        case keyValue(Int)
        case array(Int)
        case table(Int)
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
            let tablePair = source.keyTables[tableIndex]
            result[tablePair.key] = try tablePair.table.dictionary(source: source)
        }

        for arrayIndex in arrays {
            let arrayPair = source.keyArrays[arrayIndex]
            result[arrayPair.key] = try arrayPair.array.array(source: source)
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

extension TOMLDocument {
    @inline(__always)
    func table(at index: Int, keyed: Bool) -> InternalTOMLTable {
        keyed ? keyTables[index].table : tables[index]
    }

    @inline(__always)
    func array(at index: Int, keyed: Bool) -> InternalTOMLArray {
        keyed ? keyArrays[index].array : arrays[index]
    }
}
