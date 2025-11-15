//  WARNING: This file is generated from TOMLKeyedDecodingContainer.swift.gyb
//  Do not edit TOMLKeyedDecodingContainer.swift directly.

import Foundation

struct TOMLKeyedDecodingContainer<Key: CodingKey> : KeyedDecodingContainerProtocol {
    private let decoder: _TOMLDecoder
    private let table: TOMLTable

    var codingPath: [CodingKey] {
        self.decoder.codingPath
    }

    init(referencing decoder: _TOMLDecoder, wrapping table: TOMLTable) {
        self.decoder = decoder
        self.table = table
    }

    var allKeys: [Key] {
        self.table.allKeys.compactMap { Key(stringValue: $0) }
    }

    func contains(_ key: Key) -> Bool {
        self.table.contains(key: key.stringValue)
    }

    func decodeNil(forKey key: Key) throws -> Bool {
        false
    }

    func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        do {
            return try self.table.float(forKey: key.stringValue)
        } catch let floatError {
            do {
                let offsetDateTime = try decode(OffsetDateTime.self, forKey: key)
                return try Double(from: offsetDateTime, strategy: self.decoder.strategy.offsetDateTime)
            } catch let error as DecodingError {
                throw error
            } catch {
                throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.codingPath, debugDescription: "\(floatError)", underlyingError: floatError))
            }
        }
    }

    func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
        if !self.decoder.isLenient {
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: self.codingPath + [key],
                debugDescription: "Use Double or lenient decoding strategy."
            ))
        }
        do {
            return Float(try decode(Double.self, forKey: key))
        } catch {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.codingPath, debugDescription: "\(error)", underlyingError: error))
        }
    }

    func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        if !self.decoder.isLenient {
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: self.codingPath + [key],
                debugDescription: "Use Int64 or lenient decoding strategy."
            ))
        }

        do {
            let integer = try decode(Int64.self, forKey: key)
            guard let result = Int(exactly: integer) else {
                throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath + [key], debugDescription: "\(integer) cannot be represented by type Int."))
            }
            return result
        } catch {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.codingPath, debugDescription: "\(error)", underlyingError: error))
        }
    }

    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
        if !self.decoder.isLenient {
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: self.codingPath + [key],
                debugDescription: "Use Int64 or lenient decoding strategy."
            ))
        }

        do {
            let integer = try decode(Int64.self, forKey: key)
            guard let result = Int8(exactly: integer) else {
                throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath + [key], debugDescription: "\(integer) cannot be represented by type Int."))
            }
            return result
        } catch {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.codingPath, debugDescription: "\(error)", underlyingError: error))
        }
    }

    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
        if !self.decoder.isLenient {
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: self.codingPath + [key],
                debugDescription: "Use Int64 or lenient decoding strategy."
            ))
        }

        do {
            let integer = try decode(Int64.self, forKey: key)
            guard let result = Int16(exactly: integer) else {
                throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath + [key], debugDescription: "\(integer) cannot be represented by type Int."))
            }
            return result
        } catch {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.codingPath, debugDescription: "\(error)", underlyingError: error))
        }
    }

    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
        if !self.decoder.isLenient {
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: self.codingPath + [key],
                debugDescription: "Use Int64 or lenient decoding strategy."
            ))
        }

        do {
            let integer = try decode(Int64.self, forKey: key)
            guard let result = Int32(exactly: integer) else {
                throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath + [key], debugDescription: "\(integer) cannot be represented by type Int."))
            }
            return result
        } catch {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.codingPath, debugDescription: "\(error)", underlyingError: error))
        }
    }

    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
        if !self.decoder.isLenient {
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: self.codingPath + [key],
                debugDescription: "Use Int64 or lenient decoding strategy."
            ))
        }

        do {
            let integer = try decode(Int64.self, forKey: key)
            guard let result = UInt(exactly: integer) else {
                throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath + [key], debugDescription: "\(integer) cannot be represented by type Int."))
            }
            return result
        } catch {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.codingPath, debugDescription: "\(error)", underlyingError: error))
        }
    }

    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
        if !self.decoder.isLenient {
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: self.codingPath + [key],
                debugDescription: "Use Int64 or lenient decoding strategy."
            ))
        }

        do {
            let integer = try decode(Int64.self, forKey: key)
            guard let result = UInt8(exactly: integer) else {
                throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath + [key], debugDescription: "\(integer) cannot be represented by type Int."))
            }
            return result
        } catch {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.codingPath, debugDescription: "\(error)", underlyingError: error))
        }
    }

    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
        if !self.decoder.isLenient {
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: self.codingPath + [key],
                debugDescription: "Use Int64 or lenient decoding strategy."
            ))
        }

        do {
            let integer = try decode(Int64.self, forKey: key)
            guard let result = UInt16(exactly: integer) else {
                throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath + [key], debugDescription: "\(integer) cannot be represented by type Int."))
            }
            return result
        } catch {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.codingPath, debugDescription: "\(error)", underlyingError: error))
        }
    }

    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
        if !self.decoder.isLenient {
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: self.codingPath + [key],
                debugDescription: "Use Int64 or lenient decoding strategy."
            ))
        }

        do {
            let integer = try decode(Int64.self, forKey: key)
            guard let result = UInt32(exactly: integer) else {
                throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath + [key], debugDescription: "\(integer) cannot be represented by type Int."))
            }
            return result
        } catch {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.codingPath, debugDescription: "\(error)", underlyingError: error))
        }
    }

    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
        if !self.decoder.isLenient {
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: self.codingPath + [key],
                debugDescription: "Use Int64 or lenient decoding strategy."
            ))
        }

        do {
            let integer = try decode(Int64.self, forKey: key)
            guard let result = UInt64(exactly: integer) else {
                throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath + [key], debugDescription: "\(integer) cannot be represented by type Int."))
            }
            return result
        } catch {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.codingPath, debugDescription: "\(error)", underlyingError: error))
        }
    }
    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
        do {
            return try self.table.integer(forKey: key.stringValue)
        } catch {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.codingPath, debugDescription: "\(error)", underlyingError: error))
        }
    }
    func decode(_ type: String.Type, forKey key: Key) throws -> String {
        do {
            return try self.table.string(forKey: key.stringValue)
        } catch {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.codingPath, debugDescription: "\(error)", underlyingError: error))
        }
    }
    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
        do {
            return try self.table.bool(forKey: key.stringValue)
        } catch {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.codingPath, debugDescription: "\(error)", underlyingError: error))
        }
    }
    func decode(_ type: OffsetDateTime.Type, forKey key: Key) throws -> OffsetDateTime {
        do {
            return try self.table.offsetDateTime(forKey: key.stringValue)
        } catch {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.codingPath, debugDescription: "\(error)", underlyingError: error))
        }
    }
    func decode(_ type: LocalDateTime.Type, forKey key: Key) throws -> LocalDateTime {
        do {
            return try self.table.localDateTime(forKey: key.stringValue)
        } catch {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.codingPath, debugDescription: "\(error)", underlyingError: error))
        }
    }
    func decode(_ type: LocalDate.Type, forKey key: Key) throws -> LocalDate {
        do {
            return try self.table.localDate(forKey: key.stringValue)
        } catch {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.codingPath, debugDescription: "\(error)", underlyingError: error))
        }
    }
    func decode(_ type: LocalTime.Type, forKey key: Key) throws -> LocalTime {
        do {
            return try self.table.localTime(forKey: key.stringValue)
        } catch {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.codingPath, debugDescription: "\(error)", underlyingError: error))
        }
    }

    func decode(_ type: Date.Type, forKey key: Key) throws -> Date {
        if !self.decoder.isLenient {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.codingPath, debugDescription: "No date associated with key \(key). Use lenient decoding strategy."))
        }

        switch self.decoder.strategy.offsetDateTime {
        case .intervalSince1970:
            let float = try decode(Double.self, forKey: key)
            return Date(timeIntervalSince1970: float)
        case .intervalSince2001:
            let float = try decode(Double.self, forKey: key)
            return Date(timeIntervalSinceReferenceDate: float)
        case .dateFromGregorianCalendar:
            do {
                let offsetDateTime = try decode(OffsetDateTime.self, forKey: key)
                return Date(offsetDateTime: offsetDateTime, calendar: Calendar(identifier: .gregorian))
            } catch {
                throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.codingPath, debugDescription: "\(error)", underlyingError: error))
            }
        case .dateFromCalendar(let identifier):
            do {
                let offsetDateTime = try decode(OffsetDateTime.self, forKey: key)
                return Date(offsetDateTime: offsetDateTime, calendar: Calendar(identifier: identifier))
            } catch {
                throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.codingPath, debugDescription: "\(error)", underlyingError: error))
            }
        case .dateFromProlepticGregorianCalendar:
            do {
                let offsetDateTime = try decode(OffsetDateTime.self, forKey: key)
                return Date(timeIntervalSinceReferenceDate: offsetDateTime.timeIntervalSince2001)
            } catch {
                throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.codingPath, debugDescription: "\(error)", underlyingError: error))
            }
        }
    }

    func decode(_ type: DateComponents.Type, forKey key: Key) throws -> DateComponents {
        if !self.decoder.isLenient {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.codingPath, debugDescription: "No date components associated with key \(key)."))
        }

        let datetimeComponents = try self.table.datetimeComponents(forKey: key.stringValue)
        var components = DateComponents()
        if let date = datetimeComponents.date {
            components.year = Int(date.year)
            components.month = Int(date.month)
            components.day = Int(date.day)
        }
        if let time = datetimeComponents.time {
            components.hour = Int(time.hour)
            components.minute = Int(time.minute)
            components.second = Int(time.second)
        }
        if let offset = datetimeComponents.offset {
            components.timeZone = TimeZone(secondsFromGMT: Int(offset) * 60)
        }
        return components
    }

    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T: Decodable {
        // Handle types that have direct support
        if type == Int64.self {
            return try decode(Int64.self, forKey: key) as! T
        } else if type == String.self {
            return try decode(String.self, forKey: key) as! T
        } else if type == Bool.self {
            return try decode(Bool.self, forKey: key) as! T
        } else if type == OffsetDateTime.self {
            return try decode(OffsetDateTime.self, forKey: key) as! T
        } else if type == LocalDateTime.self {
            return try decode(LocalDateTime.self, forKey: key) as! T
        } else if type == LocalDate.self {
            return try decode(LocalDate.self, forKey: key) as! T
        } else if type == LocalTime.self {
            return try decode(LocalTime.self, forKey: key) as! T
        } else if type == Int.self {
            return try decode(Int.self, forKey: key) as! T
        } else if type == Int8.self {
            return try decode(Int8.self, forKey: key) as! T
        } else if type == Int16.self {
            return try decode(Int16.self, forKey: key) as! T
        } else if type == Int32.self {
            return try decode(Int32.self, forKey: key) as! T
        } else if type == UInt.self {
            return try decode(UInt.self, forKey: key) as! T
        } else if type == UInt8.self {
            return try decode(UInt8.self, forKey: key) as! T
        } else if type == UInt16.self {
            return try decode(UInt16.self, forKey: key) as! T
        } else if type == UInt32.self {
            return try decode(UInt32.self, forKey: key) as! T
        } else if type == UInt64.self {
            return try decode(UInt64.self, forKey: key) as! T
        } else if type == Date.self {
            return try decode(Date.self, forKey: key) as! T
        } else if type == DateComponents.self {
            return try decode(DateComponents.self, forKey: key) as! T
        } else if type == Float.self {
            return try decode(Float.self, forKey: key) as! T
        } else if type == Double.self {
            return try decode(Double.self, forKey: key) as! T
        }

        // For complex types, we need to create a nested decoder
        var nestedCodingPath = self.codingPath
        nestedCodingPath.append(key)

        // Try to get the nested value
        if self.table.contains(key: key.stringValue) {
            // Check if it's an array or table
            if let nestedArray = try? self.table.array(forKey: key.stringValue) {
                let nestedDecoder = _TOMLDecoder(referencing: .unkeyed(nestedArray), at: nestedCodingPath, strategy: self.decoder.strategy, isLenient: self.decoder.isLenient)
                return try T(from: nestedDecoder)
            } else if let nestedTable = try? self.table.table(forKey: key.stringValue) {
                let nestedDecoder = _TOMLDecoder(referencing: .keyed(nestedTable), at: nestedCodingPath, strategy: self.decoder.strategy, isLenient: self.decoder.isLenient)
                return try T(from: nestedDecoder)
            }
        }

        throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.codingPath, debugDescription: "No value associated with key \(key)."))
    }

    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        do {
            let nestedTable = try self.table.table(forKey: key.stringValue)
            var nestedCodingPath = self.codingPath
            nestedCodingPath.append(key)
            let nestedDecoder = _TOMLDecoder(referencing: .keyed(nestedTable), at: nestedCodingPath, strategy: self.decoder.strategy, isLenient: self.decoder.isLenient)

            let container = TOMLKeyedDecodingContainer<NestedKey>(referencing: nestedDecoder, wrapping: nestedTable)
            return KeyedDecodingContainer(container)
        } catch {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.codingPath, debugDescription: "\(error)", underlyingError: error))
        }
    }

    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        do {
            let nestedArray = try self.table.array(forKey: key.stringValue)
            var nestedCodingPath = self.codingPath
            nestedCodingPath.append(key)
            let nestedDecoder = _TOMLDecoder(referencing: .unkeyed(nestedArray), at: nestedCodingPath, strategy: self.decoder.strategy, isLenient: self.decoder.isLenient)

            return TOMLUnkeyedDecodingContainer(referencing: nestedDecoder, wrapping: nestedArray)
        } catch {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.codingPath, debugDescription: "\(error)", underlyingError: error))
        }
    }

    private func _superDecoder(forKey key: CodingKey) throws -> Decoder {
        var nestedCodingPath = self.codingPath
        nestedCodingPath.append(key)

        if let nestedTable = try? self.table.table(forKey: key.stringValue) {
            return _TOMLDecoder(referencing: .keyed(nestedTable), at: nestedCodingPath, strategy: self.decoder.strategy, isLenient: self.decoder.isLenient)
        } else if let nestedArray = try? self.table.array(forKey: key.stringValue) {
            return _TOMLDecoder(referencing: .unkeyed(nestedArray), at: nestedCodingPath, strategy: self.decoder.strategy, isLenient: self.decoder.isLenient)
        } else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(
                codingPath: self.codingPath,
                debugDescription: "No value found for key \(key)"
            ))
        }
    }

    func superDecoder() throws -> Decoder {
        return try self._superDecoder(forKey: TOMLKey.super)
    }

    func superDecoder(forKey key: Key) throws -> Decoder {
        return try self._superDecoder(forKey: key)
    }
}
