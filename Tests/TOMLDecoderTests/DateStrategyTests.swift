import Foundation
import Testing
@testable import TOMLDecoder

@Suite
struct DateStrategyTests {
    var rfc3339Style: Date.ISO8601FormatStyle {
        Date.ISO8601FormatStyle()
            .year()
            .month()
            .day()
            .time(includingFractionalSeconds: true)
            .timeZone(separator: .omitted)
    }

    @Test(.tags(.datetime))
    func `datetime as Date by key`() throws {
        struct Test: Decodable {
            let datetime: OffsetDateTime
        }

        let toml = """
        datetime = 2021-01-01T00:00:00.000567-12:34
        """

        let decoder = TOMLDecoder()
        let expected = OffsetDateTime(
            date: LocalDate(year: 2021, month: 1, day: 1),
            time: LocalTime(hour: 0, minute: 0, second: 0, nanosecond: 567_000),
            offset: -754, // minutes
            features: [.uppercaseT],
        )
        let result = try decoder.decode(Test.self, from: toml)
        #expect(result.datetime == expected)
    }

    @Test(.tags(.datetime))
    func `datetime as Date`() throws {
        struct Test: Decodable {
            let datetime: Date
        }

        let toml = """
        datetime = 2021-01-01T00:00:00.000567-12:34
        """

        let decoder = TOMLDecoder()
        let result = try decoder.decode(Test.self, from: toml)
        let expected = try rfc3339Style.parse("2021-01-01T00:00:00.000567-12:34")
        #expect(result.datetime == expected)
    }

    @Test(.tags(.datetime))
    func `datetime as time interval since 1970`() throws {
        struct Test: Decodable {
            let datetime: TimeInterval
        }

        let toml = """
        datetime = 2021-01-01T00:00:00.000567-12:34
        """

        var decoder = TOMLDecoder()
        decoder.strategy.timeInterval = .since1970
        let result = try decoder.decode(Test.self, from: toml)
        #expect(result.datetime == 1_609_504_440.000567)
    }

    @Test(.tags(.datetime))
    func `datetime as time interval since 2001`() throws {
        struct Test: Decodable {
            let datetime: TimeInterval
        }

        let toml = """
        datetime = 2021-01-01T00:00:00.000567-12:34
        """

        var decoder = TOMLDecoder()
        decoder.strategy.timeInterval = .since2001
        let result = try decoder.decode(Test.self, from: toml)
        #expect(result.datetime == 631_197_240.000567)
    }

    @Test(.tags(.datetime))
    func `datetime as proleptic Gregorian date`() throws {
        struct Test: Decodable {
            let datetime: Date
        }

        let toml = """
        datetime = 0021-01-01T00:00:00.000567-12:34
        """

        var decoder = TOMLDecoder()
        decoder.strategy.date = .prolepticGregorianCalendar
        let result = try decoder.decode(Test.self, from: toml)
        #expect(result.datetime.timeIntervalSince1970 == -61_504_399_559.999435)
    }

    @Test(.tags(.datetime))
    func `datetime as custom calendar`() throws {
        struct Test: Decodable {
            let datetime: Date
        }

        let toml = """
        datetime = 2021-01-01T00:00:00.000567-12:34
        """

        var decoder = TOMLDecoder()
        decoder.strategy.date = .calendar(identifiedBy: .gregorian)
        let result = try decoder.decode(Test.self, from: toml)
        #expect(result.datetime.timeIntervalSince1970 == 1_609_504_440.000567)
    }

    @Test(.tags(.datetime))
    func `datetime with strict strategy`() throws {
        struct Test: Decodable {
            let datetime: Date
        }

        let toml = """
        datetime = 2021-01-01T00:00:00.000567-12:34
        """

        var decoder = TOMLDecoder()
        decoder.isLenient = false

        #expect(throws: (any Error).self) {
            try decoder.decode(Test.self, from: toml)
        }
    }

    @Test(.tags(.datetime))
    func `datetime as OffsetDateTime in array`() throws {
        struct Test: Decodable {
            let datetimes: [OffsetDateTime]
        }

        let toml = """
        datetimes = [ 2021-01-01T00:00:00.000567-12:34 ]
        """

        let decoder = TOMLDecoder()
        let expected = OffsetDateTime(
            date: LocalDate(year: 2021, month: 1, day: 1),
            time: LocalTime(hour: 0, minute: 0, second: 0, nanosecond: 567_000),
            offset: -754, // minutes
            features: [.uppercaseT],
        )
        let result = try decoder.decode(Test.self, from: toml)
        #expect(result.datetimes == [expected])
    }

    @Test(.tags(.datetime))
    func `datetime as Date in array`() throws {
        struct Test: Decodable {
            let datetimes: [Date]
        }

        let toml = """
        datetimes = [ 2021-01-01T00:00:00.000567-12:34 ]
        """

        let decoder = TOMLDecoder()
        let result = try decoder.decode(Test.self, from: toml)
        let expected = try rfc3339Style.parse("2021-01-01T00:00:00.000567-12:34")
        #expect(result.datetimes == [expected])
    }

    @Test(.tags(.datetime))
    func `datetime as time interval since 1970 in array`() throws {
        struct Test: Decodable {
            let datetimes: [TimeInterval]
        }

        let toml = """
        datetimes = [ 2021-01-01T00:00:00.000567-12:34 ]
        """

        var decoder = TOMLDecoder()
        decoder.strategy.timeInterval = .since1970
        let result = try decoder.decode(Test.self, from: toml)
        #expect(result.datetimes == [1_609_504_440.000567])
    }

    @Test(.tags(.datetime))
    func `datetime as time interval since 2001 in array`() throws {
        struct Test: Decodable {
            let datetimes: [TimeInterval]
        }

        let toml = """
        datetimes = [ 2021-01-01T00:00:00.000567-12:34 ]
        """

        var decoder = TOMLDecoder()
        decoder.strategy.timeInterval = .since2001
        let result = try decoder.decode(Test.self, from: toml)
        #expect(result.datetimes == [631_197_240.000567])
    }

    @Test(.tags(.datetime))
    func `datetime as proleptic Gregorian date in array`() throws {
        struct Test: Decodable {
            let datetimes: [Date]
        }

        let toml = """
        datetimes = [ 0021-01-01T00:00:00.000567-12:34 ]
        """

        var decoder = TOMLDecoder()
        decoder.strategy.date = .prolepticGregorianCalendar
        let result = try decoder.decode(Test.self, from: toml)
        #expect(result.datetimes.map(\.timeIntervalSince1970) == [-61_504_399_559.999435])
    }

    @Test(.tags(.datetime))
    func `datetime as custom calendar in array`() throws {
        struct Test: Decodable {
            let datetimes: [Date]
        }

        let toml = """
        datetimes = [ 2021-01-01T00:00:00.000567-12:34 ]
        """

        var decoder = TOMLDecoder()
        decoder.strategy.date = .calendar(identifiedBy: .gregorian)
        let result = try decoder.decode(Test.self, from: toml)
        #expect(result.datetimes.map(\.timeIntervalSince1970) == [1_609_504_440.000567])
    }

    @Test(.tags(.datetime))
    func `datetime with strict strategy in array`() throws {
        struct Test: Decodable {
            let datetimes: [Date]
        }

        let toml = """
        datetimes = [ 2021-01-01T00:00:00.000567-12:34 ]
        """

        var decoder = TOMLDecoder()
        decoder.isLenient = false

        #expect(throws: (any Error).self) {
            try decoder.decode(Test.self, from: toml).datetimes.map(\.timeIntervalSince1970) == [1_609_504_440.000567]
        }
    }
}
