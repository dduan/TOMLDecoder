//  WARNING: This file is generated from TOMLKeyedDecodingContainer.swift.gyb
//  Do not edit TOMLKeyedDecodingContainer.swift directly.

import Foundation

struct TOMLKeyedDecodingContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
    private let decoder: _TOMLDecoder
    private let table: TOMLTable

    var codingPath: [CodingKey] {
        decoder.codingPath
    }

    init(referencing decoder: _TOMLDecoder, wrapping table: TOMLTable) {
        self.decoder = decoder
        self.table = table
    }

    var allKeys: [Key] {
        table.keys.compactMap { Key(stringValue: $0) }
    }

    func contains(_ key: Key) -> Bool {
        table.contains(key: key.stringValue)
    }

    func decodeNil(forKey _: Key) throws -> Bool {
        false
    }

    func decode(_: TOMLArray.Type, forKey key: Key) throws -> TOMLArray {
        do {
            return try table.array(forKey: key.stringValue)
        } catch {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "\(error)", underlyingError: error))
        }
    }

    func decode(_: TOMLTable.Type, forKey key: Key) throws -> TOMLTable {
        do {
            return try table.table(forKey: key.stringValue)
        } catch {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "\(error)", underlyingError: error))
        }
    }

    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T: Decodable {
        if type == TOMLArray.self {
            return try decode(TOMLArray.self, forKey: key) as! T
        } else if type == TOMLTable.self {
            return try decode(TOMLTable.self, forKey: key) as! T
        }

        // For complex types, we need to create a nested decoder
        var nestedCodingPath = codingPath
        nestedCodingPath.append(key)

        // Try to get the nested value
        if table.contains(key: key.stringValue) {
            // Check if it's an array or table
            if let nestedArray = try? table.array(forKey: key.stringValue) {
                let nestedDecoder = _TOMLDecoder(referencing: .unkeyed(nestedArray), at: nestedCodingPath, strategy: decoder.strategy, isLenient: decoder.isLenient)
                return try T(from: nestedDecoder)
            } else if let nestedTable = try? table.table(forKey: key.stringValue) {
                let nestedDecoder = _TOMLDecoder(referencing: .keyed(nestedTable), at: nestedCodingPath, strategy: decoder.strategy, isLenient: decoder.isLenient)
                return try T(from: nestedDecoder)
            }
        }

        guard let token = try? table.token(forKey: key.stringValue, expected: String(describing: T.self)) else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "No value associated with key \(key)."))
        }

        var decoder = _TOMLDecoder(referencing: .keyed(table), at: codingPath + [TOMLKey(stringValue: key.stringValue)], strategy: decoder.strategy, isLenient: decoder.isLenient)
        decoder.token = token
        // have to intercept these here otherwise Foundation will try to decode it as a float
        if type == Date.self {
            return try decoder.decode(Date.self) as! T
        } else if type == DateComponents.self {
            return try decoder.decode(DateComponents.self) as! T
        }

        return try T(from: decoder)
    }

    func nestedContainer<NestedKey>(keyedBy _: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
        do {
            let nestedTable = try table.table(forKey: key.stringValue)
            var nestedCodingPath = codingPath
            nestedCodingPath.append(key)
            let nestedDecoder = _TOMLDecoder(referencing: .keyed(nestedTable), at: nestedCodingPath, strategy: decoder.strategy, isLenient: decoder.isLenient)

            let container = TOMLKeyedDecodingContainer<NestedKey>(referencing: nestedDecoder, wrapping: nestedTable)
            return KeyedDecodingContainer(container)
        } catch {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "\(error)", underlyingError: error))
        }
    }

    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        do {
            let nestedArray = try table.array(forKey: key.stringValue)
            var nestedCodingPath = codingPath
            nestedCodingPath.append(key)
            let nestedDecoder = _TOMLDecoder(referencing: .unkeyed(nestedArray), at: nestedCodingPath, strategy: decoder.strategy, isLenient: decoder.isLenient)

            return TOMLUnkeyedDecodingContainer(referencing: nestedDecoder, wrapping: nestedArray)
        } catch {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "\(error)", underlyingError: error))
        }
    }

    func _superDecoder(forKey key: CodingKey) -> Decoder {
        _TOMLDecoder(referencing: .keyed(table), at: codingPath + [key], strategy: decoder.strategy, isLenient: decoder.isLenient)
    }

    func superDecoder() throws -> Decoder {
        _superDecoder(forKey: TOMLKey.super)
    }

    func superDecoder(forKey key: Key) throws -> Decoder {
        _superDecoder(forKey: key)
    }
}
