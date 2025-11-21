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
        let element = try element(atIndex: index)
        guard case let .array(_, arrayIndex) = element else {
            throw TOMLError.typeMismatchInArray(lineNumber: element.lineNumber, index: index, expected: "array")
        }

        return TOMLArray(source: source, index: arrayIndex)
    }

    public func table(atIndex index: Int) throws(TOMLError) -> TOMLTable {
        let element = try element(atIndex: index)
        guard case let .table(_, tableIndex) = element else {
            throw TOMLError.typeMismatchInArray(lineNumber: element.lineNumber, index: index, expected: "table")
        }
        return TOMLTable(source: source, index: tableIndex)
    }

    public func string(atIndex index: Int) throws(TOMLError) -> String {
        let element = try element(atIndex: index)
        guard case let .leaf(token) = element else {
            throw TOMLError.typeMismatchInArray(lineNumber: element.lineNumber, index: index, expected: "string")
        }
        guard let result = try stringMaybe(token.text) else {
            throw TOMLError.typeMismatchInArray(lineNumber: token.lineNumber, index: index, expected: "string")
        }
        return result
    }

    public func bool(atIndex index: Int) throws(TOMLError) -> Bool {
        let element = try element(atIndex: index)
        guard case let .leaf(token) = element else {
            throw TOMLError.typeMismatchInArray(lineNumber: element.lineNumber, index: index, expected: "bool")
        }
        do {
            return try boolMaybe(token.text)
        } catch {
            throw TOMLError.typeMismatchInArray(lineNumber: token.lineNumber, index: index, expected: "bool")
        }
    }

    public func integer(atIndex index: Int) throws(TOMLError) -> Int64 {
        let element = try element(atIndex: index)
        guard case let .leaf(token) = element else {
            throw TOMLError.typeMismatchInArray(lineNumber: element.lineNumber, index: index, expected: "integer")
        }
        do {
            return try intMaybe(token.text, mustBeInt: true)
        } catch {
            throw TOMLError.typeMismatchInArray(lineNumber: token.lineNumber, index: index, expected: "integer")
        }
    }

    public func float(atIndex index: Int) throws(TOMLError) -> Double {
        let element = try element(atIndex: index)
        guard case let .leaf(token) = element else {
            throw TOMLError.typeMismatchInArray(lineNumber: element.lineNumber, index: index, expected: "float")
        }
        do {
            return try floatMaybe(token.text, mustBeFloat: true)
        } catch {
            throw TOMLError.typeMismatchInArray(lineNumber: token.lineNumber, index: index, expected: "float")
        }
    }

    public func offsetDateTime(atIndex index: Int) throws(TOMLError) -> OffsetDateTime {
        let element = try element(atIndex: index)
        guard case let .leaf(token) = element else {
            throw TOMLError.typeMismatchInArray(lineNumber: element.lineNumber, index: index, expected: "offset datetime")
        }

        do {
            let components = try datetimeMaybe(lineNumber: nil, token.text)
            switch (components.date, components.time, components.offset, components.features) {
            case let (.some(date), .some(time), .some(offset), features):
                return OffsetDateTime(date: date, time: time, offset: offset, features: features)
            default:
                throw TOMLError.typeMismatchInArray(lineNumber: token.lineNumber, index: index, expected: "offset datetime")
            }
        } catch {
            throw TOMLError.typeMismatchInArray(lineNumber: token.lineNumber, index: index, expected: "offset datetime")
        }
    }

    public func localDateTime(atIndex index: Int, exactMatch: Bool = true) throws(TOMLError) -> LocalDateTime {
        let element = try element(atIndex: index)
        guard case let .leaf(token) = element else {
            throw TOMLError.typeMismatchInArray(lineNumber: element.lineNumber, index: index, expected: "local datetime")
        }

        do {
            let components = try datetimeMaybe(lineNumber: nil, token.text)
            return try components.localDateTime(exactMatch: exactMatch, error: TOMLError.typeMismatchInArray(lineNumber: token.lineNumber, index: index, expected: "local datetime"))
        } catch {
            throw TOMLError.typeMismatchInArray(lineNumber: token.lineNumber, index: index, expected: "local datetime")
        }
    }

    public func localDate(atIndex index: Int, exactMatch: Bool = true) throws(TOMLError) -> LocalDate {
        let element = try element(atIndex: index)
        guard case let .leaf(token) = element else {
            throw TOMLError.typeMismatchInArray(lineNumber: element.lineNumber, index: index, expected: "local date")
        }

        do {
            let components = try datetimeMaybe(lineNumber: nil, token.text)
            return try components.localDate(exactMatch: exactMatch, error: TOMLError.typeMismatchInArray(lineNumber: token.lineNumber, index: index, expected: "local date"))
        } catch {
            throw TOMLError.typeMismatchInArray(lineNumber: token.lineNumber, index: index, expected: "local date")
        }
    }

    public func localTime(atIndex index: Int, exactMatch: Bool = true) throws(TOMLError) -> LocalTime {
        let element = try element(atIndex: index)
        guard case let .leaf(token) = element else {
            throw TOMLError.typeMismatchInArray(lineNumber: element.lineNumber, index: index, expected: "local time")
        }

        do {
            let components = try datetimeMaybe(lineNumber: nil, token.text)
            return try components.localTime(exactMatch: exactMatch, error: TOMLError.typeMismatchInArray(lineNumber: token.lineNumber, index: index, expected: "local time"))
        } catch {
            throw TOMLError.typeMismatchInArray(lineNumber: token.lineNumber, index: index, expected: "local time")
        }
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
