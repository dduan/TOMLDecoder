public enum TOMLError: Error {
    case invalidDateTimeComponents(String)
}

extension TOMLError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalidDateTimeComponents(let components):
            return "Invalid date-time components: \(components)."
        }
    }
}
