//  WARNING: This file is generated from TOMLUnkeyedDecodingContainer.swift.gyb
//  Do not edit TOMLUnkeyedDecodingContainer.swift directly.
import Foundation

struct TOMLUnkeyedDecodingContainer: UnkeyedDecodingContainer {
    private let decoder: _TOMLDecoder
    private let array: TOMLArray

    /// The path of coding keys taken to get to this point in decoding.
    var codingPath: [CodingKey] {
        self.decoder.codingPath
    }

    /// The index of the element we're about to decode.
    private(set) var currentIndex: Int

    // MARK: - UnkeyedDecodingContainer Methods

    var count: Int? {
        return self.array.count
    }

    var isAtEnd: Bool {
        return self.currentIndex >= self.count!
    }

    init(referencing decoder: _TOMLDecoder, wrapping array: TOMLArray) {
        self.decoder = decoder
        self.array = array
        self.currentIndex = 0
    }

    mutating func decodeNil() throws -> Bool {
        return false
    }

    mutating func decode(_ type: Double.Type) throws -> Double {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath + [TOMLKey(intValue: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        do {
            let decoded = try self.array.float(atIndex: self.currentIndex)
            self.currentIndex += 1
            return decoded
        } catch {
            do {
                let offsetDateTime = try decode(OffsetDateTime.self)
                return try TimeInterval(from: offsetDateTime, strategy: self.decoder.strategy.offsetDateTime)
            } catch let error as DecodingError {
                throw error
            } catch {
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath + [TOMLKey(intValue: self.currentIndex)], debugDescription: "No float found at index \(self.currentIndex)."))
            }
        }
    }

   mutating func decode(_ type: Float.Type) throws -> Float {
       if !self.decoder.isLenient {
           throw DecodingError.typeMismatch(type, DecodingError.Context(
               codingPath: self.codingPath + [TOMLKey(intValue: self.currentIndex)],
               debugDescription: "Use Double or lenient number decoding strategy."
           ))
       }
       do {
            return Float(try decode(Double.self))
        } catch {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath + [TOMLKey(intValue: self.currentIndex)], debugDescription: "\(error)", underlyingError: error))
        }
   }

    mutating func decode(_ type: Int.Type) throws -> Int {
        let index = currentIndex - 1
        if !self.decoder.isLenient {
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: self.codingPath + [TOMLKey(intValue: index)],
                debugDescription: "Use Int64 or lenient number decoding strategy."
            ))
        }

        let integer = try decode(Int64.self)
        do {
            guard let result = Int(exactly: integer) else {
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath + [TOMLKey(intValue: index)], debugDescription: "Failed to convert integer \(integer) to Int."))
            }
            return result
        } catch {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath + [TOMLKey(intValue: index)], debugDescription: "Failed to convert integer \(integer) to \(type).", underlyingError: error))
        }
    }
    mutating func decode(_ type: Int8.Type) throws -> Int8 {
        let index = currentIndex - 1
        if !self.decoder.isLenient {
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: self.codingPath + [TOMLKey(intValue: index)],
                debugDescription: "Use Int64 or lenient number decoding strategy."
            ))
        }

        let integer = try decode(Int64.self)
        do {
            guard let result = Int8(exactly: integer) else {
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath + [TOMLKey(intValue: index)], debugDescription: "Failed to convert integer \(integer) to Int8."))
            }
            return result
        } catch {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath + [TOMLKey(intValue: index)], debugDescription: "Failed to convert integer \(integer) to \(type).", underlyingError: error))
        }
    }
    mutating func decode(_ type: Int16.Type) throws -> Int16 {
        let index = currentIndex - 1
        if !self.decoder.isLenient {
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: self.codingPath + [TOMLKey(intValue: index)],
                debugDescription: "Use Int64 or lenient number decoding strategy."
            ))
        }

        let integer = try decode(Int64.self)
        do {
            guard let result = Int16(exactly: integer) else {
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath + [TOMLKey(intValue: index)], debugDescription: "Failed to convert integer \(integer) to Int16."))
            }
            return result
        } catch {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath + [TOMLKey(intValue: index)], debugDescription: "Failed to convert integer \(integer) to \(type).", underlyingError: error))
        }
    }
    mutating func decode(_ type: Int32.Type) throws -> Int32 {
        let index = currentIndex - 1
        if !self.decoder.isLenient {
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: self.codingPath + [TOMLKey(intValue: index)],
                debugDescription: "Use Int64 or lenient number decoding strategy."
            ))
        }

        let integer = try decode(Int64.self)
        do {
            guard let result = Int32(exactly: integer) else {
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath + [TOMLKey(intValue: index)], debugDescription: "Failed to convert integer \(integer) to Int32."))
            }
            return result
        } catch {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath + [TOMLKey(intValue: index)], debugDescription: "Failed to convert integer \(integer) to \(type).", underlyingError: error))
        }
    }
    mutating func decode(_ type: UInt.Type) throws -> UInt {
        let index = currentIndex - 1
        if !self.decoder.isLenient {
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: self.codingPath + [TOMLKey(intValue: index)],
                debugDescription: "Use Int64 or lenient number decoding strategy."
            ))
        }

        let integer = try decode(Int64.self)
        do {
            guard let result = UInt(exactly: integer) else {
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath + [TOMLKey(intValue: index)], debugDescription: "Failed to convert integer \(integer) to UInt."))
            }
            return result
        } catch {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath + [TOMLKey(intValue: index)], debugDescription: "Failed to convert integer \(integer) to \(type).", underlyingError: error))
        }
    }
    mutating func decode(_ type: UInt8.Type) throws -> UInt8 {
        let index = currentIndex - 1
        if !self.decoder.isLenient {
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: self.codingPath + [TOMLKey(intValue: index)],
                debugDescription: "Use Int64 or lenient number decoding strategy."
            ))
        }

        let integer = try decode(Int64.self)
        do {
            guard let result = UInt8(exactly: integer) else {
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath + [TOMLKey(intValue: index)], debugDescription: "Failed to convert integer \(integer) to UInt8."))
            }
            return result
        } catch {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath + [TOMLKey(intValue: index)], debugDescription: "Failed to convert integer \(integer) to \(type).", underlyingError: error))
        }
    }
    mutating func decode(_ type: UInt16.Type) throws -> UInt16 {
        let index = currentIndex - 1
        if !self.decoder.isLenient {
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: self.codingPath + [TOMLKey(intValue: index)],
                debugDescription: "Use Int64 or lenient number decoding strategy."
            ))
        }

        let integer = try decode(Int64.self)
        do {
            guard let result = UInt16(exactly: integer) else {
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath + [TOMLKey(intValue: index)], debugDescription: "Failed to convert integer \(integer) to UInt16."))
            }
            return result
        } catch {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath + [TOMLKey(intValue: index)], debugDescription: "Failed to convert integer \(integer) to \(type).", underlyingError: error))
        }
    }
    mutating func decode(_ type: UInt32.Type) throws -> UInt32 {
        let index = currentIndex - 1
        if !self.decoder.isLenient {
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: self.codingPath + [TOMLKey(intValue: index)],
                debugDescription: "Use Int64 or lenient number decoding strategy."
            ))
        }

        let integer = try decode(Int64.self)
        do {
            guard let result = UInt32(exactly: integer) else {
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath + [TOMLKey(intValue: index)], debugDescription: "Failed to convert integer \(integer) to UInt32."))
            }
            return result
        } catch {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath + [TOMLKey(intValue: index)], debugDescription: "Failed to convert integer \(integer) to \(type).", underlyingError: error))
        }
    }
    mutating func decode(_ type: UInt64.Type) throws -> UInt64 {
        let index = currentIndex - 1
        if !self.decoder.isLenient {
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: self.codingPath + [TOMLKey(intValue: index)],
                debugDescription: "Use Int64 or lenient number decoding strategy."
            ))
        }

        let integer = try decode(Int64.self)
        do {
            guard let result = UInt64(exactly: integer) else {
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath + [TOMLKey(intValue: index)], debugDescription: "Failed to convert integer \(integer) to UInt64."))
            }
            return result
        } catch {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath + [TOMLKey(intValue: index)], debugDescription: "Failed to convert integer \(integer) to \(type).", underlyingError: error))
        }
    }

    mutating func decode(_ type: Int64.Type) throws -> Int64 {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath + [TOMLKey(intValue: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }
        do {
            let decoded = try self.array.integer(atIndex: self.currentIndex)
            self.currentIndex += 1
            return decoded
        } catch {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath + [TOMLKey(intValue: self.currentIndex)], debugDescription: "\(error)", underlyingError: error))
        }
    }
    mutating func decode(_ type: OffsetDateTime.Type) throws -> OffsetDateTime {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath + [TOMLKey(intValue: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }
        do {
            let decoded = try self.array.offsetDateTime(atIndex: self.currentIndex)
            self.currentIndex += 1
            return decoded
        } catch {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath + [TOMLKey(intValue: self.currentIndex)], debugDescription: "\(error)", underlyingError: error))
        }
    }
    mutating func decode(_ type: LocalDateTime.Type) throws -> LocalDateTime {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath + [TOMLKey(intValue: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }
        do {
            let decoded = try self.array.localDateTime(atIndex: self.currentIndex)
            self.currentIndex += 1
            return decoded
        } catch {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath + [TOMLKey(intValue: self.currentIndex)], debugDescription: "\(error)", underlyingError: error))
        }
    }
    mutating func decode(_ type: LocalDate.Type) throws -> LocalDate {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath + [TOMLKey(intValue: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }
        do {
            let decoded = try self.array.localDate(atIndex: self.currentIndex)
            self.currentIndex += 1
            return decoded
        } catch {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath + [TOMLKey(intValue: self.currentIndex)], debugDescription: "\(error)", underlyingError: error))
        }
    }
    mutating func decode(_ type: LocalTime.Type) throws -> LocalTime {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath + [TOMLKey(intValue: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }
        do {
            let decoded = try self.array.localTime(atIndex: self.currentIndex)
            self.currentIndex += 1
            return decoded
        } catch {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath + [TOMLKey(intValue: self.currentIndex)], debugDescription: "\(error)", underlyingError: error))
        }
    }
    mutating func decode(_ type: String.Type) throws -> String {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath + [TOMLKey(intValue: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }
        do {
            let decoded = try self.array.string(atIndex: self.currentIndex)
            self.currentIndex += 1
            return decoded
        } catch {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath + [TOMLKey(intValue: self.currentIndex)], debugDescription: "\(error)", underlyingError: error))
        }
    }
    mutating func decode(_ type: Bool.Type) throws -> Bool {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath + [TOMLKey(intValue: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }
        do {
            let decoded = try self.array.bool(atIndex: self.currentIndex)
            self.currentIndex += 1
            return decoded
        } catch {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath + [TOMLKey(intValue: self.currentIndex)], debugDescription: "\(error)", underlyingError: error))
        }
    }

    mutating func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath + [TOMLKey(intValue: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        var nestedCodingPath = self.codingPath
        nestedCodingPath.append(TOMLKey(intValue: self.currentIndex))

        if type == Int64.self {
            return try decode(Int64.self) as! T
        } else if type == OffsetDateTime.self {
            return try decode(OffsetDateTime.self) as! T
        } else if type == LocalDateTime.self {
            return try decode(LocalDateTime.self) as! T
        } else if type == LocalDate.self {
            return try decode(LocalDate.self) as! T
        } else if type == LocalTime.self {
            return try decode(LocalTime.self) as! T
        } else if type == String.self {
            return try decode(String.self) as! T
        } else if type == Bool.self {
            return try decode(Bool.self) as! T
        } else if type == Int.self {
            return try decode(Int.self) as! T
        } else if type == Int8.self {
            return try decode(Int8.self) as! T
        } else if type == Int16.self {
            return try decode(Int16.self) as! T
        } else if type == Int32.self {
            return try decode(Int32.self) as! T
        } else if type == UInt.self {
            return try decode(UInt.self) as! T
        } else if type == UInt8.self {
            return try decode(UInt8.self) as! T
        } else if type == UInt16.self {
            return try decode(UInt16.self) as! T
        } else if type == UInt32.self {
            return try decode(UInt32.self) as! T
        } else if type == UInt64.self {
            return try decode(UInt64.self) as! T
        } else if type == Date.self {
            return try decode(Date.self) as! T
        } else if type == Float.self {
            return try decode(Float.self) as! T
        } else if type == Double.self {
            return try decode(Double.self) as! T
        }

        // Try to get nested table or array
        if let nestedTable = try? self.array.table(atIndex: self.currentIndex) {
            let nestedDecoder = _TOMLDecoder(referencing: .keyed(nestedTable), at: nestedCodingPath, strategy: self.decoder.strategy, isLenient: self.decoder.isLenient)
            let decoded = try T(from: nestedDecoder)
            self.currentIndex += 1
            return decoded
        } else if let nestedArray = try? self.array.array(atIndex: self.currentIndex) {
            let nestedDecoder = _TOMLDecoder(referencing: .unkeyed(nestedArray), at: nestedCodingPath, strategy: self.decoder.strategy, isLenient: self.decoder.isLenient)
            let decoded = try T(from: nestedDecoder)
            self.currentIndex += 1
            return decoded
        } else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath + [TOMLKey(intValue: self.currentIndex)], debugDescription: "Expected \(type) but found unsupported type instead."))
        }
    }

    mutating func decode(_ type: Date.Type) throws -> Date {
        if !self.decoder.isLenient {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath + [TOMLKey(intValue: self.currentIndex)], debugDescription: "No date found at index \(self.currentIndex)."))
        }

        switch self.decoder.strategy.offsetDateTime {
        case .intervalSince1970:
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath + [TOMLKey(intValue: self.currentIndex)], debugDescription: "No date found at index \(self.currentIndex)."))
        case .intervalSince2001:
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath + [TOMLKey(intValue: self.currentIndex)], debugDescription: "No date found at index \(self.currentIndex)."))
        case .dateFromGregorianCalendar:
            do {
                let offsetDateTime = try decode(OffsetDateTime.self)
                return Date(offsetDateTime: offsetDateTime, calendar: Calendar(identifier: .gregorian))
            } catch {
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath + [TOMLKey(intValue: self.currentIndex)], debugDescription: "No date found at index \(self.currentIndex)."))
            }
        case .dateFromCalendar(let identifier):
            do {
                let offsetDateTime = try decode(OffsetDateTime.self)
                return Date(offsetDateTime: offsetDateTime, calendar: Calendar(identifier: identifier))
            } catch {
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath + [TOMLKey(intValue: self.currentIndex)], debugDescription: "No date found at index \(self.currentIndex)."))
            }
        case .dateFromProlepticGregorianCalendar:
            do {
                let offsetDateTime = try decode(OffsetDateTime.self)
                return Date(timeIntervalSinceReferenceDate: offsetDateTime.timeIntervalSince2001)
            } catch {
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath + [TOMLKey(intValue: self.currentIndex)], debugDescription: "No date found at index \(self.currentIndex)."))
            }
        }
    }

    mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(
                KeyedDecodingContainer<NestedKey>.self,
                DecodingError.Context(
                    codingPath: self.codingPath + [TOMLKey(intValue: self.currentIndex)],
                    debugDescription: "Unkeyed container is at end."
                )
            )
        }

        guard let nestedTable = try? self.array.table(atIndex: self.currentIndex) else {
            throw DecodingError.typeMismatch(
                KeyedDecodingContainer<NestedKey>.self,
                DecodingError.Context(
                    codingPath: self.codingPath + [TOMLKey(intValue: self.currentIndex)],
                    debugDescription: "Element is not a table."
                )
            )
        }

        var nestedCodingPath = self.codingPath
        nestedCodingPath.append(TOMLKey(intValue: self.currentIndex))
        let nestedDecoder = _TOMLDecoder(referencing: .keyed(nestedTable), at: nestedCodingPath, strategy: self.decoder.strategy, isLenient: self.decoder.isLenient)

        self.currentIndex += 1
        let container = TOMLKeyedDecodingContainer<NestedKey>(referencing: nestedDecoder, wrapping: nestedTable)
        return KeyedDecodingContainer(container)
    }

    mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(
                UnkeyedDecodingContainer.self,
                DecodingError.Context(codingPath: self.codingPath + [TOMLKey(intValue: self.currentIndex)],
                                      debugDescription: "Cannot get nested unkeyed container -- unkeyed container is at end."))
        }

        guard let nestedArray = try? self.array.array(atIndex: self.currentIndex) else {
            throw DecodingError.typeMismatch(UnkeyedDecodingContainer.self,
                                           DecodingError.Context(codingPath: self.codingPath + [TOMLKey(intValue: self.currentIndex)],
                                                               debugDescription: "Cannot get nested unkeyed container -- element is not an array."))
        }

        var nestedCodingPath = self.codingPath
        nestedCodingPath.append(TOMLKey(intValue: self.currentIndex))
        let nestedDecoder = _TOMLDecoder(referencing: .unkeyed(nestedArray), at: nestedCodingPath, strategy: self.decoder.strategy, isLenient: self.decoder.isLenient)

        self.currentIndex += 1
        return TOMLUnkeyedDecodingContainer(referencing: nestedDecoder, wrapping: nestedArray)
    }

    mutating func superDecoder() throws -> Decoder {
        _TOMLDecoder(referencing: .unkeyed(array), at: codingPath + [TOMLKey.super], strategy: self.decoder.strategy, isLenient: self.decoder.isLenient)
    }
}
