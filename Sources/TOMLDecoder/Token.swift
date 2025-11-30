import Foundation

struct Token {
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
    }

    let kind: Kind
    let lineNumber: Int
    let text: String.UTF8View.SubSequence
    let eof: Bool

    static let empty = Token(kind: .newline, lineNumber: 1, text: "".utf8[...], eof: false)
}

extension Token: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.kind == rhs.kind &&
            lhs.lineNumber == rhs.lineNumber &&
            lhs.text.startIndex == rhs.text.startIndex && lhs.text.endIndex == rhs.text.endIndex &&
            lhs.eof == rhs.eof
    }
}

extension Token: CustomDebugStringConvertible {
    var debugDescription: String {
        "text [\(String(Substring(text)))], eof: \(eof), kind: \(kind)"
    }
}

extension Token {
    func unpackBool(context: TOMLKey) throws(TOMLError) -> Bool {
        if text.count == 4, text.starts(with: Constants.true) {
            return true
        } else if text.count == 5, text.starts(with: Constants.false) {
            return false
        }

        throw TOMLError(.invalidBool(context: context, value: self))
    }

    func unpackFloat(context: TOMLKey) throws(TOMLError) -> Double {
        var resultCodeUnits: [UTF8.CodeUnit] = []
        var index = text.startIndex
        if text[index] == CodeUnits.plus || text[index] == CodeUnits.minus {
            resultCodeUnits.append(text[index])
            index = text.index(after: index)
        }

        if isdigit(Int32(text[index])) == 0 {
            guard text[index...].starts(with: Constants.nan) || text[index...].starts(with: Constants.inf) else {
                throw TOMLError(.invalidFloat2(context: context, value: self, reason: "Expected 0-9, nan or inf, found \(text[index])"))
            }
            resultCodeUnits.append(contentsOf: text[index ..< text.index(index, offsetBy: 3)])
        } else {
            if text[index] == CodeUnits.number0,
               index < text.endIndex,
               case let next = text[text.index(after: index)],
               next != CodeUnits.dot, next != CodeUnits.lowerE, next != CodeUnits.upperE
            {
                throw TOMLError(.invalidFloat2(context: context, value: self, reason: "Float begins with 0 must be followed by a '.', 'e' or 'E'"))
            }

            while index < text.endIndex {
                let ch = text[index]
                index = text.index(after: index)

                if ch == CodeUnits.underscore {
                    guard
                        let last = resultCodeUnits.last,
                        isdigit(Int32(last)) != 0
                    else {
                        throw TOMLError(.invalidFloat2(context: context, value: self, reason: "'_' must be preceded by a digit"))
                    }

                    guard
                        index < text.endIndex,
                        case let next = text[index],
                        isdigit(Int32(next)) != 0
                    else {
                        throw TOMLError(.invalidFloat2(context: context, value: self, reason: "'_' must be follewed by a digit"))
                    }

                    continue
                } else if ch == CodeUnits.dot {
                    if resultCodeUnits.isEmpty {
                        throw TOMLError(.invalidFloat2(context: context, value: self, reason: "First digit of floats cannot be '.'"))
                    }

                    if !resultCodeUnits.last!.isDecimalDigit {
                        throw TOMLError(.invalidFloat2(context: context, value: self, reason: "'.' must be preceded by a decimal digit"))
                    }

                    guard index < text.endIndex, isdigit(Int32(text[index])) != 0 else {
                        throw TOMLError(.invalidFloat2(context: context, value: self, reason: "A digit must follow '.'"))
                    }

                } else if ch == CodeUnits.upperE || ch == CodeUnits.lowerE {
                } else if !ch.isDecimalDigit, ch != CodeUnits.plus, ch != CodeUnits.minus {
                    throw TOMLError(.invalidFloat2(context: context, value: self, reason: "invalid character for float"))
                }

                resultCodeUnits.append(ch)
            }
        }

        guard let double = Double(String(decoding: resultCodeUnits, as: UTF8.self)) else {
            throw TOMLError(.invalidFloat2(context: context, value: self, reason: "not a float"))
        }

        return double
    }

    func unpackString(context: TOMLKey) throws(TOMLError) -> String {
        var multiline = false

        if text.isEmpty {
            throw TOMLError(.invalidString(context: context, value: self, reason: "missing closing quote"))
        }

        let quoteChar = text[text.startIndex]
        var index = text.startIndex
        var endIndex = text.endIndex

        assert(quoteChar == CodeUnits.doubleQuote || quoteChar == CodeUnits.singleQuote)

        if text.starts(with: Constants.tripleDoubleQuote) || text.starts(with: Constants.tripleSingleQuote) {
            multiline = true
            index = text.index(index, offsetBy: 3)
            endIndex = text.index(endIndex, offsetBy: -3)

            if index < endIndex, text[index] == CodeUnits.lf {
                index = text.index(after: index)
            } else if text[index...].starts(with: [CodeUnits.cr, CodeUnits.lf]) {
                index = text.index(index, offsetBy: 2)
            }
        } else {
            index = text.index(after: index)
            endIndex = text.index(before: endIndex)
            guard text[endIndex] == quoteChar else {
                throw TOMLError(.invalidString(context: context, value: self, reason: "missing closing quote"))
            }
        }

        if quoteChar == CodeUnits.singleQuote {
            do {
                return try literalString(source: text[index ..< endIndex], multiline: multiline)
            } catch {
                // Convert the specific string parsing error to our context-aware version
                throw TOMLError(.invalidString(context: context, value: self, reason: error.localizedDescription))
            }
        } else {
            do {
                return try basicString(source: text[index ..< endIndex], multiline: multiline)
            } catch {
                // Convert the specific string parsing error to our context-aware version
                throw TOMLError(.invalidString(context: context, value: self, reason: error.localizedDescription))
            }
        }
    }

    func unpackInteger(context: TOMLKey) throws(TOMLError) -> Int64 {
        @_transparent
        func isValidDigit(_ codeUnit: UTF8.CodeUnit, base: Int) -> Bool {
            switch base {
            case 10:
                codeUnit.isDecimalDigit
            case 16:
                codeUnit.isHexDigit
            case 2:
                codeUnit == CodeUnits.number0 || codeUnit == CodeUnits.number1
            case 8:
                CodeUnits.number0 <= codeUnit && codeUnit <= CodeUnits.number7
            default:
                false
            }
        }

        var resultCodeUnits: [UTF8.CodeUnit] = []
        var index = text.startIndex
        var base = 10
        var hasSign = false
        if text[index] == CodeUnits.plus || text[index] == CodeUnits.minus {
            hasSign = true
            resultCodeUnits.append(text[index])
            index = text.index(after: index)
        }

        if text[index] == CodeUnits.underscore {
            throw TOMLError(.invalidInteger(context: context, value: self, reason: "cannot start with a '_'"))
        }

        if text[index] == CodeUnits.number0 {
            let nextIndex = text.index(after: index)
            if nextIndex < text.endIndex {
                if text[nextIndex] == CodeUnits.lowerX {
                    if hasSign {
                        throw TOMLError(.invalidInteger(context: context, value: self, reason: "hexadecimal integers cannot have explicit signs"))
                    }
                    base = 16
                    text.formIndex(&index, offsetBy: 2)
                } else if text[nextIndex] == CodeUnits.lowerO {
                    if hasSign {
                        throw TOMLError(.invalidInteger(context: context, value: self, reason: "octal integers cannot have explicit signs"))
                    }
                    base = 8
                    text.formIndex(&index, offsetBy: 2)
                } else if text[nextIndex] == CodeUnits.lowerB {
                    if hasSign {
                        throw TOMLError(.invalidInteger(context: context, value: self, reason: "binary integers cannot have explicit signs"))
                    }
                    base = 2
                    text.formIndex(&index, offsetBy: 2)
                } else if text[nextIndex].isDecimalDigit || text[nextIndex] == CodeUnits.underscore {
                    throw TOMLError(.invalidInteger(context: context, value: self, reason: "decimal integers cannot have leading zeros"))
                }
            }
            // Single zero is allowed to continue to the main loop
        }

        while index < text.endIndex {
            let ch = text[index]
            index = text.index(after: index)

            if ch == CodeUnits.underscore {
                guard
                    let last = resultCodeUnits.last,
                    isValidDigit(last, base: base)
                else {
                    throw TOMLError(.invalidInteger(context: context, value: self, reason: "cannot use '_' adjacent to a non-digit"))
                }

                if index >= text.endIndex {
                    throw TOMLError(.invalidInteger(context: context, value: self, reason: "cannot end with a '_'"))
                }

                let next = text[index]
                if next == CodeUnits.underscore {
                    throw TOMLError(.invalidInteger(context: context, value: self, reason: "cannot contain consecutive '_'"))
                }
                guard isValidDigit(next, base: base) else {
                    throw TOMLError(.invalidInteger(context: context, value: self, reason: "cannot use '_' adjacent to a non-digit"))
                }
                continue
            }

            guard isValidDigit(ch, base: base) else {
                throw TOMLError(.invalidInteger(context: context, value: self, reason: "invalid digit for base \(base)"))
            }

            resultCodeUnits.append(ch)
        }

        let s = String(decoding: resultCodeUnits, as: UTF8.self)
        guard let i = Int64(s, radix: base) else {
            throw TOMLError(.invalidInteger(context: context, value: self, reason: "\(s) is a invalid integer of base \(base)"))
        }
        return i
    }

    func unpackDateTime(context: TOMLKey) throws(TOMLError) -> DateTimeComponents {
        var mustParseTime = false
        var date: (year: Int, month: Int, day: Int)?
        var time: (hour: Int, minute: Int, second: Int)?

        var index = text.startIndex
        if let (year, month, day, _) = scanDate(source: text) {
            // Validate date components
            if month < 1 || month > 12 {
                throw TOMLError(.invalidDateTime2(context: context, value: self, reason: "month must be between 01 and 12"))
            }
            if day < 1 {
                throw TOMLError(.invalidDateTime2(context: context, value: self, reason: "day must be between 01 and 31"))
            }

            // Validate days per month and leap years
            let isLeapYear = year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)
            let maxDaysInMonth: Int = switch month {
            case 2:
                isLeapYear ? 29 : 28
            case 4, 6, 9, 11:
                30
            default:
                31
            }

            if day > maxDaysInMonth {
                if month == 2, !isLeapYear {
                    throw TOMLError(.invalidDateTime2(context: context, value: self, reason: "February only has 28 days in non-leap years"))
                } else if month == 2, isLeapYear {
                    throw TOMLError(.invalidDateTime2(context: context, value: self, reason: "February only has 29 days in leap years"))
                } else {
                    throw TOMLError(.invalidDateTime2(context: context, value: self, reason: "day \(day) is invalid for month \(month)"))
                }
            }

            date = (year, month, day)
            text.formIndex(&index, offsetBy: 10)
        }

        var features: OffsetDateTime.Features = []
        var nanoseconds: UInt32?
        if index < text.endIndex {
            if date != nil {
                let isSeparatorLowerT = text[index] == CodeUnits.lowerT
                let isSeparatorUpperT = text[index] == CodeUnits.upperT
                guard isSeparatorLowerT || isSeparatorUpperT || text[index] == CodeUnits.space else {
                    throw TOMLError(.invalidDateTime2(context: context, value: self, reason: "expected 'T' or 't' or space to separate date and time"))
                }
                if isSeparatorLowerT {
                    features.insert(.lowercaseT)
                } else if isSeparatorUpperT {
                    features.insert(.uppercaseT)
                }
                mustParseTime = true
                text.formIndex(&index, offsetBy: 1)
            } else {
                // For standalone time values, don't advance index
                mustParseTime = true
            }
            if let (hour, minute, second, _) = scanTime(source: text[index...]) {
                // Validate time components
                if hour > 23 {
                    throw TOMLError(.invalidDateTime2(context: context, value: self, reason: "hour must be between 00 and 23"))
                }
                if minute > 59 {
                    throw TOMLError(.invalidDateTime2(context: context, value: self, reason: "minute must be between 00 and 59"))
                }
                if second > 59 {
                    throw TOMLError(.invalidDateTime2(context: context, value: self, reason: "second must be between 00 and 59"))
                }

                time = (hour, minute, second)

                text.formIndex(&index, offsetBy: 8)
                if index < text.endIndex, text[index] == CodeUnits.dot {
                    text.formIndex(&index, offsetBy: 1)
                    let beforeNanoIndex = index
                    nanoseconds = parseNanoSeconds(source: text[index...], updatedIndex: &index)
                    // Must have at least one digit after decimal point
                    if index == beforeNanoIndex {
                        throw TOMLError(.invalidDateTime2(context: context, value: self, reason: "decimal point must be followed by digits"))
                    }
                }
            }
        }

        if mustParseTime, time == nil {
            throw TOMLError(.invalidDateTime2(context: context, value: self, reason: "expected valid time"))
        }

        var timeOffset: Int16?
        if index < text.endIndex {
            if text[index] == CodeUnits.lowerZ {
                features.insert(.lowercaseZ)
                text.formIndex(&index, offsetBy: 1)
                timeOffset = 0
            } else if text[index] == CodeUnits.upperZ {
                features.insert(.uppercaseZ)
                text.formIndex(&index, offsetBy: 1)
                timeOffset = 0
            } else if text[index] == CodeUnits.plus || text[index] == CodeUnits.minus {
                let offsetIsNegative = text[index] == CodeUnits.minus
                text.formIndex(&index, offsetBy: 1)

                // Scan ahead to find the end of the timezone offset
                var endIndex = index
                while endIndex < text.endIndex {
                    let ch = text[endIndex]
                    if isdigit(Int32(ch)) != 0 || ch == CodeUnits.colon {
                        endIndex = text.index(after: endIndex)
                    } else {
                        break
                    }
                }

                do {
                    let (offsetHour, offsetMinute, consumedLength) = try parseTimezoneOffset(text[index ..< endIndex], lineNumber: lineNumber)

                    // Validate timezone offset ranges
                    if offsetHour > 24 {
                        throw TOMLError(.invalidDateTime2(context: context, value: self, reason: "timezone offset hour must be between 00 and 24"))
                    }
                    if offsetMinute > 59 {
                        throw TOMLError(.invalidDateTime2(context: context, value: self, reason: "timezone offset minute must be between 00 and 59"))
                    }

                    let offsetInMinutes = offsetHour * 60 + offsetMinute
                    timeOffset = Int16(offsetIsNegative ? -offsetInMinutes : offsetInMinutes)
                    text.formIndex(&index, offsetBy: consumedLength)
                } catch let parseError {
                    if let tomlError = parseError as? TOMLError {
                        switch tomlError.reason {
                        case let .invalidDateTime(_, reason):
                            throw TOMLError(.invalidDateTime2(context: context, value: self, reason: reason))
                        default:
                            throw tomlError
                        }
                    } else {
                        throw TOMLError(.invalidDateTime2(context: context, value: self, reason: "timezone parsing error"))
                    }
                }
            }
        }

        if index < text.endIndex {
            throw TOMLError(.invalidDateTime2(context: context, value: self, reason: "extra character after date time"))
        }

        return DateTimeComponents(
            date: date.map { LocalDate(year: .init($0.year), month: .init($0.month), day: .init($0.day)) },
            time: time.map { LocalTime(hour: .init($0.hour), minute: .init($0.minute), second: .init($0.second), nanosecond: nanoseconds ?? 0) },
            offset: timeOffset,
            features: features,
        )
    }

    func unpackOffsetDateTime(context: TOMLKey) throws(TOMLError) -> OffsetDateTime {
        let datetime = try unpackDateTime(context: context)
        switch (datetime.date, datetime.time, datetime.offset) {
        case let (.some(date), .some(time), .some(offset)):
            return OffsetDateTime(date: date, time: time, offset: offset, features: datetime.features)
        default:
            throw TOMLError(.typeMismatch(context: context, token: self, expected: "offset date-time"))
        }
    }

    func unpackLocalDateTime(context: TOMLKey, exactMatch: Bool = true) throws(TOMLError) -> LocalDateTime {
        let components = try unpackDateTime(context: context)
        guard let localDateTime = components.localDateTime(exactMatch: exactMatch) else {
            throw TOMLError(.typeMismatch(context: context, token: self, expected: "local date-time"))
        }
        return localDateTime
    }

    func unpackLocalDate(context: TOMLKey, exactMatch: Bool = true) throws(TOMLError) -> LocalDate {
        let components = try unpackDateTime(context: context)
        guard let localDate = components.localDate(exactMatch: exactMatch) else {
            throw TOMLError(.typeMismatch(context: context, token: self, expected: "local date"))
        }
        return localDate
    }

    func unpackLocalTime(context: TOMLKey, exactMatch: Bool = true) throws(TOMLError) -> LocalTime {
        let components = try unpackDateTime(context: context)
        guard let localTime = components.localTime(exactMatch: exactMatch) else {
            throw TOMLError(.typeMismatch(context: context, token: self, expected: "local time"))
        }
        return localTime
    }

    func unpackAnyValue(context: TOMLKey) throws(TOMLError) -> Any {
        let firstChar = text.first
        if firstChar == CodeUnits.singleQuote || firstChar == CodeUnits.doubleQuote {
            return try unpackString(context: context)
        }

        if let boolValue = try? unpackBool(context: context) {
            return boolValue
        }

        if let intValue = try? unpackInteger(context: context) {
            return intValue
        }

        if let floatValue = try? unpackFloat(context: context) {
            return floatValue
        }

        guard firstChar?.isDecimalDigit == true else {
            throw TOMLError(.invalidValueInTable(context: context, token: self))
        }

        let datetime = try unpackDateTime(context: .string(""))
        switch (datetime.date, datetime.time, datetime.offset) {
        case let (.some(date), .some(time), .some(offset)):
            return OffsetDateTime(date: date, time: time, offset: offset, features: datetime.features)
        case let (.some(date), .some(time), .none):
            return LocalDateTime(date: date, time: time)
        case let (.some(date), .none, .none):
            return date
        case let (.none, .some(time), .none):
            return time
        default:
            throw TOMLError(.invalidValueInTable(context: context, token: self))
        }
    }
}
