public enum TOMLError: Error {
    case notReallyCodable
    case invalidUTF8
    case badKey(lineNumber: Int)
    case expectedHexCharacters(UTF8.CodeUnit, Int)
    case illegalEscapeCharacter(UTF8.CodeUnit)
    case illegalUCSCode(UInt32)
    case internalError(lineNumber: Int)
    case invalidCharacter(UTF8.CodeUnit)
    case invalidHexCharacters(UTF8.CodeUnit)
    case keyExists(lineNumber: Int)
    case syntax(lineNumber: Int, message: String)
    case stringMissingClosingQuote(single: Bool)
    case arrayOutOfBound(index: Int, bound: Int)
    case typeMismatchInArray(index: Int, expected: String)
    case keyNotFoundInTable(key: String, type: String)
    case typeMismatchInTable(key: String, expected: String)
    case invalidNumber(reason: String)
    case invalidInteger(reason: String)
    case invalidFloat(reason: String)
    case invalidBool(String.UTF8View.SubSequence)
    case invalidDateTime(lineNumber: Int?, reason: String)
    case invalidValueInTable(key: String)
    case invalidValueInArray(index: Int)
    case invalidDateTimeComponents(String)
}

extension TOMLError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalidUTF8:
            "The given data was not valid UTF8."
        case let .badKey(lineNumber):
            "Ill-formed key at line \(lineNumber)."
        case let .expectedHexCharacters(codeUnit, hexCount):
            "Expected \(hexCount) hexadecimal characters after '\(String(UnicodeScalar(codeUnit))).'."
        case let .illegalEscapeCharacter(codeUnit):
            "Illegal escape character '\(String(UnicodeScalar(codeUnit)))'."
        case let .illegalUCSCode(ucs):
            "Illegal UCS code '\(ucs)'."
        case let .internalError(lineNumber):
            "Internal error at line \(lineNumber)."
        case let .invalidCharacter(codeUnit):
            "Invalid character '\(String(UnicodeScalar(codeUnit)))'."
        case let .invalidHexCharacters(codeUnit):
            "Invalid hexadecimal characters '\(String(UnicodeScalar(codeUnit)))'."
        case let .keyExists(lineNumber):
            "Key at line \(lineNumber) already exists."
        case let .syntax(lineNumber, message):
            "Syntax error at line \(lineNumber): \(message)."
        case let .stringMissingClosingQuote(single):
            "String missing closing quote\(single ? " (single quoted)" : " (double quoted)") character."
        case let .arrayOutOfBound(index, bound):
            "Array index \(index) is out of bounds (0..<\(bound))."
        case let .typeMismatchInArray(index, expected):
            "Type mismatch at array index \(index): expected \(expected)."
        case let .keyNotFoundInTable(key, type):
            "Key '\(key)' not found in table of type \(type)."
        case let .typeMismatchInTable(key, expected):
            "Type mismatch at table key '\(key)': expected \(expected)."
        case let .invalidNumber(reason):
            "Invalid number: \(reason)."
        case let .invalidInteger(reason):
            "Invalid integer: \(reason)."
        case let .invalidFloat(reason):
            "Invalid float: \(reason)."
        case let .invalidBool(value):
            "Invalid boolean value: \(value)."
        case let .invalidDateTime(lineNumber, reason):
            "Invalid date-time\(lineNumber.map { " at line \($0)" } ?? ""): \(reason)."
        case let .invalidValueInTable(key):
            "Invalid value in table for key '\(key)'."
        case let .invalidValueInArray(index):
            "Invalid value in array at index \(index)."
        case let .invalidDateTimeComponents(components):
            "Invalid date-time components: \(components)."
        case .notReallyCodable:
            "This type is not generally codable. Use TOMLDecoder to decode it as part of a larger Codable."
        }
    }
}
