extension TOMLTable {
    init(source: String, keyTransform: (@Sendable (String) -> String)?) throws(TOMLError) {
        self.source = try TOMLDocument(source: source, keyTransform: keyTransform)
        index = 0
    }

    /// Create a root-level TOML table from a TOML document.
    ///
    /// - Parameter source: The TOML document to parse.
    /// - Returns: A `TOMLTable` representing the root-level table of the TOML document.
    /// - Throws: A ``TOMLError`` if the document is invalid.
    public init(source: String) throws(TOMLError) {
        try self.init(source: source, keyTransform: nil)
    }

    /// Create a root-level TOML table from a TOML document
    /// represented as UTF-8 code units.
    ///
    /// - Parameter source: The TOML document encoded in UTF-8.
    ///   This could be `Data` read from from a UTF-8 text file, for example.
    /// - Returns: A `TOMLTable` representing the root-level table of the TOML document.
    /// - Throws: A ``TOMLError`` if the document is invalid.
    public init(source: some Collection<Unicode.UTF8.CodeUnit>) throws(TOMLError) {
        try self.init(source: try String(validatingUTF8: source))
    }
}

// String.init(validating:as:) does not exist in our supported OSes.
private extension String {
    init(validatingUTF8 source: some Collection<Unicode.UTF8.CodeUnit>) throws(TOMLError) {
        do {
            if let result = try source.withContiguousStorageIfAvailable(
                { buffer -> String in
                    try validateAndCreateString(from: buffer)
                }
            ) {
                self = result
                return
            }

            // Slow path: copy to contiguous buffer first
            let array = Array(source)
            self = try array.withUnsafeBufferPointer { buffer -> String in
                try validateAndCreateString(from: buffer)
            }
        } catch let error as TOMLError {
            throw error
        } catch {
            fatalError("Unexpected error type")
        }
    }
}

@_transparent
private func validateAndCreateString(from buffer: UnsafeBufferPointer<UInt8>) throws(TOMLError) -> String {
    var decoder = UTF8()
    var iterator = buffer.makeIterator()

    validationLoop: while true {
        switch decoder.decode(&iterator) {
        case .scalarValue(_):
            continue
        case .emptyInput:
            break validationLoop
        case .error:
            throw TOMLError(.invalidUTF8)
        }
    }

    return String(decoding: buffer, as: UTF8.self)
}

/// A parsed TOML table. Entry point for parsing TOML data.
/// The root of a TOML document is always a table.
///
/// This is a structural type that contains TOML fields accessible by key.
///
/// The root of a TOML document is always a table,
/// therefore this type could also represent an entire TOML document.
///
/// Parse a string or data representing a TOML by using
/// ``init(source:)-(String)``,
/// or ``init(source:)-(Collection<Unicode.UTF8.CodeUnit>)``.
///
///     let tomlDocument: String = ....
///     let tomlTable = try TOMLTable(source: tomlDocument)
///
/// The content of the table is strongly-typed.
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
/// To access content of the table of a given type as defined by TOML,
/// use a corresponding method for that type.
/// If the key does not exist in the table,
/// or if the value for the key is of the wrong type,
/// the methods will throw an ``TOMLError``.
///
///     let integer = try tomlTable.integer(forKey: "baz")
///
/// Local date / time may be retrieved from a value that's "fuller".
/// For example, a local time can be retrieved
/// when the value is a offset date-time, or local date-time.
/// Pass `exactMatch` as `false` to relax the requirement.
///
///     // Will not throw error if `time` is an offset date-time or local date-time.
///     let localTime1 = try tomlTable.localTime(forKey: "time", exactMatch: false)
///
///     // Will throw `TOMLError` error
///     // if `time` is an offset date-time or local date-time.
///     let localTime2 = try tomlTable.localTime(forKey: "time", exactMatch: true)
///
/// To check if the table contains a given key,
/// use the ``contains(key:)`` method.
///
///     tomlTable.contains(key: "foo")
///
/// You may also convert the entire table into a Swift dictionary
/// with the `Dictionary` initializer.
///
///     // get a [String: Any]
///     let swiftDictionary: [String: Any] = try Dictionary(tomlTable)
///
/// This causes all fields to be validated,
/// and replaces all intermediate ``TOMLArray``s with `[Any]`,
/// and all ``TOMLTable``s with `[String: Any]`.
/// If any fields are invalid, a ``TOMLError`` is thrown.
/// This can be slow.
///
/// ``TOMLTable`` declares conformance to `Codable`,
/// so you can use it as part of a larger Codable structure.
///
///    struct Config: Codable {
///        let owner: TOMLTable // This works.
///    }
///    let config = try TOMLDecoder().decode(Config.self, from: tomlString)
///
/// > Warning: ``TOMLTable`` declares conformance to `Codable`
///   but it is not a full `Codable` conformance.
///   The decoding logic is only implemented in ``TOMLDecoder``.
///   Attempting to use it with other encoder or decoder
///   will result in a `TOMLError` error.
///
/// Read <doc:DeserializingTOML> to learn more about ``TOMLTable``.
public struct TOMLTable: Sendable, Equatable {
    let source: TOMLDocument
    let index: Int

    /// All keys available in the table.
    public var keys: [String] {
        source.tables[index].allKeys(source)
    }

    /// Check if the table contains a given key.
    ///
    /// - Parameter key: The key to check for.
    public func contains(key: String) -> Bool {
        source.tables[index].contains(source: source, key: key)
    }

    /// Access a TOML array for a given key.
    ///
    /// The key must be a key in this table,
    /// not a dotted key.
    /// If the corresponding value is not a TOML array,
    /// the method will throw a `TOMLError` error.
    ///
    /// - Parameter key: The key to access.
    /// - Returns: A TOML array for the given key, if it exists.
    /// - Throws: `TOMLError`
    ///   if the key does not exist or is not an array.
    public func array(forKey key: String) throws(TOMLError) -> TOMLArray {
        let arrayIndices = source.tables[index].arrays
        let allArrays = source.arrays
        for i in arrayIndices {
            if allArrays[i].key == key {
                return TOMLArray(source: source, index: i)
            }
        }

        throw TOMLError(.keyNotFoundInTable(key: key, expected: "array"))
    }

    /// Access a TOML table for a given key.
    ///
    /// The key must be a key in this table,
    /// not a dotted key.
    /// If the corresponding value is not a TOML table,
    /// the method will throw a `TOMLError` error.
    ///
    /// - Parameter key: The key to access.
    /// - Returns: A TOML table for the given key, if it exists.
    /// - Throws: `TOMLError`
    ///   if the key does not exist or is not a table.
    public func table(forKey key: String) throws(TOMLError) -> TOMLTable {
        let tableIndices = source.tables[index].tables
        let allTables = source.tables
        for i in tableIndices {
            if allTables[i].key == key {
                return TOMLTable(source: source, index: i)
            }
        }

        throw TOMLError(.keyNotFoundInTable(key: key, expected: "table"))
    }

    // @inline(__always)
    // func value<T>(forKey key: String, parse: (String.UTF8View.SubSequence) throws(TOMLError) -> T) throws(TOMLError) -> T {
    //     let pairIndices = source.tables[index].keyValues
    //     let allPairs = source.keyValues
    //     for i in pairIndices {
    //         if allPairs[i].key == key {
    //             return try parse(allPairs[i].value.text)
    //         }
    //     }

    //     throw TOMLError(.keyNotFoundInTable(key: key, expected: String(describing: T.self)))
    // }

    @inline(__always)
    func token(forKey key: String, expected: String) throws(TOMLError) -> Token {
        let pairIndices = source.tables[index].keyValues
        let allPairs = source.keyValues
        for i in pairIndices {
            if allPairs[i].key == key {
                return allPairs[i].value
            }
        }

        throw TOMLError(.keyNotFoundInTable(key: key, expected: expected))
    }

    /// Access a string value for a given key.
    ///
    /// The key must be a key in this table,
    /// not a dotted key.
    /// If the corresponding value is not a string,
    /// the method will throw a `TOMLError` error.
    ///
    /// - Parameter key: The key to access.
    /// - Returns: A string value for the given key, if it exists.
    /// - Throws: `TOMLError`
    ///   if the key does not exist or is not a string.
    public func string(forKey key: String) throws(TOMLError) -> String {
        try token(forKey: key, expected: "string").unpackString(source: source.source, context: .string(key))
    }

    /// Access a boolean value for a given key.
    ///
    /// The key must be a key in this table,
    /// not a dotted key.
    /// If the corresponding value is not a boolean,
    /// the method will throw a `TOMLError` error.
    ///
    /// - Parameter key: The key to access.
    /// - Returns: A boolean value for the given key, if it exists.
    /// - Throws: A `TOMLError`
    ///   if the key does not exist or is not a boolean.
    public func bool(forKey key: String) throws(TOMLError) -> Bool {
        try token(forKey: key, expected: "bool").unpackBool(source: source.source, context: .string(key))
    }

    /// Access an integer value for a given key.
    ///
    /// The key must be a key in this table,
    /// not a dotted key.
    /// If the corresponding value is not an integer,
    /// the method will throw a `TOMLError` error.
    ///
    /// - Parameter key: The key to access.
    /// - Returns: An integer value for the given key, if it exists.
    /// - Throws: `TOMLError`
    ///   if the key does not exist or is not an integer.
    public func integer(forKey key: String) throws(TOMLError) -> Int64 {
        try token(forKey: key, expected: "integer").unpackInteger(source: source.source, context: .string(key))
    }

    /// Access a float value for a given key.
    ///
    /// The key must be a key in this table,
    /// not a dotted key.
    /// If the corresponding value is not a float,
    /// the method will throw a `TOMLError` error.
    ///
    /// - Parameter key: The key to access.
    /// - Returns: A float value for the given key, if it exists.
    /// - Throws: `TOMLError`
    ///   if the key does not exist or is not a float.
    public func float(forKey key: String) throws(TOMLError) -> Double {
        try token(forKey: key, expected: "float").unpackFloat(source: source.source, context: .string(key))
    }

    /// Access an offset date-time value for a given key.
    ///
    /// The key must be a key in this table,
    /// not a dotted key.
    /// If the corresponding value is not an offset date-time,
    /// the method will throw a `TOMLError` error.
    ///
    /// - Parameter key: The key to access.
    /// - Returns: An offset date-time value for the given key, if it exists.
    /// - Throws: `TOMLError`
    ///   if the key does not exist or is not an offset date-time.
    public func offsetDateTime(forKey key: String) throws(TOMLError) -> OffsetDateTime {
        try token(forKey: key, expected: "offset date-time").unpackOffsetDateTime(source: source.source, context: .string(key))
    }

    /// Access a local date-time value for a given key.
    ///
    /// The key must be a key in this table,
    /// not a dotted key.
    /// If the corresponding value is an offset date-time,
    /// and `exactMatch` is `false`,
    /// the method will return a local date-time,
    /// dropping the time offset.
    /// Otherwise, if the corresponding value is not a local date-time,
    /// the method will throw a `TOMLError` error.
    ///
    /// - Parameters:
    ///   - key: The key to access.
    ///   - exactMatch: Whether to require an exact match for the local date-time.
    /// - Returns: A local date-time value for the given key, if it exists.
    /// - Throws: `TOMLError`
    ///   if the key does not exist or is not a local date-time.
    public func localDateTime(forKey key: String, exactMatch: Bool = true) throws(TOMLError) -> LocalDateTime {
        let token = try token(forKey: key, expected: "local date-time")
        let components = try token.unpackDateTime(source: source.source, context: .string(key))
        guard let localDateTime = components.localDateTime(exactMatch: exactMatch)
        else {
            throw TOMLError(.typeMismatch(context: .string(key), lineNumber: token.lineNumber, expected: "local date-time"))
        }
        return localDateTime
    }

    /// Access a local date value for a given key.
    ///
    /// The key must be a key in this table,
    /// not a dotted key.
    /// If the corresponding value is an offset date-time,
    /// or a local date-time,
    /// and `exactMatch` is `false`,
    /// the method will return a local date,
    /// dropping the time and offset.
    /// Otherwise, if the corresponding value is not a local date,
    /// the method will throw a `TOMLError` error.
    ///
    /// - Parameters:
    ///   - key: The key to access.
    ///   - exactMatch: Whether to require an exact match for the local date.
    /// - Returns: A local date value for the given key, if it exists.
    /// - Throws: `TOMLError`
    public func localDate(forKey key: String, exactMatch: Bool = true) throws(TOMLError) -> LocalDate {
        let token = try token(forKey: key, expected: "local date")
        let components = try token.unpackDateTime(source: source.source, context: .string(key))
        guard let localDate = components.localDate(exactMatch: exactMatch) else {
            throw TOMLError(.typeMismatch(context: .string(key), lineNumber: token.lineNumber, expected: "local date"))
        }
        return localDate
    }

    /// Access a local time value for a given key.
    ///
    /// The key must be a key in this table,
    /// not a dotted key.
    /// If the corresponding value is an offset date-time,
    /// or a local date-time,
    /// and `exactMatch` is `false`,
    /// the method will return a local time,
    /// dropping the date and offset.
    /// Otherwise, if the corresponding value is not a local time,
    /// the method will throw a `TOMLError` error.
    ///
    /// - Parameters:
    ///   - key: The key to access.
    ///   - exactMatch: Whether to require an exact match for the local time.
    /// - Returns: A local time value for the given key, if it exists.
    /// - Throws: `TOMLError`
    ///   if the key does not exist or is not a local time.
    public func localTime(forKey key: String, exactMatch: Bool = true) throws(TOMLError) -> LocalTime {
        let token = try token(forKey: key, expected: "local time")
        let components = try token.unpackDateTime(source: source.source, context: .string(key))
        guard let localTime = components.localTime(exactMatch: exactMatch) else {
            throw TOMLError(.typeMismatch(context: .string(key), lineNumber: token.lineNumber, expected: "local time"))
        }
        return localTime
    }

    func dictionary() throws(TOMLError) -> [String: Any] {
        try source.tables[index].dictionary(source: source)
    }
}

extension TOMLTable: Codable {
    /// Makes ``TOMLTable`` eligible for `Codable`.
    ///
    ///    struct Config: Codable {
    ///        let owner: TOMLTable // This works.
    ///    }
    ///    let config = try TOMLDecoder().decode(Config.self, from: tomlString)
    ///
    /// > Warning: This is not a full `Codable` conformance.
    ///   The decoding logic is only implemented in ``TOMLDecoder``.
    ///   Attempting to use it with other encoder or decoder
    ///   will result in a `TOMLError` error.
    ///
    /// - Parameter _: The decoder to decode from.
    /// - Throws: `TOMLError`, always.
    public init(from _: any Decoder) throws {
        throw TOMLError(.notReallyCodable)
    }

    /// Makes ``TOMLTable`` eligible for `Codable`.
    ///
    ///    struct Config: Codable {
    ///        let owner: TOMLTable // This works.
    ///    }
    ///    let config = try TOMLDecoder().decode(Config.self, from: tomlString)
    ///
    /// > Warning: This is not a full `Codable` conformance.
    ///   The decoding logic is only implemented in ``TOMLDecoder``.
    ///   Attempting to use it with other encoder or decoder
    ///   will result in a `TOMLError` error.
    ///
    /// - Parameter _: The encoder to encode to.
    /// - Throws: `TOMLError`, always.
    public func encode(to _: any Encoder) throws {
        throw TOMLError(.notReallyCodable)
    }
}

extension [String: Any] {
    /// Create a `[String: Any]` from a `TOMLTable`.
    /// Validating all fields along the way.
    /// Throw a ``TOMLError`` if any of the fields are invalid.
    /// All values will have their definitive,
    /// corresponding Swift type.
    /// All intermediate `TOMLArray`s are replaced with `[Any]`.
    /// All intermediate `TOMLTable`s are replaced with `[String: Any]`.
    ///
    /// - Parameter tomlTable: The `TOMLTable` to convert to a `[String: Any]`.
    /// - Returns: A `[String: Any]` with the values converted to their definitive,
    ///   corresponding Swift type, recursively.
    /// - Throws: A ``TOMLError`` if any of the fields are invalid.
    ///   if any of the fields are invalid.
    public init(_ tomlTable: TOMLTable) throws(TOMLError) {
        self = try tomlTable.dictionary()
    }
}
