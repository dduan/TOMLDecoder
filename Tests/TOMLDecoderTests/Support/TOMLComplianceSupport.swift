import Foundation
import ProlepticGregorianTestHelpers
import Testing
import TOMLDecoder

/// The Foundation does not use a gregorian calendar for dates prior to the cutoff on 1582-10-04.
/// To get a strict proleptic Gregorian calendar per RFC 8949 §3.4.1.2, we use the ProlepticGregorianTestHelpers module
func epochSecondsViaProlepticHelper(
    year: Int, month: Int = 1, day: Int = 1,
    hour: Int = 0, minute: Int = 0, second: Int = 0
) -> Int64 {
    hh_proleptic_seconds_since_unix_epoch(
        Int32(year), Int32(month), Int32(day),
        Int32(hour), Int32(minute), Int32(second)
    )
}

enum DateTimeType {
    case localDateTime
    case localDate
    case localTime
}

enum TOMLComplianceSupport {
    static func verifyValidFixture(jsonURL: URL, tomlURL: URL, sourceLocation: SourceLocation) throws {
        do {
            let jsonData = try Data(contentsOf: jsonURL)
            let expected = try JSONSerialization.jsonObject(with: jsonData)
            let tomlData = try Data(contentsOf: tomlURL)
            let actual = try Dictionary(TOMLTable(source: tomlData))
            let failure = compare(expected: expected, actual: actual)
            #expect(failure == nil, "\(failure ?? "")", sourceLocation: sourceLocation)
        } catch {
            Issue.record("\(error)")
        }
    }

    static func verifyInvalidFixture(tomlURL: URL, sourceLocation: SourceLocation) throws {
        let tomlData = try Data(contentsOf: tomlURL)
        #expect(throws: (any Error).self, sourceLocation: sourceLocation) {
            try Dictionary(TOMLTable(source: tomlData))
        }
    }

    private static func compare(expected: Any, actual: Any, path: [String] = []) -> String? {
        if let expectedDict = expected as? [String: Any] {
            if let type = expectedDict["type"] as? String {
                return compareValue(expectedDict, actual: actual, type: type, path: path)
            }

            guard let actualDict = actual as? [String: Any] else {
                return "Expected table at \(pathDescription(path)), found \(actual)"
            }

            let expectedKeys = Set(expectedDict.keys)
            let actualKeys = Set(actualDict.keys)

            if let missing = expectedKeys.subtracting(actualKeys).sorted().first {
                return "Missing key \(pathDescription(path + [missing]))"
            }

            if let extra = actualKeys.subtracting(expectedKeys).sorted().first {
                return "Unexpected key \(pathDescription(path + [extra]))"
            }

            for key in expectedKeys.sorted() {
                guard let expectedValue = expectedDict[key], let actualValue = actualDict[key] else {
                    continue
                }
                if let failure = compare(expected: expectedValue, actual: actualValue, path: path + [key]) {
                    return failure
                }
            }
            return nil
        }

        if let expectedArray = expected as? [Any] {
            guard let actualArray = actual as? [Any] else {
                return "Expected array at \(pathDescription(path)), found \(actual)"
            }

            if expectedArray.count != actualArray.count {
                return "Array length mismatch at \(pathDescription(path)): expected \(expectedArray.count), got \(actualArray.count)"
            }

            for index in expectedArray.indices {
                if let failure = compare(expected: expectedArray[index], actual: actualArray[index], path: path + ["[\(index)]"]) {
                    return failure
                }
            }

            return nil
        }

        return "Unsupported expected structure at \(pathDescription(path))"
    }

    private static func compareValue(_ expected: [String: Any], actual: Any, type: String, path: [String]) -> String? {
        let location = pathDescription(path)
        switch type {
        case "string":
            guard let expectedValue = expected["value"] as? String else {
                return "Missing expected string at \(location)"
            }
            guard let actualString = actual as? String else {
                return "Expected string at \(location), found \(actual)"
            }
            let normalised = actualString.replacingOccurrences(of: "\r\n", with: "\n")
            let expectedNormalised = expectedValue.replacingOccurrences(of: "\r\n", with: "\n")
            if normalised != expectedNormalised {
                return "String mismatch at \(location): expected \(expectedNormalised), got \(normalised)"
            }
            return nil

        case "bool":
            guard let expectedValue = (expected["value"] as? String)?.lowercased() else {
                return "Missing expected bool at \(location)"
            }
            let actualBool = actual as? Bool

            guard let actualBool else {
                return "Expected bool at \(location), found \(actual)"
            }

            let actualValue = actualBool ? "true" : "false"
            if actualValue != expectedValue {
                return "Boolean mismatch at \(location): expected \(expectedValue), got \(actualValue)"
            }
            return nil

        case "integer":
            guard let expectedString = expected["value"] as? String, let expectedValue = Int64(expectedString) else {
                return "Missing expected integer at \(location)"
            }
            guard let actualValue = actual as? Int64 else {
                return "Expected integer at \(location), found \(actual)"
            }
            if actualValue != expectedValue {
                return "Integer mismatch at \(location): expected \(expectedValue), got \(actualValue)"
            }
            return nil

        case "float":
            guard let expectedString = expected["value"] as? String else {
                return "Missing expected float at \(location)"
            }
            guard let actualValue = actual as? Double else {
                return "Expected float at \(location), found \(actual)"
            }

            let lower = expectedString.lowercased()
            if lower == "inf" || lower == "+inf" {
                return actualValue.isInfinite && actualValue > 0 ? nil : "Float mismatch at \(location): expected +inf, got \(actualValue)"
            }
            if lower == "-inf" {
                return actualValue.isInfinite && actualValue < 0 ? nil : "Float mismatch at \(location): expected -inf, got \(actualValue)"
            }
            if lower.hasSuffix("nan") {
                return actualValue.isNaN ? nil : "Float mismatch at \(location): expected NaN, got \(actualValue)"
            }

            guard let expectedValue = Double(expectedString) else {
                return "Unable to parse expected float at \(location)"
            }

            if actualValue != expectedValue {
                return "Float mismatch at \(location): expected \(expectedValue), got \(actualValue)"
            }
            return nil

        case "datetime":
            guard let expectedString = expected["value"] as? String else {
                return "Missing expected datetime at \(location)"
            }
            guard let actualDateTime = actual as? OffsetDateTime else {
                return "Expected offset datetime at \(location), found \(actual)"
            }
            guard let expectedDate = parseDate(expectedString) else {
                return "Unable to parse expected datetime at \(location)"
            }
            if actualDateTime.timeIntervalSince1970 - expectedDate.timeIntervalSince1970 > 0.0000001 {
                return "Datetime mismatch at \(location): expected \(expectedDate.timeIntervalSince1970) \(expectedString), got \(actualDateTime.timeIntervalSince1970) [\(actualDateTime)]"
            }
            return nil

        case "datetime-local":
            return compareLocalDateTime(expected, actual: actual, path: path, type: .localDateTime)

        case "date-local":
            return compareLocalDateTime(expected, actual: actual, path: path, type: .localDate)

        case "time-local":
            return compareLocalDateTime(expected, actual: actual, path: path, type: .localTime)

        default:
            return "Unsupported type \(type) at \(location)"
        }
    }

    private static func compareLocalDateTime(_ expected: [String: Any], actual: Any, path: [String], type: DateTimeType) -> String? {
        let location = pathDescription(path)
        guard let expectedString = expected["value"] as? String else {
            return "Missing expected value at \(location)"
        }

        switch type {
        case .localDateTime:
            guard let actualDateTime = actual as? LocalDateTime else {
                return "Expected local datetime at \(location), found \(actual)"
            }
            return compareLocalDateTimeValue(expected: expectedString, actual: actualDateTime, path: path)

        case .localDate:
            guard let actualDate = actual as? LocalDate else {
                return "Expected local date at \(location), found \(actual)"
            }
            return compareLocalDateValue(expected: expectedString, actual: actualDate, path: path)

        case .localTime:
            guard let actualTime = actual as? LocalTime else {
                return "Expected local time at \(location), found \(actual)"
            }
            return compareLocalTimeValue(expected: expectedString, actual: actualTime, path: path)
        }
    }

    private static func compareLocalDateTimeValue(expected: String, actual: LocalDateTime, path: [String]) -> String? {
        let location = pathDescription(path)
        guard let expectedDateTime = parseExpectedLocalDateTime(expected) else {
            return "Unable to parse expected datetime at \(location)"
        }

        if actual != expectedDateTime {
            return "Local datetime mismatch at \(location): expected \(expected), got \(actual.description)"
        }

        return nil
    }

    private static func compareLocalDateValue(expected: String, actual: LocalDate, path: [String]) -> String? {
        let location = pathDescription(path)
        guard let expectedDate = parseExpectedLocalDate(expected) else {
            return "Unable to parse expected date at \(location)"
        }

        if actual != expectedDate {
            return "Local date mismatch at \(location): expected \(expected), got \(actual.description)"
        }

        return nil
    }

    private static func compareLocalTimeValue(expected: String, actual: LocalTime, path: [String]) -> String? {
        let location = pathDescription(path)
        guard let expectedTime = parseExpectedLocalTime(expected) else {
            return "Unable to parse expected time at \(location)"
        }

        if actual != expectedTime {
            return "Local time mismatch at \(location): expected \(expected), got \(actual.description)"
        }

        return nil
    }

    private static func parseExpectedLocalDateTime(_ value: String) -> LocalDateTime? {
        guard let (datePart, timePart) = splitDateTime(value),
              let date = parseExpectedLocalDate(String(datePart)),
              let time = parseExpectedLocalTime(String(timePart))
        else {
            return nil
        }
        return LocalDateTime(date: date, time: time)
    }

    private static func parseExpectedLocalDate(_ value: String) -> LocalDate? {
        let parts = value.split(separator: "-")
        guard parts.count == 3,
              let year = UInt16(parts[0]),
              let month = UInt8(parts[1]),
              let day = UInt8(parts[2])
        else {
            return nil
        }
        return LocalDate(year: year, month: month, day: day)
    }

    private static func parseExpectedLocalTime(_ value: String) -> LocalTime? {
        let parts = value.split(separator: ":")
        guard parts.count == 3,
              let hour = UInt8(parts[0]),
              let minute = UInt8(parts[1])
        else {
            return nil
        }

        let secondSegment = parts[2]
        var secondPart = secondSegment
        var fraction: Substring?
        if let dot = secondSegment.firstIndex(of: ".") {
            secondPart = secondSegment[..<dot]
            fraction = secondSegment[secondSegment.index(after: dot)...]
        }

        guard let second = UInt8(secondPart) else {
            return nil
        }

        var nanosecond: UInt32 = 0
        if let fraction {
            var digits = String(fraction)
            if digits.count > 9 {
                digits = String(digits.prefix(9))
            }
            while digits.count < 9 {
                digits.append("0")
            }
            nanosecond = UInt32(digits) ?? 0
        }

        return LocalTime(hour: hour, minute: minute, second: second, nanosecond: nanosecond)
    }

    private static func parseDate(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let formatter2 = ISO8601DateFormatter()
        formatter2.formatOptions = [.withInternetDateTime]

        // Try with space separator format for TOML compliance
        let formatter3 = ISO8601DateFormatter()
        formatter3.formatOptions = [.withFullDate, .withFullTime, .withFractionalSeconds]

        let date = formatter.date(from: value) ?? formatter2.date(from: value) ?? formatter3.date(from: value.replacingOccurrences(of: " ", with: "T"))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second, .nanosecond],
            from: date!
        )

        var seconds = Double(epochSecondsViaProlepticHelper(
            year: components.year!,
            month: components.month!,
            day: components.day!,
            hour: components.hour!,
            minute: components.minute!,
            second: components.second!
        ))

        if let nanoseconds = components.nanosecond {
            seconds += Double(nanoseconds) / 1_000_000_000
        }

        return Date(timeIntervalSince1970: TimeInterval(seconds))
    }

    private static func splitDateTime(_ value: String) -> (Substring, Substring)? {
        guard let index = value.firstIndex(where: { $0 == "T" || $0 == "t" || $0 == " " }) else {
            return nil
        }

        let datePart = value[..<index]
        var next = value.index(after: index)
        while next < value.endIndex, value[next].isWhitespace {
            next = value.index(after: next)
        }
        let timePart = value[next...]
        return (datePart, timePart)
    }

    private static func pathDescription(_ path: [String]) -> String {
        guard !path.isEmpty else {
            return "(root)"
        }
        var description = ""
        for component in path {
            if component.hasPrefix("[") {
                description.append(component)
            } else {
                if !description.isEmpty {
                    description.append(".")
                }
                description.append(component)
            }
        }
        return description
    }
}
