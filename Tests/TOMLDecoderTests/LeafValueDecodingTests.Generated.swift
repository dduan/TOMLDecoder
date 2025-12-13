//  WARNING: This file is generated from LeafValueDecodingTests.swift.gyb
//  Do not edit LeafValueDecodingTests.swift directly.

import Foundation
import Testing
import TOMLDecoder

@Suite
struct LeafValueDecodingTests {
    @Test func booleanAsBool() throws {
        struct Test: Decodable, Equatable {
            let boolean: Bool
            let booleans: [Bool]
            let aBoolean: ABool
            let optionalBoolean: Bool?
            let optionalBools: [Bool?]
            let optionalABool: ABool?
            let optionalBoolean2: Bool?
            let optionalABool2: ABool?
        }

        let toml = """
        boolean = true
        booleans = [true, false]
        aBoolean = true
        optionalBoolean = true
        optionalBools = [true, false]
        optionalABool = true
        """

        let result = try TOMLDecoder().decode(Test.self, from: toml)
        let expectation = Test(
            boolean: true,
            booleans: [true, false],
            aBoolean: .true,
            optionalBoolean: true,
            optionalBools: [true, false],
            optionalABool: .true,
            optionalBoolean2: nil,
            optionalABool2: nil
        )
        #expect(result == expectation)
    }

    @Test func stringAsString() throws {
        struct Test: Decodable, Equatable {
            let string: String
            let strings: [String]
            let aString: AString
            let optionalString: String?
            let optionalStrings: [String?]
            let optionalAString: AString?
            let optionalString2: String?
            let optionalAString2: AString?
        }

        let toml = """
        string = "foo"
        strings = ["foo", "bar"]
        aString = "foo"
        optionalString = "foo"
        optionalStrings = ["foo", "bar"]
        optionalAString = "foo"
        """

        let result = try TOMLDecoder().decode(Test.self, from: toml)
        let expectation = Test(
            string: "foo",
            strings: ["foo", "bar"],
            aString: .foo,
            optionalString: "foo",
            optionalStrings: ["foo", "bar"],
            optionalAString: .foo,
            optionalString2: nil,
            optionalAString2: nil
        )
        #expect(result == expectation)
    }

    @Test func integerAsInt() throws {
        struct Test: Decodable, Equatable {
            let integer: Int
            let integers: [Int]
            let aInteger: AInt
            let optionalInteger: Int?
            let optionalIntegers: [Int?]
            let optionalAInteger: AInt?
            let optionalInteger2: Int?
            let optionalAInteger2: AInt?
        }

        let toml = """
        integer = 0
        integers = [2, 3]
        aInteger = 2
        optionalInteger = 0
        optionalIntegers = [2, 3]
        optionalAInteger = 2
        """

        let result = try TOMLDecoder().decode(Test.self, from: toml)
        let expectation = Test(
            integer: 0,
            integers: [2, 3],
            aInteger: .foo,
            optionalInteger: 0,
            optionalIntegers: [2, 3],
            optionalAInteger: .foo,
            optionalInteger2: nil,
            optionalAInteger2: nil
        )
        #expect(result == expectation)
    }

    @Test func integerAsInt8() throws {
        struct Test: Decodable, Equatable {
            let integer: Int8
            let integers: [Int8]
            let aInteger: AInt8
            let optionalInteger: Int8?
            let optionalIntegers: [Int8?]
            let optionalAInteger: AInt8?
            let optionalInteger2: Int8?
            let optionalAInteger2: AInt8?
        }

        let toml = """
        integer = 0
        integers = [2, 3]
        aInteger = 2
        optionalInteger = 0
        optionalIntegers = [2, 3]
        optionalAInteger = 2
        """

        let result = try TOMLDecoder().decode(Test.self, from: toml)
        let expectation = Test(
            integer: 0,
            integers: [2, 3],
            aInteger: .foo,
            optionalInteger: 0,
            optionalIntegers: [2, 3],
            optionalAInteger: .foo,
            optionalInteger2: nil,
            optionalAInteger2: nil
        )
        #expect(result == expectation)
    }

    @Test func integerAsInt16() throws {
        struct Test: Decodable, Equatable {
            let integer: Int16
            let integers: [Int16]
            let aInteger: AInt16
            let optionalInteger: Int16?
            let optionalIntegers: [Int16?]
            let optionalAInteger: AInt16?
            let optionalInteger2: Int16?
            let optionalAInteger2: AInt16?
        }

        let toml = """
        integer = 0
        integers = [2, 3]
        aInteger = 2
        optionalInteger = 0
        optionalIntegers = [2, 3]
        optionalAInteger = 2
        """

        let result = try TOMLDecoder().decode(Test.self, from: toml)
        let expectation = Test(
            integer: 0,
            integers: [2, 3],
            aInteger: .foo,
            optionalInteger: 0,
            optionalIntegers: [2, 3],
            optionalAInteger: .foo,
            optionalInteger2: nil,
            optionalAInteger2: nil
        )
        #expect(result == expectation)
    }

    @Test func integerAsInt32() throws {
        struct Test: Decodable, Equatable {
            let integer: Int32
            let integers: [Int32]
            let aInteger: AInt32
            let optionalInteger: Int32?
            let optionalIntegers: [Int32?]
            let optionalAInteger: AInt32?
            let optionalInteger2: Int32?
            let optionalAInteger2: AInt32?
        }

        let toml = """
        integer = 0
        integers = [2, 3]
        aInteger = 2
        optionalInteger = 0
        optionalIntegers = [2, 3]
        optionalAInteger = 2
        """

        let result = try TOMLDecoder().decode(Test.self, from: toml)
        let expectation = Test(
            integer: 0,
            integers: [2, 3],
            aInteger: .foo,
            optionalInteger: 0,
            optionalIntegers: [2, 3],
            optionalAInteger: .foo,
            optionalInteger2: nil,
            optionalAInteger2: nil
        )
        #expect(result == expectation)
    }

    @Test func integerAsUInt() throws {
        struct Test: Decodable, Equatable {
            let integer: UInt
            let integers: [UInt]
            let aInteger: AUInt
            let optionalInteger: UInt?
            let optionalIntegers: [UInt?]
            let optionalAInteger: AUInt?
            let optionalInteger2: UInt?
            let optionalAInteger2: AUInt?
        }

        let toml = """
        integer = 0
        integers = [2, 3]
        aInteger = 2
        optionalInteger = 0
        optionalIntegers = [2, 3]
        optionalAInteger = 2
        """

        let result = try TOMLDecoder().decode(Test.self, from: toml)
        let expectation = Test(
            integer: 0,
            integers: [2, 3],
            aInteger: .foo,
            optionalInteger: 0,
            optionalIntegers: [2, 3],
            optionalAInteger: .foo,
            optionalInteger2: nil,
            optionalAInteger2: nil
        )
        #expect(result == expectation)
    }

    @Test func integerAsUInt8() throws {
        struct Test: Decodable, Equatable {
            let integer: UInt8
            let integers: [UInt8]
            let aInteger: AUInt8
            let optionalInteger: UInt8?
            let optionalIntegers: [UInt8?]
            let optionalAInteger: AUInt8?
            let optionalInteger2: UInt8?
            let optionalAInteger2: AUInt8?
        }

        let toml = """
        integer = 0
        integers = [2, 3]
        aInteger = 2
        optionalInteger = 0
        optionalIntegers = [2, 3]
        optionalAInteger = 2
        """

        let result = try TOMLDecoder().decode(Test.self, from: toml)
        let expectation = Test(
            integer: 0,
            integers: [2, 3],
            aInteger: .foo,
            optionalInteger: 0,
            optionalIntegers: [2, 3],
            optionalAInteger: .foo,
            optionalInteger2: nil,
            optionalAInteger2: nil
        )
        #expect(result == expectation)
    }

    @Test func integerAsUInt16() throws {
        struct Test: Decodable, Equatable {
            let integer: UInt16
            let integers: [UInt16]
            let aInteger: AUInt16
            let optionalInteger: UInt16?
            let optionalIntegers: [UInt16?]
            let optionalAInteger: AUInt16?
            let optionalInteger2: UInt16?
            let optionalAInteger2: AUInt16?
        }

        let toml = """
        integer = 0
        integers = [2, 3]
        aInteger = 2
        optionalInteger = 0
        optionalIntegers = [2, 3]
        optionalAInteger = 2
        """

        let result = try TOMLDecoder().decode(Test.self, from: toml)
        let expectation = Test(
            integer: 0,
            integers: [2, 3],
            aInteger: .foo,
            optionalInteger: 0,
            optionalIntegers: [2, 3],
            optionalAInteger: .foo,
            optionalInteger2: nil,
            optionalAInteger2: nil
        )
        #expect(result == expectation)
    }

    @Test func integerAsUInt32() throws {
        struct Test: Decodable, Equatable {
            let integer: UInt32
            let integers: [UInt32]
            let aInteger: AUInt32
            let optionalInteger: UInt32?
            let optionalIntegers: [UInt32?]
            let optionalAInteger: AUInt32?
            let optionalInteger2: UInt32?
            let optionalAInteger2: AUInt32?
        }

        let toml = """
        integer = 0
        integers = [2, 3]
        aInteger = 2
        optionalInteger = 0
        optionalIntegers = [2, 3]
        optionalAInteger = 2
        """

        let result = try TOMLDecoder().decode(Test.self, from: toml)
        let expectation = Test(
            integer: 0,
            integers: [2, 3],
            aInteger: .foo,
            optionalInteger: 0,
            optionalIntegers: [2, 3],
            optionalAInteger: .foo,
            optionalInteger2: nil,
            optionalAInteger2: nil
        )
        #expect(result == expectation)
    }

    @Test func integerAsUInt64() throws {
        struct Test: Decodable, Equatable {
            let integer: UInt64
            let integers: [UInt64]
            let aInteger: AUInt64
            let optionalInteger: UInt64?
            let optionalIntegers: [UInt64?]
            let optionalAInteger: AUInt64?
            let optionalInteger2: UInt64?
            let optionalAInteger2: AUInt64?
        }

        let toml = """
        integer = 0
        integers = [2, 3]
        aInteger = 2
        optionalInteger = 0
        optionalIntegers = [2, 3]
        optionalAInteger = 2
        """

        let result = try TOMLDecoder().decode(Test.self, from: toml)
        let expectation = Test(
            integer: 0,
            integers: [2, 3],
            aInteger: .foo,
            optionalInteger: 0,
            optionalIntegers: [2, 3],
            optionalAInteger: .foo,
            optionalInteger2: nil,
            optionalAInteger2: nil
        )
        #expect(result == expectation)
    }

    @Test func floatAsFloat() throws {
        struct Test: Decodable, Equatable {
            let float: Float
            let floats: [Float]
            let aFloat: AFloat
            let optionalFloat: Float?
            let optionalFloats: [Float?]
            let optionalAFloat: AFloat?
            let optionalFloat2: Float?
            let optionalAFloat2: AFloat?
        }

        let toml = """
        float = 3.14
        floats = [3.14, 3.15]
        aFloat = 3.14
        optionalFloat = 3.14
        optionalFloats = [3.14, 3.15]
        optionalAFloat = 3.14
        """

        let result = try TOMLDecoder().decode(Test.self, from: toml)
        let expectation = Test(
            float: 3.14,
            floats: [3.14, 3.15],
            aFloat: .thirtyOneFour,
            optionalFloat: 3.14,
            optionalFloats: [3.14, 3.15],
            optionalAFloat: .thirtyOneFour,
            optionalFloat2: nil,
            optionalAFloat2: nil
        )
        #expect(result == expectation)
    }

    @Test func floatAsDouble() throws {
        struct Test: Decodable, Equatable {
            let float: Double
            let floats: [Double]
            let aFloat: ADouble
            let optionalFloat: Double?
            let optionalFloats: [Double?]
            let optionalAFloat: ADouble?
            let optionalFloat2: Double?
            let optionalAFloat2: ADouble?
        }

        let toml = """
        float = 3.14
        floats = [3.14, 3.15]
        aFloat = 3.14
        optionalFloat = 3.14
        optionalFloats = [3.14, 3.15]
        optionalAFloat = 3.14
        """

        let result = try TOMLDecoder().decode(Test.self, from: toml)
        let expectation = Test(
            float: 3.14,
            floats: [3.14, 3.15],
            aFloat: .thirtyOneFour,
            optionalFloat: 3.14,
            optionalFloats: [3.14, 3.15],
            optionalAFloat: .thirtyOneFour,
            optionalFloat2: nil,
            optionalAFloat2: nil
        )
        #expect(result == expectation)
    }

    @Test func allTheNativeDates() throws {
        struct Test: Decodable, Equatable {
            let localDate: LocalDate
            let localDateFromLocalDateTime: LocalDate
            let localDateFromOffsetDateTime: LocalDate

            let optionalLocalDate: LocalDate?
            let optionalLocalDateFromLocalDateTime: LocalDate?
            let optionalLocalDateFromOffsetDateTime: LocalDate?

            let optionalLocalDate2: LocalDate?
            let optionalLocalDateFromLocalDateTime2: LocalDate?
            let optionalLocalDateFromOffsetDateTime2: LocalDate?

            let localTime: LocalTime
            let localTimeFromLocalDateTime: LocalTime
            let localTimeFromOffsetDateTime: LocalTime

            let optionalLocalTime: LocalTime?
            let optionalLocalTimeFromLocalDateTime: LocalTime?
            let optionalLocalTimeFromOffsetDateTime: LocalTime?

            let optionalLocalTime2: LocalTime?
            let optionalLocalTimeFromLocalDateTime2: LocalTime?
            let optionalLocalTimeFromOffsetDateTime2: LocalTime?

            let localDateTime: LocalDateTime
            let localDateTimeFromOffsetDateTime: LocalDateTime

            let optionalLocalDateTime: LocalDateTime?
            let optionalLocalDateTimeFromOffsetDateTime: LocalDateTime?

            let optionalLocalDateTime2: LocalDateTime?
            let optionalLocalDateTimeFromOffsetDateTime2: LocalDateTime?

            let offsetDateTime: OffsetDateTime
            let optionalOffsetDateTime: OffsetDateTime?
            let optionalOffsetDateTime2: OffsetDateTime?

            let date: Date
            let optionalDate: Date?
            let optionalDate2: Date?

            let dateComponents: DateComponents
            let dateComponentsFromOffsetDateTime: DateComponents
            let dateComponentsFromLocalDateTime: DateComponents
            let dateComponentsFromLocalTime: DateComponents
            let dateComponentsFromLocalDate: DateComponents

            let optionalDateComponents: DateComponents?
            let optionalDateComponentsFromOffsetDateTime: DateComponents?
            let optionalDateComponentsFromLocalDateTime: DateComponents?
            let optionalDateComponentsFromLocalTime: DateComponents?
            let optionalDateComponentsFromLocalDate: DateComponents?

            let optionalDateComponents2: DateComponents?
            let optionalDateComponentsFromOffsetDateTime2: DateComponents?
            let optionalDateComponentsFromLocalDateTime2: DateComponents?
            let optionalDateComponentsFromLocalTime2: DateComponents?
            let optionalDateComponentsFromLocalDate2: DateComponents?

            let localDates: [LocalDate]
            let localDateFromLocalDateTimes: [LocalDate]
            let localDateFromOffsetDateTimes: [LocalDate]

            let optionalLocalDates: [LocalDate?]
            let optionalLocalDateFromLocalDateTimes: [LocalDate?]
            let optionalLocalDateFromOffsetDateTimes: [LocalDate?]

            let localTimes: [LocalTime]
            let localTimeFromLocalDateTimes: [LocalTime]
            let localTimeFromOffsetDateTimes: [LocalTime]

            let optionalLocalTimes: [LocalTime?]
            let optionalLocalTimeFromLocalDateTimes: [LocalTime?]
            let optionalLocalTimeFromOffsetDateTimes: [LocalTime?]

            let localDateTimes: [LocalDateTime]
            let localDateTimeFromOffsetDateTimes: [LocalDateTime]

            let optionalLocalDateTimes: [LocalDateTime?]
            let optionalLocalDateTimeFromOffsetDateTimes: [LocalDateTime?]

            let offsetDateTimes: [OffsetDateTime]
            let optionalOffsetDateTimes: [OffsetDateTime?]

            let dates: [Date]
            let optionalDates: [Date?]

            let dateComponentss: [DateComponents]
            let dateComponentsFromOffsetDateTimes: [DateComponents]
            let dateComponentsFromLocalDateTimes: [DateComponents]
            let dateComponentsFromLocalTimes: [DateComponents]
            let dateComponentsFromLocalDates: [DateComponents]

            let optionalDateComponentss: [DateComponents?]
            let optionalDateComponentsFromOffsetDateTimes: [DateComponents?]
            let optionalDateComponentsFromLocalDateTimes: [DateComponents?]
            let optionalDateComponentsFromLocalTimes: [DateComponents?]
            let optionalDateComponentsFromLocalDates: [DateComponents?]
        }

        let toml = """
        localDate = 2001-01-01
        localDateFromLocalDateTime = 2001-01-01T01:00:01
        localDateFromOffsetDateTime = 2001-01-01T01:00:01Z

        optionalLocalDate = 2001-01-01
        optionalLocalDateFromLocalDateTime = 2001-01-01T01:00:01
        optionalLocalDateFromOffsetDateTime = 2001-01-01T01:00:01Z

        localTime = 01:00:01
        localTimeFromLocalDateTime = 2001-01-01T01:00:01
        localTimeFromOffsetDateTime = 2001-01-01T01:00:01Z

        optionalLocalTime = 01:00:01
        optionalLocalTimeFromLocalDateTime = 2001-01-01T01:00:01
        optionalLocalTimeFromOffsetDateTime = 2001-01-01T01:00:01Z

        localDateTime = 2001-01-01T01:00:01
        localDateTimeFromOffsetDateTime = 2001-01-01T01:00:01Z

        optionalLocalDateTime = 2001-01-01T01:00:01
        optionalLocalDateTimeFromOffsetDateTime = 2001-01-01T01:00:01Z

        offsetDateTime = 2001-01-01T01:00:01Z
        optionalOffsetDateTime = 2001-01-01T01:00:01Z

        date = 2001-01-01T01:00:01Z
        optionalDate = 2001-01-01T01:00:01Z

        dateComponents = 2001-01-01T01:00:01
        dateComponentsFromOffsetDateTime = 2001-01-01T01:00:01Z
        dateComponentsFromLocalDateTime = 2001-01-01T01:00:01
        dateComponentsFromLocalTime = 01:00:01
        dateComponentsFromLocalDate = 2001-01-01

        optionalDateComponents = 2001-01-01T01:00:01
        optionalDateComponentsFromOffsetDateTime = 2001-01-01T01:00:01Z
        optionalDateComponentsFromLocalDateTime = 2001-01-01T01:00:01
        optionalDateComponentsFromLocalTime = 01:00:01
        optionalDateComponentsFromLocalDate = 2001-01-01

        localDates = [2001-01-01]
        localDateFromLocalDateTimes = [2001-01-01T01:00:01]
        localDateFromOffsetDateTimes = [2001-01-01T01:00:01Z]

        optionalLocalDates = [2001-01-01]
        optionalLocalDateFromLocalDateTimes = [2001-01-01T01:00:01]
        optionalLocalDateFromOffsetDateTimes = [2001-01-01T01:00:01Z]

        localTimes = [01:00:01]
        localTimeFromLocalDateTimes = [2001-01-01T01:00:01]
        localTimeFromOffsetDateTimes = [2001-01-01T01:00:01Z]

        optionalLocalTimes = [01:00:01]
        optionalLocalTimeFromLocalDateTimes = [2001-01-01T01:00:01]
        optionalLocalTimeFromOffsetDateTimes = [2001-01-01T01:00:01Z]

        localDateTimes = [2001-01-01T01:00:01]
        localDateTimeFromOffsetDateTimes = [2001-01-01T01:00:01Z]

        optionalLocalDateTimes = [2001-01-01T01:00:01]
        optionalLocalDateTimeFromOffsetDateTimes = [2001-01-01T01:00:01Z]

        offsetDateTimes = [2001-01-01T01:00:01Z]
        optionalOffsetDateTimes = [2001-01-01T01:00:01Z]

        dates = [2001-01-01T01:00:01Z]
        optionalDates = [2001-01-01T01:00:01Z]

        dateComponentss = [2001-01-01T01:00:01]
        dateComponentsFromOffsetDateTimes = [2001-01-01T01:00:01Z]
        dateComponentsFromLocalDateTimes = [2001-01-01T01:00:01]
        dateComponentsFromLocalTimes = [01:00:01]
        dateComponentsFromLocalDates = [2001-01-01]

        optionalDateComponentss = [2001-01-01T01:00:01]
        optionalDateComponentsFromOffsetDateTimes = [2001-01-01T01:00:01Z]
        optionalDateComponentsFromLocalDateTimes = [2001-01-01T01:00:01]
        optionalDateComponentsFromLocalTimes = [01:00:01]
        optionalDateComponentsFromLocalDates = [2001-01-01]
        """

        let result = try TOMLDecoder().decode(Test.self, from: toml)
        let expectation = Test(
            localDate: LocalDate(year: 2001, month: 1, day: 1),
            localDateFromLocalDateTime: LocalDate(year: 2001, month: 1, day: 1),
            localDateFromOffsetDateTime: LocalDate(year: 2001, month: 1, day: 1),

            optionalLocalDate: LocalDate(year: 2001, month: 1, day: 1),
            optionalLocalDateFromLocalDateTime: LocalDate(year: 2001, month: 1, day: 1),
            optionalLocalDateFromOffsetDateTime: LocalDate(year: 2001, month: 1, day: 1),

            optionalLocalDate2: nil,
            optionalLocalDateFromLocalDateTime2: nil,
            optionalLocalDateFromOffsetDateTime2: nil,

            localTime: LocalTime(hour: 1, minute: 0, second: 1),
            localTimeFromLocalDateTime: LocalTime(hour: 1, minute: 0, second: 1),
            localTimeFromOffsetDateTime: LocalTime(hour: 1, minute: 0, second: 1),

            optionalLocalTime: LocalTime(hour: 1, minute: 0, second: 1),
            optionalLocalTimeFromLocalDateTime: LocalTime(hour: 1, minute: 0, second: 1),
            optionalLocalTimeFromOffsetDateTime: LocalTime(hour: 1, minute: 0, second: 1),

            optionalLocalTime2: nil,
            optionalLocalTimeFromLocalDateTime2: nil,
            optionalLocalTimeFromOffsetDateTime2: nil,

            localDateTime: LocalDateTime(date: LocalDate(year: 2001, month: 1, day: 1), time: LocalTime(hour: 1, minute: 0, second: 1)),
            localDateTimeFromOffsetDateTime: LocalDateTime(date: LocalDate(year: 2001, month: 1, day: 1), time: LocalTime(hour: 1, minute: 0, second: 1)),

            optionalLocalDateTime: LocalDateTime(date: LocalDate(year: 2001, month: 1, day: 1), time: LocalTime(hour: 1, minute: 0, second: 1)),
            optionalLocalDateTimeFromOffsetDateTime: LocalDateTime(date: LocalDate(year: 2001, month: 1, day: 1), time: LocalTime(hour: 1, minute: 0, second: 1)),

            optionalLocalDateTime2: nil,
            optionalLocalDateTimeFromOffsetDateTime2: nil,

            offsetDateTime: OffsetDateTime(date: LocalDate(year: 2001, month: 1, day: 1), time: LocalTime(hour: 1, minute: 0, second: 1), offset: 0, features: [.uppercaseT, .uppercaseZ]),
            optionalOffsetDateTime: OffsetDateTime(date: LocalDate(year: 2001, month: 1, day: 1), time: LocalTime(hour: 1, minute: 0, second: 1), offset: 0, features: [.uppercaseT, .uppercaseZ]),
            optionalOffsetDateTime2: nil,

            date: Date(timeIntervalSinceReferenceDate: 3601),
            optionalDate: Date(timeIntervalSinceReferenceDate: 3601),
            optionalDate2: nil,

            dateComponents: DateComponents(year: 2001, month: 1, day: 1, hour: 1, minute: 0, second: 1),
            dateComponentsFromOffsetDateTime: DateComponents(timeZone: TimeZone(secondsFromGMT: 0), year: 2001, month: 1, day: 1, hour: 1, minute: 0, second: 1),
            dateComponentsFromLocalDateTime: DateComponents(year: 2001, month: 1, day: 1, hour: 1, minute: 0, second: 1),
            dateComponentsFromLocalTime: DateComponents(hour: 1, minute: 0, second: 1),
            dateComponentsFromLocalDate: DateComponents(year: 2001, month: 1, day: 1),

            optionalDateComponents: DateComponents(year: 2001, month: 1, day: 1, hour: 1, minute: 0, second: 1),
            optionalDateComponentsFromOffsetDateTime: DateComponents(timeZone: TimeZone(secondsFromGMT: 0), year: 2001, month: 1, day: 1, hour: 1, minute: 0, second: 1),
            optionalDateComponentsFromLocalDateTime: DateComponents(year: 2001, month: 1, day: 1, hour: 1, minute: 0, second: 1),
            optionalDateComponentsFromLocalTime: DateComponents(hour: 1, minute: 0, second: 1),
            optionalDateComponentsFromLocalDate: DateComponents(year: 2001, month: 1, day: 1),

            optionalDateComponents2: nil,
            optionalDateComponentsFromOffsetDateTime2: nil,
            optionalDateComponentsFromLocalDateTime2: nil,
            optionalDateComponentsFromLocalTime2: nil,
            optionalDateComponentsFromLocalDate2: nil,

            localDates: [LocalDate(year: 2001, month: 1, day: 1)],
            localDateFromLocalDateTimes: [LocalDate(year: 2001, month: 1, day: 1)],
            localDateFromOffsetDateTimes: [LocalDate(year: 2001, month: 1, day: 1)],

            optionalLocalDates: [LocalDate(year: 2001, month: 1, day: 1)],
            optionalLocalDateFromLocalDateTimes: [LocalDate(year: 2001, month: 1, day: 1)],
            optionalLocalDateFromOffsetDateTimes: [LocalDate(year: 2001, month: 1, day: 1)],

            localTimes: [LocalTime(hour: 1, minute: 0, second: 1)],
            localTimeFromLocalDateTimes: [LocalTime(hour: 1, minute: 0, second: 1)],
            localTimeFromOffsetDateTimes: [LocalTime(hour: 1, minute: 0, second: 1)],

            optionalLocalTimes: [LocalTime(hour: 1, minute: 0, second: 1)],
            optionalLocalTimeFromLocalDateTimes: [LocalTime(hour: 1, minute: 0, second: 1)],
            optionalLocalTimeFromOffsetDateTimes: [LocalTime(hour: 1, minute: 0, second: 1)],

            localDateTimes: [LocalDateTime(date: LocalDate(year: 2001, month: 1, day: 1), time: LocalTime(hour: 1, minute: 0, second: 1))],
            localDateTimeFromOffsetDateTimes: [LocalDateTime(date: LocalDate(year: 2001, month: 1, day: 1), time: LocalTime(hour: 1, minute: 0, second: 1))],

            optionalLocalDateTimes: [LocalDateTime(date: LocalDate(year: 2001, month: 1, day: 1), time: LocalTime(hour: 1, minute: 0, second: 1))],
            optionalLocalDateTimeFromOffsetDateTimes: [LocalDateTime(date: LocalDate(year: 2001, month: 1, day: 1), time: LocalTime(hour: 1, minute: 0, second: 1))],

            offsetDateTimes: [OffsetDateTime(date: LocalDate(year: 2001, month: 1, day: 1), time: LocalTime(hour: 1, minute: 0, second: 1), offset: 0, features: [.uppercaseT, .uppercaseZ])],
            optionalOffsetDateTimes: [OffsetDateTime(date: LocalDate(year: 2001, month: 1, day: 1), time: LocalTime(hour: 1, minute: 0, second: 1), offset: 0, features: [.uppercaseT, .uppercaseZ])],

            dates: [Date(timeIntervalSinceReferenceDate: 3601)],
            optionalDates: [Date(timeIntervalSinceReferenceDate: 3601)],

            dateComponentss: [DateComponents(year: 2001, month: 1, day: 1, hour: 1, minute: 0, second: 1)],
            dateComponentsFromOffsetDateTimes: [DateComponents(timeZone: TimeZone(secondsFromGMT: 0), year: 2001, month: 1, day: 1, hour: 1, minute: 0, second: 1)],
            dateComponentsFromLocalDateTimes: [DateComponents(year: 2001, month: 1, day: 1, hour: 1, minute: 0, second: 1)],
            dateComponentsFromLocalTimes: [DateComponents(hour: 1, minute: 0, second: 1)],
            dateComponentsFromLocalDates: [DateComponents(year: 2001, month: 1, day: 1)],

            optionalDateComponentss: [DateComponents(year: 2001, month: 1, day: 1, hour: 1, minute: 0, second: 1)],
            optionalDateComponentsFromOffsetDateTimes: [DateComponents(timeZone: TimeZone(secondsFromGMT: 0), year: 2001, month: 1, day: 1, hour: 1, minute: 0, second: 1)],
            optionalDateComponentsFromLocalDateTimes: [DateComponents(year: 2001, month: 1, day: 1, hour: 1, minute: 0, second: 1)],
            optionalDateComponentsFromLocalTimes: [DateComponents(hour: 1, minute: 0, second: 1)],
            optionalDateComponentsFromLocalDates: [DateComponents(year: 2001, month: 1, day: 1)]
        )

        #expect(result == expectation)
    }
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
