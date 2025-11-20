import Foundation

public struct TOMLDecoder {
    public var isLenient: Bool
    public var strategy: Strategy

    public init(isLenient: Bool = true, strategy: Strategy = .default) {
        self.isLenient = isLenient
        self.strategy = strategy
    }

    public struct Strategy: Sendable {
        public var offsetDateTime: OffsetDateTime
        public var key: Key

        init(offsetDateTime: OffsetDateTime, key: Key) {
            self.offsetDateTime = offsetDateTime
            self.key = key
        }

        public static let `default` = Strategy(offsetDateTime: .dateFromGregorianCalendar, key: .useOriginalKeys)

        public enum OffsetDateTime: Sendable {
            case intervalSince1970
            case intervalSince2001
            case dateFromGregorianCalendar
            case dateFromCalendar(identifiedBy: Calendar.Identifier)
            case dateFromProlepticGregorianCalendar
        }

        public enum Key: Sendable {
            /// Use the keys specified by each type. This is the default strategy.
            case useOriginalKeys

            /// Convert from "snake_case_keys" to "camelCaseKeys" before attempting to match a key with the one specified by each type.
            ///
            /// The conversion to upper case uses `Locale.system`, also known as the ICU "root" locale. This means the result is consistent regardless of the current user's locale and language preferences.
            ///
            /// Converting from snake case to camel case:
            /// 1. Capitalizes the word starting after each `_`
            /// 2. Removes all `_`
            /// 3. Preserves starting and ending `_` (as these are often used to indicate private variables or other metadata).
            /// For example, `one_two_three` becomes `oneTwoThree`. `_one_two_three_` becomes `_oneTwoThree_`.
            ///
            /// - Note: Using a key decoding strategy has a nominal performance cost, as each string key has to be inspected for the `_` character.
            case convertFromSnakeCase

            /// Provide a custom conversion from the key in the encoded JSON to the keys specified by the decoded types.
            /// The full path to the current decoding position is provided for context (in case you need to locate this key within the payload). The returned key is used in place of the last component in the coding path before decoding.
            /// If the result of the conversion is a duplicate key, then only one value will be present in the container for the type to decode from.
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

    public func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        guard let text = String(bytes: data, encoding: .utf8) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "The given data was not valid UTF8.", underlyingError: nil))
        }

        return try decode(type, from: text)
    }

    public func decode<T: Decodable>(_ type: T.Type, from text: String) throws -> T {
        let topLevel: TOMLTable
        do {
            let parser = Deserializer(source: text, keyTransform: strategy.key.converter)
            topLevel = try parser.parse()
        } catch {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "The given data was not valid TOML.", underlyingError: error))
        }

        let decoder = _TOMLDecoder(referencing: .keyed(topLevel), at: [], strategy: strategy, isLenient: isLenient)
        return try type.init(from: decoder)
    }
}

extension TOMLDecoder {
    /// Deserialize `text` into a TOML table.
    ///
    /// - Parameter text: String whose content conforms to TOML's spec.
    ///
    /// - Returns: A TOML table that contains the entire content from `text`. The table uses
    ///            types from Swift standard library, and Foundation, to represent TOML values:
    ///
    ///            | TOML             | Swift                       |
    ///            | ---------------- | --------------------------- |
    ///            | String           | `Swift.String`              |
    ///            | Integer          | `Swift.Int64`               |
    ///            | Float            | `Swift.Double`              |
    ///            | Boolean          | `Swift.Bool`                |
    ///            | Local Time       | `Foundation.DateComponents` |
    ///            | Local Date       | `Foundation.DateComponents` |
    ///            | Local Date-Time  | `Foundation.DateComponents` |
    ///            | Offset Date-Time | `Foundation.Date`           |
    ///            | Array            | `Swift.[Any]`               |
    ///            | Table            | `Swift.[String: Any]`       |
    public static func tomlTable(from text: String) throws -> [String: Any] {
        let parser = Deserializer(source: text, keyTransform: nil)
        let table = try parser.parse()
        return try table.dictionary()
    }

    /// Deserialize `bytes` into a TOML table.
    ///
    /// - Parameter text: Bytes whose content conforms to TOML's spec. Per TOML, the bytes should
    ///                   use UTF8 encoding.
    ///
    /// - Returns: A TOML table that contains the entire content from `bytes`. The table uses
    ///            types from Swift standard library, and Foundation, to represent TOML values:
    ///
    ///            | TOML             | Swift                       |
    ///            | ---------------- | --------------------------- |
    ///            | String           | `Swift.String`              |
    ///            | Integer          | `Swift.Int64`               |
    ///            | Float            | `Swift.Double`              |
    ///            | Boolean          | `Swift.Bool`                |
    ///            | Local Time       | `Foundation.DateComponents` |
    ///            | Local Date       | `Foundation.DateComponents` |
    ///            | Local Date-Time  | `Foundation.DateComponents` |
    ///            | Offset Date-Time | `Foundation.Date`           |
    ///            | Array            | `Swift.[Any]`               |
    ///            | Table            | `Swift.[String: Any]`       |
    public static func tomlTable(from bytes: some Collection<Unicode.UTF8.CodeUnit>) throws -> [String: Any] {
        guard let source = String(bytes: bytes, encoding: .utf8) else {
            throw TOMLError.invalidUTF8
        }
        let parser = Deserializer(source: source, keyTransform: nil)
        let table = try parser.parse()
        return try table.dictionary()
    }
}
