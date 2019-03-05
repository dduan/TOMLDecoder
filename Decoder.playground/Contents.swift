public final class TOMLDecoder {
    public init() {}
    public func decode<T : Decodable, Bytes>(_ type: T.Type, from data: Bytes) throws -> T
        where Bytes: Collection, Bytes.Element == UInt8
    {
        let topLevel = ["a": Int64(42)]
        let decoder = TOMLDecoderImpl(referencing: self)
        guard let value = try decoder.unbox(topLevel, as: type) else {
            throw "Bad"
        }

        return value
    }
}

extension String: Error {}

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

    fileprivate func unbox<T : Decodable>(_ value: Any, as type: T.Type) throws -> T? {
        return nil
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
        fatalError()
    }

    func decodeNil(forKey key: K) throws -> Bool {
        fatalError()
    }

    func decode(_ type: Bool.Type, forKey key: K) throws -> Bool {
        fatalError()
    }

    func decode(_ type: String.Type, forKey key: K) throws -> String {
        fatalError()
    }

    func decode(_ type: Double.Type, forKey key: K) throws -> Double {
        fatalError()
    }

    func decode(_ type: Float.Type, forKey key: K) throws -> Float {
        fatalError()
    }

    func decode(_ type: Int.Type, forKey key: K) throws -> Int {
        fatalError()
    }

    func decode(_ type: Int8.Type, forKey key: K) throws -> Int8 {
        fatalError()
    }

    func decode(_ type: Int16.Type, forKey key: K) throws -> Int16 {
        fatalError()
    }

    func decode(_ type: Int32.Type, forKey key: K) throws -> Int32 {
        fatalError()
    }

    func decode(_ type: Int64.Type, forKey key: K) throws -> Int64 {
        fatalError()
    }

    func decode(_ type: UInt.Type, forKey key: K) throws -> UInt {
        fatalError()
    }

    func decode(_ type: UInt8.Type, forKey key: K) throws -> UInt8 {
        fatalError()
    }

    func decode(_ type: UInt16.Type, forKey key: K) throws -> UInt16 {
        fatalError()
    }

    func decode(_ type: UInt32.Type, forKey key: K) throws -> UInt32 {
        fatalError()
    }

    func decode(_ type: UInt64.Type, forKey key: K) throws -> UInt64 {
        fatalError()
    }

    func decode<T>(_ type: T.Type, forKey key: K) throws -> T where T : Decodable {
        fatalError()
    }

    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: K) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        fatalError()
    }

    func nestedUnkeyedContainer(forKey key: K) throws -> UnkeyedDecodingContainer {
        fatalError()
    }

    func superDecoder() throws -> Decoder {
        fatalError()
    }

    func superDecoder(forKey key: K) throws -> Decoder {
        fatalError()
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
        fatalError()
    }

    mutating func decode(_ type: Bool.Type) throws -> Bool {
        fatalError()
    }

    mutating func decode(_ type: String.Type) throws -> String {
        fatalError()
    }

    mutating func decode(_ type: Double.Type) throws -> Double {
        fatalError()
    }

    mutating func decode(_ type: Float.Type) throws -> Float {
        fatalError()
    }

    mutating func decode(_ type: Int.Type) throws -> Int {
        fatalError()
    }

    mutating func decode(_ type: Int8.Type) throws -> Int8 {
        fatalError()
    }

    mutating func decode(_ type: Int16.Type) throws -> Int16 {
        fatalError()
    }

    mutating func decode(_ type: Int32.Type) throws -> Int32 {
        fatalError()
    }

    mutating func decode(_ type: Int64.Type) throws -> Int64 {
        fatalError()
    }

    mutating func decode(_ type: UInt.Type) throws -> UInt {
        fatalError()
    }

    mutating func decode(_ type: UInt8.Type) throws -> UInt8 {
        fatalError()
    }

    mutating func decode(_ type: UInt16.Type) throws -> UInt16 {
        fatalError()
    }

    mutating func decode(_ type: UInt32.Type) throws -> UInt32 {
        fatalError()
    }

    mutating func decode(_ type: UInt64.Type) throws -> UInt64 {
        fatalError()
    }

    mutating func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        fatalError()
    }

    mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        fatalError()
    }

    mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        fatalError()
    }

    mutating func superDecoder() throws -> Decoder {
        fatalError()
    }

}

extension TOMLDecoderImpl: SingleValueDecodingContainer {
    func decodeNil() -> Bool {
        fatalError()
    }

    func decode(_ type: Bool.Type) throws -> Bool {
        fatalError()
    }

    func decode(_ type: String.Type) throws -> String {
        fatalError()
    }

    func decode(_ type: Double.Type) throws -> Double {
        fatalError()
    }

    func decode(_ type: Float.Type) throws -> Float {
        fatalError()
    }

    func decode(_ type: Int.Type) throws -> Int {
        fatalError()
    }

    func decode(_ type: Int8.Type) throws -> Int8 {
        fatalError()
    }

    func decode(_ type: Int16.Type) throws -> Int16 {
        fatalError()
    }

    func decode(_ type: Int32.Type) throws -> Int32 {
        fatalError()
    }

    func decode(_ type: Int64.Type) throws -> Int64 {
        fatalError()
    }

    func decode(_ type: UInt.Type) throws -> UInt {
        fatalError()
    }

    func decode(_ type: UInt8.Type) throws -> UInt8 {
        fatalError()
    }

    func decode(_ type: UInt16.Type) throws -> UInt16 {
        fatalError()
    }

    func decode(_ type: UInt32.Type) throws -> UInt32 {
        fatalError()
    }

    func decode(_ type: UInt64.Type) throws -> UInt64 {
        fatalError()
    }

    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        fatalError()
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
