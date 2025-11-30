//  WARNING: This file is generated from TOMLUnkeyedDecodingContainer.swift.gyb
//  Do not edit TOMLUnkeyedDecodingContainer.swift directly.
import Foundation

struct TOMLUnkeyedDecodingContainer: UnkeyedDecodingContainer {
    private let decoder: _TOMLDecoder
    private let array: TOMLArray

    /// The path of coding keys taken to get to this point in decoding.
    var codingPath: [CodingKey] {
        decoder.codingPath
    }

    /// The index of the element we're about to decode.
    private(set) var currentIndex: Int

    // MARK: - UnkeyedDecodingContainer Methods

    var count: Int? {
        array.count
    }

    var isAtEnd: Bool {
        currentIndex >= count!
    }

    init(referencing decoder: _TOMLDecoder, wrapping array: TOMLArray) {
        self.decoder = decoder
        self.array = array
        currentIndex = 0
    }

    mutating func decodeNil() throws -> Bool {
        false
    }

    mutating func decode(_ type: TOMLArray.Type) throws -> TOMLArray {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath + [TOMLKey(intValue: currentIndex)], debugDescription: "Unkeyed container is at end."))
        }
        do {
            let decoded = try array.array(atIndex: currentIndex)
            currentIndex += 1
            return decoded
        } catch {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath + [TOMLKey(intValue: currentIndex)], debugDescription: "\(error)", underlyingError: error))
        }
    }

    mutating func decode(_ type: TOMLTable.Type) throws -> TOMLTable {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath + [TOMLKey(intValue: currentIndex)], debugDescription: "Unkeyed container is at end."))
        }
        do {
            let decoded = try array.table(atIndex: currentIndex)
            currentIndex += 1
            return decoded
        } catch {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath + [TOMLKey(intValue: currentIndex)], debugDescription: "\(error)", underlyingError: error))
        }
    }

    mutating func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        if type == TOMLArray.self {
            return try decode(TOMLArray.self) as! T
        } else if type == TOMLTable.self {
            return try decode(TOMLTable.self) as! T
        }

        var nestedCodingPath = codingPath
        nestedCodingPath.append(TOMLKey(intValue: currentIndex))

        defer { currentIndex += 1 }

        // Try to get nested table or array
        if let nestedTable = try? array.table(atIndex: currentIndex) {
            let nestedDecoder = _TOMLDecoder(referencing: .keyed(nestedTable), at: nestedCodingPath, strategy: decoder.strategy, isLenient: decoder.isLenient)
            let decoded = try T(from: nestedDecoder)
            return decoded
        } else if let nestedArray = try? array.array(atIndex: currentIndex) {
            let nestedDecoder = _TOMLDecoder(referencing: .unkeyed(nestedArray), at: nestedCodingPath, strategy: decoder.strategy, isLenient: decoder.isLenient)
            let decoded = try T(from: nestedDecoder)
            return decoded
        }

        let token = try array.token(forIndex: currentIndex, type: String(describing: T.self))
        decoder.codingPath.append(TOMLKey(intValue: currentIndex))
        defer {
            decoder.codingPath.removeLast()
        }
        decoder.token = token

        // have to intercept these here otherwise Foundation will try to decode it as a float
        if type == Date.self {
            return try decoder.decode(Date.self) as! T
        } else if type == DateComponents.self {
            return try decoder.decode(DateComponents.self) as! T
        }

        return try T(from: decoder)
    }

    mutating func nestedContainer<NestedKey>(keyedBy _: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(
                KeyedDecodingContainer<NestedKey>.self,
                DecodingError.Context(
                    codingPath: codingPath + [TOMLKey(intValue: currentIndex)],
                    debugDescription: "Unkeyed container is at end.",
                ),
            )
        }

        guard let nestedTable = try? array.table(atIndex: currentIndex) else {
            throw DecodingError.typeMismatch(
                KeyedDecodingContainer<NestedKey>.self,
                DecodingError.Context(
                    codingPath: codingPath + [TOMLKey(intValue: currentIndex)],
                    debugDescription: "Element is not a table.",
                ),
            )
        }

        var nestedCodingPath = codingPath
        nestedCodingPath.append(TOMLKey(intValue: currentIndex))
        let nestedDecoder = _TOMLDecoder(referencing: .keyed(nestedTable), at: nestedCodingPath, strategy: decoder.strategy, isLenient: decoder.isLenient)

        currentIndex += 1
        let container = TOMLKeyedDecodingContainer<NestedKey>(referencing: nestedDecoder, wrapping: nestedTable)
        return KeyedDecodingContainer(container)
    }

    mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(
                UnkeyedDecodingContainer.self,
                DecodingError.Context(
                    codingPath: codingPath + [TOMLKey(intValue: currentIndex)],
                    debugDescription: "Cannot get nested unkeyed container -- unkeyed container is at end.",
                ),
            )
        }

        guard let nestedArray = try? array.array(atIndex: currentIndex) else {
            throw DecodingError.typeMismatch(
                UnkeyedDecodingContainer.self,
                DecodingError.Context(
                    codingPath: codingPath + [TOMLKey(intValue: currentIndex)],
                    debugDescription: "Cannot get nested unkeyed container -- element is not an array.",
                ),
            )
        }

        var nestedCodingPath = codingPath
        nestedCodingPath.append(TOMLKey(intValue: currentIndex))
        let nestedDecoder = _TOMLDecoder(referencing: .unkeyed(nestedArray), at: nestedCodingPath, strategy: decoder.strategy, isLenient: decoder.isLenient)

        currentIndex += 1
        return TOMLUnkeyedDecodingContainer(referencing: nestedDecoder, wrapping: nestedArray)
    }

    mutating func superDecoder() throws -> Decoder {
        _TOMLDecoder(referencing: .unkeyed(array), at: codingPath + [TOMLKey.super], strategy: decoder.strategy, isLenient: decoder.isLenient)
    }
}
