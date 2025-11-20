import Foundation

public struct TOMLArray: Equatable, Sendable {
    let source: Deserializer
    let index: Int

    public var count: Int {
        source.arrays[index].elements.count
    }

    @inline(__always)
    func element(atIndex index: Int) throws(TOMLError) -> TOMLArrayImplementation.Element {
        let elements = source.arrays[self.index].elements
        guard index < elements.count else {
            throw TOMLError.arrayOutOfBound(index: index, bound: elements.count)
        }

        return elements[index]
    }

    public func array(atIndex index: Int) throws(TOMLError) -> TOMLArray {
        guard case let .array(arrayIndex) = try element(atIndex: index) else {
            throw TOMLError.typeMismatchInArray(index: index, expected: "array")
        }

        return TOMLArray(source: source, index: arrayIndex)
    }

    public func table(atIndex index: Int) throws(TOMLError) -> TOMLTable {
        guard case let .table(tableIndex) = try element(atIndex: index) else {
            throw TOMLError.typeMismatchInArray(index: index, expected: "table")
        }
        return TOMLTable(source: source, index: tableIndex)
    }

    public func string(atIndex index: Int) throws(TOMLError) -> String {
        guard case let .leaf(.string(text)) = try element(atIndex: index) else {
            throw TOMLError.typeMismatchInArray(index: index, expected: "string")
        }
        return try stringMaybe(text)!
    }

    public func bool(atIndex index: Int) throws(TOMLError) -> Bool {
        guard case let .leaf(.bool(value)) = try element(atIndex: index) else {
            throw TOMLError.typeMismatchInArray(index: index, expected: "bool")
        }
        return value
    }

    public func integer(atIndex index: Int) throws(TOMLError) -> Int64 {
        guard case let .leaf(.int(value)) = try element(atIndex: index) else {
            throw TOMLError.typeMismatchInArray(index: index, expected: "integer")
        }
        return value
    }

    public func float(atIndex index: Int) throws(TOMLError) -> Double {
        guard case let .leaf(.double(value)) = try element(atIndex: index) else {
            throw TOMLError.typeMismatchInArray(index: index, expected: "float")
        }
        return value
    }

    public func offsetDateTime(atIndex index: Int) throws(TOMLError) -> OffsetDateTime {
        guard case let .leaf(.dateTimeComponents(components)) = try element(atIndex: index) else {
            throw TOMLError.typeMismatchInArray(index: index, expected: "offset datetime")
        }

        switch (components.date, components.time, components.offset, components.features) {
        case let (.some(date), .some(time), .some(offset), features):
            return OffsetDateTime(date: date, time: time, offset: offset, features: features)
        default:
            throw TOMLError.typeMismatchInArray(index: index, expected: "offset datetime")
        }
    }

    public func localDateTime(atIndex index: Int, exactMatch: Bool = true) throws(TOMLError) -> LocalDateTime {
        guard case let .leaf(.dateTimeComponents(components)) = try element(atIndex: index) else {
            throw TOMLError.typeMismatchInArray(index: index, expected: "local datetime")
        }

        return try components.localDateTime(exactMatch: exactMatch, error: TOMLError.typeMismatchInArray(index: index, expected: "local datetime"))
    }

    public func localDate(atIndex index: Int, exactMatch: Bool = true) throws(TOMLError) -> LocalDate {
        guard case let .leaf(.dateTimeComponents(components)) = try element(atIndex: index) else {
            throw TOMLError.typeMismatchInArray(index: index, expected: "local date")
        }

        return try components.localDate(exactMatch: exactMatch, error: TOMLError.typeMismatchInArray(index: index, expected: "local date"))
    }

    public func localTime(atIndex index: Int, exactMatch: Bool = true) throws(TOMLError) -> LocalTime {
        guard case let .leaf(.dateTimeComponents(components)) = try element(atIndex: index) else {
            throw TOMLError.typeMismatchInArray(index: index, expected: "local time")
        }

        return try components.localTime(exactMatch: exactMatch, error: TOMLError.typeMismatchInArray(index: index, expected: "local time"))
    }

    func array() throws(TOMLError) -> [Any] {
        let count = source.arrays.count
        guard index < count else {
            throw TOMLError.arrayOutOfBound(index: index, bound: count)
        }
        return try source.arrays[index].array(source: source)
    }
}

extension TOMLArray: Codable {
    public init(from _: any Decoder) throws(TOMLError) {
        throw .notReallyCodable
    }

    public func encode(to _: any Encoder) throws(TOMLError) {
        throw .notReallyCodable
    }
}

extension [Any] {
    public init(_ tomlArray: TOMLArray) throws(TOMLError) {
        self = try tomlArray.array()
    }
}
