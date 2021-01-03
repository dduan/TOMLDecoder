import struct Foundation.Calendar
import struct Foundation.Date
import struct Foundation.DateComponents
import struct Foundation.TimeZone

extension Date {
    init(date: DateComponents, time: DateComponents, timeZone: TimeZone) {
        var components = DateComponents(date: date, time: time)
        components.timeZone = timeZone
        self = Calendar(identifier: .gregorian).date(from: components)!
    }
}
