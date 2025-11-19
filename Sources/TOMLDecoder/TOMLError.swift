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
    case invalidDateTimeComponents(String)
}

extension TOMLError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalidUTF8:
            return "The given data was not valid UTF8."
        case .badKey(let lineNumber):
            return "Ill-formed key at line \(lineNumber)."
        case .expectedHexCharacters(let codeUnit, let hexCount):
            return "Expected \(hexCount) hexadecimal characters after '\(String(UnicodeScalar(codeUnit))).'."
        case .illegalEscapeCharacter(let codeUnit):
            return "Illegal escape character '\(String(UnicodeScalar(codeUnit)))'."
        case .illegalUCSCode(let ucs):
            return "Illegal UCS code '\(ucs)'."
        case .internalError(let lineNumber):
            return "Internal error at line \(lineNumber)."
        case .invalidCharacter(let codeUnit):
            return "Invalid character '\(String(UnicodeScalar(codeUnit)))'."
        case .invalidHexCharacters(let codeUnit):
            return "Invalid hexadecimal characters '\(String(UnicodeScalar(codeUnit)))'."
        case .keyExists(let lineNumber):
            return "Key at line \(lineNumber) already exists."
        case .syntax(let lineNumber, let message):
            return "Syntax error at line \(lineNumber): \(message)."
        case .stringMissingClosingQuote(let single):
            return "String missing closing quote\(single ? " (single quoted)" : " (double quoted)") character."
        case .arrayOutOfBound(let index, let bound):
            return "Array index \(index) is out of bounds (0..<\(bound))."
        case .typeMismatchInArray(let index, let expected):
            return "Type mismatch at array index \(index): expected \(expected)."
        case .keyNotFoundInTable(let key, let type):
            return "Key '\(key)' not found in table of type \(type)."
        case .typeMismatchInTable(let key, let expected):
            return "Type mismatch at table key '\(key)': expected \(expected)."
        case .invalidNumber(let reason):
            return "Invalid number: \(reason)."
        case .invalidInteger(let reason):
            return "Invalid integer: \(reason)."
        case .invalidFloat(let reason):
            return "Invalid float: \(reason)."
        case .invalidBool(let value):
            return "Invalid boolean value: \(value)."
        case .invalidDateTime(let lineNumber, let reason):
            return "Invalid date-time\(lineNumber.map { " at line \($0)" } ?? ""): \(reason)."
        case .invalidValueInTable(let key):
            return "Invalid value in table for key '\(key)'."
        case .invalidDateTimeComponents(let components):
            return "Invalid date-time components: \(components)."
        case .notReallyCodable:
            return "This type is not generally codable. Use TOMLDecoder to decode it as part of a larger Codable."
        }
    }
}
