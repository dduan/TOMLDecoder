public struct TOMLError: Error {
    let reason: Reason

    init(_ reason: Reason) {
        self.reason = reason
    }

    enum Reason {
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
        case invalidString(context: TOMLKey, value: Token, reason: String)
        case invalidDateTime2(context: TOMLKey, value: Token, reason: String)
        case arrayOutOfBound(index: Int, bound: Int)
        case typeMismatchInArray(lineNumber: Int, index: Int, expected: String)
        case keyNotFoundInTable(key: String, expected: String)
        case typeMismatch(context: TOMLKey, token: Token, expected: String)
        case typeMismatchInTable(key: String, expected: String)
        case invalidNumber(reason: String)
        case invalidInteger(context: TOMLKey, value: Token, reason: String)
        case invalidFloat(context: TOMLKey, value: Token, reason: String)
        case invalidBool(context: TOMLKey, value: Token)
        case invalidDateTime(lineNumber: Int?, reason: String)
        case invalidValueInTable(context: TOMLKey, token: Token)
        case invalidValueInArray(context: TOMLKey, token: Token)
        case invalidDateTimeComponents(String)
    }
}

extension TOMLError: CustomStringConvertible {
    public var description: String {
        switch reason {
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
        case let .invalidString(context, value, reason):
            switch context {
            case let .string(key):
                "Invalid string value '\(value.text)' for key '\(key)' on line \(value.lineNumber): \(reason)."
            case let .int(index):
                "Invalid string value '\(value.text)' for index \(index) on line \(value.lineNumber): \(reason)."
            case .super:
                "Invalid string value '\(value.text)' for 'super' on line \(value.lineNumber): \(reason)."
            }
        case let .arrayOutOfBound(index, bound):
            "Array index \(index) is out of bounds (0..<\(bound))."
        case let .typeMismatchInArray(lineNumber, index, expected):
            "Type mismatch at array index \(index) at line \(lineNumber): expected \(expected)."
        case let .keyNotFoundInTable(key, expected):
            "Key '\(key)' not found in table while looking for \(expected)."
        case let .typeMismatch(context, token, expected):
            switch context {
            case let .string(key):
                "Type mismatch at table key '\(key)' on line \(token.lineNumber): expected \(expected)."
            case let .int(index):
                "Type mismatch at array index \(index) at line \(token.lineNumber): expected \(expected)."
            case .super:
                "Type mismatch at 'super' on line \(token.lineNumber): expected \(expected)."
            }
        case let .typeMismatchInTable(key, expected):
            "Type mismatch at table key '\(key)': expected \(expected)."
        case let .invalidNumber(reason):
            "Invalid number: \(reason)."
        case let .invalidInteger(context, value, reason):
            switch context {
            case let .string(key):
                "Invalid integer value '\(value.text)' for key '\(key)' on line \(value.lineNumber): \(reason)."
            case let .int(index):
                "Invalid integer value '\(value.text)' for index \(index) on line \(value.lineNumber): \(reason)."
            case .super:
                "Invalid integer value '\(value.text)' for 'super' on line \(value.lineNumber): \(reason)."
            }
        case let .invalidFloat(context, value, reason):
            switch context {
            case let .string(key):
                "Invalid float value '\(value.text)' for key '\(key)' on line \(value.lineNumber): \(reason)."
            case let .int(index):
                "Invalid float value '\(value.text)' for index \(index) on line \(value.lineNumber): \(reason)."
            case .super:
                "Invalid float value '\(value.text)' for 'super' on line \(value.lineNumber): \(reason)."
            }
        case let .invalidBool(context, value):
            switch context {
            case let .string(key):
                "Invalid boolean value '\(value.text)' for key '\(key)' on line \(value.lineNumber)."
            case let .int(index):
                "Invalid boolean value '\(value.text)' for index \(index) on line \(value.lineNumber)."
            case .super:
                "Invalid boolean value '\(value.text)' for 'super' on line \(value.lineNumber)."
            }
        case let .invalidDateTime2(context, value, reason):
            switch context {
            case let .string(key):
                "Invalid date-time value '\(value.text)' for key '\(key)' on line \(value.lineNumber): \(reason)."
            case let .int(index):
                "Invalid date-time value '\(value.text)' for index \(index) on line \(value.lineNumber): \(reason)."
            case .super:
                "Invalid date-time value '\(value.text)' for 'super' on line \(value.lineNumber): \(reason)."
            }
        case let .invalidDateTime(lineNumber, reason):
            "Invalid date-time\(lineNumber.map { " at line \($0)" } ?? ""): \(reason)."
        case let .invalidValueInTable(context, value):
            switch context {
            case let .string(key):
                "Invalid value in table for key '\(key)' at line \(value.lineNumber)."
            case let .int(index):
                "Invalid value in table for index \(index) at line \(value.lineNumber)."
            case .super:
                "Invalid value in table for 'super' at line \(value.lineNumber)."
            }
        case let .invalidValueInArray(context, value):
            switch context {
            case let .string(key):
                "Invalid value in array for key '\(key)' at line \(value.lineNumber)."
            case let .int(index):
                "Invalid value in array for index \(index) at line \(value.lineNumber)."
            case .super:
                "Invalid value in array for 'super' at line \(value.lineNumber)."
            }
        case let .invalidDateTimeComponents(components):
            "Invalid date-time components: \(components)."
        case .notReallyCodable:
            "This type is not generally codable. Use TOMLDecoder to decode it as part of a larger Codable."
        }
    }
}
