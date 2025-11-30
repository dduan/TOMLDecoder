import Foundation
import Testing
import TOMLDecoder

private enum ABool: Decodable, Equatable {
    case `true`
    case `false`

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let bool = try container.decode(Bool.self)
        self = bool ? .`true` : .`false`
    }
}

private enum AString: String, Decodable, Equatable {
    case foo
    case bar
}

private enum AInt: Int, Decodable, Equatable {
    case foo = 2
}

private enum AInt8: Int8, Decodable, Equatable {
    case foo = 2
}

private enum AInt16: Int16, Decodable, Equatable {
    case foo = 2
}

private enum AInt32: Int32, Decodable, Equatable {
    case foo = 2
}

private enum AUInt: UInt, Decodable, Equatable {
    case foo = 2
}

private enum AUInt8: UInt8, Decodable, Equatable {
    case foo = 2
}

private enum AUInt16: UInt16, Decodable, Equatable {
    case foo = 2
}

private enum AUInt32: UInt32, Decodable, Equatable {
    case foo = 2
}

private enum AUInt64: UInt64, Decodable, Equatable {
    case foo = 2
}

private enum AFloat: Float, Decodable, Equatable {
    case thirtyOneFour = 3.14
}

private enum ADouble: Double, Decodable, Equatable {
    case thirtyOneFour = 3.14
}

@Suite
struct LeafValueDecodingTests {
    @Test func `boolean as Bool`() throws {
        struct Test: Decodable, Equatable {
            let boolean: Bool
            let booleans: [Bool]
            let aBoolean: ABool
        }

        let toml = """
        boolean = true
        booleans = [true, false]
        aBoolean = true
        """

        let result = try TOMLDecoder().decode(Test.self, from: toml)
        let expectation = Test(boolean: true, booleans: [true, false], aBoolean: .`true`)
        #expect(result == expectation)
    }

    @Test func `string as String`() throws {
        struct Test: Decodable, Equatable {
            let string: String
            let strings: [String]
            let aString: AString
        }

        let toml = """
        string = "foo"
        strings = ["foo", "bar"]
        aString = "foo"
        """

        let result = try TOMLDecoder().decode(Test.self, from: toml)
        let expectation = Test(string: "foo", strings: ["foo", "bar"], aString: .foo)
        #expect(result == expectation)
    }

    @Test func `integer as Int`() throws {
        struct Test: Decodable, Equatable {
            let integer: Int
            let integers: [Int]
            let aInteger: AInt
        }

        let toml = """
        integer = 0
        integers = [2, 3]
        aInteger = 2
        """

        let result = try TOMLDecoder().decode(Test.self, from: toml)
        let expectation = Test(integer: 0, integers: [2, 3], aInteger: .foo)
        #expect(result == expectation)
    }

    @Test func `integer as Int8`() throws {
        struct Test: Decodable, Equatable {
            let integer: Int8
            let integers: [Int8]
            let aInteger: AInt8
        }

        let toml = """
        integer = 0
        integers = [2, 3]
        aInteger = 2
        """

        let result = try TOMLDecoder().decode(Test.self, from: toml)
        let expectation = Test(integer: 0, integers: [2, 3], aInteger: .foo)
        #expect(result == expectation)
    }

    @Test func `integer as Int16`() throws {
        struct Test: Decodable, Equatable {
            let integer: Int16
            let integers: [Int16]
            let aInteger: AInt16
        }

        let toml = """
        integer = 0
        integers = [2, 3]
        aInteger = 2
        """

        let result = try TOMLDecoder().decode(Test.self, from: toml)
        let expectation = Test(integer: 0, integers: [2, 3], aInteger: .foo)
        #expect(result == expectation)
    }

    @Test func `integer as Int32`() throws {
        struct Test: Decodable, Equatable {
            let integer: Int32
            let integers: [Int32]
            let aInteger: AInt32
        }

        let toml = """
        integer = 0
        integers = [2, 3]
        aInteger = 2
        """

        let result = try TOMLDecoder().decode(Test.self, from: toml)
        let expectation = Test(integer: 0, integers: [2, 3], aInteger: .foo)
        #expect(result == expectation)
    }

    @Test func `integer as UInt`() throws {
        struct Test: Decodable, Equatable {
            let integer: UInt
            let integers: [UInt]
            let aInteger: AUInt
        }

        let toml = """
        integer = 0
        integers = [2, 3]
        aInteger = 2
        """

        let result = try TOMLDecoder().decode(Test.self, from: toml)
        let expectation = Test(integer: 0, integers: [2, 3], aInteger: .foo)
        #expect(result == expectation)
    }

    @Test func `integer as UInt8`() throws {
        struct Test: Decodable, Equatable {
            let integer: UInt8
            let integers: [UInt8]
            let aInteger: AUInt8
        }

        let toml = """
        integer = 0
        integers = [2, 3]
        aInteger = 2
        """

        let result = try TOMLDecoder().decode(Test.self, from: toml)
        let expectation = Test(integer: 0, integers: [2, 3], aInteger: .foo)
        #expect(result == expectation)
    }

    @Test func `integer as UInt16`() throws {
        struct Test: Decodable, Equatable {
            let integer: UInt16
            let integers: [UInt16]
            let aInteger: AUInt16
        }

        let toml = """
        integer = 0
        integers = [2, 3]
        aInteger = 2
        """

        let result = try TOMLDecoder().decode(Test.self, from: toml)
        let expectation = Test(integer: 0, integers: [2, 3], aInteger: .foo)
        #expect(result == expectation)
    }

    @Test func `integer as UInt32`() throws {
        struct Test: Decodable, Equatable {
            let integer: UInt32
            let integers: [UInt32]
            let aInteger: AUInt32
        }

        let toml = """
        integer = 0
        integers = [2, 3]
        aInteger = 2
        """

        let result = try TOMLDecoder().decode(Test.self, from: toml)
        let expectation = Test(integer: 0, integers: [2, 3], aInteger: .foo)
        #expect(result == expectation)
    }

    @Test func `integer as UInt64`() throws {
        struct Test: Decodable, Equatable {
            let integer: UInt64
            let integers: [UInt64]
            let aInteger: AUInt64
        }

        let toml = """
        integer = 0
        integers = [2, 3]
        aInteger = 2
        """

        let result = try TOMLDecoder().decode(Test.self, from: toml)
        let expectation = Test(integer: 0, integers: [2, 3], aInteger: .foo)
        #expect(result == expectation)
    }

    @Test func `float as Float`() throws {
        struct Test: Decodable, Equatable {
            let float: Float
            let floats: [Float]
            let aFloat: AFloat
        }

        let toml = """
        float = 3.14
        floats = [3.14, 3.15]
        aFloat = 3.14
        """

        let result = try TOMLDecoder().decode(Test.self, from: toml)
        let expectation = Test(float: 3.14, floats: [3.14, 3.15], aFloat: .thirtyOneFour)
        #expect(result == expectation)
    }

    @Test func `float as Double`() throws {
        struct Test: Decodable, Equatable {
            let float: Double
            let floats: [Double]
            let aFloat: ADouble
        }

        let toml = """
        float = 3.14
        floats = [3.14, 3.15]
        aFloat = 3.14
        """

        let result = try TOMLDecoder().decode(Test.self, from: toml)
        let expectation = Test(float: 3.14, floats: [3.14, 3.15], aFloat: .thirtyOneFour)
        #expect(result == expectation)
    }

    @Test func `all the native dates`() throws {
        struct Test: Decodable, Equatable {
            let localDate: LocalDate
            let localDateFromLocalDateTime: LocalDate
            let localDateFromOffsetDateTime: LocalDate

            let localTime: LocalTime
            let localTimeFromLocalDateTime: LocalTime
            let localTimeFromOffsetDateTime: LocalTime

            let localDateTime: LocalDateTime
            let localDateTimeFromOffsetDateTime: LocalDateTime

            let offsetDateTime: OffsetDateTime

            let date: Date

            let dateComponents: DateComponents
            let dateComponentsFromOffsetDateTime: DateComponents
            let dateComponentsFromLocalDateTime: DateComponents
            let dateComponentsFromLocalTime: DateComponents
            let dateComponentsFromLocalDate: DateComponents

            let localDates: [LocalDate]
            let localDateFromLocalDateTimes: [LocalDate]
            let localDateFromOffsetDateTimes: [LocalDate]

            let localTimes: [LocalTime]
            let localTimeFromLocalDateTimes: [LocalTime]
            let localTimeFromOffsetDateTimes: [LocalTime]

            let localDateTimes: [LocalDateTime]
            let localDateTimeFromOffsetDateTimes: [LocalDateTime]

            let offsetDateTimes: [OffsetDateTime]

            let dates: [Date]

            let dateComponentss: [DateComponents]
            let dateComponentsFromOffsetDateTimes: [DateComponents]
            let dateComponentsFromLocalDateTimes: [DateComponents]
            let dateComponentsFromLocalTimes: [DateComponents]
            let dateComponentsFromLocalDates: [DateComponents]
        }

        let toml = """
        localDate = 2001-01-01
        localDateFromLocalDateTime = 2001-01-01T01:00:01
        localDateFromOffsetDateTime = 2001-01-01T01:00:01Z

        localTime = 01:00:01
        localTimeFromLocalDateTime = 2001-01-01T01:00:01
        localTimeFromOffsetDateTime = 2001-01-01T01:00:01Z

        localDateTime = 2001-01-01T01:00:01
        localDateTimeFromOffsetDateTime = 2001-01-01T01:00:01Z

        offsetDateTime = 2001-01-01T01:00:01Z

        date = 2001-01-01T01:00:01Z

        dateComponents = 2001-01-01T01:00:01
        dateComponentsFromOffsetDateTime = 2001-01-01T01:00:01Z
        dateComponentsFromLocalDateTime = 2001-01-01T01:00:01
        dateComponentsFromLocalTime = 01:00:01
        dateComponentsFromLocalDate = 2001-01-01


        localDates = [2001-01-01]
        localDateFromLocalDateTimes = [2001-01-01T01:00:01]
        localDateFromOffsetDateTimes = [2001-01-01T01:00:01Z]

        localTimes = [01:00:01]
        localTimeFromLocalDateTimes = [2001-01-01T01:00:01]
        localTimeFromOffsetDateTimes = [2001-01-01T01:00:01Z]

        localDateTimes = [2001-01-01T01:00:01]
        localDateTimeFromOffsetDateTimes = [2001-01-01T01:00:01Z]

        offsetDateTimes = [2001-01-01T01:00:01Z]

        dates = [2001-01-01T01:00:01Z]

        dateComponentss = [2001-01-01T01:00:01]
        dateComponentsFromOffsetDateTimes = [2001-01-01T01:00:01Z]
        dateComponentsFromLocalDateTimes = [2001-01-01T01:00:01]
        dateComponentsFromLocalTimes = [01:00:01]
        dateComponentsFromLocalDates = [2001-01-01]
        """

        let result = try TOMLDecoder().decode(Test.self, from: toml)
        let expectation = Test(
            localDate: LocalDate(year: 2001, month: 1, day: 1),
            localDateFromLocalDateTime: LocalDate(year: 2001, month: 1, day: 1),
            localDateFromOffsetDateTime: LocalDate(year: 2001, month: 1, day: 1),

            localTime: LocalTime(hour: 1, minute: 0, second: 1),
            localTimeFromLocalDateTime: LocalTime(hour: 1, minute: 0, second: 1),
            localTimeFromOffsetDateTime: LocalTime(hour: 1, minute: 0, second: 1),

            localDateTime: LocalDateTime(date: LocalDate(year: 2001, month: 1, day: 1), time: LocalTime(hour: 1, minute: 0, second: 1)),
            localDateTimeFromOffsetDateTime: LocalDateTime(date: LocalDate(year: 2001, month: 1, day: 1), time: LocalTime(hour: 1, minute: 0, second: 1)),

            offsetDateTime: OffsetDateTime(date: LocalDate(year: 2001, month: 1, day: 1), time: LocalTime(hour: 1, minute: 0, second: 1), offset: 0, features: [.uppercaseT, .uppercaseZ]),

            date: Date(timeIntervalSinceReferenceDate: 3601),

            dateComponents: DateComponents(year: 2001, month: 1, day: 1, hour: 1, minute: 0, second: 1),
            dateComponentsFromOffsetDateTime: DateComponents(timeZone: TimeZone(secondsFromGMT: 0), year: 2001, month: 1, day: 1, hour: 1, minute: 0, second: 1),
            dateComponentsFromLocalDateTime: DateComponents(year: 2001, month: 1, day: 1, hour: 1, minute: 0, second: 1),
            dateComponentsFromLocalTime: DateComponents(hour: 1, minute: 0, second: 1),
            dateComponentsFromLocalDate: DateComponents(year: 2001, month: 1, day: 1),

            localDates: [LocalDate(year: 2001, month: 1, day: 1)],
            localDateFromLocalDateTimes: [LocalDate(year: 2001, month: 1, day: 1)],
            localDateFromOffsetDateTimes: [LocalDate(year: 2001, month: 1, day: 1)],

            localTimes: [LocalTime(hour: 1, minute: 0, second: 1)],
            localTimeFromLocalDateTimes: [LocalTime(hour: 1, minute: 0, second: 1)],
            localTimeFromOffsetDateTimes: [LocalTime(hour: 1, minute: 0, second: 1)],

            localDateTimes: [LocalDateTime(date: LocalDate(year: 2001, month: 1, day: 1), time: LocalTime(hour: 1, minute: 0, second: 1))],
            localDateTimeFromOffsetDateTimes: [LocalDateTime(date: LocalDate(year: 2001, month: 1, day: 1), time: LocalTime(hour: 1, minute: 0, second: 1))],

            offsetDateTimes: [OffsetDateTime(date: LocalDate(year: 2001, month: 1, day: 1), time: LocalTime(hour: 1, minute: 0, second: 1), offset: 0, features: [.uppercaseT, .uppercaseZ])],

            dates: [Date(timeIntervalSinceReferenceDate: 3601)],

            dateComponentss: [DateComponents(year: 2001, month: 1, day: 1, hour: 1, minute: 0, second: 1)],
            dateComponentsFromOffsetDateTimes: [DateComponents(timeZone: TimeZone(secondsFromGMT: 0), year: 2001, month: 1, day: 1, hour: 1, minute: 0, second: 1)],
            dateComponentsFromLocalDateTimes: [DateComponents(year: 2001, month: 1, day: 1, hour: 1, minute: 0, second: 1)],
            dateComponentsFromLocalTimes: [DateComponents(hour: 1, minute: 0, second: 1)],
            dateComponentsFromLocalDates: [DateComponents(year: 2001, month: 1, day: 1)],
        )

        #expect(result == expectation)
    }
}
