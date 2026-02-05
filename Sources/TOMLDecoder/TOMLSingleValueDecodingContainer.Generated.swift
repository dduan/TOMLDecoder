//  WARNING: This file is generated from TOMLSingleValueDecodingContainer.swift.gyb
//  Do not edit TOMLSingleValueDecodingContainer.swift directly.

import Foundation

extension _TOMLDecoder: SingleValueDecodingContainer {
    var context: TOMLKey {
        codingPath.last as! TOMLKey
    }

    @inline(__always)
    func decode(_: Bool.Type) throws -> Bool {
        try token.unpackBool(source: source, context: context)
    }

    @inline(__always)
    func decode(_: String.Type) throws -> String {
        try token.unpackString(source: source, context: context)
    }

    @inline(__always)
    func decode(_: Int64.Type) throws -> Int64 {
        try token.unpackInteger(source: source, context: context)
    }

    @inline(__always)
    func decode(_ type: Int.Type) throws -> Int {
        if !isLenient {
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Use Int64 or lenient decoding strategy."
            ))
        }

        do {
            let integer = try decode(Int64.self)
            guard let result = Int(exactly: integer) else {
                throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(integer) cannot be represented by type Int."))
            }
            return result
        } catch {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(error)", underlyingError: error))
        }
    }

    @inline(__always)
    func decode(_ type: Int8.Type) throws -> Int8 {
        if !isLenient {
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Use Int64 or lenient decoding strategy."
            ))
        }

        do {
            let integer = try decode(Int64.self)
            guard let result = Int8(exactly: integer) else {
                throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(integer) cannot be represented by type Int."))
            }
            return result
        } catch {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(error)", underlyingError: error))
        }
    }

    @inline(__always)
    func decode(_ type: Int16.Type) throws -> Int16 {
        if !isLenient {
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Use Int64 or lenient decoding strategy."
            ))
        }

        do {
            let integer = try decode(Int64.self)
            guard let result = Int16(exactly: integer) else {
                throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(integer) cannot be represented by type Int."))
            }
            return result
        } catch {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(error)", underlyingError: error))
        }
    }

    @inline(__always)
    func decode(_ type: Int32.Type) throws -> Int32 {
        if !isLenient {
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Use Int64 or lenient decoding strategy."
            ))
        }

        do {
            let integer = try decode(Int64.self)
            guard let result = Int32(exactly: integer) else {
                throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(integer) cannot be represented by type Int."))
            }
            return result
        } catch {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(error)", underlyingError: error))
        }
    }

    @inline(__always)
    func decode(_ type: UInt.Type) throws -> UInt {
        if !isLenient {
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Use Int64 or lenient decoding strategy."
            ))
        }

        do {
            let integer = try decode(Int64.self)
            guard let result = UInt(exactly: integer) else {
                throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(integer) cannot be represented by type Int."))
            }
            return result
        } catch {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(error)", underlyingError: error))
        }
    }

    @inline(__always)
    func decode(_ type: UInt8.Type) throws -> UInt8 {
        if !isLenient {
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Use Int64 or lenient decoding strategy."
            ))
        }

        do {
            let integer = try decode(Int64.self)
            guard let result = UInt8(exactly: integer) else {
                throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(integer) cannot be represented by type Int."))
            }
            return result
        } catch {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(error)", underlyingError: error))
        }
    }

    @inline(__always)
    func decode(_ type: UInt16.Type) throws -> UInt16 {
        if !isLenient {
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Use Int64 or lenient decoding strategy."
            ))
        }

        do {
            let integer = try decode(Int64.self)
            guard let result = UInt16(exactly: integer) else {
                throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(integer) cannot be represented by type Int."))
            }
            return result
        } catch {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(error)", underlyingError: error))
        }
    }

    @inline(__always)
    func decode(_ type: UInt32.Type) throws -> UInt32 {
        if !isLenient {
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Use Int64 or lenient decoding strategy."
            ))
        }

        do {
            let integer = try decode(Int64.self)
            guard let result = UInt32(exactly: integer) else {
                throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(integer) cannot be represented by type Int."))
            }
            return result
        } catch {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(error)", underlyingError: error))
        }
    }

    @inline(__always)
    func decode(_ type: UInt64.Type) throws -> UInt64 {
        if !isLenient {
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Use Int64 or lenient decoding strategy."
            ))
        }

        do {
            let integer = try decode(Int64.self)
            guard let result = UInt64(exactly: integer) else {
                throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(integer) cannot be represented by type Int."))
            }
            return result
        } catch {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(error)", underlyingError: error))
        }
    }

    func decode(_ type: Double.Type) throws -> Double {
        do {
            return try token.unpackFloat(source: source, context: context)
        } catch let floatError {
            do {
                return try Double(from: decode(OffsetDateTime.self), strategy: strategy.timeInterval)
            } catch let error as DecodingError {
                throw error
            } catch {
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(floatError)", underlyingError: floatError))
            }
        }
    }

    func decode(_ type: Float.Type) throws -> Float {
        if !isLenient {
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Use Double or lenient decoding strategy."
            ))
        }
        do {
            return try Float(decode(Double.self))
        } catch {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(error)", underlyingError: error))
        }
    }

    @inline(__always)
    func decode<T: Decodable>(_ type: T.Type) throws -> T {
        if type == Bool.self {
            return try decode(Bool.self) as! T
        } else if type == String.self {
            return try decode(String.self) as! T
        } else if type == Int64.self {
            return try decode(Int64.self) as! T
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
        } else if type == Double.self {
            return try decode(Double.self) as! T
        } else if type == Float.self {
            return try decode(Float.self) as! T
        } else if type == LocalDate.self {
            return try decode(LocalDate.self) as! T
        } else if type == LocalDateTime.self {
            return try decode(LocalDateTime.self) as! T
        } else if type == LocalTime.self {
            return try decode(LocalTime.self) as! T
        } else if type == OffsetDateTime.self {
            return try decode(OffsetDateTime.self) as! T
        } else if type == Date.self {
            return try decode(Date.self) as! T
        } else if type == DateComponents.self {
            return try decode(DateComponents.self) as! T
        }
        throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Unsupported type \(type)"))
    }

    func decodeNil() -> Bool {
        false
    }
}

extension _TOMLDecoder {
    @inline(__always)
    func decode(_: LocalDate.Type) throws -> LocalDate {
        do {
            return try token.unpackLocalDate(source: source, context: context, exactMatch: !isLenient)
        } catch {
            throw DecodingError.valueNotFound(LocalDate.self, DecodingError.Context(codingPath: codingPath, debugDescription: "\(error)", underlyingError: error))
        }
    }

    @inline(__always)
    func decode(_: LocalDateTime.Type) throws -> LocalDateTime {
        do {
            return try token.unpackLocalDateTime(source: source, context: context, exactMatch: !isLenient)
        } catch {
            throw DecodingError.valueNotFound(LocalDateTime.self, DecodingError.Context(codingPath: codingPath, debugDescription: "\(error)", underlyingError: error))
        }
    }

    @inline(__always)
    func decode(_: LocalTime.Type) throws -> LocalTime {
        do {
            return try token.unpackLocalTime(source: source, context: context, exactMatch: !isLenient)
        } catch {
            throw DecodingError.valueNotFound(LocalTime.self, DecodingError.Context(codingPath: codingPath, debugDescription: "\(error)", underlyingError: error))
        }
    }

    @inline(__always)
    func decode(_: OffsetDateTime.Type) throws -> OffsetDateTime {
        do {
            return try token.unpackOffsetDateTime(source: source, context: context)
        } catch {
            throw DecodingError.valueNotFound(OffsetDateTime.self, DecodingError.Context(codingPath: codingPath, debugDescription: "\(error)", underlyingError: error))
        }
    }

    @inline(__always)
    func decode(_: Date.Type) throws -> Date {
        if !isLenient {
            throw DecodingError.valueNotFound(Date.self, DecodingError.Context(codingPath: codingPath, debugDescription: "No date found."))
        }

        switch strategy.date {
        case .gregorianCalendar:
            do {
                let offsetDateTime = try decode(OffsetDateTime.self)
                return Date(offsetDateTime: offsetDateTime, calendar: Calendar(identifier: .gregorian))
            } catch {
                throw DecodingError.valueNotFound(Date.self, DecodingError.Context(codingPath: codingPath, debugDescription: "\(error)", underlyingError: error))
            }
        case let .calendar(identifiedBy: identifier):
            do {
                let offsetDateTime = try decode(OffsetDateTime.self)
                return Date(offsetDateTime: offsetDateTime, calendar: Calendar(identifier: identifier))
            } catch {
                throw DecodingError.valueNotFound(Date.self, DecodingError.Context(codingPath: codingPath, debugDescription: "\(error)", underlyingError: error))
            }
        case .prolepticGregorianCalendar:
            do {
                let offsetDateTime = try decode(OffsetDateTime.self)
                return Date(timeIntervalSinceReferenceDate: offsetDateTime.timeIntervalSince2001)
            } catch {
                throw DecodingError.valueNotFound(Date.self, DecodingError.Context(codingPath: codingPath, debugDescription: "\(error)", underlyingError: error))
            }
        }
    }

    @inline(__always)
    func decode(_: DateComponents.Type) throws -> DateComponents {
        if !isLenient {
            throw DecodingError.valueNotFound(DateComponents.self, DecodingError.Context(codingPath: codingPath, debugDescription: "No date components found."))
        }

        let datetimeComponents = try token.unpackDateTime(source: source, context: context)
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
}
