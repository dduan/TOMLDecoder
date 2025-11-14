import Foundation

public struct TOMLArray {
    let source: Deserializer
    let index: Int

    public var count: Int {
        return source.arrays[self.index].elements.count
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
        guard case .array(let arrayIndex) = try element(atIndex: index) else {
            throw TOMLError.typeMismatchInArray(index: index, expected: "array")
        }

        return TOMLArray(source: source, index: arrayIndex)
    }

    public func table(atIndex index: Int) throws(TOMLError) -> TOMLTable {
        guard case .table(let tableIndex) = try element(atIndex: index) else {
            throw TOMLError.typeMismatchInArray(index: index, expected: "table")
        }
        return TOMLTable(source: source, index: tableIndex)
    }

    public func string(atIndex index: Int) throws(TOMLError) -> String {
        guard case .leaf(.string(let text)) = try element(atIndex: index) else {
            throw TOMLError.typeMismatchInArray(index: index, expected: "string")
        }
        return try stringMaybe(text)!
    }

    public func bool(atIndex index: Int) throws(TOMLError) -> Bool {
        guard case .leaf(.bool(let value)) = try element(atIndex: index) else {
            throw TOMLError.typeMismatchInArray(index: index, expected: "bool")
        }
        return value
    }

    public func integer(atIndex index: Int) throws(TOMLError) -> Int64 {
        guard case .leaf(.int(let value)) = try element(atIndex: index) else {
            throw TOMLError.typeMismatchInArray(index: index, expected: "integer")
        }
        return value
    }

    public func float(atIndex index: Int) throws(TOMLError) -> Double {
        guard case .leaf(.double(let value)) = try element(atIndex: index) else {
            throw TOMLError.typeMismatchInArray(index: index, expected: "float")
        }
        return value
    }

    public func offsetDateTime(atIndex index: Int) throws(TOMLError) -> OffsetDateTime {
        guard case .leaf(.offsetDateTime(let value)) = try element(atIndex: index) else {
            throw TOMLError.typeMismatchInArray(index: index, expected: "offset datetime")
        }
        return value
    }

    public func localDateTime(atIndex index: Int) throws(TOMLError) -> LocalDateTime {
        guard case .leaf(.localDateTime(let value)) = try element(atIndex: index) else {
            throw TOMLError.typeMismatchInArray(index: index, expected: "local datetime")
        }
        return value
    }

    public func localDate(atIndex index: Int) throws(TOMLError) -> LocalDate {
        guard case .leaf(.localDate(let value)) = try element(atIndex: index) else {
            throw TOMLError.typeMismatchInArray(index: index, expected: "local date")
        }
        return value
    }

    public func localTime(atIndex index: Int) throws(TOMLError) -> LocalTime {
        guard case .leaf(.localTime(let value)) = try element(atIndex: index) else {
            throw TOMLError.typeMismatchInArray(index: index, expected: "local time")
        }
        return value
    }

    func array() throws(TOMLError) -> [Any] {
        let count = source.arrays.count
        guard index < count else {
            throw TOMLError.arrayOutOfBound(index: index, bound: count)
        }
        return try source.arrays[index].array(source: source)
    }
}

extension Array<Any> {
    public init(_ tomlArray: TOMLArray) throws(TOMLError) {
        self = try tomlArray.array()
    }
}
