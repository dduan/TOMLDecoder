public struct TOMLError: Error {
    let reason: Reason

    init(_ reason: Reason) {
        self.reason = reason
    }

    // TODO: the ranges in Token.text is no longer useful as part of error message
    enum Reason {
        case arrayOutOfBound(index: Int, bound: Int)
        case badKey(lineNumber: Int)
        case expectedHexCharacters(UTF8.CodeUnit, Int)
        case illegalEscapeCharacter(UTF8.CodeUnit)
        case illegalUCSCode(UInt32)
        case internalError(lineNumber: Int)
        case invalidBool(context: TOMLKey, value: Token)
        case invalidCharacter(UTF8.CodeUnit)
        case invalidDateTime(lineNumber: Int?, reason: String)
        case invalidDateTime3(context: TOMLKey, value: Token, reason: String)
        case invalidDateTimeComponents(String)
        case invalidFloat(context: TOMLKey, value: Token, reason: String)
        case invalidHexCharacters(UTF8.CodeUnit)
        case invalidInteger(context: TOMLKey, value: Token, reason: String)
        case invalidNumber(reason: String)
        case invalidString(context: TOMLKey, value: Token, reason: String)
        case invalidUTF8
        case invalidValueInTable(context: TOMLKey, token: Token)
        case keyExists(lineNumber: Int)
        case keyNotFoundInTable(key: String, expected: String)
        case notReallyCodable
        case syntax(lineNumber: Int, message: String)
        case typeMismatch(context: TOMLKey, token: Token, expected: String)
        case typeMismatchInArray(lineNumber: Int, index: Int, expected: String)
        case typeMismatchInTable(key: String, expected: String)
    }
}

extension TOMLError: CustomStringConvertible {
    public var description: String {
        switch reason {
        case let .arrayOutOfBound(index, bound):
            "Array index \(index) is out of bounds (0..<\(bound))."
        case let .badKey(lineNumber):
            "(Line \(lineNumber)) Ill-formed key."
        case let .expectedHexCharacters(codeUnit, hexCount):
            "Expected \(hexCount) hexadecimal characters after '\(String(UnicodeScalar(codeUnit))).'."
        case let .illegalEscapeCharacter(codeUnit):
            "Illegal escape character '\(String(UnicodeScalar(codeUnit)))'."
        case let .illegalUCSCode(ucs):
            "Illegal UCS code '\(ucs)'."
        case let .internalError(lineNumber):
            "(Line \(lineNumber)) Internal error."
        case let .invalidBool(context, value):
            switch context {
            case let .string(key):
                "(Line \(value.lineNumber)) Invalid boolean value '\(value.text)' for key '\(key)'."
            case let .int(index):
                "(Line \(value.lineNumber)) Invalid boolean value '\(value.text)' for index \(index)."
            case .super:
                "(Line \(value.lineNumber)) Invalid boolean value '\(value.text)' for 'super'."
            }
        case let .invalidCharacter(codeUnit):
            "Invalid character '\(String(UnicodeScalar(codeUnit)))'."
        case let .invalidDateTime(lineNumber, reason):
            "\(lineNumber.map { "(Line \($0)) " } ?? "")Invalid date-time: \(reason)."
        case let .invalidDateTime3(context, value, reason):
            switch context {
            case let .string(key):
                "(Line \(value.lineNumber)) Invalid date-time value '\(value.text)' for key '\(key)': \(reason)."
            case let .int(index):
                "(Line \(value.lineNumber)) Invalid date-time value '\(value.text)' for index \(index)': \(reason)."
            case .super:
                "(Line \(value.lineNumber)) Invalid date-time value '\(value.text)' for 'super': \(reason)."
            }
        case let .invalidDateTimeComponents(components):
            "Invalid date-time components: \(components)."
        case let .invalidFloat(context, value, reason):
            switch context {
            case let .string(key):
                "(Line \(value.lineNumber)) Invalid float value '\(value.text)' for key '\(key)': \(reason)."
            case let .int(index):
                "(Line \(value.lineNumber)) Invalid float value '\(value.text)' for index \(index)': \(reason)."
            case .super:
                "(Line \(value.lineNumber)) Invalid float value '\(value.text)' for 'super': \(reason)."
            }
        case let .invalidHexCharacters(codeUnit):
            "Invalid hexadecimal characters '\(String(UnicodeScalar(codeUnit)))'."
        case let .invalidInteger(context, value, reason):
            switch context {
            case let .string(key):
                "(Line \(value.lineNumber)) Invalid integer value '\(value.text)' for key '\(key)': \(reason)."
            case let .int(index):
                "(Line \(value.lineNumber)) Invalid integer value '\(value.text)' for index \(index)': \(reason)."
            case .super:
                "(Line \(value.lineNumber)) Invalid integer value '\(value.text)' for 'super': \(reason)."
            }
        case let .invalidNumber(reason):
            "Invalid number: \(reason)."
        case let .invalidString(context, value, reason):
            switch context {
            case let .string(key):
                "(Line \(value.lineNumber)) Invalid string value '\(value.text)' for key '\(key)': \(reason)."
            case let .int(index):
                "(Line \(value.lineNumber)) Invalid string value '\(value.text)' for index \(index)': \(reason)."
            case .super:
                "(Line \(value.lineNumber)) Invalid string value '\(value.text)' for 'super': \(reason)."
            }
        case .invalidUTF8:
            "The given data was not valid UTF8."
        case let .invalidValueInTable(context, value):
            switch context {
            case let .string(key):
                "(Line \(value.lineNumber)) Invalid value in table for key '\(key)'."
            case let .int(index):
                "(Line \(value.lineNumber)) Invalid value in table for index \(index)."
            case .super:
                "(Line \(value.lineNumber)) Invalid value in table for 'super'."
            }
        case let .keyExists(lineNumber):
            "(Line \(lineNumber)) Key already exists."
        case let .keyNotFoundInTable(key, expected):
            "Key '\(key)' not found in table while looking for \(expected)."
        case .notReallyCodable:
            "This type is not generally codable. Use TOMLDecoder to decode it as part of a larger Codable."
        case let .syntax(lineNumber, message):
            "(Line \(lineNumber)) Syntax error: \(message)."
        case let .typeMismatch(context, token, expected):
            switch context {
            case let .string(key):
                "(Line \(token.lineNumber)) Type mismatch at table key '\(key)': expected \(expected)."
            case let .int(index):
                "(Line \(token.lineNumber)) Type mismatch at array index \(index): expected \(expected)."
            case .super:
                "(Line \(token.lineNumber)) Type mismatch at 'super': expected \(expected)."
            }
        case let .typeMismatchInArray(lineNumber, index, expected):
            "(Line \(lineNumber)) Type mismatch at array index \(index): expected \(expected)."
        case let .typeMismatchInTable(key, expected):
            "Type mismatch at table key '\(key)': expected \(expected)."
        }
    }
}
