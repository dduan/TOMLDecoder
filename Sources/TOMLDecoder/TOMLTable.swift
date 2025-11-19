import Foundation

extension TOMLTable {
    public init(source: String) throws(TOMLError) {
        var parser = Deserializer(source: source, keyTransform: nil)
        self = try parser.parse()
    }

    public init<Bytes: Collection>(source: Bytes) throws(TOMLError) where Bytes.Element == Unicode.UTF8.CodeUnit {
        guard let source = String(bytes: source, encoding: .utf8) else {
            throw TOMLError.invalidUTF8
        }
        try self.init(source: source)
    }
}

public struct TOMLTable {
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
            case (.some(let date), .some(let time), .some(let offset)):
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
            case (.some(let date), .some(let time), .some) where !strict:
                return LocalDateTime(date: date, time: time)
            case (.some(let date), .some(let time), .none):
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
            case (.some(let date), .some, .some) where !strict:
                return date
            case (.some(let date), .some, .none) where !strict:
                return date
            case (.some(let date), .none, .none):
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
            case (.some, .some(let time), .some) where !strict:
                return time
            case (.some, .some(let time), .none) where !strict:
                return time
            case (.none, .some(let time), .none):
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

extension Dictionary<String, Any> {
    public init(_ tomlTable: TOMLTable) throws(TOMLError) {
        self = try tomlTable.dictionary()
    }
}

extension TOMLTable: Collection {
    public subscript(position: Index) -> (key: String, value: Any) {
        let sourceTable = source.tables[index]
        switch position {
        case .keyValue(let index):
            let kv = try? source.keyValues[sourceTable.keyValues[index]].unpackedValue()
            guard let kv, let v = kv.1 else { fatalError("Invalid key-value pair at index \(index)") }
            return (kv.0, v)
        case .array(let index):
            let array = source.arrays[sourceTable.arrays[index]]
            return (array.key!, array)
        case .table(let index):
            let table = source.tables[sourceTable.tables[index]]
            return (table.key!, table)
        case .empty:
            fatalError("TOMLTable is empty")
        case .end:
            fatalError("TOMLTable.Index.end is not a valid position")
        }
    }

    public func index(after i: Index) -> Index {
        let sourceTable = source.tables[index]
        switch i {
        case .keyValue(let index):
            if index < sourceTable.keyValues.count - 1 {
                return .keyValue(index + 1)
            }

            if !sourceTable.arrays.isEmpty {
                return .array(0)
            }

            if !sourceTable.tables.isEmpty {
                return .table(0)
            }

            return .end
        case .array(let index):
            if index < sourceTable.arrays.count - 1 {
                return .array(index + 1)
            }

            if !sourceTable.tables.isEmpty {
                return .table(0)
            }

            return .end
        case .table(let index):
            if index < sourceTable.tables.count - 1 {
                return .table(index + 1)
            }

            return .end
        case .empty:
            if !sourceTable.keyValues.isEmpty {
                return .keyValue(0)
            }

            if !sourceTable.arrays.isEmpty {
                return .array(0)
            }

            if !sourceTable.tables.isEmpty {
                return .table(0)
            }

            return .empty
        case .end:
            return .end
        }
    }

    public var startIndex: Index {
        let sourceTable = source.tables[index]
        if !sourceTable.keyValues.isEmpty {
            return .keyValue(0)
        }

        if !sourceTable.arrays.isEmpty {
            return .array(0)
        }

        if !sourceTable.tables.isEmpty {
            return .table(0)
        }

        return .empty
    }

    public var endIndex: Index { .end }

    public enum Index: Comparable {
        case empty
        case end
        case keyValue(Int)
        case array(Int)
        case table(Int)

        public static func < (lhs: Index, rhs: Index) -> Bool {
            switch (lhs, rhs) {
            case (.keyValue(let lhsIndex), .keyValue(let rhsIndex)):
                return lhsIndex < rhsIndex
            case (.array(let lhsIndex), .array(let rhsIndex)):
                return lhsIndex < rhsIndex
            case (.table(let lhsIndex), .table(let rhsIndex)):
                return lhsIndex < rhsIndex
            case (.keyValue, .array):
                return true
            case (.keyValue, .table):
                return true
            case (.array, .keyValue):
                return false
            case (.array, .table):
                return true
            case (.table, .keyValue):
                return false
            case (.table, .array):
                return false
            case (.empty, _):
                return true
            case (_, .empty):
                return false
            case (_, .end):
                return true
            case (.end, _):
                return false
            }
        }
    }
}
