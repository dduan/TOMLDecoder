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
            topLevel = try TOMLTable(source: text, keyTransform: strategy.key.converter)
        } catch {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "The given data was not valid TOML.", underlyingError: error))
        }

        let decoder = _TOMLDecoder(referencing: .keyed(topLevel), at: [], strategy: strategy, isLenient: isLenient)
        return try type.init(from: decoder)
    }
}

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
    let result: String = if leadingUnderscoreRange.isEmpty, trailingUnderscoreRange.isEmpty {
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
    return result
}
