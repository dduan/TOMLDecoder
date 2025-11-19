enum TOMLKey: CodingKey {
    case string(String)
    case int(Int)
    case `super`

    init(stringValue: String) {
        self = .string(stringValue)
    }

    init(intValue: Int) {
        self = .int(intValue)
    }

    var stringValue: String {
        switch self {
        case let .string(string):
            string
        case let .int(int):
            "Index \(int)"
        case .super:
            "super"
        }
    }

    var intValue: Int? {
        switch self {
        case let .int(int):
            int
        default:
            nil
        }
    }
}
