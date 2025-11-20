import Testing
import TOMLDecoder

@Suite
struct DateTimeExactMatchTests {
    @Test(.tags(.local_date))
    func `local date exact match`() throws {
        let toml = """
        date = 2021-01-01
        date_with_time = 2021-01-01T01:02:03
        date_with_offset = 2021-01-01T01:02:03+01:00
        """

        let table = try TOMLTable(source: toml)
        let expectedDate = LocalDate(year: 2021, month: 1, day: 1)
        #expect(try table.localDate(forKey: "date", exactMatch: true) == expectedDate)
        #expect(try table.localDate(forKey: "date", exactMatch: false) == expectedDate)
        #expect(throws: TOMLError.self) { try table.localDate(forKey: "date_with_time", exactMatch: true) }
        #expect(try table.localDate(forKey: "date_with_time", exactMatch: false) == expectedDate)
        #expect(throws: TOMLError.self) { try table.localDate(forKey: "date_with_offset", exactMatch: true) }
        #expect(try table.localDate(forKey: "date_with_offset", exactMatch: false) == expectedDate)
    }

    @Test(.tags(.local_time))
    func `local time exact match`() throws {
        let toml = """
        time = 01:02:03
        time_with_date = 2021-01-01T01:02:03
        time_with_offset = 2021-01-01T01:02:03+01:00
        """

        let table = try TOMLTable(source: toml)
        let expectedTime = LocalTime(hour: 1, minute: 2, second: 3)
        #expect(try table.localTime(forKey: "time", exactMatch: true) == expectedTime)
        #expect(try table.localTime(forKey: "time", exactMatch: false) == expectedTime)
        #expect(throws: TOMLError.self) { try table.localTime(forKey: "time_with_date", exactMatch: true) }
        #expect(try table.localTime(forKey: "time_with_date", exactMatch: false) == expectedTime)
        #expect(throws: TOMLError.self) { try table.localTime(forKey: "time_with_offset", exactMatch: true) }
        #expect(try table.localTime(forKey: "time_with_offset", exactMatch: false) == expectedTime)
    }

    @Test(.tags(.local_datetime))
    func `local datetime exact match`() throws {
        let toml = """
        datetime = 2021-01-01T01:02:03
        datetime_with_offset = 2021-01-01T01:02:03+01:00
        """

        let table = try TOMLTable(source: toml)
        let expectedDateTime = LocalDateTime(date: LocalDate(year: 2021, month: 1, day: 1), time: LocalTime(hour: 1, minute: 2, second: 3))

        #expect(try table.localDateTime(forKey: "datetime", exactMatch: true) == expectedDateTime)
        #expect(try table.localDateTime(forKey: "datetime", exactMatch: false) == expectedDateTime)
        #expect(throws: TOMLError.self) { try table.localDateTime(forKey: "datetime_with_offset", exactMatch: true) }
        #expect(try table.localDateTime(forKey: "datetime_with_offset", exactMatch: false) == expectedDateTime)
    }

    @Test(.tags(.local_date, .array))
    func `local date exact match in array`() throws {
        let toml = """
        dates = [2021-01-01, 2021-01-01T01:02:03, 2021-01-01T01:02:03+01:00]
        """

        let table = try TOMLTable(source: toml)
        let expectedDate = LocalDate(year: 2021, month: 1, day: 1)
        let dates = try table.array(forKey: "dates")
        #expect(try dates.localDate(atIndex: 0, exactMatch: true) == expectedDate)
        #expect(try dates.localDate(atIndex: 0, exactMatch: false) == expectedDate)
        #expect(throws: TOMLError.self) { try dates.localDate(atIndex: 1, exactMatch: true) }
        #expect(try dates.localDate(atIndex: 1, exactMatch: false) == expectedDate)
        #expect(throws: TOMLError.self) { try dates.localDate(atIndex: 2, exactMatch: true) }
        #expect(try dates.localDate(atIndex: 2, exactMatch: false) == expectedDate)
    }

    @Test(.tags(.local_time, .array))
    func `local time exact match in array`() throws {
        let toml = """
        times = [01:02:03, 2021-01-01T01:02:03, 2021-01-01T01:02:03+01:00]
        """

        let table = try TOMLTable(source: toml)
        let expectedTime = LocalTime(hour: 1, minute: 2, second: 3)
        let times = try table.array(forKey: "times")
        #expect(try times.localTime(atIndex: 0, exactMatch: true) == expectedTime)
        #expect(try times.localTime(atIndex: 0, exactMatch: false) == expectedTime)
        #expect(throws: TOMLError.self) { try times.localTime(atIndex: 1, exactMatch: true) }
        #expect(try times.localTime(atIndex: 1, exactMatch: false) == expectedTime)
        #expect(throws: TOMLError.self) { try times.localTime(atIndex: 2, exactMatch: true) }
        #expect(try times.localTime(atIndex: 2, exactMatch: false) == expectedTime)
    }

    @Test(.tags(.local_datetime, .array))
    func `local datetime exact match in array`() throws {
        let toml = """
        datetimes = [2021-01-01T01:02:03, 2021-01-01T01:02:03+01:00]
        """

        let table = try TOMLTable(source: toml)
        let expectedDateTime = LocalDateTime(date: LocalDate(year: 2021, month: 1, day: 1), time: LocalTime(hour: 1, minute: 2, second: 3))
        let datetimes = try table.array(forKey: "datetimes")
        #expect(try datetimes.localDateTime(atIndex: 0, exactMatch: true) == expectedDateTime)
        #expect(try datetimes.localDateTime(atIndex: 0, exactMatch: false) == expectedDateTime)
        #expect(throws: TOMLError.self) { try datetimes.localDateTime(atIndex: 1, exactMatch: true) }
        #expect(try datetimes.localDateTime(atIndex: 1, exactMatch: false) == expectedDateTime)
    }
}
