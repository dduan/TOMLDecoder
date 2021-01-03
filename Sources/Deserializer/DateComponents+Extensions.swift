import struct Foundation.DateComponents

extension DateComponents {
    init?(validatingHour hour: Int, minute: Int, second: Int, secondFraction: [Int] = []) {
        if hour.isInvalidHour ||
            minute.isInvalidMinute ||
            second.isInvalidSecond ||
            secondFraction.contains(where: { $0.isInvalidDigit })
        {
            return nil
        }

        if secondFraction.isEmpty {
            self.init(hour: hour, minute: minute, second: second)
        } else {
            var digits = secondFraction
            var fraction = 0
            if secondFraction.count < 9 {
                digits += Array(repeating: 0, count: 9 - secondFraction.count)
                for i in 0 ..< 9 {
                    fraction = fraction * 10 + digits[i]
                }
            }
            self.init(hour: hour, minute: minute, second: second, nanosecond: fraction)
        }
    }
}

extension DateComponents {
    init?(validatingYear year: Int, month: Int, day: Int) {
        if year.isInvalidYear ||
            month.isInvalidMonth ||
            day.isInvalidDay(inYear: year, month: month)
        {
            return nil
        }

        self.init(year: year, month: month, day: day)
    }
}

extension DateComponents {
    init(date: DateComponents, time: DateComponents) {
        self.init(
            year: date.year, month: date.month, day: date.day,
            hour: time.hour, minute: time.minute, second: time.second , nanosecond: time.nanosecond
        )
    }
}

extension SignedInteger {
    @inline(__always)
    fileprivate var isInvalidYear: Bool {
        return self < 1 || self > 9999
    }

    @inline(__always)
    fileprivate var isInvalidMonth: Bool {
        return self < 1 || self > 12
    }

    @inline(__always)
    fileprivate func isInvalidDay<Y, M>(inYear year: Y, month: M) -> Bool
        where Y: SignedInteger, M: SignedInteger
    {
        let maxDayCount: Self
        let isLeapYear = year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)
        switch month {
        case 2:
            maxDayCount = isLeapYear ? 29 : 28
        case 4, 6, 9, 11:
            maxDayCount = 30
        default:
            maxDayCount = 31
        }

        return self < 1 || self > maxDayCount
    }

    @inline(__always)
    fileprivate var isInvalidDigit: Bool {
        return self < 0 || self > 9
    }

    @inline(__always)
    fileprivate var isInvalidSecond: Bool {
        return self < 0 || self > 60
    }

    @inline(__always)
    var isInvalidMinute: Bool {
        return self < 0 || self > 59
    }

    @inline(__always)
    var isInvalidHour: Bool {
        return self < 0 || self > 23
    }
}
