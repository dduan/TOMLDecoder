import Foundation

extension TOMLTable {
    /// Create a root-level TOML table from a TOML document.
    ///
    /// - Parameter source: The TOML document to parse.
    /// - Returns: A `TOMLTable` representing the root-level table of the TOML document.
    /// - Throws: A ``TOMLError`` if the document is invalid.
    public init(source: String) throws(TOMLError) {
        let parser = Deserializer(source: source, keyTransform: nil)
        self = try parser.parse()
    }

    /// Create a root-level TOML table from a TOML document
    /// represented as UTF-8 code units.
    ///
    /// - Parameter source: The TOML document encoded in UTF-8.
    ///   This could be `Data` read from from a UTF-8 text file, for example.
    /// - Returns: A `TOMLTable` representing the root-level table of the TOML document.
    /// - Throws: A ``TOMLError`` if the document is invalid.
    public init(source: some Collection<Unicode.UTF8.CodeUnit>) throws(TOMLError) {
        guard let source = String(bytes: source, encoding: .utf8) else {
            throw TOMLError.invalidUTF8
        }
        try self.init(source: source)
    }
}

/// A parsed TOML table. Entry point for  parsing TOML data.
/// The root of a TOML document is always a table.
///
/// This type reperesents the result of parsing a TOML table.
/// It's the only type that the parser produces
/// as a result of parsing a TOML document.
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
/// or if the value for the key is the wrong type,
/// the methods will throw an ``TOMLError``.
///
///     let integer = try tomlTable.integer(forKey: "baz")
///
/// Local date / time may be retrieved from a value that's "fuller".
/// For example, a local time can be retrieved
/// when the value is a offset date-time, or lacal date-time.
/// Pass `exactMatch` as `false` to relax the requirement.
///
///     // Will not throw error if `time` is an offset date-time or local date-time.
///     let localTime1 = try tomlTable.localTime(forKey: "time", exactMatch: false)
///
///     // Will throw `TOMLError.typeMismatchInTable` error
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
/// ... doing this can be slow.
/// It also erases the type of the values to `Any`.
public struct TOMLTable: Sendable, Equatable {
    let source: Deserializer
    let index: Int

    // All keys available in the table.
    public var keys: [String] {
        source.tables[index].allKeys(parser: source)
    }

    /// Check if the table contains a given key.
    ///
    /// - Parameter key: The key to check for.
    public func contains(key: String) -> Bool {
        source.tables[index].contains(parser: source, key: key)
    }

    /// Access a TOML array for a given key.
    ///
    /// The key must be a key in this table,
    /// not a dotted key.
    /// If the corresponding value is not a TOML array,
    /// the method will throw a `TOMLError.typeMismatchInTable` error.
    ///
    /// - Parameter key: The key to access.
    /// - Returns: A TOML array for the given key, if it exists.
    /// - Throws: `TOMLError.keyNotFoundInTable`
    ///   if the key does not exist or is not an array.
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

    /// Access a TOML table for a given key.
    ///
    /// The key must be a key in this table,
    /// not a dotted key.
    /// If the corresponding value is not a TOML table,
    /// the method will throw a `TOMLError.typeMismatchInTable` error.
    ///
    /// - Parameter key: The key to access.
    /// - Returns: A TOML table for the given key, if it exists.
    /// - Throws: `TOMLError.keyNotFoundInTable`
    ///   if the key does not exist or is not a table.
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
                return try parse(allPairs[i].value.text)
            }
        }

        throw TOMLError.keyNotFoundInTable(key: key, type: String(describing: T.self))
    }

    /// Access a string value for a given key.
    ///
    /// The key must be a key in this table,
    /// not a dotted key.
    /// If the corresponding value is not a string,
    /// the method will throw a `TOMLError.typeMismatchInTable` error.
    ///
    /// - Parameter key: The key to access.
    /// - Returns: A string value for the given key, if it exists.
    /// - Throws: `TOMLError.keyNotFoundInTable`
    ///   if the key does not exist or is not a string.
    public func string(forKey key: String) throws(TOMLError) -> String {
        try value(forKey: key) { text throws(TOMLError) in
            guard let s = try stringMaybe(text) else {
                throw TOMLError.typeMismatchInTable(key: key, expected: "string")
            }
            return s
        }
    }

    /// Access a boolean value for a given key.
    ///
    /// The key must be a key in this table,
    /// not a dotted key.
    /// If the corresponding value is not a boolean,
    /// the method will throw a `TOMLError.typeMismatchInTable` error.
    ///
    /// - Parameter key: The key to access.
    /// - Returns: A boolean value for the given key, if it exists.
    /// - Throws: `TOMLError.keyNotFoundInTable`
    ///   if the key does not exist or is not a boolean.
    public func bool(forKey key: String) throws(TOMLError) -> Bool {
        try value(forKey: key, parse: boolMaybe)
    }

    /// Access an integer value for a given key.
    ///
    /// The key must be a key in this table,
    /// not a dotted key.
    /// If the corresponding value is not an integer,
    /// the method will throw a `TOMLError.typeMismatchInTable` error.
    ///
    /// - Parameter key: The key to access.
    /// - Returns: An integer value for the given key, if it exists.
    /// - Throws: `TOMLError.keyNotFoundInTable`
    ///   if the key does not exist or is not an integer.
    public func integer(forKey key: String) throws(TOMLError) -> Int64 {
        try value(forKey: key) { text throws(TOMLError) in
            try intMaybe(text, mustBeInt: true)
        }
    }

    /// Access a float value for a given key.
    ///
    /// The key must be a key in this table,
    /// not a dotted key.
    /// If the corresponding value is not a float,
    /// the method will throw a `TOMLError.typeMismatchInTable` error.
    ///
    /// - Parameter key: The key to access.
    /// - Returns: A float value for the given key, if it exists.
    /// - Throws: `TOMLError.keyNotFoundInTable`
    ///   if the key does not exist or is not a float.
    public func float(forKey key: String) throws(TOMLError) -> Double {
        try value(forKey: key) { text throws(TOMLError) in
            try floatMaybe(text, mustBeFloat: true)
        }
    }

    /// Access an offset date-time value for a given key.
    ///
    /// The key must be a key in this table,
    /// not a dotted key.
    /// If the corresponding value is not an offset date-time,
    /// the method will throw a `TOMLError.typeMismatchInTable` error.
    ///
    /// - Parameter key: The key to access.
    /// - Returns: An offset date-time value for the given key, if it exists.
    /// - Throws: `TOMLError.keyNotFoundInTable`
    ///   if the key does not exist or is not an offset date-time.
    public func offsetDateTime(forKey key: String) throws(TOMLError) -> OffsetDateTime {
        try value(forKey: key) { text throws(TOMLError) in
            let components = try datetimeMaybe(lineNumber: nil, text)
            switch (components.date, components.time, components.offset) {
            case let (.some(date), .some(time), .some(offset)):
                return OffsetDateTime(date: date, time: time, offset: offset, features: components.features)
            default:
                throw TOMLError.keyNotFoundInTable(key: key, type: "offset date-time")
            }
        }
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
    /// the method will throw a `TOMLError.typeMismatchInTable` error.
    ///
    /// - Parameters:
    ///   - key: The key to access.
    ///   - exactMatch: Whether to require an exact match for the local date-time.
    /// - Returns: A local date-time value for the given key, if it exists.
    /// - Throws: `TOMLError.keyNotFoundInTable`
    ///   if the key does not exist or is not a local date-time.
    public func localDateTime(forKey key: String, exactMatch: Bool = true) throws(TOMLError) -> LocalDateTime {
        try value(forKey: key) { text throws(TOMLError) in
            let components = try datetimeMaybe(lineNumber: nil, text)
            return try components.localDateTime(exactMatch: exactMatch, error: TOMLError.keyNotFoundInTable(key: key, type: "local date-time"))
        }
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
    /// the method will throw a `TOMLError.typeMismatchInTable` error.
    ///
    /// - Parameters:
    ///   - key: The key to access.
    ///   - exactMatch: Whether to require an exact match for the local date.
    /// - Returns: A local date value for the given key, if it exists.
    /// - Throws: `TOMLError.keyNotFoundInTable`
    public func localDate(forKey key: String, exactMatch: Bool = true) throws(TOMLError) -> LocalDate {
        try value(forKey: key) { text throws(TOMLError) in
            let components = try datetimeMaybe(lineNumber: nil, text)
            return try components.localDate(exactMatch: exactMatch, error: TOMLError.keyNotFoundInTable(key: key, type: "local date"))
        }
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
    /// the method will throw a `TOMLError.typeMismatchInTable` error.
    ///
    /// - Parameters:
    ///   - key: The key to access.
    ///   - exactMatch: Whether to require an exact match for the local time.
    /// - Returns: A local time value for the given key, if it exists.
    /// - Throws: `TOMLError.keyNotFoundInTable`
    ///   if the key does not exist or is not a local time.
    public func localTime(forKey key: String, exactMatch: Bool = true) throws(TOMLError) -> LocalTime {
        try value(forKey: key) { text throws(TOMLError) in
            let components = try datetimeMaybe(lineNumber: nil, text)
            return try components.localTime(exactMatch: exactMatch, error: TOMLError.keyNotFoundInTable(key: key, type: "local time"))
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
    /// Create a `Dictionary<String, Any>` from a `TOMLTable`.
    /// Validating all fields along the way.
    /// Throw a ``TOMLError`` if any of the fields are invalid.
    /// All values will have the definitive,
    /// corresponding Swift type.
    ///
    /// - Parameter tomlTable: The `TOMLTable` to convert to a `Dictionary<String, Any>`.
    /// - Returns: A `Dictionary<String, Any>` with the values converted to the definitive,
    ///   corresponding Swift type.
    /// - Throws: A ``TOMLError`` if any of the fields are invalid.
    public init(_ tomlTable: TOMLTable) throws(TOMLError) {
        self = try tomlTable.dictionary()
    }
}
