import Testing
@testable import TOMLDecoder

@Suite
struct DateTimeDescriptionTests {
    @Test(.tags(.local_date))
    func `local date basic formatting`() {
        let date = LocalDate(year: 2023, month: 5, day: 27)
        #expect(date.description == "2023-05-27")
        
        let dateWithPadding = LocalDate(year: 1979, month: 1, day: 3)
        #expect(dateWithPadding.description == "1979-01-03")
    }

    @Test(.tags(.local_time))
    func `local time without fractional seconds`() {
        let time = LocalTime(hour: 7, minute: 32, second: 0, nanosecond: 0)
        #expect(time.description == "07:32:00")
        
        let timeWithPadding = LocalTime(hour: 23, minute: 5, second: 59, nanosecond: 0)
        #expect(timeWithPadding.description == "23:05:59")
    }

    @Test(.tags(.local_time))
    func `local time with fractional seconds`() {
        let timeWithMicroseconds = LocalTime(hour: 7, minute: 32, second: 0, nanosecond: 999_000_000)
        #expect(timeWithMicroseconds.description == "07:32:00.999")
        
        let timeWithNanoseconds = LocalTime(hour: 0, minute: 32, second: 0, nanosecond: 999_999_000)
        #expect(timeWithNanoseconds.description == "00:32:00.999999")
        
        let timeWithNanoseconds2 = LocalTime(hour: 0, minute: 32, second: 0, nanosecond: 123)
        #expect(timeWithNanoseconds2.description == "00:32:00.000000123")

        let timeWithSingleDigit = LocalTime(hour: 12, minute: 0, second: 1, nanosecond: 100_000_000)
        #expect(timeWithSingleDigit.description == "12:00:01.1")
    }

    @Test(.tags(.local_datetime))
    func `local date time basic formatting`() {
        let date = LocalDate(year: 1979, month: 5, day: 27)
        let time = LocalTime(hour: 7, minute: 32, second: 0, nanosecond: 0)
        let dateTime = LocalDateTime(date: date, time: time)
        #expect(dateTime.description == "1979-05-27T07:32:00")
        
        let timeWithFraction = LocalTime(hour: 7, minute: 32, second: 0, nanosecond: 999_000_000)
        let dateTimeWithFraction = LocalDateTime(date: date, time: timeWithFraction)
        #expect(dateTimeWithFraction.description == "1979-05-27T07:32:00.999")
    }

    @Test(.tags(.datetime))
    func `offset date time Z suffix formatting`() {
        let date = LocalDate(year: 1979, month: 5, day: 27)
        let time = LocalTime(hour: 7, minute: 32, second: 0, nanosecond: 0)
        let uppercaseZ = OffsetDateTime(date: date, time: time, offset: 0, features: [.uppercaseZ])
        #expect(uppercaseZ.description == "1979-05-27 07:32:00Z")
        
        let lowercaseZ = OffsetDateTime(date: date, time: time, offset: 0, features: [.uppercaseT, .lowercaseZ])
        #expect(lowercaseZ.description == "1979-05-27T07:32:00z")
    }

    @Test(.tags(.datetime))
    func `offset date time numeric offset formatting`() {
        let date = LocalDate(year: 1979, month: 5, day: 27)
        let time = LocalTime(hour: 0, minute: 32, second: 0, nanosecond: 0)
        
        let negativeOffset = OffsetDateTime(date: date, time: time, offset: -420, features: [.uppercaseT])
        #expect(negativeOffset.description == "1979-05-27T00:32:00-07:00")
        
        let positiveOffset = OffsetDateTime(date: date, time: time, offset: 330, features: [])
        #expect(positiveOffset.description == "1979-05-27 00:32:00+05:30")
        
        let zeroOffset = OffsetDateTime(date: date, time: time, offset: 0, features: [.uppercaseT])
        #expect(zeroOffset.description == "1979-05-27T00:32:00+00:00")
    }

    @Test(.tags(.datetime))
    func `offset date time lowercase T separator`() {
        let date = LocalDate(year: 1979, month: 5, day: 27)
        let time = LocalTime(hour: 7, minute: 32, second: 0, nanosecond: 0)
        
        let lowercaseT = OffsetDateTime(date: date, time: time, offset: 0, features: [.lowercaseT, .uppercaseZ])
        #expect(lowercaseT.description == "1979-05-27t07:32:00Z")
        
        let lowercaseTWithOffset = OffsetDateTime(date: date, time: time, offset: -300, features: [.lowercaseT])
        #expect(lowercaseTWithOffset.description == "1979-05-27t07:32:00-05:00")
    }

    @Test(.tags(.datetime))
    func `offset date time with fractional seconds`() {
        let date = LocalDate(year: 1979, month: 5, day: 27)
        let timeWithFraction = LocalTime(hour: 0, minute: 32, second: 0, nanosecond: 999_999_000)
        
        let offsetWithFraction = OffsetDateTime(date: date, time: timeWithFraction, offset: -420, features: [])
        #expect(offsetWithFraction.description == "1979-05-27 00:32:00.999999-07:00")
    }

    @Test(.tags(.datetime))
    func `offset date time validation with Z flags`() {
        let date = LocalDate(year: 1979, month: 5, day: 27)
        let time = LocalTime(hour: 7, minute: 32, second: 0, nanosecond: 0)
        
        // Valid: Z with zero offset
        let validZ = OffsetDateTime(date: date, time: time, offset: 0, features: [.uppercaseZ])
        #expect(validZ.isValid)
        
        // Invalid: Z with non-zero offset
        let invalidZ = OffsetDateTime(date: date, time: time, offset: -420, features: [.uppercaseZ])
        #expect(!invalidZ.isValid)
        
        // Valid: no Z with non-zero offset
        let validOffset = OffsetDateTime(date: date, time: time, offset: -420, features: [])
        #expect(validOffset.isValid)
    }
}
