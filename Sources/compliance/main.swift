// This is CLI app that provides decoder interface for the test suite at
// https://github.com/BurntSushi/toml-test
import Foundation
import TOMLDecoder

if #available(macOS 12, *) {
let input = FileHandle.standardInput.availableData
guard let table = try? TOMLDecoder.tomlTable(from: input) else {
    exit(1)
}

func translate(value: Any) -> Any {
    if let table = value as? [String: Any] {
        return table.reduce(into: [:]) { (result, pair) in
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
        return ["type": "datetime", "value": value.formatted(.iso8601)]
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
            content = date.formatted(.iso8601)
        case (false, true):
            type = "time-local"
            content = date.formatted(.iso8601.time(includingFractionalSeconds: true))
        case (true, false):
            type = "date-local"
            content = date.formatted(.iso8601.year().month().day())
        default:
            fatalError()
        }
        return ["type": type, "value": content]
    } else {
        fatalError()
    }
}


let json = try JSONSerialization.data(withJSONObject: translate(value: table))
print(String(data: json, encoding: .utf8)!)
}
