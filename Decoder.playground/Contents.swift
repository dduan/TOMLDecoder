public final class TOMLDecoder {
    public init() {}
    public func decode<T : Decodable, Bytes>(_ type: T.Type, from data: Bytes) throws -> T
        where Bytes: Collection, Bytes.Element == UInt8
    {
        let topLevel: [String: Any] = ["a": Int64(42), "b": UInt16(0), "c": "a c"]
        let decoder = TOMLDecoderImpl(referencing: self)
        guard let value = try decoder.unbox(topLevel, as: type) else {
            throw "Bad"
        }

        return value
    }

    // TODO: delete. This is for debug only.
    public func decode<T : Decodable>(_ type: T.Type, from topLevel: [String: Any]) throws -> T {
        let decoder = TOMLDecoderImpl(referencing: self)
        guard let value = try decoder.unbox(topLevel, as: type) else {
            throw "Bad"
        }

        return value
    }
}

extension String: Error {}

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
    var userInfo: [CodingUserInfoKey : Any] = [:]

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

    fileprivate init(referencing container: Any, at codingPath: [CodingKey] = []) {
        self.storage = TOMLDecodingStorage()
        self.storage.push(container: container)
        self.codingPath = codingPath
    }
}

extension TOMLDecoderImpl {
    fileprivate func unbox<T : Decodable>(_ value: Any, as type: T.Type) throws -> T? {
        self.storage.push(container: value)
        defer { self.storage.popContainer() }
        return try type.init(from: self)
    }

    fileprivate func unbox(_ value: Any, as type: Bool.Type) throws -> Bool? {
        return value as? Bool
    }

    fileprivate func unbox(_ value: Any, as type: String.Type) throws -> String? {
        return value as? String
    }

    fileprivate func unbox(_ value: Any, as type: Double.Type) throws -> Double? {
        return value as? Double
    }

    fileprivate func unbox(_ value: Any, as type: Float.Type) throws -> Float? {
        return value as? Float
    }

    fileprivate func unbox(_ value: Any, as type: Int.Type) throws -> Int? {
        return value as? Int
    }

    fileprivate func unbox(_ value: Any, as type: Int8.Type) throws -> Int8? {
        return value as? Int8
    }

    fileprivate func unbox(_ value: Any, as type: Int16.Type) throws -> Int16? {
        return value as? Int16
    }

    fileprivate func unbox(_ value: Any, as type: Int32.Type) throws -> Int32? {
        return value as? Int32
    }

    fileprivate func unbox(_ value: Any, as type: Int64.Type) throws -> Int64? {
        return value as? Int64
    }

    fileprivate func unbox(_ value: Any, as type: UInt.Type) throws -> UInt? {
        return value as? UInt
    }

    fileprivate func unbox(_ value: Any, as type: UInt8.Type) throws -> UInt8? {
        return value as? UInt8
    }

    fileprivate func unbox(_ value: Any, as type: UInt16.Type) throws -> UInt16? {
        return value as? UInt16
    }

    fileprivate func unbox(_ value: Any, as type: UInt32.Type) throws -> UInt32? {
        return value as? UInt32
    }

    fileprivate func unbox(_ value: Any, as type: UInt64.Type) throws -> UInt64? {
        return value as? UInt64
    }
}

fileprivate struct TOMLKeyedDecodingContainer<K : CodingKey> : KeyedDecodingContainerProtocol {
    typealias Key = K

    let codingPath: [CodingKey]

    private let decoder: TOMLDecoderImpl
    private let container: [String: Any]

    fileprivate init(referencing decoder: TOMLDecoderImpl, wrapping container: [String : Any]) {
        self.decoder = decoder
        self.container = container
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
        return TOMLDecoderImpl(referencing: value, at: self.decoder.codingPath)
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
        return TOMLDecoderImpl(referencing: value, at: self.decoder.codingPath)
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

struct MyValue: Codable {
    let a: Int64
    let b: UInt16
    let c: [String]
}

struct X: Codable {
    let value: MyValue
}

dump(
    try TOMLDecoder()
        .decode(
            X.self,
            from: ["value": ["a": Int64(42), "b": UInt16(0), "c": ["a c", "d c"]]]
    )
)
