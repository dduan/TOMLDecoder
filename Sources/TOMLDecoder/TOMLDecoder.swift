import Foundation
import NetTime
import TOMLDeserializer

public final class TOMLDecoder {
    public enum NumberDecodingStrategy {
        case strict
        case normal
    }

    public enum DateDecodingStrategy {
        case strict
        case normal
    }

    public enum DataDecodingStrategy {
        case base64
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

    var numberDecodingStrategy = NumberDecodingStrategy.normal
    var dateDecodingStrategy = NumberDecodingStrategy.normal
    var dataDecodingStrategy = DataDecodingStrategy.base64
    var keyDecodingStrategy = KeyDecodingStrategy.useDefaultKeys
    var userInfo: [CodingUserInfoKey : Any] = [:]

    /// Options set on the top-level encoder to pass down the decoding hierarchy.
    fileprivate struct Options {
        let numberDecodingStrategy: NumberDecodingStrategy
        let dateDecodingStrategy: NumberDecodingStrategy
        let dataDecodingStrategy: DataDecodingStrategy
        let keyDecodingStrategy: KeyDecodingStrategy
        let userInfo: [CodingUserInfoKey : Any]
    }


    /// The options set on the top-level decoder.
    fileprivate var options: Options {
        return Options(numberDecodingStrategy: self.numberDecodingStrategy,
                       dateDecodingStrategy: self.dateDecodingStrategy,
                       dataDecodingStrategy: self.dataDecodingStrategy,
                       keyDecodingStrategy: self.keyDecodingStrategy,
                       userInfo: userInfo)
    }

    public init() {}
    public func decode<T : Decodable, Bytes>(_ type: T.Type, from data: Bytes) throws -> T
        where Bytes: Collection, Bytes.Element == UInt8
    {
        let topLevel = try TOMLDeserializer.tomlTable(with: data)
        let decoder = TOMLDecoderImpl(referencing: self, options: self.options)
        guard let value = try decoder.unbox(topLevel, as: type) else {
            throw "Bad"
        }

        return value
    }

    public func decode<T : Decodable>(_ type: T.Type, from string: String) throws -> T {
        let topLevel = try TOMLDeserializer.tomlTable(with: string)
        let decoder = TOMLDecoderImpl(referencing: self, options: self.options)
        guard let value = try decoder.unbox(topLevel, as: type) else {
            throw "Bad"
        }

        return value
    }
}

extension DecodingError {
    /// Returns a `.typeMismatch` error describing the expected type.
    ///
    /// - parameter path: The path of `CodingKey`s taken to decode a value of this type.
    /// - parameter expectation: The type expected to be encountered.
    /// - parameter reality: The value that was encountered instead of the expected type.
    /// - returns: A `DecodingError` with the appropriate path and debug description.
    internal static func _typeMismatch(at path: [CodingKey], expectation: Any.Type, reality: Any) -> DecodingError {
        let description = "Expected to decode \(expectation) but found \(_typeDescription(of: reality)) instead."
        return .typeMismatch(expectation, Context(codingPath: path, debugDescription: description))
    }

    /// Returns a description of the type of `value` appropriate for an error message.
    ///
    /// - parameter value: The value whose type to describe.
    /// - returns: A string describing `value`.
    /// - precondition: `value` is one of the types below.
    fileprivate static func _typeDescription(of value: Any) -> String {
        if value is String {
            return "a string/data"
        } else if value is [Any] {
            return "an array"
        } else if value is [String : Any] {
            return "a dictionary"
        } else {
            return "\(type(of: value))"
        }
    }
}

fileprivate final class TOMLDecoderImpl: Decoder {
    var storage: TOMLDecodingStorage
    var codingPath: [CodingKey]
    var options: TOMLDecoder.Options
    var userInfo: [CodingUserInfoKey : Any] {
        return self.options.userInfo
    }

    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        guard let table = self.storage.topContainer as? [String: Any] else {
            throw "Expected table." // TODO: replace with real error
        }

        return KeyedDecodingContainer(TOMLKeyedDecodingContainer(referencing: self, wrapping: table))
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        guard let array = self.storage.topContainer as? [Any] else {
            throw "Expected array." // TODO: replace with real error
        }

        return TOMLUnkeyedDecodingContainer(referencing: self, wrapping: array)
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        return self
    }

    fileprivate init(referencing container: Any, at codingPath: [CodingKey] = [], options: TOMLDecoder.Options) {
        self.storage = TOMLDecodingStorage()
        self.storage.push(container: container)
        self.codingPath = codingPath
        self.options = options
    }
}

extension TOMLDecoderImpl {
    fileprivate func unbox<T : Decodable>(_ value: Any, as type: T.Type) throws -> T? {
        if type == String.self {
            return (value as? String) as? T
        } else if type == Bool.self {
            return (value as? Bool) as? T
        } else if type == Date.self {
            if self.options.dateDecodingStrategy == .strict {
                throw DecodingError.valueNotFound(Date.self, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Foundation Date is not allowed in strict date strategy"))
            }
            return try self.unbox(value, as: Date.self) as? T
        } else if type == DateComponents.self {
            if self.options.dateDecodingStrategy == .strict {
                throw DecodingError.valueNotFound(Date.self, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Foundation DateComponents is not allowed in strict date strategy"))
            }
            return try self.unbox(value, as: DateComponents.self) as? T
        } else if type == DateTime.self {
            return (value as? DateTime) as? T
        } else if type == LocalDate.self {
            return (value as? LocalDate) as? T
        } else if type == LocalTime.self {
            return (value as? LocalTime) as? T
        } else if type == LocalDateTime.self {
            return (value as? LocalDateTime) as? T
        } else if type == Data.self {
            return try self.unbox(value, as: Data.self) as? T
        }

        self.storage.push(container: value)
        defer { self.storage.popContainer() }
        return try type.init(from: self)
    }

    fileprivate func unbox(_ value: Any, as type: Data.Type) throws -> Data? {
        switch self.options.dataDecodingStrategy {
        case .base64:
            guard let string = value as? String else {
                throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
            }

            guard let data = Data(base64Encoded: string) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Encountered Data is not valid Base64."))
            }

            return data

        case .custom(let closure):
            self.storage.push(container: value)
            defer { self.storage.popContainer() }
            return try closure(self)
        }
    }

    fileprivate func unbox(_ value: Any, as type: DateComponents.Type) throws -> DateComponents? {
        if let time = value as? LocalTime {
            // TODO: second fractions needs to be supported
            return DateComponents(hour: Int(time.hour), minute: Int(time.minute), second: Int(time.second))
        } else if let date = value as? LocalDate {
            return DateComponents(year: Int(date.year), month: Int(date.month), day: Int(date.day))
        } else if let date = value as? LocalDateTime {
            return DateComponents(year: Int(date.year), month: Int(date.month), day: Int(date.day),
                                  hour: Int(date.hour), minute: Int(date.minute), second: Int(date.second))
        }

        throw DecodingError._typeMismatch(at: self.codingPath, expectation: LocalDateTime.self, reality: value)
    }

    fileprivate func unbox(_ value: Any, as type: Date.Type) throws -> Date? {
        guard let datetime = value as? DateTime else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: DateTime.self, reality: value)
        }

        return Date(timeIntervalSinceReferenceDate: datetime.timeIntervalSince2001)
    }

    fileprivate func unbox(_ value: Any, as type: Bool.Type) throws -> Bool? {
        return value as? Bool
    }

    fileprivate func unbox(_ value: Any, as type: String.Type) throws -> String? {
        return value as? String
    }

    fileprivate func unbox(_ value: Any, as type: Double.Type) throws -> Double? {
        switch self.options.numberDecodingStrategy {
        case .strict:
            return value as? Double
        case .normal:
            return (value as? Double) ?? (value as? Int64).flatMap(Double.init(exactly:))
        }
    }

    fileprivate func unbox(_ value: Any, as type: Float.Type) throws -> Float? {
        switch self.options.numberDecodingStrategy {
        case .strict:
            return value as? Float
        case .normal:
            return (value as? Double).flatMap(Float.init(exactly:))
                ?? (value as? Int64).flatMap(Float.init(exactly:))
        }
    }

    fileprivate func unbox(_ value: Any, as type: Int.Type) throws -> Int? {
        switch self.options.numberDecodingStrategy {
        case .strict:
            return value as? Int
        case .normal:
            return (value as? Int64).flatMap(Int.init(exactly:))
                ?? (value as? Double).flatMap(Int.init(exactly:))
        }
    }

    fileprivate func unbox(_ value: Any, as type: Int8.Type) throws -> Int8? {
        switch self.options.numberDecodingStrategy {
        case .strict:
            return value as? Int8
        case .normal:
            return (value as? Int64).flatMap(Int8.init(exactly:))
                ?? (value as? Double).flatMap(Int8.init(exactly:))
        }
    }

    fileprivate func unbox(_ value: Any, as type: Int16.Type) throws -> Int16? {
        switch self.options.numberDecodingStrategy {
        case .strict:
            return value as? Int16
        case .normal:
            return (value as? Int64).flatMap(Int16.init(exactly:))
                ?? (value as? Double).flatMap(Int16.init(exactly:))
        }
    }

    fileprivate func unbox(_ value: Any, as type: Int32.Type) throws -> Int32? {
        switch self.options.numberDecodingStrategy {
        case .strict:
            return value as? Int32
        case .normal:
            return (value as? Int64).flatMap(Int32.init(exactly:))
                ?? (value as? Double).flatMap(Int32.init(exactly:))
        }
    }

    fileprivate func unbox(_ value: Any, as type: Int64.Type) throws -> Int64? {
        switch self.options.numberDecodingStrategy {
        case .strict:
            return value as? Int64
        case .normal:
            return (value as? Int64) ?? (value as? Double).flatMap(Int64.init(exactly:))
        }
    }

    fileprivate func unbox(_ value: Any, as type: UInt.Type) throws -> UInt? {
        switch self.options.numberDecodingStrategy {
        case .strict:
            return value as? UInt
        case .normal:
            return (value as? Int64).flatMap(UInt.init(exactly:))
                ?? (value as? Double).flatMap(UInt.init(exactly:))
        }
    }

    fileprivate func unbox(_ value: Any, as type: UInt8.Type) throws -> UInt8? {
        switch self.options.numberDecodingStrategy {
        case .strict:
            return value as? UInt8
        case .normal:
            return (value as? Int64).flatMap(UInt8.init(exactly:))
                ?? (value as? Double).flatMap(UInt8.init(exactly:))
        }
    }

    fileprivate func unbox(_ value: Any, as type: UInt16.Type) throws -> UInt16? {
        switch self.options.numberDecodingStrategy {
        case .strict:
            return value as? UInt16
        case .normal:
            return (value as? Int64).flatMap(UInt16.init(exactly:))
                ?? (value as? Double).flatMap(UInt16.init(exactly:))
        }
    }

    fileprivate func unbox(_ value: Any, as type: UInt32.Type) throws -> UInt32? {
        switch self.options.numberDecodingStrategy {
        case .strict:
            return value as? UInt32
        case .normal:
            return (value as? Int64).flatMap(UInt32.init(exactly:))
                ?? (value as? Double).flatMap(UInt32.init(exactly:))
        }
    }

    fileprivate func unbox(_ value: Any, as type: UInt64.Type) throws -> UInt64? {
        switch self.options.numberDecodingStrategy {
        case .strict:
            return value as? UInt64
        case .normal:
            return (value as? Int64).flatMap(UInt64.init(exactly:))
                ?? (value as? Double).flatMap(UInt64.init(exactly:))
        }
    }
}

fileprivate struct TOMLKeyedDecodingContainer<K : CodingKey> : KeyedDecodingContainerProtocol {
    typealias Key = K

    let codingPath: [CodingKey]

    private let decoder: TOMLDecoderImpl
    private let container: [String: Any]

    fileprivate init(referencing decoder: TOMLDecoderImpl, wrapping container: [String : Any]) {
        self.decoder = decoder
        switch decoder.options.keyDecodingStrategy {
        case .useDefaultKeys:
            self.container = container
        case .convertFromSnakeCase:
            // Convert the snake case keys in the container to camel case.
            // If we hit a duplicate key after conversion, then we'll use the first one we saw. Effectively an undefined behavior with JSON dictionaries.
            self.container = Dictionary(
                container.map { (TOMLDecoder.KeyDecodingStrategy.snakeCasify($0.key), $0.value) },
                uniquingKeysWith: { (first, _) in first }
            )
        case .custom(let converter):
            self.container = Dictionary(
                container.map {
                    (converter(decoder.codingPath + [TOMLKey(stringValue: $0.key, intValue: nil)]).stringValue, $0.value) },
                uniquingKeysWith: { (first, _) in first }
            )
        }
        self.codingPath = decoder.codingPath
    }

    var allKeys: [K] {
        return self.container.keys.compactMap { Key(stringValue: $0) }
    }

    func contains(_ key: K) -> Bool {
        return self.container[key.stringValue] != nil
    }

    func decodeNil(forKey key: K) throws -> Bool {
        return false
    }

    func decode(_ type: Bool.Type, forKey key: K) throws -> Bool {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(key)."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: Bool.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    func decode(_ type: String.Type, forKey key: K) throws -> String {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(key)."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: String.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    func decode(_ type: Double.Type, forKey key: K) throws -> Double {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(key)."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: Double.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    func decode(_ type: Float.Type, forKey key: K) throws -> Float {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(key)."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: Float.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    func decode(_ type: Int.Type, forKey key: K) throws -> Int {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(key)."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: Int.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    func decode(_ type: Int8.Type, forKey key: K) throws -> Int8 {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(key)."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: Int8.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    func decode(_ type: Int16.Type, forKey key: K) throws -> Int16 {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(key)."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: Int16.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    func decode(_ type: Int32.Type, forKey key: K) throws -> Int32 {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(key)."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: Int32.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    func decode(_ type: Int64.Type, forKey key: K) throws -> Int64 {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(key)."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: Int64.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    func decode(_ type: UInt.Type, forKey key: K) throws -> UInt {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(key)."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: UInt.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    func decode(_ type: UInt8.Type, forKey key: K) throws -> UInt8 {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(key)."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: UInt8.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    func decode(_ type: UInt16.Type, forKey key: K) throws -> UInt16 {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(key)."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: UInt16.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    func decode(_ type: UInt32.Type, forKey key: K) throws -> UInt32 {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(key)."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: UInt32.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    func decode(_ type: UInt64.Type, forKey key: K) throws -> UInt64 {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(key)."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: UInt64.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    func decode<T>(_ type: T.Type, forKey key: K) throws -> T where T : Decodable {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(key)."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: type) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: K) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key,
                                            DecodingError.Context(codingPath: self.codingPath,
                                                                  debugDescription: "Cannot get \(KeyedDecodingContainer<NestedKey>.self) -- no value found for key \(key)"))
        }

        guard let dictionary = value as? [String : Any] else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: [String : Any].self, reality: value)
        }

        let container = TOMLKeyedDecodingContainer<NestedKey>(referencing: self.decoder, wrapping: dictionary)
        return KeyedDecodingContainer(container)
    }

    func nestedUnkeyedContainer(forKey key: K) throws -> UnkeyedDecodingContainer {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key,
                                            DecodingError.Context(codingPath: self.codingPath,
                                                                  debugDescription: "Cannot get UnkeyedDecodingContainer -- no value found for key \(key)"))
        }

        guard let array = value as? [Any] else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: [Any].self, reality: value)
        }

        return TOMLUnkeyedDecodingContainer(referencing: self.decoder, wrapping: array)
    }

    private func _superDecoder(forKey key: CodingKey) throws -> Decoder {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        let value: Any = self.container[key.stringValue]! // ?? NSNull() TODO: huh?
        return TOMLDecoderImpl(referencing: value, at: self.decoder.codingPath, options: self.decoder.options)
    }


    func superDecoder() throws -> Decoder {
        return try self._superDecoder(forKey: TOMLKey.super)
    }

    func superDecoder(forKey key: K) throws -> Decoder {
        return try self._superDecoder(forKey: key)
    }
}

fileprivate struct TOMLUnkeyedDecodingContainer : UnkeyedDecodingContainer {
    private let decoder: TOMLDecoderImpl
    private let container: [Any]
    public private(set) var codingPath: [CodingKey]

    public var count: Int? {
        return self.container.count
    }

    public var isAtEnd: Bool {
        return self.currentIndex >= self.count!
    }

    public private(set) var currentIndex: Int

    fileprivate init(referencing decoder: TOMLDecoderImpl, wrapping container: [Any]) {
        self.decoder = decoder
        self.container = container
        self.codingPath = decoder.codingPath
        self.currentIndex = 0
    }

    mutating func decodeNil() throws -> Bool {
        return false
    }

    mutating func decode(_ type: Bool.Type) throws -> Bool {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [TOMLKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(TOMLKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: Bool.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [TOMLKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    mutating func decode(_ type: String.Type) throws -> String {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [TOMLKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(TOMLKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: String.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [TOMLKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    mutating func decode(_ type: Double.Type) throws -> Double {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [TOMLKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(TOMLKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: Double.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [TOMLKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    mutating func decode(_ type: Float.Type) throws -> Float {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [TOMLKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(TOMLKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: Float.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [TOMLKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    mutating func decode(_ type: Int.Type) throws -> Int {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [TOMLKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(TOMLKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: Int.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [TOMLKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    mutating func decode(_ type: Int8.Type) throws -> Int8 {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [TOMLKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(TOMLKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: Int8.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [TOMLKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    mutating func decode(_ type: Int16.Type) throws -> Int16 {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [TOMLKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(TOMLKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: Int16.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [TOMLKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    mutating func decode(_ type: Int32.Type) throws -> Int32 {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [TOMLKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(TOMLKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: Int32.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [TOMLKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    mutating func decode(_ type: Int64.Type) throws -> Int64 {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [TOMLKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(TOMLKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: Int64.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [TOMLKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    mutating func decode(_ type: UInt.Type) throws -> UInt {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [TOMLKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(TOMLKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: UInt.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [TOMLKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    mutating func decode(_ type: UInt8.Type) throws -> UInt8 {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [TOMLKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(TOMLKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: UInt8.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [TOMLKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    mutating func decode(_ type: UInt16.Type) throws -> UInt16 {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [TOMLKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(TOMLKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: UInt16.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [TOMLKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    mutating func decode(_ type: UInt32.Type) throws -> UInt32 {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [TOMLKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(TOMLKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: UInt32.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [TOMLKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    mutating func decode(_ type: UInt64.Type) throws -> UInt64 {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [TOMLKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(TOMLKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: UInt64.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [TOMLKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    mutating func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [TOMLKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(TOMLKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: type) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [TOMLKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        self.decoder.codingPath.append(TOMLKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(KeyedDecodingContainer<NestedKey>.self,
                                              DecodingError.Context(codingPath: self.codingPath,
                                                                    debugDescription: "Cannot get nested keyed container -- unkeyed container is at end."))
        }

        let value = self.container[self.currentIndex]
        guard let dictionary = value as? [String : Any] else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: [String : Any].self, reality: value)
        }

        self.currentIndex += 1
        let container = TOMLKeyedDecodingContainer<NestedKey>(referencing: self.decoder, wrapping: dictionary)
        return KeyedDecodingContainer(container)
    }

    mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        self.decoder.codingPath.append(TOMLKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(UnkeyedDecodingContainer.self,
                                              DecodingError.Context(codingPath: self.codingPath,
                                                                    debugDescription: "Cannot get nested keyed container -- unkeyed container is at end."))
        }

        let value = self.container[self.currentIndex]
        guard let array = value as? [Any] else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: [Any].self, reality: value)
        }

        self.currentIndex += 1
        return TOMLUnkeyedDecodingContainer(referencing: self.decoder, wrapping: array)
    }

    mutating func superDecoder() throws -> Decoder {
        self.decoder.codingPath.append(TOMLKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(Decoder.self,
                                              DecodingError.Context(codingPath: self.codingPath,
                                                                    debugDescription: "Cannot get superDecoder() -- unkeyed container is at end."))
        }

        let value = self.container[self.currentIndex]
        self.currentIndex += 1
        return TOMLDecoderImpl(referencing: value, at: self.decoder.codingPath, options: self.decoder.options)
    }

}

extension TOMLDecoderImpl: SingleValueDecodingContainer {
    func decodeNil() -> Bool {
        return false
    }

    func decode(_ type: Bool.Type) throws -> Bool {
        return try self.unbox(self.storage.topContainer, as: Bool.self)!
    }

    func decode(_ type: String.Type) throws -> String {
        return try self.unbox(self.storage.topContainer, as: String.self)!
    }

    func decode(_ type: Double.Type) throws -> Double {
        return try self.unbox(self.storage.topContainer, as: Double.self)!
    }

    func decode(_ type: Float.Type) throws -> Float {
        return try self.unbox(self.storage.topContainer, as: Float.self)!
    }

    func decode(_ type: Int.Type) throws -> Int {
        return try self.unbox(self.storage.topContainer, as: Int.self)!
    }

    func decode(_ type: Int8.Type) throws -> Int8 {
        return try self.unbox(self.storage.topContainer, as: Int8.self)!
    }

    func decode(_ type: Int16.Type) throws -> Int16 {
        return try self.unbox(self.storage.topContainer, as: Int16.self)!
    }

    func decode(_ type: Int32.Type) throws -> Int32 {
        return try self.unbox(self.storage.topContainer, as: Int32.self)!
    }

    func decode(_ type: Int64.Type) throws -> Int64 {
        return try self.unbox(self.storage.topContainer, as: Int64.self)!
    }

    func decode(_ type: UInt.Type) throws -> UInt {
        return try self.unbox(self.storage.topContainer, as: UInt.self)!
    }

    func decode(_ type: UInt8.Type) throws -> UInt8 {
        return try self.unbox(self.storage.topContainer, as: UInt8.self)!
    }

    func decode(_ type: UInt16.Type) throws -> UInt16 {
        return try self.unbox(self.storage.topContainer, as: UInt16.self)!
    }

    func decode(_ type: UInt32.Type) throws -> UInt32 {
        return try self.unbox(self.storage.topContainer, as: UInt32.self)!
    }

    func decode(_ type: UInt64.Type) throws -> UInt64 {
        return try self.unbox(self.storage.topContainer, as: UInt64.self)!
    }

    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        return try self.unbox(self.storage.topContainer, as: type)!
    }
}

fileprivate struct TOMLDecodingStorage {
    // MARK: Properties

    /// The container stack.
    /// Elements may be any one of the JSON types (NSNull, NSNumber, String, Array, [String : Any]).
    private(set) fileprivate var containers: [Any] = []

    // MARK: - Initialization

    /// Initializes `self` with no containers.
    fileprivate init() {}

    // MARK: - Modifying the Stack

    fileprivate var count: Int {
        return self.containers.count
    }

    fileprivate var topContainer: Any {
        precondition(!self.containers.isEmpty, "Empty container stack.")
        return self.containers.last!
    }

    fileprivate mutating func push(container: Any) {
        self.containers.append(container)
    }

    fileprivate mutating func popContainer() {
        precondition(!self.containers.isEmpty, "Empty container stack.")
        self.containers.removeLast()
    }
}

fileprivate struct TOMLKey : CodingKey {
    public var stringValue: String
    public var intValue: Int?

    public init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    public init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }

    public init(stringValue: String, intValue: Int?) {
        self.stringValue = stringValue
        self.intValue = intValue
    }

    fileprivate init(index: Int) {
        self.stringValue = "Index \(index)"
        self.intValue = index
    }

    fileprivate static let `super` = TOMLKey(stringValue: "super")!
}


extension TOMLDecoder.KeyDecodingStrategy {
    fileprivate static func snakeCasify(_ stringKey: String) -> String {
        guard !stringKey.isEmpty else { return stringKey }

        // Find the first non-underscore character
        guard let firstNonUnderscore = stringKey.firstIndex(where: { $0 != "_" }) else {
            // Reached the end without finding an _
            return stringKey
        }

        // Find the last non-underscore character
        var lastNonUnderscore = stringKey.index(before: stringKey.endIndex)
        while lastNonUnderscore > firstNonUnderscore && stringKey[lastNonUnderscore] == "_" {
            stringKey.formIndex(before: &lastNonUnderscore)
        }

        let keyRange = firstNonUnderscore...lastNonUnderscore
        let leadingUnderscoreRange = stringKey.startIndex..<firstNonUnderscore
        let trailingUnderscoreRange = stringKey.index(after: lastNonUnderscore)..<stringKey.endIndex

        var components = stringKey[keyRange].split(separator: "_")
        let joinedString : String
        if components.count == 1 {
            // No underscores in key, leave the word as is - maybe already camel cased
            joinedString = String(stringKey[keyRange])
        } else {
            joinedString = ([components[0].lowercased()] + components[1...].map { $0.capitalized }).joined()
        }

        // Do a cheap isEmpty check before creating and appending potentially empty strings
        let result : String
        if (leadingUnderscoreRange.isEmpty && trailingUnderscoreRange.isEmpty) {
            result = joinedString
        } else if (!leadingUnderscoreRange.isEmpty && !trailingUnderscoreRange.isEmpty) {
            // Both leading and trailing underscores
            result = String(stringKey[leadingUnderscoreRange]) + joinedString + String(stringKey[trailingUnderscoreRange])
        } else if (!leadingUnderscoreRange.isEmpty) {
            // Just leading
            result = String(stringKey[leadingUnderscoreRange]) + joinedString
        } else {
            // Just trailing
            result = joinedString + String(stringKey[trailingUnderscoreRange])
        }
        return result
    }
}
