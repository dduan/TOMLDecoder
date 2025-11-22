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

    func decode(_: Double.Type, forKey key: Key) throws -> Double {
        do {
            return try table.float(forKey: key.stringValue)
        } catch let floatError {
            do {
                let offsetDateTime = try decode(OffsetDateTime.self, forKey: key)
                return try Double(from: offsetDateTime, strategy: decoder.strategy.offsetDateTime)
            } catch let error as DecodingError {
                throw error
            } catch {
                throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "\(floatError)", underlyingError: floatError))
            }
        }
    }

    func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
        if !decoder.isLenient {
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "Use Double or lenient decoding strategy.",
            ))
        }
        do {
            return try Float(decode(Double.self, forKey: key))
        } catch {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "\(error)", underlyingError: error))
        }
    }

    func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        if !decoder.isLenient {
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "Use Int64 or lenient decoding strategy.",
            ))
        }

        do {
            let integer = try decode(Int64.self, forKey: key)
            guard let result = Int(exactly: integer) else {
                throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath + [key], debugDescription: "\(integer) cannot be represented by type Int."))
            }
            return result
        } catch {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "\(error)", underlyingError: error))
        }
    }

    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
        if !decoder.isLenient {
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "Use Int64 or lenient decoding strategy.",
            ))
        }

        do {
            let integer = try decode(Int64.self, forKey: key)
            guard let result = Int8(exactly: integer) else {
                throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath + [key], debugDescription: "\(integer) cannot be represented by type Int."))
            }
            return result
        } catch {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "\(error)", underlyingError: error))
        }
    }

    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
        if !decoder.isLenient {
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "Use Int64 or lenient decoding strategy.",
            ))
        }

        do {
            let integer = try decode(Int64.self, forKey: key)
            guard let result = Int16(exactly: integer) else {
                throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath + [key], debugDescription: "\(integer) cannot be represented by type Int."))
            }
            return result
        } catch {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "\(error)", underlyingError: error))
        }
    }

    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
        if !decoder.isLenient {
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "Use Int64 or lenient decoding strategy.",
            ))
        }

        do {
            let integer = try decode(Int64.self, forKey: key)
            guard let result = Int32(exactly: integer) else {
                throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath + [key], debugDescription: "\(integer) cannot be represented by type Int."))
            }
            return result
        } catch {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "\(error)", underlyingError: error))
        }
    }

    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
        if !decoder.isLenient {
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "Use Int64 or lenient decoding strategy.",
            ))
        }

        do {
            let integer = try decode(Int64.self, forKey: key)
            guard let result = UInt(exactly: integer) else {
                throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath + [key], debugDescription: "\(integer) cannot be represented by type Int."))
            }
            return result
        } catch {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "\(error)", underlyingError: error))
        }
    }

    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
        if !decoder.isLenient {
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "Use Int64 or lenient decoding strategy.",
            ))
        }

        do {
            let integer = try decode(Int64.self, forKey: key)
            guard let result = UInt8(exactly: integer) else {
                throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath + [key], debugDescription: "\(integer) cannot be represented by type Int."))
            }
            return result
        } catch {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "\(error)", underlyingError: error))
        }
    }

    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
        if !decoder.isLenient {
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "Use Int64 or lenient decoding strategy.",
            ))
        }

        do {
            let integer = try decode(Int64.self, forKey: key)
            guard let result = UInt16(exactly: integer) else {
                throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath + [key], debugDescription: "\(integer) cannot be represented by type Int."))
            }
            return result
        } catch {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "\(error)", underlyingError: error))
        }
    }

    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
        if !decoder.isLenient {
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "Use Int64 or lenient decoding strategy.",
            ))
        }

        do {
            let integer = try decode(Int64.self, forKey: key)
            guard let result = UInt32(exactly: integer) else {
                throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath + [key], debugDescription: "\(integer) cannot be represented by type Int."))
            }
            return result
        } catch {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "\(error)", underlyingError: error))
        }
    }

    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
        if !decoder.isLenient {
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "Use Int64 or lenient decoding strategy.",
            ))
        }

        do {
            let integer = try decode(Int64.self, forKey: key)
            guard let result = UInt64(exactly: integer) else {
                throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath + [key], debugDescription: "\(integer) cannot be represented by type Int."))
            }
            return result
        } catch {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "\(error)", underlyingError: error))
        }
    }

    func decode(_: Int64.Type, forKey key: Key) throws -> Int64 {
        do {
            return try table.integer(forKey: key.stringValue)
        } catch {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "\(error)", underlyingError: error))
        }
    }

    func decode(_: String.Type, forKey key: Key) throws -> String {
        do {
            return try table.string(forKey: key.stringValue)
        } catch {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "\(error)", underlyingError: error))
        }
    }

    func decode(_: Bool.Type, forKey key: Key) throws -> Bool {
        do {
            return try table.bool(forKey: key.stringValue)
        } catch {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "\(error)", underlyingError: error))
        }
    }

    func decode(_: OffsetDateTime.Type, forKey key: Key) throws -> OffsetDateTime {
        do {
            return try table.offsetDateTime(forKey: key.stringValue)
        } catch {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "\(error)", underlyingError: error))
        }
    }

    func decode(_: LocalDateTime.Type, forKey key: Key) throws -> LocalDateTime {
        do {
            return try table.localDateTime(forKey: key.stringValue)
        } catch {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "\(error)", underlyingError: error))
        }
    }

    func decode(_: LocalDate.Type, forKey key: Key) throws -> LocalDate {
        do {
            return try table.localDate(forKey: key.stringValue)
        } catch {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "\(error)", underlyingError: error))
        }
    }

    func decode(_: LocalTime.Type, forKey key: Key) throws -> LocalTime {
        do {
            return try table.localTime(forKey: key.stringValue)
        } catch {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "\(error)", underlyingError: error))
        }
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

    func decode(_: Date.Type, forKey key: Key) throws -> Date {
        if !decoder.isLenient {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "No date associated with key \(key). Use lenient decoding strategy."))
        }

        switch decoder.strategy.offsetDateTime {
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
                throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "\(error)", underlyingError: error))
            }
        case let .dateFromCalendar(identifier):
            do {
                let offsetDateTime = try decode(OffsetDateTime.self, forKey: key)
                return Date(offsetDateTime: offsetDateTime, calendar: Calendar(identifier: identifier))
            } catch {
                throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "\(error)", underlyingError: error))
            }
        case .dateFromProlepticGregorianCalendar:
            do {
                let offsetDateTime = try decode(OffsetDateTime.self, forKey: key)
                return Date(timeIntervalSinceReferenceDate: offsetDateTime.timeIntervalSince2001)
            } catch {
                throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "\(error)", underlyingError: error))
            }
        }
    }

    func decode(_: DateComponents.Type, forKey key: Key) throws -> DateComponents {
        if !decoder.isLenient {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "No date components associated with key \(key)."))
        }

        let datetimeComponents = try table.datetimeComponents(forKey: key.stringValue)
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
        } else if type == TOMLArray.self {
            return try decode(TOMLArray.self, forKey: key) as! T
        } else if type == TOMLTable.self {
            return try decode(TOMLTable.self, forKey: key) as! T
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

        guard let token = table.token(forKey: key.stringValue) else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "No value associated with key \(key)."))
        }

        var decoder = _TOMLDecoder(referencing: .keyed(table), at: codingPath + [TOMLKey(stringValue: key.stringValue)], strategy: decoder.strategy, isLenient: decoder.isLenient)
        decoder.userInfo[.init(rawValue: "token")!] = token
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
