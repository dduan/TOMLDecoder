import Foundation

open class TOMLDecoder {
    /// The strategy to use for decoding numbers.
    public enum NumberDecodingStrategy {
        /// Decode only `Int64` for integers or `Double` for floating numbers. Consider other types of number a type mismatch.
        case strict

        /// Decode to requested standard library number types or NSNumber. This is the default stractegy.
        case lenient
    }

    public enum DataDecodingStrategy {
        /// Decode the `Data` from a Base64-encoded string. This is the default strategy.
        case base64

        /// Decode the `Data` as a custom value decoded by the given closure.
        case custom((_ decoder: Decoder) throws -> Data)
    }

    public enum KeyDecodingStrategy {
        /// Use the keys specified by each type. This is the default strategy.
        case useDefaultKeys

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
        case custom((_ codingPath: [CodingKey]) -> CodingKey)
    }

    /// The strategy to use in decoding integer and floats. Defaults to `.lenient`.
    open var numberDecodingStrategy = NumberDecodingStrategy.lenient

    /// The strategy to use in decoding binary data. Defaults to `.base64`.
    open var dataDecodingStrategy = DataDecodingStrategy.base64

    /// The strategy to use for decoding keys. Defaults to `.useDefaultKeys`.
    open var keyDecodingStrategy = KeyDecodingStrategy.useDefaultKeys

    /// Contextual user-provided information for use during decoding.
    open var userInfo: [CodingUserInfoKey : Any] = [:]


    public init() {}
    public func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        guard let text = String(bytes: data, encoding: .utf8) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "The given data was not valid UTF8.", underlyingError: nil))

        }

        return try self.decode(type, from: text)
    }

    public func decode<T: Decodable>(_ type: T.Type, from text: String) throws -> T {
        let topLevel: Any
        do {
            topLevel = try TOMLDeserializer.tomlTable(with: text)
        } catch {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "The given data was not valid TOML.", underlyingError: error))
        }

        let decoder = TOMLDecoderImpl(referencing: self, options: self.options)
        guard let value = try decoder.unbox(topLevel, as: type) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: [], debugDescription: "The given data did not contain a top-level value."))
        }

        return value
    }

    /// Options set on the top-level encoder to pass down the decoding hierarchy.
    struct Options {
        let numberDecodingStrategy: NumberDecodingStrategy
        let dataDecodingStrategy: DataDecodingStrategy
        let keyDecodingStrategy: KeyDecodingStrategy
        let userInfo: [CodingUserInfoKey : Any]
    }


    /// The options set on the top-level decoder.
    var options: Options {
        return Options(numberDecodingStrategy: self.numberDecodingStrategy,
                       dataDecodingStrategy: self.dataDecodingStrategy,
                       keyDecodingStrategy: self.keyDecodingStrategy,
                       userInfo: userInfo)
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
        try TOMLDeserializer.tomlTable(with: text)
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
    public static func tomlTable<Bytes>(from bytes: Bytes) throws -> [String: Any]
        where Bytes: Collection, Bytes.Element == Unicode.UTF8.CodeUnit
    {
        try TOMLDeserializer.tomlTable(with: bytes)
    }
}
