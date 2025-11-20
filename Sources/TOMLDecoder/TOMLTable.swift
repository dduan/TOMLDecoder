import Foundation

extension TOMLTable {
    public init(source: String) throws(TOMLError) {
        let parser = Deserializer(source: source, keyTransform: nil)
        self = try parser.parse()
    }

    public init(source: some Collection<Unicode.UTF8.CodeUnit>) throws(TOMLError) {
        guard let source = String(bytes: source, encoding: .utf8) else {
            throw TOMLError.invalidUTF8
        }
        try self.init(source: source)
    }
}

public struct TOMLTable: Sendable, Equatable {
    let source: Deserializer
    let index: Int

    public var allKeys: [String] {
        source.tables[index].allKeys(parser: source)
    }

    public func contains(key: String) -> Bool {
        source.tables[index].contains(parser: source, key: key)
    }

    public func array(forKey key: String) throws(TOMLError) -> TOMLArray {
        let arrayIndices = source.tables[index].arrays
        let allArrays = source.arrays
        for i in arrayIndices {
            if allArrays[i].key == key {
                return TOMLArray(source: source, index: i)
            }
        }

        throw TOMLError.keyNotFoundInTable(key: key, type: "array")
    }

    public func table(forKey key: String) throws(TOMLError) -> TOMLTable {
        let tableIndices = source.tables[index].tables
        let allTables = source.tables
        for i in tableIndices {
            if allTables[i].key == key {
                return TOMLTable(source: source, index: i)
            }
        }

        throw TOMLError.keyNotFoundInTable(key: key, type: "table")
    }

    @inline(__always)
    func value<T>(forKey key: String, parse: (String.UTF8View.SubSequence) throws(TOMLError) -> T) throws(TOMLError) -> T {
        let pairIndices = source.tables[index].keyValues
        let allPairs = source.keyValues
        for i in pairIndices {
            if allPairs[i].key == key {
                return try parse(allPairs[i].value)
            }
        }

        throw TOMLError.keyNotFoundInTable(key: key, type: String(describing: T.self))
    }

    public func string(forKey key: String) throws(TOMLError) -> String {
        try value(forKey: key) { text throws(TOMLError) in
            guard let s = try stringMaybe(text) else {
                throw TOMLError.typeMismatchInTable(key: key, expected: "string")
            }
            return s
        }
    }

    public func bool(forKey key: String) throws(TOMLError) -> Bool {
        try value(forKey: key, parse: boolMaybe)
    }

    public func integer(forKey key: String) throws(TOMLError) -> Int64 {
        try value(forKey: key) { text throws(TOMLError) in
            try intMaybe(text, mustBeInt: true)
        }
    }

    public func float(forKey key: String) throws(TOMLError) -> Double {
        try value(forKey: key) { text throws(TOMLError) in
            try floatMaybe(text, mustBeFloat: true)
        }
    }

    public func offsetDateTime(forKey key: String) throws(TOMLError) -> OffsetDateTime {
        try value(forKey: key) { text throws(TOMLError) in
            let datetime = try datetimeMaybe(lineNumber: nil, text)
            switch (datetime.date, datetime.time, datetime.offset) {
            case let (.some(date), .some(time), .some(offset)):
                return OffsetDateTime(date: date, time: time, offset: offset, features: datetime.features)
            default:
                throw TOMLError.keyNotFoundInTable(key: key, type: "offset date-time")
            }
        }
    }

    public func localDateTime(forKey key: String, strict: Bool = false) throws(TOMLError) -> LocalDateTime {
        try value(forKey: key) { text throws(TOMLError) in
            let datetime = try datetimeMaybe(lineNumber: nil, text)
            switch (datetime.date, datetime.time, datetime.offset) {
            case let (.some(date), .some(time), .some) where !strict:
                return LocalDateTime(date: date, time: time)
            case let (.some(date), .some(time), .none):
                return LocalDateTime(date: date, time: time)
            default:
                throw TOMLError.keyNotFoundInTable(key: key, type: "local date-time")
            }
        }
    }

    public func localDate(forKey key: String, strict: Bool = false) throws(TOMLError) -> LocalDate {
        try value(forKey: key) { text throws(TOMLError) in
            let datetime = try datetimeMaybe(lineNumber: nil, text)
            switch (datetime.date, datetime.time, datetime.offset) {
            case let (.some(date), .some, .some) where !strict:
                return date
            case let (.some(date), .some, .none) where !strict:
                return date
            case let (.some(date), .none, .none):
                return date
            default:
                throw TOMLError.keyNotFoundInTable(key: key, type: "local date")
            }
        }
    }

    public func localTime(forKey key: String, strict: Bool = false) throws(TOMLError) -> LocalTime {
        try value(forKey: key) { text throws(TOMLError) in
            let datetime = try datetimeMaybe(lineNumber: nil, text)
            switch (datetime.date, datetime.time, datetime.offset) {
            case let (.some, .some(time), .some) where !strict:
                return time
            case let (.some, .some(time), .none) where !strict:
                return time
            case let (.none, .some(time), .none):
                return time
            default:
                throw TOMLError.keyNotFoundInTable(key: key, type: "local time")
            }
        }
    }

    func datetimeComponents(forKey key: String) throws(TOMLError) -> DateTimeComponents {
        try value(forKey: key) { text throws(TOMLError) in
            try datetimeMaybe(lineNumber: nil, text)
        }
    }

    func dictionary() throws(TOMLError) -> [String: Any] {
        try source.tables[index].dictionary(source: source)
    }
}

extension TOMLTable: Codable {
    public init(from _: any Decoder) throws {
        throw TOMLError.notReallyCodable
    }

    public func encode(to _: any Encoder) throws {
        throw TOMLError.notReallyCodable
    }
}

extension [String: Any] {
    public init(_ tomlTable: TOMLTable) throws(TOMLError) {
        self = try tomlTable.dictionary()
    }
}
