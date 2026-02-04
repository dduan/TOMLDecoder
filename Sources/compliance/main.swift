// This is CLI app that provides decoder interface for the test suite at
// https://github.com/BurntSushi/toml-test
import Foundation
import TOMLDecoder

/// iOS 13+ compatible date formatter functions
private func createISO8601FullFormatter() -> ISO8601DateFormatter {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
}

private func createISO8601DateTimeFormatter() -> ISO8601DateFormatter {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter
}

private func createISO8601TimeFormatter() -> ISO8601DateFormatter {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withTime, .withFractionalSeconds]
    return formatter
}

private func createISO8601DateFormatter() -> ISO8601DateFormatter {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withFullDate]
    return formatter
}

let input = FileHandle.standardInput.availableData
guard let tomlTable = try? TOMLTable(source: input),
      let table = try? Dictionary(tomlTable)
else {
    exit(1)
}

func translate(value: Any) -> Any {
    if let table = value as? [String: Any] {
        return table.reduce(into: [:]) { result, pair in
            result[pair.key] = translate(value: pair.value)
        }
    } else if let array = value as? [Any] {
        return array.map(translate(value:))
    } else if let value = value as? String {
        return ["type": "string", "value": value]
    } else if let value = value as? Int64 {
        return ["type": "integer", "value": "\(value)"]
    } else if let value = value as? Double {
        return ["type": "float", "value": "\(value)"]
    } else if let value = value as? Bool {
        return ["type": "bool", "value": "\(value)"]
    } else if let value = value as? Date {
        return ["type": "datetime", "value": createISO8601FullFormatter().string(from: value)]
    } else if let value = value as? OffsetDateTime {
        return ["type": "datetime", "value": value.description]
    } else if let value = value as? LocalDateTime {
        return ["type": "datetime-local", "value": value.description]
    } else if let value = value as? LocalDate {
        return ["type": "date-local", "value": value.description]
    } else if let value = value as? LocalTime {
        return ["type": "time-local", "value": value.description]
    } else if var value = value as? DateComponents {
        value.timeZone = TimeZone(secondsFromGMT: 0)
        let date = Calendar.current.date(from: value)!
        let hasDate = value.year != nil
        let hasTime = value.hour != nil
        let content: String
        let type: String
        switch (hasDate, hasTime) {
        case (true, true):
            type = "datetime-local"
            content = createISO8601DateTimeFormatter().string(from: date)
        case (false, true):
            type = "time-local"
            content = createISO8601TimeFormatter().string(from: date)
        case (true, false):
            type = "date-local"
            content = createISO8601DateFormatter().string(from: date)
        default:
            fatalError()
        }
        return ["type": type, "value": content]
    } else {
        fatalError("Unknown value type: \(type(of: value)) with value: \(value)")
    }
}

let json = try JSONSerialization.data(withJSONObject: translate(value: table))
print(String(data: json, encoding: .utf8)!)
