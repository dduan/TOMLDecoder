// copy parsing logic from toml.c


struct Token {
    enum Kind {
        case invalid
        case dot
        case comma
        case equal
        case lbrace
        case rbrace
        case newline
        case lbracket
        case rbracket
        case string
    }
    let kind: Kind
    let lineNumber: Int
    let ptr: String.UTF8View.Index
    let length: Int
    let eof: UTF8.CodeUnit
}

struct Table {}

final class Context {
    var start: String.UTF8View.Index
    var stop: String.UTF8View.Index
    var error: String
    var tok: Token
    var root: Table
    var currentTable: Table?

    init(
        start: String.UTF8View.Index,
        stop: String.UTF8View.Index,
        error: String,
        tok: Token,
        root: Table,
        currentTable: Table?
    ) {
        self.start = start
        self.stop = stop
        self.error = error
        self.tok = tok
        self.root = root
        self.currentTable = currentTable
    }
}

enum ParseError: Error {
    case invalidCharacter(UTF8.CodeUnit)
    case expectedHexCharacters(UTF8.CodeUnit, Int)
    case invalidHexCharacters(UTF8.CodeUnit)
    case illegalEscapeCharacter(UTF8.CodeUnit)
    case illegalUCSCode(UInt32)
}

enum CodeUnits {
    static let lf = "\n".utf8.first!
    static let cr = "\r".utf8.first!
    static let backslash = "\\".utf8.first!
    static let lowerU = "u".utf8.first!
    static let upperU = "U".utf8.first!
    static let number0 = "0".utf8.first!
    static let number9 = "9".utf8.first!
    static let upperA = "A".utf8.first!
    static let upperF = "F".utf8.first!
    static let lowerB = "b".utf8.first!
    static let lowerT = "t".utf8.first!
    static let lowerF = "f".utf8.first!
    static let lowerR = "r".utf8.first!
    static let doubleQuote = "\"".utf8.first!
    static let tab = "\t".utf8.first!
    static let formfeed = "\u{000c}".utf8.first!
    static let backspace = "\u{0008}".utf8.first!
    static let space = " ".utf8.first!
}

func literalString(source: String.UTF8View, multiline: Bool) throws -> String {
    var resultCodeUnits: [UTF8.CodeUnit] = []
    for codeUnit in source {
        if codeUnit >= 0 && codeUnit <= 0x08 || codeUnit >= 0x0a && codeUnit <= 0x1f || codeUnit == 0x7f {
            if !(multiline && (codeUnit == CodeUnits.cr || codeUnit == CodeUnits.lf)) {
                throw ParseError.invalidCharacter(codeUnit)
            }
        }
        resultCodeUnits.append(codeUnit)
    }
    return String(decoding: resultCodeUnits, as: UTF8.self)
}

extension String.UTF8View {
    func indexAfterSkippingCharacters(start: Index, characters: [UTF8.CodeUnit]) -> Index {
        var index = start
        while index < self.endIndex {
            if characters.contains(self[index]) {
                index = self.index(after: index)
            } else {
                break
            }
        }
        return index
    }
}

func basicString(source: String.UTF8View, multiline: Bool) throws -> String {
    var resultCodeUnits: [UTF8.CodeUnit] = []
    var index = source.startIndex
    while true {
        if index >= source.endIndex {
            break
        }

        var codeUnit = source[index]
        index = source.index(after: index)
        if codeUnit != CodeUnits.backslash {
            if codeUnit >= 0 && codeUnit <= 0x08 || codeUnit >= 0x0a && codeUnit <= 0x1f || codeUnit == 0x7f {
                if !(multiline && (codeUnit == CodeUnits.cr || codeUnit == CodeUnits.lf)) {
                    throw ParseError.invalidCharacter(codeUnit)
                }
            }
            resultCodeUnits.append(codeUnit)
            continue
        }

        if index >= source.endIndex {
            throw ParseError.invalidCharacter(CodeUnits.backslash)
        }

        if multiline {
            if source[source.indexAfterSkippingCharacters(start: index, characters: [CodeUnits.space, CodeUnits.tab, CodeUnits.cr])] == CodeUnits.lf {
                index = source.indexAfterSkippingCharacters(start: index, characters: [CodeUnits.space, CodeUnits.tab, CodeUnits.cr, CodeUnits.lf])
                continue
            }
        }

        codeUnit = source[index]
        index = source.index(after: index)

        if codeUnit == CodeUnits.lowerU || codeUnit == CodeUnits.upperU {
            let hexCount = (codeUnit == CodeUnits.lowerU ? 4 : 8)
            var ucs: UInt32 = 0
            for _ in 0..<hexCount {
                if index >= source.endIndex {
                    throw ParseError.expectedHexCharacters(codeUnit, hexCount)
                }
                codeUnit = source[index]
                index = source.index(after: index)
                let v: Int32 = (codeUnit >= CodeUnits.number0 && codeUnit <= CodeUnits.number9)
                    ? Int32(codeUnit - CodeUnits.number0)
                    : (codeUnit >= CodeUnits.upperA && codeUnit <= CodeUnits.upperF)
                        ? Int32(codeUnit - CodeUnits.upperA + 10)
                        : -1
                if v == -1 {
                    throw ParseError.invalidHexCharacters(codeUnit)
                }
                ucs = ucs * 16 + UInt32(v)
            }
            guard let scalar = Unicode.Scalar(ucs) else {
                throw ParseError.illegalUCSCode(ucs)
            }
            resultCodeUnits.append(contentsOf: scalar.utf8)
            continue
        } else if codeUnit == CodeUnits.lowerB {
            codeUnit = CodeUnits.backspace
        } else if codeUnit == CodeUnits.lowerT {
            codeUnit = CodeUnits.tab
        } else if codeUnit == CodeUnits.lowerF {
            codeUnit = CodeUnits.formfeed
        } else if codeUnit == CodeUnits.lowerR {
            codeUnit = CodeUnits.cr
        } else if codeUnit != CodeUnits.doubleQuote && codeUnit != CodeUnits.backslash {
            throw ParseError.illegalEscapeCharacter(codeUnit)
        }

        resultCodeUnits.append(codeUnit)
    }
    return String(decoding: resultCodeUnits, as: UTF8.self)
}

let source = #"Hello\u002C world"#
let result = try basicString(source: source.utf8, multiline: false)
print(result)
