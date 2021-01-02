import Foundation
import NetTime

final class TOMLDecoderImpl: Decoder {
    var storage: TOMLDecodingStorage
    var codingPath: [CodingKey]
    var options: TOMLDecoder.Options
    var userInfo: [CodingUserInfoKey : Any] {
        return self.options.userInfo
    }

    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        guard let table = self.storage.topContainer as? [String: Any] else {
            throw DecodingError.valueNotFound(KeyedDecodingContainer<Key>.self,
                                              DecodingError.Context(codingPath: self.codingPath,
                                                                    debugDescription: "Cannot get keyed decoding container -- found null value instead."))
        }

        return KeyedDecodingContainer(TOMLKeyedDecodingContainer(referencing: self, wrapping: table))
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        guard let array = self.storage.topContainer as? [Any] else {
            throw DecodingError.valueNotFound(UnkeyedDecodingContainer.self,
                                              DecodingError.Context(codingPath: self.codingPath,
                                                                    debugDescription: "Cannot get unkeyed decoding container -- found null value instead."))
        }

        return TOMLUnkeyedDecodingContainer(referencing: self, wrapping: array)
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        return self
    }

    init(referencing container: Any, at codingPath: [CodingKey] = [], options: TOMLDecoder.Options) {
        self.storage = TOMLDecodingStorage()
        self.storage.push(container: container)
        self.codingPath = codingPath
        self.options = options
    }
}

extension TOMLDecoderImpl {
    func unbox<T : Decodable>(_ value: Any, as type: T.Type) throws -> T? {
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
        } else if type == NSNumber.self {
            return try self.unbox(value, as: NSNumber.self) as? T
        }

        self.storage.push(container: value)
        defer { self.storage.popContainer() }
        return try type.init(from: self)
    }

    func unbox(_ value: Any, as type: NSNumber.Type) throws -> NSNumber? {
        if self.options.numberDecodingStrategy == .lenient {
            if let integer = value as? Int64 {
                return NSNumber(value: integer)
            } else if let float = value as? Double {
                return NSNumber(value: float)
            }
        }

        throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
    }

    func unbox(_ value: Any, as type: Data.Type) throws -> Data? {
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

    func unbox(_ value: Any, as type: DateComponents.Type) throws -> DateComponents? {
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

    func unbox(_ value: Any, as type: Date.Type) throws -> Date? {
        guard let datetime = value as? DateTime else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: DateTime.self, reality: value)
        }

        return Date(timeIntervalSinceReferenceDate: datetime.timeIntervalSince2001)
    }

    func unbox(_ value: Any, as type: Bool.Type) throws -> Bool? {
        return value as? Bool
    }

    func unbox(_ value: Any, as type: String.Type) throws -> String? {
        return value as? String
    }

    func unbox(_ value: Any, as type: Double.Type) throws -> Double? {
        switch self.options.numberDecodingStrategy {
        case .strict:
            return value as? Double
        case .lenient:
            return (value as? Double) ?? (value as? Int64).flatMap(Double.init(exactly:))
        }
    }

    func unbox(_ value: Any, as type: Float.Type) throws -> Float? {
        switch self.options.numberDecodingStrategy {
        case .strict:
            return value as? Float
        case .lenient:
            return (value as? Double).flatMap(Float.init(exactly:))
                ?? (value as? Int64).flatMap(Float.init(exactly:))
        }
    }

    func unbox(_ value: Any, as type: Int.Type) throws -> Int? {
        switch self.options.numberDecodingStrategy {
        case .strict:
            return value as? Int
        case .lenient:
            return (value as? Int64).flatMap(Int.init(exactly:))
                ?? (value as? Double).flatMap(Int.init(exactly:))
        }
    }

    func unbox(_ value: Any, as type: Int8.Type) throws -> Int8? {
        switch self.options.numberDecodingStrategy {
        case .strict:
            return value as? Int8
        case .lenient:
            return (value as? Int64).flatMap(Int8.init(exactly:))
                ?? (value as? Double).flatMap(Int8.init(exactly:))
        }
    }

    func unbox(_ value: Any, as type: Int16.Type) throws -> Int16? {
        switch self.options.numberDecodingStrategy {
        case .strict:
            return value as? Int16
        case .lenient:
            return (value as? Int64).flatMap(Int16.init(exactly:))
                ?? (value as? Double).flatMap(Int16.init(exactly:))
        }
    }

    func unbox(_ value: Any, as type: Int32.Type) throws -> Int32? {
        switch self.options.numberDecodingStrategy {
        case .strict:
            return value as? Int32
        case .lenient:
            return (value as? Int64).flatMap(Int32.init(exactly:))
                ?? (value as? Double).flatMap(Int32.init(exactly:))
        }
    }

    func unbox(_ value: Any, as type: Int64.Type) throws -> Int64? {
        switch self.options.numberDecodingStrategy {
        case .strict:
            return value as? Int64
        case .lenient:
            return (value as? Int64) ?? (value as? Double).flatMap(Int64.init(exactly:))
        }
    }

    func unbox(_ value: Any, as type: UInt.Type) throws -> UInt? {
        switch self.options.numberDecodingStrategy {
        case .strict:
            return value as? UInt
        case .lenient:
            return (value as? Int64).flatMap(UInt.init(exactly:))
                ?? (value as? Double).flatMap(UInt.init(exactly:))
        }
    }

    func unbox(_ value: Any, as type: UInt8.Type) throws -> UInt8? {
        switch self.options.numberDecodingStrategy {
        case .strict:
            return value as? UInt8
        case .lenient:
            return (value as? Int64).flatMap(UInt8.init(exactly:))
                ?? (value as? Double).flatMap(UInt8.init(exactly:))
        }
    }

    func unbox(_ value: Any, as type: UInt16.Type) throws -> UInt16? {
        switch self.options.numberDecodingStrategy {
        case .strict:
            return value as? UInt16
        case .lenient:
            return (value as? Int64).flatMap(UInt16.init(exactly:))
                ?? (value as? Double).flatMap(UInt16.init(exactly:))
        }
    }

    func unbox(_ value: Any, as type: UInt32.Type) throws -> UInt32? {
        switch self.options.numberDecodingStrategy {
        case .strict:
            return value as? UInt32
        case .lenient:
            return (value as? Int64).flatMap(UInt32.init(exactly:))
                ?? (value as? Double).flatMap(UInt32.init(exactly:))
        }
    }

    func unbox(_ value: Any, as type: UInt64.Type) throws -> UInt64? {
        switch self.options.numberDecodingStrategy {
        case .strict:
            return value as? UInt64
        case .lenient:
            return (value as? Int64).flatMap(UInt64.init(exactly:))
                ?? (value as? Double).flatMap(UInt64.init(exactly:))
        }
    }
}

extension TOMLDecoderImpl: SingleValueDecodingContainer {
    func decodeNil() -> Bool {
        return false
    }

    func decode(_ type: Bool.Type) throws -> Bool {
        guard let value = try self.unbox(self.storage.topContainer, as: type) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath,
                                                                         debugDescription: "Expected \(type) but found null instead."))
        }

        return value
    }

    func decode(_ type: String.Type) throws -> String {
        guard let value = try self.unbox(self.storage.topContainer, as: type) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath,
                                                                         debugDescription: "Expected \(type) but found null instead."))
        }

        return value
    }

    func decode(_ type: Double.Type) throws -> Double {
        guard let value = try self.unbox(self.storage.topContainer, as: type) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath,
                                                                         debugDescription: "Expected \(type) but found null instead."))
        }
        return value
    }

    func decode(_ type: Float.Type) throws -> Float {
        guard let value = try self.unbox(self.storage.topContainer, as: type) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath,
                                                                         debugDescription: "Expected \(type) but found null instead."))
        }
        return value
    }

    func decode(_ type: Int.Type) throws -> Int {
        guard let value = try self.unbox(self.storage.topContainer, as: type) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath,
                                                                         debugDescription: "Expected \(type) but found null instead."))
        }
        return value
    }

    func decode(_ type: Int8.Type) throws -> Int8 {
        guard let value = try self.unbox(self.storage.topContainer, as: type) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath,
                                                                         debugDescription: "Expected \(type) but found null instead."))
        }
        return value
    }

    func decode(_ type: Int16.Type) throws -> Int16 {
        guard let value = try self.unbox(self.storage.topContainer, as: type) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath,
                                                                         debugDescription: "Expected \(type) but found null instead."))
        }
        return value
    }

    func decode(_ type: Int32.Type) throws -> Int32 {
        guard let value = try self.unbox(self.storage.topContainer, as: type) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath,
                                                                         debugDescription: "Expected \(type) but found null instead."))
        }
        return value
    }

    func decode(_ type: Int64.Type) throws -> Int64 {
        guard let value = try self.unbox(self.storage.topContainer, as: type) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath,
                                                                         debugDescription: "Expected \(type) but found null instead."))
        }
        return value
    }

    func decode(_ type: UInt.Type) throws -> UInt {
        guard let value = try self.unbox(self.storage.topContainer, as: type) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath,
                                                                         debugDescription: "Expected \(type) but found null instead."))
        }
        return value
    }

    func decode(_ type: UInt8.Type) throws -> UInt8 {
        guard let value = try self.unbox(self.storage.topContainer, as: type) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath,
                                                                         debugDescription: "Expected \(type) but found null instead."))
        }
        return value
    }

    func decode(_ type: UInt16.Type) throws -> UInt16 {
        guard let value = try self.unbox(self.storage.topContainer, as: type) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath,
                                                                         debugDescription: "Expected \(type) but found null instead."))
        }
        return value
    }

    func decode(_ type: UInt32.Type) throws -> UInt32 {
       guard let value = try self.unbox(self.storage.topContainer, as: type) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath,
                                                                         debugDescription: "Expected \(type) but found null instead."))
        }
        return value
    }

    func decode(_ type: UInt64.Type) throws -> UInt64 {
        guard let value = try self.unbox(self.storage.topContainer, as: type) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath,
                                                                         debugDescription: "Expected \(type) but found null instead."))
        }
        return value
    }

    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        guard let value = try self.unbox(self.storage.topContainer, as: type) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath,
                                                                         debugDescription: "Expected \(type) but found null instead."))
        }
        return value
    }
}
