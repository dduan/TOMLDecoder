import Foundation

/// A parsed TOML array.
///
/// This is a structural type that contains TOML fields accessible by index.
///
/// The content of the array is strongly-typed.
/// Each TOML type has a definitive, corresponding Swift type,
/// * integer: `Swift.Int64`
/// * float: `Swift.Double`
/// * boolean: `Swift.Bool`
/// * string: `Swift.String`
/// * offset date-time: `OffsetDateTime`
/// * local date-time: `LocalDateTime`
/// * local date: `LocalDate`
/// * local time: `LocalTime`
/// * array: `TOMLArray`
/// * table: `TOMLTable`
///
/// To access content of the array of a given type as defined by TOML,
/// use a corresponding method for that type.
/// If the index is out of bounds,
/// or if the value at the index is of the wrong type,
/// the methods will throw an ``TOMLError``.
///
///     let integer = try tomlArray.integer(atIndex: 0)
///
/// Local date / time may be retrieved from a value that's "fuller".
/// For example, a local time can be retrieved
/// when the value is a offset date-time, or local date-time.
/// Pass `exactMatch` as `false` to relax the requirement.
///
///     // Will not throw error if `time` is an offset date-time or local date-time.
///     let localTime1 = try tomlArray.localTime(atIndex: 0, exactMatch: false)
///
///     // Will throw `TOMLError` error
///     // if `time` is an offset date-time or local date-time.
///     let localTime2 = try tomlArray.localTime(atIndex: 0, exactMatch: true)
///
/// To check if an index is in range of an array,
/// use the `count` property.
///
///     let indexIsValid = myIndex < tomlArray.count
///
/// You may also convert the entire array into a Swift array
/// with the `Array` initializer.
///
///     // get a [Any]
///     let swiftArray: [Any] = try Array(tomlArray)
///
/// This causes all fields to be validated,
/// and replaces all intermediate ``TOMLArray``s with `[Any]`,
/// and all ``TOMLTable``s with `[String: Any]`.
/// If any fields are invalid, a ``TOMLError`` is thrown.
/// This can be slow.
///
/// ``TOMLArray`` declares conformance to `Codable`,
/// so you can use it as part of a larger Codable structure.
///
///    struct Config: Codable {
///        let servers: TOMLArray // This works.
///    }
///    let config = try TOMLDecoder().decode(Config.self, from: tomlString)
///
/// > Warning: ``TOMLArray`` declares conformance to `Codable`
///   but it is not a full `Codable` conformance.
///   The decoding logic is only implemented in ``TOMLDecoder``.
///   Attempting to use it with other encoder or decoder
///   will result in a `TOMLError` error.
///
/// Read <doc:DeserializingTOML> to learn more about ``TOMLArray``.
public struct TOMLArray: Equatable, Sendable {
    let source: TOMLDocument
    let index: Int

    /// Number of elements in the array.
    public var count: Int {
        source.arrays[index].elements.count
    }

    @inline(__always)
    func element(atIndex index: Int) throws(TOMLError) -> InternalTOMLArray.Element {
        let elements = source.arrays[self.index].elements
        guard index < elements.count else {
            throw TOMLError(.arrayOutOfBound(index: index, bound: elements.count))
        }

        return elements[index]
    }

    /// Access a TOML array at a given index.
    ///
    /// The index must be within bounds of the array,
    /// If the corresponding value is not a TOML array,
    /// the method will throw a `TOMLError` error.
    ///
    /// - Parameter index: The index to access.
    /// - Returns: A TOML array for the given index, if it exists.
    /// - Throws: `TOMLError`
    ///   if the index is out of bounds or is not a TOML array.
    public func array(atIndex index: Int) throws(TOMLError) -> TOMLArray {
        let element = try element(atIndex: index)
        guard case let .array(_, arrayIndex) = element else {
            throw TOMLError(.typeMismatchInArray(lineNumber: element.lineNumber, index: index, expected: "array"))
        }

        return TOMLArray(source: source, index: arrayIndex)
    }

    /// Access a TOML table at a given index.
    ///
    /// The index must be within bounds of the array,
    /// If the corresponding value is not a TOML table,
    /// the method will throw a `TOMLError` error.
    ///
    /// - Parameter index: The index to access.
    /// - Returns: A TOML table for the given index, if it exists.
    /// - Throws: `TOMLError`
    ///   if the index is out of bounds or is not a TOML table.
    public func table(atIndex index: Int) throws(TOMLError) -> TOMLTable {
        let element = try element(atIndex: index)
        guard case let .table(_, tableIndex) = element else {
            throw TOMLError(.typeMismatchInArray(lineNumber: element.lineNumber, index: index, expected: "table"))
        }
        return TOMLTable(source: source, index: tableIndex)
    }

    @inline(__always)
    func token(forIndex index: Int, type: String) throws(TOMLError) -> Token {
        let element = try element(atIndex: index)
        guard case let .leaf(token) = element else {
            throw TOMLError(.typeMismatchInArray(lineNumber: element.lineNumber, index: index, expected: type))
        }
        return token
    }

    /// Access a string value at a given index.
    ///
    /// The index must be within bounds of the array,
    /// If the corresponding value is not a string,
    /// the method will throw a `TOMLError` error.
    ///
    /// - Parameter index: The index to access.
    /// - Returns: A string value for the given index, if it exists.
    /// - Throws: `TOMLError`
    ///   if the index is out of bounds or is not a string.
    public func string(atIndex index: Int) throws(TOMLError) -> String {
        try token(forIndex: index, type: "string").unpackString(source: source.source, context: .int(index))
    }

    /// Access a boolean value at a given index.
    ///
    /// The index must be within bounds of the array,
    /// If the corresponding value is not a boolean,
    /// the method will throw a `TOMLError` error.
    ///
    /// - Parameter index: The index to access.
    /// - Returns: A boolean value for the given index, if it exists.
    /// - Throws: `TOMLError`
    ///   if the index is out of bounds or is not a boolean.
    public func bool(atIndex index: Int) throws(TOMLError) -> Bool {
        try token(forIndex: index, type: "bool").unpackBool(source: source.source, context: .int(index))
    }

    /// Access an integer value at a given index.
    ///
    /// The index must be within bounds of the array,
    /// If the corresponding value is not an integer,
    /// the method will throw a `TOMLError` error.
    ///
    /// - Parameter index: The index to access.
    /// - Returns: An integer value for the given index, if it exists.
    /// - Throws: `TOMLError`
    ///   if the index is out of bounds or is not an integer.
    public func integer(atIndex index: Int) throws(TOMLError) -> Int64 {
        try token(forIndex: index, type: "integer").unpackInteger(source: source.source, context: .int(index))
    }

    /// Access a float value at a given index.
    ///
    /// The index must be within bounds of the array,
    /// If the corresponding value is not a float,
    /// the method will throw a `TOMLError` error.
    ///
    /// - Parameter index: The index to access.
    /// - Returns: A float value for the given index, if it exists.
    /// - Throws: `TOMLError`
    ///   if the index is out of bounds or is not a float.
    public func float(atIndex index: Int) throws(TOMLError) -> Double {
        try token(forIndex: index, type: "float").unpackFloat(source: source.source, context: .int(index))
    }

    /// Access an offset date-time value at a given index.
    ///
    /// The index must be within bounds of the array,
    /// If the corresponding value is not an offset date-time,
    /// the method will throw a `TOMLError` error.
    ///
    /// - Parameter index: The index to access.
    /// - Returns: An offset date-time value for the given index, if it exists.
    /// - Throws: `TOMLError`
    ///   if the index is out of bounds or is not an offset date-time.
    public func offsetDateTime(atIndex index: Int) throws(TOMLError) -> OffsetDateTime {
        try token(forIndex: index, type: "offset date-time").unpackOffsetDateTime(source: source.source, context: .int(index))
    }

    /// Access a local date-time value at a given index.
    ///
    /// The index must be within bounds of the array,
    /// If the corresponding value is not a local date-time,
    /// the method will throw a `TOMLError` error.
    /// If the corresponding value is an offset date-time,
    /// and `exactMatch` is `false`,
    /// the method will return a local date-time,
    /// dropping the time offset.
    /// Otherwise, if the corresponding value is not a local date-time,
    /// the method will throw a `TOMLError` error.
    ///
    /// - Parameters:
    ///   - index: The index to access.
    ///   - exactMatch: Whether to require an exact match for the local date-time.
    /// - Returns: A local date-time value for the given index, if it exists.
    /// - Throws: `TOMLError`
    ///   if the index is out of bounds or is not a local date-time.
    public func localDateTime(atIndex index: Int, exactMatch: Bool = true) throws(TOMLError) -> LocalDateTime {
        let token = try token(forIndex: index, type: "local datetime")
        let components = try token.unpackDateTime(source: source.source, context: .int(index))
        guard let localDateTime = components.localDateTime(exactMatch: exactMatch) else {
            throw TOMLError(.typeMismatchInArray(lineNumber: token.lineNumber, index: index, expected: "local datetime"))
        }
        return localDateTime
    }

    /// Access a local date value at a given index.
    ///
    /// The index must be within bounds of the array,
    /// If the corresponding value is not a local date,
    /// the method will throw a `TOMLError` error.
    /// If the corresponding value is an offset date-time,
    /// or a local date-time,
    /// and `exactMatch` is `false`,
    /// the method will return a local date,
    /// dropping the time and offset.
    /// Otherwise, if the corresponding value is not a local date,
    /// the method will throw a `TOMLError` error.
    ///
    /// - Parameters:
    ///   - index: The index to access.
    ///   - exactMatch: Whether to require an exact match for the local date.
    /// - Returns: A local date value for the given index, if it exists.
    /// - Throws: `TOMLError`
    ///   if the index is out of bounds or is not a local date.
    public func localDate(atIndex index: Int, exactMatch: Bool = true) throws(TOMLError) -> LocalDate {
        let token = try token(forIndex: index, type: "local date")
        let components = try token.unpackDateTime(source: source.source, context: .int(index))
        guard let localDate = components.localDate(exactMatch: exactMatch) else {
            throw TOMLError(.typeMismatchInArray(lineNumber: token.lineNumber, index: index, expected: "local date"))
        }
        return localDate
    }

    /// Access a local time value at a given index.
    ///
    /// The index must be within bounds of the array,
    /// If the corresponding value is not a local time,
    /// the method will throw a `TOMLError` error.
    /// If the corresponding value is an offset date-time,
    /// or a local date-time,
    /// and `exactMatch` is `false`,
    /// the method will return a local time,
    /// dropping the date and offset.
    /// Otherwise, if the corresponding value is not a local time,
    /// the method will throw a `TOMLError` error.
    ///
    /// - Parameters:
    ///   - index: The index to access.
    ///   - exactMatch: Whether to require an exact match for the local time.
    /// - Returns: A local time value for the given index, if it exists.
    /// - Throws: `TOMLError`
    ///   if the index is out of bounds or is not a local time.
    public func localTime(atIndex index: Int, exactMatch: Bool = true) throws(TOMLError) -> LocalTime {
        let token = try token(forIndex: index, type: "local time")
        let components = try token.unpackDateTime(source: source.source, context: .int(index))
        guard let localTime = components.localTime(exactMatch: exactMatch) else {
            throw TOMLError(.typeMismatchInArray(lineNumber: token.lineNumber, index: index, expected: "local time"))
        }
        return localTime
    }

    func array() throws(TOMLError) -> [Any] {
        let count = source.arrays.count
        guard index < count else {
            throw TOMLError(.arrayOutOfBound(index: index, bound: count))
        }
        return try source.arrays[index].array(source: source)
    }
}

extension TOMLArray: Codable {
    /// Makes ``TOMLArray`` eligible for `Codable`.
    ///
    ///    struct Config: Codable {
    ///        let servers: TOMLArray // This works.
    ///    }
    ///
    /// > Warning: This is not a full `Codable` conformance.
    ///   It only works with ``TOMLDecoder``.
    ///
    /// - Parameter _: The decoder to decode from.
    /// - Throws: `TOMLError`
    public init(from _: any Decoder) throws(TOMLError) {
        throw TOMLError(.notReallyCodable)
    }

    /// Makes ``TOMLArray`` eligible for `Codable`.
    ///
    ///    struct Config: Codable {
    ///        let servers: TOMLArray // This works.
    ///    }
    ///
    /// > Warning: This is not a full `Codable` conformance.
    ///   It only works with ``TOMLDecoder``.
    ///
    /// - Parameter _: The encoder to encode to.
    /// - Throws: `TOMLError`
    public func encode(to _: any Encoder) throws(TOMLError) {
        throw TOMLError(.notReallyCodable)
    }
}

extension [Any] {
    /// Create a `[Any]` from a `TOMLArray`.
    /// Validating all fields recursively.
    /// Throw a ``TOMLError`` if any of the fields are invalid.
    /// All intermediate `TOMLArray`s are replaced with `[Any]`.
    /// All intermediate `TOMLTable`s are replaced with `[String: Any]`.
    ///
    /// - Parameter tomlArray: The `TOMLArray` to convert to a `[Any]`.
    /// - Returns: A `[Any]` with the values converted to their definitive,
    ///   corresponding Swift type, recursively.
    /// - Throws: A ``TOMLError`` if any of the fields are invalid.
    ///   if any of the fields are invalid.
    public init(_ tomlArray: TOMLArray) throws(TOMLError) {
        self = try tomlArray.array()
    }
}
