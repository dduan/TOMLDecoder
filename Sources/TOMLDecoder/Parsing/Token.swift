struct Token: Equatable {
    enum Kind {
        case dot
        case comma
        case equal
        case lbrace
        case rbrace
        case newline
        case lbracket
        case rbracket
        case string
        case bareKey
        case eof
    }

    let kind: Kind
    let lineNumber: Int
    let text: Range<Int>

    static let empty = Token(kind: .newline, lineNumber: 1, text: 0 ..< 0)
}

extension Token {
    func unpackBool(source: String, context: TOMLKey) throws(TOMLError) -> Bool {
        do {
            return try (source.utf8.withContiguousStorageIfAvailable { try unpackBool(bytes: $0, context: context) })!
        } catch {
            throw error as! TOMLError
        }
    }

    func unpackFloat(source: String, context: TOMLKey) throws(TOMLError) -> Double {
        do {
            return try (source.utf8.withContiguousStorageIfAvailable { try unpackFloat(bytes: $0, context: context) })!
        } catch {
            throw error as! TOMLError
        }
    }

    func unpackString(source: String, context: TOMLKey) throws(TOMLError) -> String {
        do {
            return try (source.utf8.withContiguousStorageIfAvailable { try unpackString(bytes: $0, context: context) })!
        } catch {
            throw error as! TOMLError
        }
    }

    func unpackInteger(source: String, context: TOMLKey) throws(TOMLError) -> Int64 {
        do {
            return try (source.utf8.withContiguousStorageIfAvailable { try unpackInteger(bytes: $0, context: context) })!
        } catch {
            throw error as! TOMLError
        }
    }

    func unpackDateTime(source: String, context: TOMLKey) throws(TOMLError) -> DateTimeComponents {
        do {
            return try (source.utf8.withContiguousStorageIfAvailable { try unpackDateTime(bytes: $0, context: context) })!
        } catch {
            throw error as! TOMLError
        }
    }

    func unpackOffsetDateTime(source: String, context: TOMLKey) throws(TOMLError) -> OffsetDateTime {
        let datetime: DateTimeComponents
        do {
            datetime = try (source.utf8.withContiguousStorageIfAvailable { try unpackDateTime(bytes: $0, context: context) })!
        } catch {
            throw error as! TOMLError
        }
        switch (datetime.date, datetime.time, datetime.offset) {
        case let (.some(date), .some(time), .some(offset)):
            return OffsetDateTime(date: date, time: time, offset: offset, features: datetime.features)
        default:
            throw TOMLError(.typeMismatch(context: context, lineNumber: lineNumber, expected: "offset date-time"))
        }
    }

    func unpackLocalDateTime(source: String, context: TOMLKey, exactMatch: Bool = true) throws(TOMLError) -> LocalDateTime {
        let components = try unpackDateTime(source: source, context: context)
        guard let localDateTime = components.localDateTime(exactMatch: exactMatch) else {
            throw TOMLError(.typeMismatch(context: context, lineNumber: lineNumber, expected: "local date-time"))
        }
        return localDateTime
    }

    func unpackLocalDate(source: String, context: TOMLKey, exactMatch: Bool = true) throws(TOMLError) -> LocalDate {
        let components = try unpackDateTime(source: source, context: context)
        guard let localDate = components.localDate(exactMatch: exactMatch) else {
            throw TOMLError(.typeMismatch(context: context, lineNumber: lineNumber, expected: "local date"))
        }
        return localDate
    }

    func unpackLocalTime(source: String, context: TOMLKey, exactMatch: Bool = true) throws(TOMLError) -> LocalTime {
        let components = try unpackDateTime(source: source, context: context)
        guard let localTime = components.localTime(exactMatch: exactMatch) else {
            throw TOMLError(.typeMismatch(context: context, lineNumber: lineNumber, expected: "local time"))
        }
        return localTime
    }

    func unpackAnyValue(source: String, context: TOMLKey) throws(TOMLError) -> Any {
        do {
            return try (source.utf8.withContiguousStorageIfAvailable { try unpackAnyValue(bytes: $0, context: context) })!
        } catch {
            throw error as! TOMLError
        }
    }
}
