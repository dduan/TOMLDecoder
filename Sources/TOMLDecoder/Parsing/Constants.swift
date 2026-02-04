enum CodeUnits {
    static let escape: UTF8.CodeUnit = 27
    static let equal: UTF8.CodeUnit = 61
    static let comma: UTF8.CodeUnit = 44
    static let lbrace: UTF8.CodeUnit = 123
    static let rbrace: UTF8.CodeUnit = 125
    static let lbracket: UTF8.CodeUnit = 91
    static let rbracket: UTF8.CodeUnit = 93
    static let pound: UTF8.CodeUnit = 35
    static let backslash: UTF8.CodeUnit = 92
    static let backspace: UTF8.CodeUnit = 8
    static let cr: UTF8.CodeUnit = 13
    static let colon: UTF8.CodeUnit = 58
    static let dot: UTF8.CodeUnit = 46
    static let doubleQuote: UTF8.CodeUnit = 34
    static let formfeed: UTF8.CodeUnit = 12
    static let lf: UTF8.CodeUnit = 10
    static let minus: UTF8.CodeUnit = 45
    static let plus: UTF8.CodeUnit = 43
    static let singleQuote: UTF8.CodeUnit = 39
    static let space: UTF8.CodeUnit = 32
    static let tab: UTF8.CodeUnit = 9
    static let underscore: UTF8.CodeUnit = 95

    static let number0: UTF8.CodeUnit = 48
    static let number1: UTF8.CodeUnit = 49
    static let number7: UTF8.CodeUnit = 55
    static let number9: UTF8.CodeUnit = 57

    static let lowerA: UTF8.CodeUnit = 97
    static let lowerB: UTF8.CodeUnit = 98
    static let lowerI: UTF8.CodeUnit = 105
    static let lowerE: UTF8.CodeUnit = 101
    static let lowerF: UTF8.CodeUnit = 102
    static let lowerL: UTF8.CodeUnit = 108
    static let lowerS: UTF8.CodeUnit = 115
    static let lowerN: UTF8.CodeUnit = 110
    static let lowerO: UTF8.CodeUnit = 111
    static let lowerR: UTF8.CodeUnit = 114
    static let lowerT: UTF8.CodeUnit = 116
    static let lowerU: UTF8.CodeUnit = 117
    static let lowerX: UTF8.CodeUnit = 120
    static let lowerZ: UTF8.CodeUnit = 122
    static let upperA: UTF8.CodeUnit = 65
    static let upperE: UTF8.CodeUnit = 69
    static let upperF: UTF8.CodeUnit = 70
    static let upperT: UTF8.CodeUnit = 84
    static let upperU: UTF8.CodeUnit = 85
    static let upperZ: UTF8.CodeUnit = 90

    nonisolated(unsafe) static let isBareKeyChar: UnsafePointer<Bool> = {
        let ptr = UnsafeMutablePointer<Bool>.allocate(capacity: 256)
        ptr.initialize(repeating: false, count: 256)
        for i in 0 ..< 256 {
            let ch = UTF8.CodeUnit(i)
            if (ch >= CodeUnits.lowerA && ch <= CodeUnits.lowerZ) ||
                (ch >= CodeUnits.upperA && ch <= CodeUnits.upperZ) ||
                (ch >= CodeUnits.number0 && ch <= CodeUnits.number9) ||
                ch == CodeUnits.underscore ||
                ch == CodeUnits.minus
            {
                ptr[i] = true
            }
        }
        return UnsafePointer(ptr)
    }()

    nonisolated(unsafe) static let isValueChar: UnsafePointer<Bool> = {
        let ptr = UnsafeMutablePointer<Bool>.allocate(capacity: 256)
        ptr.initialize(repeating: false, count: 256)
        for i in 0 ..< 256 {
            let ch = UTF8.CodeUnit(i)
            if (ch >= CodeUnits.lowerA && ch <= CodeUnits.lowerZ) ||
                (ch >= CodeUnits.upperA && ch <= CodeUnits.upperZ) ||
                (ch >= CodeUnits.number0 && ch <= CodeUnits.number9) ||
                ch == CodeUnits.underscore ||
                ch == CodeUnits.minus ||
                ch == CodeUnits.plus ||
                ch == CodeUnits.dot
            {
                ptr[i] = true
            }
        }
        return UnsafePointer(ptr)
    }()

    static let null: UTF8.CodeUnit = 0x00
    static let unitSeparator: UTF8.CodeUnit = 0x1F
    static let delete: UTF8.CodeUnit = 0x7F
}

extension UTF8.CodeUnit {
    @_transparent
    var isDecimalDigit: Bool {
        CodeUnits.number0 <= self && self <= CodeUnits.number9
    }

    @_transparent
    var isHexDigit: Bool {
        isDecimalDigit
            || CodeUnits.lowerA <= self && self <= CodeUnits.lowerF
            || CodeUnits.upperA <= self && self <= CodeUnits.upperF
    }
}
