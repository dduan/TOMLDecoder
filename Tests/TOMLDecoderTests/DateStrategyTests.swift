#if CodableSupport
import Foundation
import Testing
@testable import TOMLDecoder

@Suite
struct DateStrategyTests {
    @Test(.tags(.datetime))
    func datetimeAsDateByKey() throws {
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
            features: [.uppercaseT]
        )
        let result = try decoder.decode(Test.self, from: toml)
        #expect(result.datetime == expected)
    }

    @Test(.tags(.datetime))
    func datetimeAsDate() throws {
        struct Test: Decodable {
            let datetime: Date
        }

        let toml = """
        datetime = 2021-01-01T00:00:00.000567-12:34
        """

        let decoder = TOMLDecoder()
        let result = try decoder.decode(Test.self, from: toml)
        let expected = Date(timeIntervalSince1970: 1_609_504_440.000567)
        #expect(result.datetime == expected)
    }

    @Test(.tags(.datetime))
    func datetimeAsTimeIntervalSince1970() throws {
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
    func datetimeAsTimeIntervalSince2001() throws {
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
    func datetimeAsProlepticGregorianDate() throws {
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
    func datetimeAsCustomCalendar() throws {
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
    func datetimeWithStrictStrategy() throws {
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
    func datetimeAsOffsetDateTimeInArray() throws {
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
            features: [.uppercaseT]
        )
        let result = try decoder.decode(Test.self, from: toml)
        #expect(result.datetimes == [expected])
    }

    @Test(.tags(.datetime))
    func datetimeAsDateInArray() throws {
        struct Test: Decodable {
            let datetimes: [Date]
        }

        let toml = """
        datetimes = [ 2021-01-01T00:00:00.000567-12:34 ]
        """

        let decoder = TOMLDecoder()
        let result = try decoder.decode(Test.self, from: toml)
        let expected = Date(timeIntervalSince1970: 1_609_504_440.000567)
        #expect(result.datetimes == [expected])
    }

    @Test(.tags(.datetime))
    func datetimeAsTimeIntervalSince1970InArray() throws {
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
    func datetimeAsTimeIntervalSince2001InArray() throws {
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
    func datetimeAsProlepticGregorianDateInArray() throws {
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
    func datetimeAsCustomCalendarInArray() throws {
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
    func datetimeWithStrictStrategyInArray() throws {
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
#endif
