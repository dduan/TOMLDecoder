public import Foundation

/// Convert data for a TOML document into `Codable` types.
///
/// Use this struct to configure and initiate the decoding process.
///
///     let tomlData = """
///     ip = "127.0.0.1"
///     port = "8080"
///     """
///     struct Server: Codable {
///         let ip: String
///         let port: String
///     }
///
///     let server = try TOMLDecoder().decode(Server.self, from: tomlData)
///     print(server.ip) // 127.0.0.1
///
/// Setting ``TOMLDecoder/isLenient`` to `false` causes errors to be thrown
/// if the declared types in the `Codable` mis-matches those strictly defined
/// for each TOML value. See <doc:DeserializingTOML>.
///
/// Use ``TOMLDecoder/strategy`` to customize the decoding behavior.
/// Each TOML value may be decoded into one or more Swift types.
/// See <doc:DecodingTOML> to learn all possible types.
public struct TOMLDecoder: Sendable {
    /// Specify whether TOMLDecoder should attempt to convert the value
    /// from its initial type made by the parser to one of its compatible types.
    ///
    /// For example, TOML integers are natively represented with `Int64`.
    /// If this value is `true`,
    /// This integer may be decoded as a `Int`, `UInt`, `Int8`, etc.
    /// But the decoding may still fail during the type conversion because
    /// the requested type cannot fully represent the specific value.
    /// (For example,
    /// an integer might be too large to be represented by a type such as `Int8`).
    /// When `isLenient` is set to `false`,
    /// attempts to decode a TOML value into anything other than the original
    /// deserialized values
    /// (see <doc:DeserializingTOML#The-Definitive-List-of-TOML-to-Swift-Types>)
    /// will result in an decoding error.
    ///
    /// defaults to `true`.
    public var isLenient: Bool

    /// Customize the decoding behavior of a `TOMLDecoder`.
    ///
    /// Use ``KeyStrategy`` to customize how a TOML key gets mapped
    /// to the property name of a `Codable`.
    ///
    /// Use ``TimeIntervalStrategy`` to specify how TOML offset date-times
    /// are interpreted as `TimeInterval`s.
    ///
    /// Use ``DateStrategy`` to specify how TOML offset date-times
    /// are interpreted as `Date`s.
    ///
    /// Defaults to ``TOMLDecoder/Strategy/default``.
    public var strategy: Strategy

    /// Initializes a `TOMLDecoder`.
    ///
    /// - Parameters:
    ///   - isLenient: whether the decoder is allowed to convert the parsed type
    ///     into related types. See <doc:DecodingTOML>. Defaults to `true`.
    ///   - strategy: options that changes some details of the decoding process.
    ///     Defaults to ``TOMLDecoder/Strategy/default``.
    public init(isLenient: Bool = true, strategy: Strategy = .default) {
        self.isLenient = isLenient
        self.strategy = strategy
    }

    /// A value for customizing ``TOMLDecoder``'s behaviors.
    ///
    /// Choose how a TOML table's key is mapped to a `Codable`'s property
    /// via ``Strategy/key``.
    ///
    /// Use ``TimeIntervalStrategy`` to specify how TOML offset date-times
    /// are interpreted as `TimeInterval`s.
    ///
    /// Use ``DateStrategy`` to specify how TOML offset date-times
    /// are interpreted as `Date`s.
    public struct Strategy: Sendable {
        /// Specifies how a TOML table's key is mapped to the name of a `Decodable`'s property.
        ///
        /// For example, ``/TOMLDecoder/TOMLDecoder/KeyStrategy/convertFromSnakeCase``
        /// maps a key in TOML written as `foo_bar`
        /// to the corresponding property `fooBar` in the Swift type.
        ///
        /// See ``KeyStrategy`` to learn more.
        public var key: KeyStrategy

        /// Specifies how a TOML offset date-time is re-interpreted as a date.
        ///
        /// See ``DateStrategy`` to learn more.
        public var date: DateStrategy

        /// Specifies how a TOML offset date-time is re-interpreted as a
        /// time interval.
        ///
        /// See ``TimeIntervalStrategy`` to learn more.
        public var timeInterval: TimeIntervalStrategy

        /// Creates a `Strategy`.
        ///
        /// - Parameters:
        ///   - key: strategy for TOML table keys.
        ///   - timeInterval: strategy for converting offset date-times to
        ///     `Foundation.TimeInterval`s.
        ///   - date: strategy for converting a offset date-times to
        ///     `Foundation.Date`s.
        public init(
            key: KeyStrategy = .useOriginalKeys,
            date: DateStrategy = .gregorianCalendar,
            timeInterval: TimeIntervalStrategy = .since1970
        ) {
            self.key = key
            self.timeInterval = timeInterval
            self.date = date
        }

        /// ``TOMLDecoder``'s default strategy.
        public static let `default` = Strategy(
            key: .useOriginalKeys,
            date: .gregorianCalendar,
            timeInterval: .since1970
        )
    }

    /// Decode `Data` representing a TOML document into `type`.
    ///
    /// The `data` must represent a valid, UTF-8-encoded TOML document.
    ///
    /// - Parameters:
    ///   - type: a `Codable`, or `Decodable` type.
    ///     TOMLDecoder will create an instance of such type if it matches content of `data`.
    ///   - data: A bytes sequence that represents a valid TOML document.
    /// - Returns: An instance of `T`.
    public func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        guard let text = String(bytes: data, encoding: .utf8) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "The given data was not valid UTF8.", underlyingError: nil))
        }

        return try decode(type, from: text)
    }

    /// Decode a string representing a TOML document into `type`.
    ///
    /// The `text` must represent a valid, UTF-8-encoded TOML document.
    ///
    /// - Parameters:
    ///   - type: a `Codable`, or `Decodable` type.
    ///     TOMLDecoder will create an instance of such type if it matches content of `data`.
    ///   - text: A string that represents a valid TOML document.
    /// - Returns: An instance of `T`.
    public func decode<T: Decodable>(_ type: T.Type, from text: String) throws -> T {
        let topLevel: TOMLTable
        do {
            topLevel = try TOMLTable(source: text, keyTransform: strategy.key.converter)
        } catch {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "The given data was not valid TOML.", underlyingError: error))
        }

        let decoder = _TOMLDecoder(referencing: .keyed(topLevel), at: [], strategy: strategy, isLenient: isLenient)
        return try type.init(from: decoder)
    }
}

extension TOMLDecoder {
    /// Specifies how to re-interpret a TOML offset date-time,
    /// or a TOML float,
    /// as a time interval.
    ///
    /// An offset date-time is always parsed as a ``OffsetDateTime`` first.
    /// But sometimes you want it as a `Foundation.TimeInterval` or `Double`.
    /// This is allowed as long as `/TOMLDecoder/TOMLDecoder/isLenient` is `true`.
    public enum TimeIntervalStrategy: Sendable {
        /// Interpret TOML offset date-times,
        /// or TOML floats,
        /// as a time interval since 1970-01-01T00:00:00Z.
        case since1970

        /// Interpret TOML offset date-times,
        /// or TOML floats,
        /// as a time interval since 2001-01-01T00:00:00Z.
        case since2001
    }

    /// Specifies how to re-interpret a TOML offset date-time as a Foundation `Date`.
    ///
    /// An offset date-time is always parsed as a ``OffsetDateTime`` first.
    /// But sometimes you need it as a `Foundation.Date`.
    /// This is allowed as long as `/TOMLDecoder/TOMLDecoder/isLenient` is `true`.
    ///
    /// If you don't deal with ancient dates earlier than 1582-10-04,
    /// you should use ``/TOMLDecoder/TOMLDecoder/DateStrategy/gregorianCalendar``.
    ///
    /// This strategy exists because Foundation's Gregorian calendar is *not* proleptic.
    /// Read <doc:DecodingTOML#Date-strategies> to learn more about this.
    public enum DateStrategy: Sendable {
        /// Give the components from a TOML offset date-time to Foundation's Gregorian calendar
        /// to create a `Foundation.Date`.
        case gregorianCalendar

        /// Give the components from a TOML offset date-time to a custom calendar from Foundation
        /// specified by a `Foundation.Calendar.Identifier`
        /// to create a `Foundation.Date`.
        case calendar(identifiedBy: Calendar.Identifier)

        /// Calculate the number of seconds using a proleptic Gregorian calendar.
        /// Then use it to create a `Foundation.Date`.
        /// For modern dates, this should result in the same `Foundation.Date` as ``gregorianCalendar``.
        case prolepticGregorianCalendar
    }

    /// Strategy for mapping TOML table keys to `Codable` or `Decodable` property names.
    ///
    /// You may choose to use the TOML key as-is,
    /// map a snake_case to a camelCase,
    /// or apply a custom function that maps the original TOML key to a property name.
    ///
    ///   let tomlData = """
    ///   first_name = "Tom"
    ///   """
    ///   struct Person: Codable {
    ///       let firstName: String
    ///   }
    ///
    ///   // even though it's `first_name` in the TOML,
    ///   // we choose to map it to `Person.firstName`.
    ///   let decoder = TOMLDecoder(strategy: .init(key: .convertFromSnakeCase))
    ///   try print(decoder.decode(Person.self, from: tomlData).firstName) // Tom
    public enum KeyStrategy: Sendable {
        /// Use the keys specified by each type.
        /// This is the default strategy.
        case useOriginalKeys

        /// Convert from "snake_case_keys" to "camelCaseKeys"
        /// before attempting to match a key with the one specified by each type.
        ///
        /// Converting from snake case to camel case:
        /// 1. Capitalizes the word starting after each `_`
        /// 2. Removes all `_`
        /// 3. Preserves starting and ending `_`
        ///    (as these are often used to indicate private variables or other metadata).
        ///    for example,
        ///    `one_two_three` becomes `oneTwoThree`.
        ///    `_one_two_three_` becomes `_oneTwoThree_`.
        ///
        /// - Note: Using a key decoding strategy has a nominal performance cost,
        ///   as each string key has to be inspected for the `_` character.
        case convertFromSnakeCase

        /// Provide a custom conversion from the key in the encoded TOML
        /// to the keys specified by the decoded types.
        case custom(@Sendable (String) -> String)

        var converter: (@Sendable (String) -> String)? {
            switch self {
            case .useOriginalKeys:
                nil
            case .convertFromSnakeCase:
                snakeCasify(_:)
            case let .custom(custom):
                custom
            }
        }
    }
}

// TODO: make this fast
@Sendable
func snakeCasify(_ stringKey: String) -> String {
    guard !stringKey.isEmpty else { return stringKey }

    // Find the first non-underscore character
    guard let firstNonUnderscore = stringKey.firstIndex(where: { $0 != "_" }) else {
        // Reached the end without finding an _
        return stringKey
    }

    // Find the last non-underscore character
    var lastNonUnderscore = stringKey.index(before: stringKey.endIndex)
    while lastNonUnderscore > firstNonUnderscore, stringKey[lastNonUnderscore] == "_" {
        stringKey.formIndex(before: &lastNonUnderscore)
    }

    let keyRange = firstNonUnderscore ... lastNonUnderscore
    let leadingUnderscoreRange = stringKey.startIndex ..< firstNonUnderscore
    let trailingUnderscoreRange = stringKey.index(after: lastNonUnderscore) ..< stringKey.endIndex

    let components = stringKey[keyRange].split(separator: "_")
    let joinedString: String = if components.count == 1 {
        // No underscores in key, leave the word as is - maybe already camel cased
        String(stringKey[keyRange])
    } else {
        ([components[0].lowercased()] + components[1...].map(\.capitalized)).joined()
    }

    // Do a cheap isEmpty check before creating and appending potentially empty strings
    return if leadingUnderscoreRange.isEmpty, trailingUnderscoreRange.isEmpty {
        joinedString
    } else if !leadingUnderscoreRange.isEmpty, !trailingUnderscoreRange.isEmpty {
        // Both leading and trailing underscores
        String(stringKey[leadingUnderscoreRange]) + joinedString + String(stringKey[trailingUnderscoreRange])
    } else if !leadingUnderscoreRange.isEmpty {
        // Just leading
        String(stringKey[leadingUnderscoreRange]) + joinedString
    } else {
        // Just trailing
        joinedString + String(stringKey[trailingUnderscoreRange])
    }
}
