/// A Offset Date-Time as defined by TOML.
///
/// A offset date-time represents a instant in time.
/// Conceptually ``OffsetDateTime`` simialar to `Foundation.Date`.
/// Operationally, ``OffsetDateTime`` works more like `Foundation.DateComponents`.
/// It stores the components, except each component is non-optional.
///
/// ``OffsetDateTime`` stores fractional seconds to the nanosecond precision.
/// It's also capable of representing some spelling variations in the string format of the date-time.
/// If a date-time string has sub-nanosecond precision,
/// and it does not have superflous trailing zeros in the fractional seconds,
/// ``OffsetDateTime`` stores enough information to exactly reconstruct the date-time string.
///
/// > Important: Offset date-time in TOML is defined by RFC 3339,
/// > which intepret the date with proleptic Gregorian calendar.
/// > This is different from Foundation's usage of the Gregorian calendar,
/// > which follows the Julian calendar up to 1582-10-04,
/// > then transitions to the Gregorian calendar after that.
/// > This means for ancient dates,
/// > ``OffsetDateTime`` may disagree with `Foundation.Date` on how much time has passed since a reference date.
/// > For modern dates, there's no difference between the two.
public struct OffsetDateTime: Equatable, Hashable, Sendable, Codable, CustomStringConvertible {
    /// The date component of the offset date-time.
    public var date: LocalDate
    /// The time component of the offset date-time.
    public var time: LocalTime
    /// The offset from UTC in minutes, valid range is [-1440, 1440].
    public var offset: Int16
    /// Details about the formatting of the date-time string.
    /// For example, whether the 'T' connecting the date and time is lowercase or uppercase.
    /// Or whether 00:00 offset is represented as 'Z' or '+00:00'.
    public var features: Features

    /// Create a new offset date-time from it's members.
    ///
    /// This initializer does not validate the components.
    /// Use ``isValid`` to check if the offset date-time is valid.
    ///
    /// - Parameters:
    ///   - date: The date component of the offset date-time.
    ///   - time: The time component of the offset date-time.
    ///   - offset: The offset from UTC in minutes, valid range is [-1440, 1440].
    ///   - features: Details about the formatting of the date-time string.
    public init(date: LocalDate, time: LocalTime, offset: Int16, features: Features) {
        self.date = date
        self.time = time
        self.offset = offset
        self.features = features
    }

    public init(from decoder: any Decoder) throws {
        if let decoder = decoder as? _TOMLDecoder {
            self = try decoder.decode(OffsetDateTime.self)
        } else {
            try self.init(from: decoder)
        }
    }

    /// Create a new offset date-time from it's members.
    ///
    /// This initializer validates the components.
    /// A invalid component causes a error to be thrown.
    ///
    /// - Parameters:
    ///   - date: The date component of the offset date-time.
    ///   - time: The time component of the offset date-time.
    ///   - offset: The offset from UTC in minutes, valid range is [-1440, 1440].
    ///   - features: Details about the formatting of the date-time string.
    public init(validatingDate date: LocalDate, time: LocalTime, offset: Int16, features: Features) throws(TOMLError) {
        self.init(date: date, time: time, offset: offset, features: features)
        guard date.isValid else {
            throw TOMLError(.invalidDateTimeComponents("Invalid local date: \(date)"))
        }
        guard time.isValid else {
            throw TOMLError(.invalidDateTimeComponents("Invalid local time: \(time)"))
        }
        guard offsetIsValid else {
            throw TOMLError(.invalidDateTimeComponents("Invalid offset: \(offset)"))
        }
        guard featuresAreValid else {
            throw TOMLError(.invalidDateTimeComponents("Invalid features: \(features)"))
        }
    }

    /// Check if the offset date-time is valid.
    public var isValid: Bool {
        guard date.isValid, time.isValid, offsetIsValid else {
            return false
        }

        return featuresAreValid
    }

    private var offsetIsValid: Bool {
        offset >= -1440 && offset <= 1440
    }

    private var featuresAreValid: Bool {
        if features.contains(.lowercaseZ) || features.contains(.uppercaseZ) {
            return offset == 0
        }

        return true
    }

    /// Number of seconds since 2001-01-01T00:00:00Z according to the proleptic Gregorian calendar.
    ///
    /// > Important: This is similar to `Foundation.Date.timeIntervalSinceReferenceDate`.
    /// But for ancient dates, this result may disagree with `Foundation.Date` on how much time has passed.
    /// this is because Foundation's Gregorian calendar follows the Julian calendar up to 1582-10-04,
    /// then the Gregorian calendar after that. According to the TOML specification,
    /// an offset date-time should follow the proleptic Gregorian calendar,
    /// which extends the Gregorian calendar backwards to year 1.
    public var timeIntervalSince2001: Double {
        timeIntervalSince1970 - 978_307_200
    }

    /// Number of seconds since 1970-01-01T00:00:00Z according to the proleptic Gregorian calendar.
    ///
    /// > Important: This is similar to `Foundation.Date.timeIntervalSinceReferenceDate`.
    /// But for ancient dates, this result may disagree with `Foundation.Date` on how much time has passed.
    /// this is because Foundation's Gregorian calendar follows the Julian calendar up to 1582-10-04,
    /// then the Gregorian calendar after that. According to the TOML specification,
    /// an offset date-time should follow the proleptic Gregorian calendar,
    /// which extends the Gregorian calendar backwards to year 1.
    public var timeIntervalSince1970: Double {
        let year = Int64(date.year)
        let month = Int64(date.month)
        let day = Int64(date.day)
        let hour = Int64(time.hour)
        let minute = Int64(time.minute)
        let second = Int64(time.second)
        let nanosecond = Int64(time.nanosecond)
        let offsetInSeconds = Int64(offset) * 60

        var y = year
        if month <= 2 { y -= 1 }

        let era = (y >= 0 ? y : y - 399) / 400
        let yoe = y - era * 400
        let doy = (153 * (month + (month > 2 ? -3 : 9)) + 2) / 5 + day - 1
        let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy
        let epochOffset = Int64(719_468)
        let dayCounts = era * 146_097 + doe - epochOffset
        let secondOfDay = hour * 3600 + minute * 60 + second
        let totalSeconds = dayCounts * 86400 + secondOfDay - offsetInSeconds

        return Double(totalSeconds) + Double(nanosecond) / 1_000_000_000
    }

    /// The string representation of the offset date-time.
    ///
    /// If a value has precision up to 1 nanosecond,
    /// and it does not require superflous trailing zeros in its fraction seconds,
    /// this value can be recreated exactly.
    public var description: String {
        let dateString = date.description
        let timeString = time.description
        let separator = if features.contains(.lowercaseT) {
            "t"
        } else if features.contains(.uppercaseT) {
            "T"
        } else {
            " "
        }

        if features.contains(.lowercaseZ) {
            return "\(dateString)\(separator)\(timeString)z"
        } else if features.contains(.uppercaseZ) {
            return "\(dateString)\(separator)\(timeString)Z"
        } else {
            let sign = offset >= 0 ? "+" : "-"
            let absOffset = abs(offset)
            let hours = absOffset / 60
            let minutes = absOffset % 60
            let hoursStr = hours < 10 ? "0\(hours)" : "\(hours)"
            let minutesStr = minutes < 10 ? "0\(minutes)" : "\(minutes)"
            return "\(dateString)\(separator)\(timeString)\(sign)\(hoursStr):\(minutesStr)"
        }
    }

    /// Pressentation details for string representation of the offset date-time.
    ///
    /// A parser can preserve features of a offset date-time string with this type.
    /// If neither lowercase nor uppercase 'T' is present, the date-time seprator is a space, which is allowed by TOML.
    public struct Features: OptionSet, Hashable, Sendable, Codable {
        /// The raw value of the features.
        public let rawValue: UInt8

        /// Create a new features from it's raw value.
        public init(rawValue: UInt8) {
            self.rawValue = rawValue
        }

        /// Indicates the date-time seprator is a lowercase 't'.
        static let lowercaseT = Features(rawValue: 1 << 1)

        /// Indicates the date-time seprator is a uppercase 'T'.
        static let uppercaseT = Features(rawValue: 1 << 2)

        /// Indicates the offset is represented as a lowercase 'z'.
        /// This should not be present if the offset is non-zero,
        /// or if it's +00:00.
        static let lowercaseZ = Features(rawValue: 1 << 3)

        /// Indicates the offset is represented as a uppercase 'Z'.
        /// This should not be present if the offset is non-zero,
        /// or if it's +00:00.
        static let uppercaseZ = Features(rawValue: 1 << 4)
    }
}

/// A local date-time as defined by TOML.
///
/// ``LocalDateTime`` stores fractional seconds to the nanosecond precision.
public struct LocalDateTime: Equatable, Hashable, Sendable, Codable, CustomStringConvertible {
    /// The date component of the local date-time.
    public var date: LocalDate
    /// The time component of the local date-time.
    public var time: LocalTime

    /// Create a new local date-time from it's members.
    ///
    /// This initializer does not validate the components.
    /// Use ``isValid`` to check if the local date-time is valid.
    /// - Parameters:
    ///   - date: The date component of the local date-time.
    ///   - time: The time component of the local date-time.
    public init(date: LocalDate, time: LocalTime) {
        self.date = date
        self.time = time
    }

    public init(from decoder: any Decoder) throws {
        if let decoder = decoder as? _TOMLDecoder {
            self = try decoder.decode(LocalDateTime.self)
        } else {
            try self.init(from: decoder)
        }
    }

    /// Create a new local date-time from it's members.
    ///
    /// This initializer validates the components.
    /// A invalid component causes a error to be thrown.
    ///
    /// - Parameters:
    ///   - date: The date component of the local date-time.
    ///   - time: The time component of the local date-time.
    public init(validatingDate date: LocalDate, time: LocalTime) throws(TOMLError) {
        self.init(date: date, time: time)
        guard date.isValid else {
            throw TOMLError(.invalidDateTimeComponents("Invalid local date: \(date)"))
        }
        guard time.isValid else {
            throw TOMLError(.invalidDateTimeComponents("Invalid local time: \(time)"))
        }
    }

    /// Check if the local date-time is valid.
    public var isValid: Bool {
        date.isValid && time.isValid
    }

    /// The string representation of the local date-time.
    public var description: String {
        "\(date.description)T\(time.description)"
    }
}

/// A local time as defined by TOML.
///
/// ``LocalTime`` stores fractional seconds to the nanosecond precision.
public struct LocalTime: Equatable, Hashable, Sendable, Codable, CustomStringConvertible {
    /// The hour component of the local time.
    public var hour: UInt8
    /// The minute component of the local time.
    public var minute: UInt8
    /// The second component of the local time.
    public var second: UInt8
    /// The fractional second component of the local time in nanoseconds.
    public var nanosecond: UInt32

    /// Create a new local time from it's members.
    ///
    /// This initializer validates the components.
    /// A invalid component causes a error to be thrown.
    ///
    /// - Parameters:
    ///   - hour: The hour component of the local time.
    ///   - minute: The minute component of the local time.
    ///   - second: The second component of the local time.
    ///   - nanosecond: The fractional second component of the local time in nanoseconds.
    public init(validatingHour hour: UInt8, minute: UInt8, second: UInt8, nanosecond: UInt32 = 0) throws(TOMLError) {
        self.init(hour: hour, minute: minute, second: second, nanosecond: nanosecond)
        guard isValid else {
            throw TOMLError(.invalidDateTimeComponents("Invalid local time components: \(hour):\(minute):\(second).\(nanosecond)"))
        }
    }

    /// Create a new local time from it's members.
    ///
    /// This initializer does not validate the components.
    /// Use ``isValid`` to check if the local time is valid.
    ///
    /// - Parameters:
    ///   - hour: The hour component of the local time.
    ///   - minute: The minute component of the local time.
    ///   - second: The second component of the local time.
    ///   - nanosecond: The fractional second component of the local time in nanoseconds.
    public init(hour: UInt8, minute: UInt8, second: UInt8, nanosecond: UInt32 = 0) {
        self.hour = hour
        self.minute = minute
        self.second = second
        self.nanosecond = nanosecond
    }

    /// Check if the local time is valid.
    public var isValid: Bool {
        hour < 24 && minute < 60 && second < 60 && nanosecond < 1_000_000_000
    }

    /// The string representation of the local time.
    public var description: String {
        let hourStr = hour < 10 ? "0\(hour)" : "\(hour)"
        let minuteStr = minute < 10 ? "0\(minute)" : "\(minute)"
        let secondStr = second < 10 ? "0\(second)" : "\(second)"

        if nanosecond == 0 {
            return "\(hourStr):\(minuteStr):\(secondStr)"
        } else {
            let nanosecondStr = String(nanosecond).padded(to: 9, with: "0")
            let trimmedFractional = nanosecondStr.trimmingSuffix("0")
            let finalFractional = trimmedFractional.isEmpty ? "0" : trimmedFractional
            return "\(hourStr):\(minuteStr):\(secondStr).\(finalFractional)"
        }
    }
}

/// A local date as defined by TOML.
///
/// ``LocalDate`` stores the year, month, and day components of a date.
public struct LocalDate: Equatable, Hashable, Sendable, Codable, CustomStringConvertible {
    /// The year component of the local date.
    /// Valid range is [1, 9999].
    public var year: UInt16

    /// The month component of the local date.
    /// Valid range is [1, 12].
    public var month: UInt8

    /// The day component of the local date.
    /// Valid range is depends on the month and year.
    public var day: UInt8

    /// Create a new local date from it's members.
    ///
    /// This initializer validates the components.
    /// A invalid component causes a error to be thrown.
    ///
    /// - Parameters:
    ///   - year: The year component of the local date.
    ///   - month: The month component of the local date.
    ///   - day: The day component of the local date.
    public init(validatingYear year: UInt16, month: UInt8, day: UInt8) throws(TOMLError) {
        self.init(year: year, month: month, day: day)
        guard isValid else {
            throw TOMLError(.invalidDateTimeComponents("Invalid local date components: \(year)-\(month)-\(day)"))
        }
    }

    /// Create a new local date from it's members.
    ///
    /// This initializer does not validate the components.
    /// Use ``isValid`` to check if the local date is valid.
    ///
    /// - Parameters:
    ///   - year: The year component of the local date.
    ///   - month: The month component of the local date.
    ///   - day: The day component of the local date.
    public init(year: UInt16, month: UInt8, day: UInt8) {
        self.year = year
        self.month = month
        self.day = day
    }

    /// Check if the local date is valid.
    public var isValid: Bool {
        guard month >= 1, month <= 12 else { return false }
        guard day >= 1 else { return false }

        let daysInMonth: UInt8
        switch month {
        case 1, 3, 5, 7, 8, 10, 12:
            daysInMonth = 31
        case 4, 6, 9, 11:
            daysInMonth = 30
        case 2:
            let isLeapYear = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
            daysInMonth = isLeapYear ? 29 : 28
        default:
            return false
        }

        return day <= daysInMonth
    }

    /// The string representation of the local date.
    public var description: String {
        let yearStr = String(year).padded(to: 4, with: "0")
        let monthStr = month < 10 ? "0\(month)" : "\(month)"
        let dayStr = day < 10 ? "0\(day)" : "\(day)"
        return "\(yearStr)-\(monthStr)-\(dayStr)"
    }
}

extension String {
    fileprivate func padded(to length: Int, with character: Character) -> String {
        if count >= length {
            return self
        }
        return String(repeating: character, count: length - count) + self
    }

    fileprivate func trimmingSuffix(_ suffix: Character) -> String {
        var result = self
        while result.last == suffix {
            result.removeLast()
        }
        return result
    }
}

import Foundation

extension DateComponents {
    /// Create a new `Foundation.DateComponents` from an offset date-time.
    /// Only the literal components of a offset date-time will be in the components.
    /// the calendar component, for example, is not set.
    ///
    /// - Parameter offsetDateTime: The offset date-time to convert.
    public init(offsetDateTime: OffsetDateTime) {
        self.init(
            timeZone: TimeZone(secondsFromGMT: Int(offsetDateTime.offset) * 60),
            year: Int(offsetDateTime.date.year),
            month: Int(offsetDateTime.date.month),
            day: Int(offsetDateTime.date.day),
            hour: Int(offsetDateTime.time.hour),
            minute: Int(offsetDateTime.time.minute),
            second: Int(offsetDateTime.time.second),
            nanosecond: Int(offsetDateTime.time.nanosecond),
        )
    }
}

extension Date {
    /// Create a new `Foundation.Date` from an offset date-time.
    ///
    /// - Parameter offsetDateTime: The offset date-time to convert.
    /// - Parameter calendar: The calendar based on which the date is constructed.
    ///   Defaults to the Gregorian calendar.
    ///   Note that Foundation's Gregorian calendar is NOT proleptic.
    ///   It follows the Julian calendar up to 1582-10-04,
    ///   then the Gregorian calendar after that.
    ///   According to the TOML specification,
    ///   an offset date-time should follow the proleptic Gregorian calendar,
    ///   which extends the Gregorian calendar backwards to year 1.
    ///   Therefore,
    ///   for ancient dates,
    ///   the resulting `Date`'s `.timeIntervalSince1970` or `.timeIntervalSinceReferenceDate` may have a different value as defined in the TOML specification,
    ///   which follows RFC 3339.
    ///   To get the proleptic Gregorian time interval,
    ///   use ``OffsetDateTime/timeIntervalSince2001`` or ``OffsetDateTime/timeIntervalSince1970``.
    public init(offsetDateTime: OffsetDateTime, calendar: Calendar = Calendar(identifier: .gregorian)) {
        var components = DateComponents(offsetDateTime: offsetDateTime)
        components.calendar = calendar
        self = components.date!
    }
}
