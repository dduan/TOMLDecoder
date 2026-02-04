struct Parser: ~Copyable {
    var token = Token.empty
    var cursor = 0
    var currentLineNumber = 1
    var currentTable = 0
    var currentTableIsKeyed = false
    var tablePath: [(key: String, keyHash: Int, token: Token)] = []
    var tables: [InternalTOMLTable] = [InternalTOMLTable()]
    var arrays: [InternalTOMLArray] = []
    var keyTables: [KeyTablePair] = []
    var keyArrays: [KeyArrayPair] = []
    var keyValues: [KeyValuePair] = []
    var keyTransform: (@Sendable (String) -> String)?

    mutating func parse(bytes: UnsafeBufferPointer<UInt8>) throws(TOMLError) {
        while token.kind != .eof {
            switch token.kind {
            case .newline:
                try nextToken(bytes: bytes, isDotSpecial: true)
            case .string, .bareKey:
                try parseKeyValue(bytes: bytes, tableIndex: currentTable, isKeyed: currentTableIsKeyed)
                if token.kind != .newline, token.kind != .eof {
                    throw TOMLError(.syntax(lineNumber: token.lineNumber, message: "extra chars after value"))
                }
                if token.kind == .newline {
                    try eatToken(bytes: bytes, kind: .newline, isDotSpecial: true)
                }
            case .lbracket:
                try parseSelect(bytes: bytes)
            default:
                throw TOMLError(.syntax(lineNumber: token.lineNumber, message: "syntax error"))
            }
        }
    }

    mutating func nextToken(bytes: UnsafeBufferPointer<UInt8>, isDotSpecial: Bool) throws(TOMLError) {
        let lineNumber = currentLineNumber
        var position = cursor

        @inline(__always)
        func emitToken(kind: Token.Kind, start: Int, end: Int, newlines: Int = 0) {
            token = Token(kind: kind, lineNumber: lineNumber, text: start ..< end)
            cursor = end
            currentLineNumber = lineNumber + newlines
        }

        let count = bytes.count
        while position < count {
            let ch = bytes[position]
            switch ch {
            case CodeUnits.pound:
                // skip comment, stop just before the \n.
                position += 1
                while position < count, bytes[position] != CodeUnits.lf {
                    let commentChar = bytes[position]
                    // Validate comment characters - control characters are not allowed except CR when followed by LF (CRLF)
                    if (commentChar >= CodeUnits.null && commentChar <= CodeUnits.backspace)
                        || (commentChar >= CodeUnits.lf && commentChar <= CodeUnits.unitSeparator)
                        || commentChar == CodeUnits.delete
                    {
                        if commentChar == CodeUnits.cr {
                            let nextPosition = position + 1
                            if nextPosition < count, bytes[nextPosition] == CodeUnits.lf {
                                // Allow CRLF sequence
                            } else {
                                throw TOMLError(
                                    .syntax(
                                        lineNumber: lineNumber,
                                        message: "control characters are not allowed in comments"
                                    )
                                )
                            }
                        } else {
                            throw TOMLError(
                                .syntax(
                                    lineNumber: lineNumber,
                                    message: "control characters are not allowed in comments"
                                )
                            )
                        }
                    }
                    position += 1
                }
                continue
            case CodeUnits.space, CodeUnits.tab:
                // ignore white spaces
                position += 1
                while position < count {
                    let ws = bytes[position]
                    if ws != CodeUnits.space, ws != CodeUnits.tab {
                        break
                    }
                    position += 1
                }
                continue
            case CodeUnits.dot where isDotSpecial:
                emitToken(kind: .dot, start: position, end: position + 1)
                return
            case CodeUnits.comma:
                emitToken(kind: .comma, start: position, end: position + 1)
                return
            case CodeUnits.equal:
                emitToken(kind: .equal, start: position, end: position + 1)
                return
            case CodeUnits.lbrace:
                emitToken(kind: .lbrace, start: position, end: position + 1)
                return
            case CodeUnits.rbrace:
                emitToken(kind: .rbrace, start: position, end: position + 1)
                return
            case CodeUnits.lbracket:
                emitToken(kind: .lbracket, start: position, end: position + 1)
                return
            case CodeUnits.rbracket:
                emitToken(kind: .rbracket, start: position, end: position + 1)
                return
            case CodeUnits.lf:
                emitToken(kind: .newline, start: position, end: position + 1, newlines: 1)
                return
            case CodeUnits.cr:
                // Check if this is part of a CRLF sequence
                let nextPosition = position + 1
                if nextPosition < count, bytes[nextPosition] == CodeUnits.lf {
                    // This is CRLF, treat as newline
                    emitToken(kind: .newline, start: position, end: nextPosition + 1, newlines: 1)
                    return
                }
                // Bare CR is invalid
                throw TOMLError(
                    .syntax(
                        lineNumber: lineNumber,
                        message: "bare carriage return is not allowed"
                    )
                )
            default:
                break
            }

            func scanString(range: Range<Int>, lineNumber: Int) throws(TOMLError) {
                let isBareKeyChar = CodeUnits.isBareKeyChar
                let isValueChar = CodeUnits.isValueChar
                let start = range.lowerBound
                let head = bytes[start]
                if (head >= CodeUnits.lowerA && head <= CodeUnits.lowerZ) ||
                    (head >= CodeUnits.upperA && head <= CodeUnits.upperZ) ||
                    head == CodeUnits.underscore
                {
                    var index = start + 1
                    while index < range.upperBound {
                        let ch = bytes[index]
                        if isBareKeyChar[Int(ch)] {
                            index += 1
                            continue
                        }
                        break
                    }
                    emitToken(kind: .bareKey, start: start, end: index)
                    return
                }

                if start + 3 <= range.upperBound,
                   bytes[start] == CodeUnits.singleQuote,
                   bytes[start + 1] == CodeUnits.singleQuote,
                   bytes[start + 2] == CodeUnits.singleQuote
                {
                    var i = start + 3
                    var newlinesInToken = 0

                    while i < range.upperBound {
                        if bytes[i] == CodeUnits.lf {
                            newlinesInToken += 1
                        }
                        if i + 3 <= range.upperBound,
                           bytes[i] == CodeUnits.singleQuote,
                           bytes[i + 1] == CodeUnits.singleQuote,
                           bytes[i + 2] == CodeUnits.singleQuote
                        {
                            if i + 3 >= range.upperBound || bytes[i + 3] != CodeUnits.singleQuote {
                                break
                            }
                        }
                        i += 1
                    }

                    guard i < range.upperBound else {
                        throw TOMLError(
                            .syntax(lineNumber: lineNumber, message: "unterminated triple-s-quote")
                        )
                    }

                    let end = i + 3
                    emitToken(kind: .string, start: start, end: end, newlines: newlinesInToken)
                    return
                }

                if start + 3 < range.upperBound,
                   bytes[start] == CodeUnits.doubleQuote,
                   bytes[start + 1] == CodeUnits.doubleQuote,
                   bytes[start + 2] == CodeUnits.doubleQuote
                {
                    var i = start + 3
                    let textCount = range.upperBound
                    var newlinesInToken = 0

                    while i < textCount {
                        if bytes[i] == CodeUnits.lf {
                            newlinesInToken += 1
                        }
                        if i + 3 <= textCount,
                           bytes[i] == CodeUnits.doubleQuote,
                           bytes[i + 1] == CodeUnits.doubleQuote,
                           bytes[i + 2] == CodeUnits.doubleQuote
                        {
                            // Check if this is exactly 3 quotes (not part of a longer sequence)
                            if i + 3 >= textCount || bytes[i + 3] != CodeUnits.doubleQuote {
                                if bytes[i - 1] == CodeUnits.backslash {
                                    i += 1
                                    continue
                                }
                                break
                            }
                        }
                        i += 1
                    }

                    guard i < range.upperBound else {
                        throw TOMLError(
                            .syntax(lineNumber: lineNumber, message: "unterminated triple-d-quote")
                        )
                    }

                    let end = i + 3
                    emitToken(kind: .string, start: start, end: end, newlines: newlinesInToken)
                    return
                }

                let ch = bytes[start]
                if ch == CodeUnits.singleQuote {
                    var i = start + 1
                    let textCount = range.upperBound

                    while i < textCount {
                        let ch = bytes[i]
                        if ch == CodeUnits.singleQuote || ch == CodeUnits.lf {
                            break
                        }
                        i += 1
                    }

                    if i >= textCount || bytes[i] != CodeUnits.singleQuote {
                        throw TOMLError(
                            .syntax(lineNumber: lineNumber, message: "unterminated s-quote")
                        )
                    }

                    emitToken(kind: .string, start: start, end: i + 1)
                    return
                }

                if ch == CodeUnits.doubleQuote {
                    var i = start + 1

                    // 8x unrolling for double-quoted strings
                    while i + 8 <= range.upperBound {
                        if bytes[i] == CodeUnits.backslash || bytes[i] == CodeUnits.doubleQuote || bytes[i] == CodeUnits.lf { break }
                        if bytes[i + 1] == CodeUnits.backslash || bytes[i + 1] == CodeUnits.doubleQuote || bytes[i + 1] == CodeUnits.lf { break }
                        if bytes[i + 2] == CodeUnits.backslash || bytes[i + 2] == CodeUnits.doubleQuote || bytes[i + 2] == CodeUnits.lf { break }
                        if bytes[i + 3] == CodeUnits.backslash || bytes[i + 3] == CodeUnits.doubleQuote || bytes[i + 3] == CodeUnits.lf { break }
                        if bytes[i + 4] == CodeUnits.backslash || bytes[i + 4] == CodeUnits.doubleQuote || bytes[i + 4] == CodeUnits.lf { break }
                        if bytes[i + 5] == CodeUnits.backslash || bytes[i + 5] == CodeUnits.doubleQuote || bytes[i + 5] == CodeUnits.lf { break }
                        if bytes[i + 6] == CodeUnits.backslash || bytes[i + 6] == CodeUnits.doubleQuote || bytes[i + 6] == CodeUnits.lf { break }
                        if bytes[i + 7] == CodeUnits.backslash || bytes[i + 7] == CodeUnits.doubleQuote || bytes[i + 7] == CodeUnits.lf { break }
                        i += 8
                    }

                    while i < range.upperBound {
                        let ch = bytes[i]
                        if ch == CodeUnits.backslash {
                            i += 1
                            if i < range.upperBound {
                                i += 1
                                continue
                            }
                            break
                        }

                        if ch == CodeUnits.lf || ch == CodeUnits.doubleQuote {
                            break
                        }
                        i += 1
                    }

                    if i >= range.upperBound || bytes[i] != CodeUnits.doubleQuote {
                        throw TOMLError(
                            .syntax(lineNumber: lineNumber, message: "unterminated quote")
                        )
                    }

                    emitToken(kind: .string, start: start, end: i + 1)
                    return
                }

                if !isDotSpecial {
                    var index = start
                    var dateEnder: Int?
                    // Fast path: Dates must produce YYYY-MM-DD, so checks for the dash
                    if start + 4 < range.upperBound && bytes[start + 4] == CodeUnits.minus {
                        dateEnder = scanDate(bytes: bytes, range: range)?.3
                    }

                    if let dateEnder, dateEnder < range.upperBound,
                       bytes[dateEnder] == CodeUnits.upperT || bytes[dateEnder] == CodeUnits.lowerT
                       || bytes[dateEnder] == CodeUnits.space
                    {
                        let timeStarter = dateEnder + 1
                        if let timeEnder = scanTime(
                            bytes: bytes, range: timeStarter ..< range.upperBound
                        )?.3 {
                            index = timeEnder
                        }
                    } else if let dateEnder {
                        index = dateEnder
                    } else if start + 2 < range.upperBound, bytes[start + 2] == CodeUnits.colon,
                              let timeEnder = scanTime(
                                  bytes: bytes, range: start ..< range.upperBound
                              )?.3
                    {
                        index = timeEnder
                    }
                    if index > start {
                        if index < range.upperBound {
                            if bytes[index] == CodeUnits.dot {
                                index += 1
                                while index < range.upperBound, bytes[index] >= CodeUnits.number0,
                                      bytes[index] <= CodeUnits.number9
                                {
                                    index += 1
                                }
                            }
                            if bytes[index] == CodeUnits.upperZ || bytes[index] == CodeUnits.lowerZ {
                                index += 1
                            } else if let timzoneEnder = scanTimezoneOffset(
                                bytes: bytes, range: index ..< range.upperBound
                            ) {
                                index = timzoneEnder
                            }
                        }
                        // squeeze out any spaces at end of string
                        while index >= start,
                              bytes[index - 1] == CodeUnits.space
                        {
                            index -= 1
                        }
                        // tokenize
                        emitToken(kind: .string, start: start, end: index)
                        return
                    }
                }

                if isDotSpecial {
                    var index = start
                    var isValidKey = true
                    while index < range.upperBound {
                        let ch = bytes[index]
                        if isBareKeyChar[Int(ch)] {
                            index += 1
                            continue
                        }
                        if ch == CodeUnits.plus {
                            isValidKey = false
                            index += 1
                            continue
                        }
                        break
                    }
                    emitToken(kind: isValidKey ? .bareKey : .string, start: start, end: index)
                } else {
                    var index = start
                    while index < range.upperBound {
                        let ch = bytes[index]
                        if isValueChar[Int(ch)] {
                            index += 1
                            continue
                        }
                        break
                    }
                    emitToken(kind: .string, start: start, end: index)
                }
            }

            try scanString(range: position ..< count, lineNumber: lineNumber)
            return
        }

        emitToken(kind: .eof, start: position, end: count)
    }

    mutating func eatToken(bytes: UnsafeBufferPointer<UInt8>, kind: Token.Kind, isDotSpecial: Bool)
        throws(TOMLError)
    {
        if token.kind != kind {
            throw TOMLError(.internalError(lineNumber: token.lineNumber))
        }
        try nextToken(bytes: bytes, isDotSpecial: isDotSpecial)
    }

    mutating func createKeyValue(bytes: UnsafeBufferPointer<UInt8>, token: Token, inTable tableIndex: Int, isKeyed: Bool) throws(TOMLError) -> Int {
        let key = try normalizeKey(bytes: bytes, token: token, keyTransform: keyTransform)
        let keyHash = fastKeyHash(key)
        if tableValue(tableIndex: tableIndex, keyed: isKeyed, key: key, keyHash: keyHash) != nil {
            throw TOMLError(.badKey(lineNumber: token.lineNumber))
        }
        let kv = KeyValuePair(key: key, keyHash: keyHash, value: Token.empty)
        let index = keyValues.count
        keyValues.append(kv)

        if isKeyed {
            if keyTables[tableIndex].table.keyValues.isEmpty {
                keyTables[tableIndex].table.keyValues.reserveCapacity(8)
            }
            keyTables[tableIndex].table.keyValues.append(index)
        } else {
            if tables[tableIndex].keyValues.isEmpty {
                tables[tableIndex].keyValues.reserveCapacity(8)
            }
            tables[tableIndex].keyValues.append(index)
        }
        return index
    }

    mutating func createKeyTable(bytes: UnsafeBufferPointer<UInt8>, token: Token, inTable tableIndex: Int, isKeyed: Bool, implicit: Bool = false) throws(TOMLError) -> Int {
        let key = try normalizeKey(bytes: bytes, token: token, keyTransform: keyTransform)
        let keyHash = fastKeyHash(key)
        // Check if parent table is readOnly (inline table)
        if isKeyed ? keyTables[tableIndex].table.readOnly : tables[tableIndex].readOnly {
            throw TOMLError(.syntax(lineNumber: token.lineNumber, message: "cannot add to inline table"))
        }

        switch tableValue(tableIndex: tableIndex, keyed: isKeyed, key: key, keyHash: keyHash) {
        case let .table(existingTableIndex):
            if keyTables[existingTableIndex].table.implicit {
                if keyTables[existingTableIndex].table.definedByDottedKey {
                    throw TOMLError(.keyExists(lineNumber: token.lineNumber))
                }
                keyTables[existingTableIndex].table.implicit = false
                return existingTableIndex
            }
            throw TOMLError(.keyExists(lineNumber: token.lineNumber))
        case .keyValue, .array:
            throw TOMLError(.keyExists(lineNumber: token.lineNumber))
        case nil:
            break
        }
        let index = keyTables.count
        var newTable = InternalTOMLTable()
        newTable.implicit = implicit
        newTable.definedByDottedKey = implicit
        keyTables.append(KeyTablePair(key: key, keyHash: keyHash, table: newTable))

        if isKeyed {
            if keyTables[tableIndex].table.tables.isEmpty {
                keyTables[tableIndex].table.tables.reserveCapacity(8)
            }
            keyTables[tableIndex].table.tables.append(index)
        } else {
            if tables[tableIndex].tables.isEmpty {
                tables[tableIndex].tables.reserveCapacity(8)
            }
            tables[tableIndex].tables.append(index)
        }
        return index
    }

    mutating func createKeyArray(bytes: UnsafeBufferPointer<UInt8>, token: Token, inTable tableIndex: Int, isKeyed: Bool, kind: InternalTOMLArray.Kind? = nil) throws(TOMLError) -> Int {
        let key = try normalizeKey(bytes: bytes, token: token, keyTransform: keyTransform)
        let keyHash = fastKeyHash(key)
        if tableValue(tableIndex: tableIndex, keyed: isKeyed, key: key, keyHash: keyHash) != nil {
            throw TOMLError(.keyExists(lineNumber: token.lineNumber))
        }

        let index = keyArrays.count
        keyArrays.append(KeyArrayPair(key: key, keyHash: keyHash, array: InternalTOMLArray(kind: kind)))
        if isKeyed {
            if keyTables[tableIndex].table.arrays.isEmpty {
                keyTables[tableIndex].table.arrays.reserveCapacity(8)
            }
            keyTables[tableIndex].table.arrays.append(index)
        } else {
            if tables[tableIndex].arrays.isEmpty {
                tables[tableIndex].arrays.reserveCapacity(8)
            }
            tables[tableIndex].arrays.append(index)
        }
        return index
    }

    @inline(__always)
    mutating func skipNewlines(bytes: UnsafeBufferPointer<UInt8>, isDotSpecial: Bool) throws(TOMLError) {
        if token.kind != .newline {
            return
        }

        let count = bytes.count
        var position = cursor
        var lineNumber = currentLineNumber

        while position < count {
            let ch = bytes[position]
            if ch == CodeUnits.space || ch == CodeUnits.tab {
                // 8x unrolling for space/tab skipping
                while position + 8 <= count {
                    let c0 = bytes[position]
                    let c1 = bytes[position + 1]
                    let c2 = bytes[position + 2]
                    let c3 = bytes[position + 3]
                    let c4 = bytes[position + 4]
                    let c5 = bytes[position + 5]
                    let c6 = bytes[position + 6]
                    let c7 = bytes[position + 7]

                    if c0 == CodeUnits.space || c0 == CodeUnits.tab,
                       c1 == CodeUnits.space || c1 == CodeUnits.tab,
                       c2 == CodeUnits.space || c2 == CodeUnits.tab,
                       c3 == CodeUnits.space || c3 == CodeUnits.tab,
                       c4 == CodeUnits.space || c4 == CodeUnits.tab,
                       c5 == CodeUnits.space || c5 == CodeUnits.tab,
                       c6 == CodeUnits.space || c6 == CodeUnits.tab,
                       c7 == CodeUnits.space || c7 == CodeUnits.tab
                    {
                        position += 8
                    } else {
                        break
                    }
                }

                while position < count {
                    let ws = bytes[position]
                    if ws != CodeUnits.space, ws != CodeUnits.tab {
                        break
                    }
                    position += 1
                }
                continue
            }
            switch ch {
            case CodeUnits.lf:
                lineNumber += 1
                position += 1
            case CodeUnits.cr:
                if position + 1 < count, bytes[position + 1] == CodeUnits.lf {
                    lineNumber += 1
                    position += 2
                } else {
                    // Bare CR, let nextToken handle error
                    cursor = position
                    currentLineNumber = lineNumber
                    try nextToken(bytes: bytes, isDotSpecial: isDotSpecial)
                    return
                }
            case CodeUnits.pound:
                // Comment
                position += 1
                while position < count {
                    let c = bytes[position]
                    if c == CodeUnits.lf {
                        break // Leave LF for next iteration to handle line number
                    }
                    if (c >= CodeUnits.null && c <= CodeUnits.backspace) ||
                        (c >= CodeUnits.lf && c <= CodeUnits.unitSeparator) ||
                        c == CodeUnits.delete
                    {
                        if c == CodeUnits.cr {
                            if position + 1 < count, bytes[position + 1] == CodeUnits.lf {
                                // CRLF ends comment
                                break
                            }
                        }
                        // Let nextToken throw the error
                        cursor = position
                        currentLineNumber = lineNumber
                        try nextToken(bytes: bytes, isDotSpecial: isDotSpecial)
                        return
                    }
                    position += 1
                }
            default:
                // Found something else, stop skipping
                cursor = position
                currentLineNumber = lineNumber
                try nextToken(bytes: bytes, isDotSpecial: isDotSpecial)
                return
            }
        }

        // If we hit EOF or loop finishes
        cursor = position
        currentLineNumber = lineNumber
        try nextToken(bytes: bytes, isDotSpecial: isDotSpecial)
    }

    mutating func parseKeyedInlineTable(bytes: UnsafeBufferPointer<UInt8>, tableIndex: Int) throws(TOMLError) {
        try eatToken(bytes: bytes, kind: .lbrace, isDotSpecial: true)

        while true {
            try skipNewlines(bytes: bytes, isDotSpecial: false)

            if token.kind == .rbrace {
                break
            }

            if token.kind != .string, token.kind != .bareKey {
                throw TOMLError(.syntax(lineNumber: token.lineNumber, message: "expect a string"))
            }

            try parseKeyValue(bytes: bytes, tableIndex: tableIndex, isKeyed: true)

            try skipNewlines(bytes: bytes, isDotSpecial: false)

            if token.kind == .comma {
                try eatToken(bytes: bytes, kind: .comma, isDotSpecial: true)
                continue
            }
            break
        }

        try eatToken(bytes: bytes, kind: .rbrace, isDotSpecial: true)

        keyTables[tableIndex].table.readOnly = true
    }

    mutating func parseInlineTable(bytes: UnsafeBufferPointer<UInt8>, tableIndex: Int) throws(TOMLError) {
        try eatToken(bytes: bytes, kind: .lbrace, isDotSpecial: true)

        while true {
            try skipNewlines(bytes: bytes, isDotSpecial: false)

            if token.kind == .rbrace {
                break
            }

            if token.kind != .string, token.kind != .bareKey {
                throw TOMLError(.syntax(lineNumber: token.lineNumber, message: "expect a string"))
            }

            try parseKeyValue(bytes: bytes, tableIndex: tableIndex, isKeyed: false)

            try skipNewlines(bytes: bytes, isDotSpecial: false)

            if token.kind == .comma {
                try eatToken(bytes: bytes, kind: .comma, isDotSpecial: true)
                continue
            }
            break
        }

        try eatToken(bytes: bytes, kind: .rbrace, isDotSpecial: true)

        tables[tableIndex].readOnly = true
    }

    mutating func parseKeyedArray(bytes: UnsafeBufferPointer<UInt8>, arrayIndex: Int) throws(TOMLError) {
        try eatToken(bytes: bytes, kind: .lbracket, isDotSpecial: false)

        while true {
            try skipNewlines(bytes: bytes, isDotSpecial: false)

            if token.kind == .rbracket {
                break
            }
            if keyArrays[arrayIndex].array.elements.isEmpty {
                keyArrays[arrayIndex].array.elements.reserveCapacity(8)
            }

            switch token.kind {
            case .string, .bareKey:
                if keyArrays[arrayIndex].array.kind == nil {
                    keyArrays[arrayIndex].array.kind = .value
                } else if keyArrays[arrayIndex].array.kind != .value {
                    keyArrays[arrayIndex].array.kind = .mixed
                }

                keyArrays[arrayIndex].array.elements.append(.leaf(token))

                try nextToken(bytes: bytes, isDotSpecial: true)

            case .lbracket: // Nested array
                if keyArrays[arrayIndex].array.kind == nil {
                    keyArrays[arrayIndex].array.kind = .array
                } else if keyArrays[arrayIndex].array.kind != .array {
                    keyArrays[arrayIndex].array.kind = .mixed
                }

                let newArrayIndex = arrays.count
                arrays.append(InternalTOMLArray())
                keyArrays[arrayIndex].array.elements.append(.array(lineNumber: token.lineNumber, newArrayIndex))

                try parseArray(bytes: bytes, arrayIndex: newArrayIndex)

            case .lbrace: // Nested table
                if keyArrays[arrayIndex].array.kind == nil {
                    keyArrays[arrayIndex].array.kind = .table
                } else if keyArrays[arrayIndex].array.kind != .table {
                    keyArrays[arrayIndex].array.kind = .mixed
                }

                let newTableIndex = tables.count
                tables.append(InternalTOMLTable())
                keyArrays[arrayIndex].array.elements.append(.table(lineNumber: token.lineNumber, newTableIndex))

                try parseInlineTable(bytes: bytes, tableIndex: newTableIndex)

            default:
                throw TOMLError(.syntax(lineNumber: token.lineNumber, message: "syntax error"))
            }

            try skipNewlines(bytes: bytes, isDotSpecial: false)

            if token.kind == .comma {
                try eatToken(bytes: bytes, kind: .comma, isDotSpecial: false)
                continue
            }
            break
        }

        try eatToken(bytes: bytes, kind: .rbracket, isDotSpecial: true)
    }

    mutating func parseArray(bytes: UnsafeBufferPointer<UInt8>, arrayIndex: Int) throws(TOMLError) {
        try eatToken(bytes: bytes, kind: .lbracket, isDotSpecial: false)

        while true {
            try skipNewlines(bytes: bytes, isDotSpecial: false)

            if token.kind == .rbracket {
                break
            }
            if arrays[arrayIndex].elements.isEmpty {
                arrays[arrayIndex].elements.reserveCapacity(8)
            }

            switch token.kind {
            case .string:
                if arrays[arrayIndex].kind == nil {
                    arrays[arrayIndex].kind = .value
                } else if arrays[arrayIndex].kind != .value {
                    arrays[arrayIndex].kind = .mixed
                }

                arrays[arrayIndex].elements.append(.leaf(token))

                try nextToken(bytes: bytes, isDotSpecial: true)

            case .lbracket: // Nested array
                if arrays[arrayIndex].kind == nil {
                    arrays[arrayIndex].kind = .array
                } else if arrays[arrayIndex].kind != .array {
                    arrays[arrayIndex].kind = .mixed
                }

                let newArrayIndex = arrays.count
                arrays.append(InternalTOMLArray())
                arrays[arrayIndex].elements.append(.array(lineNumber: token.lineNumber, newArrayIndex))

                try parseArray(bytes: bytes, arrayIndex: newArrayIndex)

            case .lbrace: // Nested table
                if arrays[arrayIndex].kind == nil {
                    arrays[arrayIndex].kind = .table
                } else if arrays[arrayIndex].kind != .table {
                    arrays[arrayIndex].kind = .mixed
                }

                let newTableIndex = tables.count
                tables.append(InternalTOMLTable())
                arrays[arrayIndex].elements.append(.table(lineNumber: token.lineNumber, newTableIndex))

                try parseInlineTable(bytes: bytes, tableIndex: newTableIndex)

            default:
                throw TOMLError(.syntax(lineNumber: token.lineNumber, message: "syntax error"))
            }

            try skipNewlines(bytes: bytes, isDotSpecial: false)

            if token.kind == .comma {
                try eatToken(bytes: bytes, kind: .comma, isDotSpecial: false)
                continue
            }
            break
        }

        try eatToken(bytes: bytes, kind: .rbracket, isDotSpecial: true)
    }

    mutating func parseKeyValue(bytes: UnsafeBufferPointer<UInt8>, tableIndex: Int, isKeyed: Bool) throws(TOMLError) {
        if isKeyed ? keyTables[tableIndex].table.readOnly : tables[tableIndex].readOnly {
            throw TOMLError(.syntax(lineNumber: token.lineNumber, message: "cannot insert new entry into existing table"))
        }

        let key = token
        try nextToken(bytes: bytes, isDotSpecial: true)

        if token.kind == .dot {
            let subTableKey = try normalizeKey(bytes: bytes, token: key, keyTransform: keyTransform)
            let subTableHash = fastKeyHash(subTableKey)
            let subTableIndex: Int

            if let existingTableIndex = lookupTable(in: tableIndex, keyed: isKeyed, key: subTableKey, keyHash: subTableHash) {
                // Check if the existing table is explicitly defined (not implicit)
                if !keyTables[existingTableIndex].table.implicit {
                    throw TOMLError(.syntax(lineNumber: token.lineNumber, message: "cannot add to explicitly defined table using dotted keys"))
                }
                subTableIndex = existingTableIndex
            } else {
                subTableIndex = try createKeyTable(bytes: bytes, token: key, inTable: tableIndex, isKeyed: isKeyed, implicit: true)
            }

            try nextToken(bytes: bytes, isDotSpecial: true)
            try parseKeyValue(bytes: bytes, tableIndex: subTableIndex, isKeyed: true)
            return
        }

        if token.kind != .equal {
            throw TOMLError(.syntax(lineNumber: token.lineNumber, message: "missing ="))
        }

        try nextToken(bytes: bytes, isDotSpecial: false)

        if token.kind == .string || token.kind == .bareKey {
            let index = try createKeyValue(bytes: bytes, token: key, inTable: tableIndex, isKeyed: isKeyed)
            let value = token
            keyValues[index].value = value
            try nextToken(bytes: bytes, isDotSpecial: false)
            return
        }

        if token.kind == .lbracket {
            let index = try createKeyArray(bytes: bytes, token: key, inTable: tableIndex, isKeyed: isKeyed)
            try parseKeyedArray(bytes: bytes, arrayIndex: index)
            return
        }

        if token.kind == .lbrace {
            let index = try createKeyTable(bytes: bytes, token: key, inTable: tableIndex, isKeyed: isKeyed)
            try parseKeyedInlineTable(bytes: bytes, tableIndex: index)
            return
        }

        throw TOMLError(.syntax(lineNumber: token.lineNumber, message: "syntax error"))
    }

    mutating func fillTablePath(bytes: UnsafeBufferPointer<UInt8>) throws(TOMLError) {
        let lineNumber = token.lineNumber
        tablePath.removeAll(keepingCapacity: true)

        while true {
            if token.kind != .string, token.kind != .bareKey {
                throw TOMLError(.syntax(lineNumber: lineNumber, message: "invalid or missing key"))
            }

            let key = try normalizeKey(bytes: bytes, token: token, keyTransform: keyTransform)
            tablePath.append((key: key, keyHash: fastKeyHash(key), token: token))
            try nextToken(bytes: bytes, isDotSpecial: true)

            if token.kind == .rbracket {
                break
            }

            if token.kind != .dot {
                throw TOMLError(.syntax(lineNumber: token.lineNumber, message: "invalid key"))
            }

            try nextToken(bytes: bytes, isDotSpecial: true)
        }
        if tablePath.isEmpty {
            throw TOMLError(.syntax(lineNumber: lineNumber, message: "empty table selector"))
        }
    }

    mutating func parseSelect(bytes: UnsafeBufferPointer<UInt8>) throws(TOMLError) {
        assert(token.kind == .lbracket)
        let index = token.text.lowerBound
        let nextIndex = index + 1
        let llb = index < bytes.count
            && bytes[index] == CodeUnits.lbracket
            && nextIndex < bytes.count
            && bytes[nextIndex] == CodeUnits.lbracket

        try eatToken(bytes: bytes, kind: .lbracket, isDotSpecial: true)
        if llb {
            try eatToken(bytes: bytes, kind: .lbracket, isDotSpecial: true)
        }

        try fillTablePath(bytes: bytes)

        // For [x.y.z] or [[x.y.z]], remove z from tpath.
        let (lastKey, lastKeyHash, z) = tablePath.removeLast()
        try walkTablePath()

        if !llb {
            // [x.y.z] -> create z = {} in x.y
            currentTable = try createKeyTable(bytes: bytes, token: z, inTable: currentTable, isKeyed: currentTableIsKeyed)
            currentTableIsKeyed = true
        } else {
            // [[x.y.z]] -> create z = [] in x.y
            var maybeArrayIndex = lookupArray(in: currentTable, keyed: currentTableIsKeyed, key: lastKey, keyHash: lastKeyHash)
            if maybeArrayIndex == nil {
                maybeArrayIndex = try createKeyArray(bytes: bytes, token: z, inTable: currentTable, isKeyed: currentTableIsKeyed, kind: .table)
            }
            let arrayIndex = maybeArrayIndex!
            if keyArrays[arrayIndex].array.kind != .table {
                throw TOMLError(.syntax(lineNumber: token.lineNumber, message: "array mismatch"))
            }

            // add to z[]
            let newTableIndex = tables.count
            tables.append(InternalTOMLTable())
            keyArrays[arrayIndex].array.elements.append(.table(lineNumber: token.lineNumber, newTableIndex))
            currentTable = newTableIndex
            currentTableIsKeyed = false
        }

        if token.kind != .rbracket {
            throw TOMLError(.syntax(lineNumber: token.lineNumber, message: "expects ]"))
        }

        if llb {
            let nextIndex = token.text.index(after: token.text.startIndex)
            guard nextIndex < bytes.count, bytes[nextIndex] == CodeUnits.rbracket else {
                throw TOMLError(.syntax(lineNumber: token.lineNumber, message: "expects ]]"))
            }
            try eatToken(bytes: bytes, kind: .rbracket, isDotSpecial: true)
        }
        try eatToken(bytes: bytes, kind: .rbracket, isDotSpecial: true)

        if token.kind != .newline, token.kind != .eof {
            throw TOMLError(.syntax(lineNumber: token.lineNumber, message: "extra chars after ] or ]]"))
        }
    }
}

extension Token {
    func unpackBool(bytes: UnsafeBufferPointer<UInt8>, context: TOMLKey) throws(TOMLError) -> Bool {
        if text.count == 4,
           bytes[text.lowerBound] == CodeUnits.lowerT,
           bytes[text.lowerBound + 1] == CodeUnits.lowerR,
           bytes[text.lowerBound + 2] == CodeUnits.lowerU,
           bytes[text.lowerBound + 3] == CodeUnits.lowerE
        {
            return true
        } else if text.count == 5,
                  bytes[text.lowerBound] == CodeUnits.lowerF,
                  bytes[text.lowerBound + 1] == CodeUnits.lowerA,
                  bytes[text.lowerBound + 2] == CodeUnits.lowerL,
                  bytes[text.lowerBound + 3] == CodeUnits.lowerS,
                  bytes[text.lowerBound + 4] == CodeUnits.lowerE
        {
            return false
        }

        throw TOMLError(.invalidBool(context: context, lineNumber: lineNumber))
    }

    func unpackFloat(bytes: UnsafeBufferPointer<UInt8>, context: TOMLKey) throws(TOMLError) -> Double {
        var resultCodeUnits: [UTF8.CodeUnit] = []
        var index = text.lowerBound
        if bytes[index] == CodeUnits.plus || bytes[index] == CodeUnits.minus {
            resultCodeUnits.append(bytes[index])
            index += 1
        }

        if !bytes[index].isDecimalDigit {
            guard (
                bytes[index] == CodeUnits.lowerN &&
                    bytes[index + 1] == CodeUnits.lowerA &&
                    bytes[index + 2] == CodeUnits.lowerN
            ) ||
                (
                    bytes[index] == CodeUnits.lowerI &&
                        bytes[index + 1] == CodeUnits.lowerN &&
                        bytes[index + 2] == CodeUnits.lowerF
                )
            else {
                throw TOMLError(.invalidFloat(context: context, lineNumber: lineNumber, reason: "Expected nan or inf, found \(bytes[index])"))
            }
            resultCodeUnits.append(bytes[index])
            resultCodeUnits.append(bytes[index + 1])
            resultCodeUnits.append(bytes[index + 2])
        } else {
            if bytes[index] == CodeUnits.number0,
               index < text.upperBound,
               case let next = bytes[index + 1],
               next != CodeUnits.dot, next != CodeUnits.lowerE, next != CodeUnits.upperE
            {
                throw TOMLError(.invalidFloat(context: context, lineNumber: lineNumber, reason: "Float begins with 0 must be followed by a '.', 'e' or 'E'"))
            }

            while index < text.upperBound {
                let ch = bytes[index]
                index += 1

                if ch == CodeUnits.underscore {
                    guard
                        let last = resultCodeUnits.last,
                        last.isDecimalDigit
                    else {
                        throw TOMLError(.invalidFloat(context: context, lineNumber: lineNumber, reason: "'_' must be preceded by a digit"))
                    }

                    guard
                        index < text.upperBound,
                        case let next = bytes[index],
                        next.isDecimalDigit
                    else {
                        throw TOMLError(.invalidFloat(context: context, lineNumber: lineNumber, reason: "'_' must be follewed by a digit"))
                    }

                    continue
                } else if ch == CodeUnits.dot {
                    if resultCodeUnits.isEmpty {
                        throw TOMLError(.invalidFloat(context: context, lineNumber: lineNumber, reason: "First digit of floats cannot be '.'"))
                    }

                    if !resultCodeUnits.last!.isDecimalDigit {
                        throw TOMLError(.invalidFloat(context: context, lineNumber: lineNumber, reason: "'.' must be preceded by a decimal digit"))
                    }

                    guard index < text.upperBound, bytes[index].isDecimalDigit else {
                        throw TOMLError(.invalidFloat(context: context, lineNumber: lineNumber, reason: "A digit must follow '.'"))
                    }

                } else if ch == CodeUnits.upperE || ch == CodeUnits.lowerE {
                } else if !ch.isDecimalDigit, ch != CodeUnits.plus, ch != CodeUnits.minus {
                    throw TOMLError(.invalidFloat(context: context, lineNumber: lineNumber, reason: "invalid character for float"))
                }

                resultCodeUnits.append(ch)
            }
        }

        guard let double = Double(String(decoding: resultCodeUnits, as: UTF8.self)) else {
            throw TOMLError(.invalidFloat(context: context, lineNumber: lineNumber, reason: "not a float"))
        }

        return double
    }

    func unpackString(bytes: UnsafeBufferPointer<UInt8>, context: TOMLKey) throws(TOMLError) -> String {
        var multiline = false

        if bytes.count == 0 {
            throw TOMLError(.invalidString(context: context, lineNumber: lineNumber, reason: "missing closing quote"))
        }

        let quoteChar = bytes[text.lowerBound]
        var index = text.lowerBound
        var endIndex = text.upperBound

        if endIndex - index >= 3 && bytes[index] == CodeUnits.doubleQuote && bytes[index + 1] == CodeUnits.doubleQuote && bytes[index + 2] == CodeUnits.doubleQuote ||
            endIndex - index >= 3 && bytes[index] == CodeUnits.singleQuote && bytes[index + 1] == CodeUnits.singleQuote && bytes[index + 2] == CodeUnits.singleQuote
        {
            multiline = true
            index += 3
            endIndex -= 3

            if index < endIndex, bytes[index] == CodeUnits.lf {
                index += 1
            } else if endIndex - index >= 2, bytes[index] == CodeUnits.cr, bytes[index + 1] == CodeUnits.lf {
                index += 2
            }
        } else {
            index = index + 1
            endIndex = endIndex - 1
            guard endIndex >= 0, bytes[endIndex] == quoteChar else {
                throw TOMLError(.invalidString(context: context, lineNumber: lineNumber, reason: "missing closing quote"))
            }
        }

        if quoteChar == CodeUnits.singleQuote {
            return try literalString(bytes: bytes, range: index ..< endIndex, multiline: multiline)
        } else {
            return try basicString(bytes: bytes, range: index ..< endIndex, multiline: multiline)
        }
    }

    func unpackInteger(bytes: UnsafeBufferPointer<UInt8>, context: TOMLKey) throws(TOMLError) -> Int64 {
        @_transparent
        func isValidDigit(_ codeUnit: UTF8.CodeUnit, base: Int) -> Bool {
            switch base {
            case 10:
                codeUnit.isDecimalDigit
            case 16:
                codeUnit.isHexDigit
            case 2:
                codeUnit == CodeUnits.number0 || codeUnit == CodeUnits.number1
            case 8:
                CodeUnits.number0 <= codeUnit && codeUnit <= CodeUnits.number7
            default:
                false
            }
        }

        var resultCodeUnits: [UTF8.CodeUnit] = []
        var index = text.lowerBound
        var base = 10
        var hasSign = false
        if bytes[index] == CodeUnits.plus || bytes[index] == CodeUnits.minus {
            hasSign = true
            resultCodeUnits.append(bytes[index])
            index = text.index(after: index)
        }

        if bytes[index] == CodeUnits.underscore {
            throw TOMLError(.invalidInteger(context: context, lineNumber: lineNumber, reason: "cannot start with a '_'"))
        }

        if bytes[index] == CodeUnits.number0 {
            let nextIndex = index + 1
            if nextIndex < text.upperBound {
                if bytes[nextIndex] == CodeUnits.lowerX {
                    if hasSign {
                        throw TOMLError(.invalidInteger(context: context, lineNumber: lineNumber, reason: "hexadecimal integers cannot have explicit signs"))
                    }
                    base = 16
                    index += 2
                } else if bytes[nextIndex] == CodeUnits.lowerO {
                    if hasSign {
                        throw TOMLError(.invalidInteger(context: context, lineNumber: lineNumber, reason: "octal integers cannot have explicit signs"))
                    }
                    base = 8
                    index += 2
                } else if bytes[nextIndex] == CodeUnits.lowerB {
                    if hasSign {
                        throw TOMLError(.invalidInteger(context: context, lineNumber: lineNumber, reason: "binary integers cannot have explicit signs"))
                    }
                    base = 2
                    index += 2
                } else if bytes[nextIndex].isDecimalDigit || bytes[nextIndex] == CodeUnits.underscore {
                    throw TOMLError(.invalidInteger(context: context, lineNumber: lineNumber, reason: "decimal integers cannot have leading zeros"))
                }
            }
            // Single zero is allowed to continue to the main loop
        }

        while index < text.upperBound {
            let ch = bytes[index]
            index += 1

            if ch == CodeUnits.underscore {
                guard
                    let last = resultCodeUnits.last,
                    isValidDigit(last, base: base)
                else {
                    throw TOMLError(.invalidInteger(context: context, lineNumber: lineNumber, reason: "cannot use '_' adjacent to a non-digit"))
                }

                if index >= text.endIndex {
                    throw TOMLError(.invalidInteger(context: context, lineNumber: lineNumber, reason: "cannot end with a '_'"))
                }

                let next = bytes[index]
                if next == CodeUnits.underscore {
                    throw TOMLError(.invalidInteger(context: context, lineNumber: lineNumber, reason: "cannot contain consecutive '_'"))
                }
                guard isValidDigit(next, base: base) else {
                    throw TOMLError(.invalidInteger(context: context, lineNumber: lineNumber, reason: "cannot use '_' adjacent to a non-digit"))
                }
                continue
            }

            guard isValidDigit(ch, base: base) else {
                throw TOMLError(.invalidInteger(context: context, lineNumber: lineNumber, reason: "invalid digit for base \(base)"))
            }

            resultCodeUnits.append(ch)
        }

        let s = String(decoding: resultCodeUnits, as: UTF8.self)
        guard let i = Int64(s, radix: base) else {
            throw TOMLError(.invalidInteger(context: context, lineNumber: lineNumber, reason: "\(s) is a invalid integer of base \(base)"))
        }
        return i
    }

    func unpackDateTime(bytes: UnsafeBufferPointer<UInt8>, context: TOMLKey) throws(TOMLError) -> DateTimeComponents {
        var mustParseTime = false
        var date: (year: Int, month: Int, day: Int)?
        var time: (hour: Int, minute: Int, second: Int)?

        var index = text.lowerBound
        if let (year, month, day, _) = scanDate(bytes: bytes, range: text) {
            // Validate date components
            if month < 1 || month > 12 {
                throw TOMLError(.invalidDateTime3(context: context, lineNumber: lineNumber, reason: "month must be between 01 and 12"))
            }
            if day < 1 {
                throw TOMLError(.invalidDateTime3(context: context, lineNumber: lineNumber, reason: "day must be between 01 and 31"))
            }

            // Validate days per month and leap years
            let isLeapYear = year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)
            let maxDaysInMonth: Int = switch month {
            case 2:
                isLeapYear ? 29 : 28
            case 4, 6, 9, 11:
                30
            default:
                31
            }

            if day > maxDaysInMonth {
                if month == 2, !isLeapYear {
                    throw TOMLError(.invalidDateTime3(context: context, lineNumber: lineNumber, reason: "February only has 28 days in non-leap years"))
                } else if month == 2, isLeapYear {
                    throw TOMLError(.invalidDateTime3(context: context, lineNumber: lineNumber, reason: "February only has 29 days in leap years"))
                } else {
                    throw TOMLError(.invalidDateTime3(context: context, lineNumber: lineNumber, reason: "day \(day) is invalid for month \(month)"))
                }
            }

            date = (year, month, day)
            index += 10
        }

        var features: OffsetDateTime.Features = []
        var nanoseconds: UInt32?
        if index < text.upperBound {
            if date != nil {
                let isSeparatorLowerT = bytes[index] == CodeUnits.lowerT
                let isSeparatorUpperT = bytes[index] == CodeUnits.upperT
                guard isSeparatorLowerT || isSeparatorUpperT || bytes[index] == CodeUnits.space else {
                    throw TOMLError(.invalidDateTime3(context: context, lineNumber: lineNumber, reason: "expected 'T' or 't' or space to separate date and time"))
                }
                if isSeparatorLowerT {
                    features.insert(.lowercaseT)
                } else if isSeparatorUpperT {
                    features.insert(.uppercaseT)
                }
                mustParseTime = true
                index += 1
            } else {
                // For standalone time values, don't advance index
                mustParseTime = true
            }
            if let (hour, minute, second, newIndex) = scanTime(bytes: bytes, range: index ..< text.upperBound) {
                // Validate time components
                if hour > 23 {
                    throw TOMLError(.invalidDateTime3(context: context, lineNumber: lineNumber, reason: "hour must be between 00 and 23"))
                }
                if minute > 59 {
                    throw TOMLError(.invalidDateTime3(context: context, lineNumber: lineNumber, reason: "minute must be between 00 and 59"))
                }
                if second > 59 {
                    throw TOMLError(.invalidDateTime3(context: context, lineNumber: lineNumber, reason: "second must be between 00 and 59"))
                }

                time = (hour, minute, second)

                index = newIndex
                if index < text.upperBound, bytes[index] == CodeUnits.dot {
                    index += 1
                    let beforeNanoIndex = index
                    nanoseconds = parseNanoSeconds(bytes: bytes, range: index ..< text.upperBound, updatedIndex: &index)
                    // Must have at least one digit after decimal point
                    if index == beforeNanoIndex {
                        throw TOMLError(.invalidDateTime3(context: context, lineNumber: lineNumber, reason: "decimal point must be followed by digits"))
                    }
                }
            }
        }

        if mustParseTime, time == nil {
            throw TOMLError(.invalidDateTime3(context: context, lineNumber: lineNumber, reason: "expected valid time"))
        }

        var timeOffset: Int16?
        if index < text.upperBound {
            if bytes[index] == CodeUnits.lowerZ {
                features.insert(.lowercaseZ)
                index += 1
                timeOffset = 0
            } else if bytes[index] == CodeUnits.upperZ {
                features.insert(.uppercaseZ)
                index += 1
                timeOffset = 0
            } else if bytes[index] == CodeUnits.plus || bytes[index] == CodeUnits.minus {
                let offsetIsNegative = bytes[index] == CodeUnits.minus
                index += 1

                // Scan ahead to find the end of the timezone offset
                var endIndex = index
                while endIndex < text.upperBound {
                    let ch = bytes[endIndex]
                    if ch.isDecimalDigit || ch == CodeUnits.colon {
                        endIndex += 1
                    } else {
                        break
                    }
                }

                do {
                    let (offsetHour, offsetMinute, consumedLength) = try parseTimezoneOffset(bytes: bytes, range: index ..< endIndex, lineNumber: lineNumber)

                    // Validate timezone offset ranges
                    if offsetHour > 24 {
                        throw TOMLError(.invalidDateTime3(context: context, lineNumber: lineNumber, reason: "timezone offset hour must be between 00 and 24"))
                    }
                    if offsetMinute > 59 {
                        throw TOMLError(.invalidDateTime3(context: context, lineNumber: lineNumber, reason: "timezone offset minute must be between 00 and 59"))
                    }

                    let offsetInMinutes = offsetHour * 60 + offsetMinute
                    timeOffset = Int16(offsetIsNegative ? -offsetInMinutes : offsetInMinutes)
                    index += consumedLength
                } catch let parseError {
                    if let tomlError = parseError as? TOMLError {
                        switch tomlError.reason {
                        case let .invalidDateTime(_, reason):
                            throw TOMLError(.invalidDateTime3(context: context, lineNumber: lineNumber, reason: reason))
                        default:
                            throw tomlError
                        }
                    } else {
                        throw TOMLError(.invalidDateTime3(context: context, lineNumber: lineNumber, reason: "timezone parsing error"))
                    }
                }
            }
        }

        if index < text.upperBound {
            throw TOMLError(.invalidDateTime3(context: context, lineNumber: lineNumber, reason: "extra character after date time"))
        }

        return DateTimeComponents(
            date: date.map { LocalDate(year: .init($0.year), month: .init($0.month), day: .init($0.day)) },
            time: time.map { LocalTime(hour: .init($0.hour), minute: .init($0.minute), second: .init($0.second), nanosecond: nanoseconds ?? 0) },
            offset: timeOffset,
            features: features
        )
    }

    func unpackAnyValue(bytes: UnsafeBufferPointer<UInt8>, context: TOMLKey) throws(TOMLError) -> Any {
        let firstChar = text.count > 0 ? bytes[text.lowerBound] : nil
        if firstChar == CodeUnits.singleQuote || firstChar == CodeUnits.doubleQuote {
            return try unpackString(bytes: bytes, context: context)
        }

        if let boolValue = try? unpackBool(bytes: bytes, context: context) {
            return boolValue
        }

        if let intValue = try? unpackInteger(bytes: bytes, context: context) {
            return intValue
        }

        if let floatValue = try? unpackFloat(bytes: bytes, context: context) {
            return floatValue
        }

        guard firstChar?.isDecimalDigit == true else {
            throw TOMLError(.invalidValueInTable(context: context, lineNumber: lineNumber))
        }

        let datetime = try unpackDateTime(bytes: bytes, context: context)
        switch (datetime.date, datetime.time, datetime.offset) {
        case let (.some(date), .some(time), .some(offset)):
            return OffsetDateTime(date: date, time: time, offset: offset, features: datetime.features)
        case let (.some(date), .some(time), .none):
            return LocalDateTime(date: date, time: time)
        case let (.some(date), .none, .none):
            return date
        case let (.none, .some(time), .none):
            return time
        default:
            throw TOMLError(.invalidValueInTable(context: context, lineNumber: lineNumber))
        }
    }
}

func parseTimezoneOffset(bytes: UnsafeBufferPointer<UInt8>, range: Range<Int>, lineNumber: Int) throws(TOMLError) -> (hour: Int, minute: Int, consumedLength: Int) {
    guard range.count >= 2 else {
        throw TOMLError(.invalidDateTime(lineNumber: lineNumber, reason: "timezone offset must have at least 2 digits for hour"))
    }

    var index = range.lowerBound

    // Parse hour digits (exactly 2 required)
    guard
        index < range.upperBound,
        bytes[index].isDecimalDigit,
        case let firstHourDigit = bytes[index],
        case let nextIndex = index + 1,
        nextIndex < range.upperBound,
        bytes[nextIndex].isDecimalDigit,
        case let secondHourDigit = bytes[nextIndex]
    else {
        throw TOMLError(.invalidDateTime(lineNumber: lineNumber, reason: "timezone offset hour must be exactly 2 digits"))
    }

    let offsetHour = Int(firstHourDigit - CodeUnits.number0) * 10 + Int(secondHourDigit - CodeUnits.number0)
    index += 2
    var consumedLength = 2

    // Parse required minute digits (timezone offset must include minutes)
    guard index < range.upperBound, bytes[index] == CodeUnits.colon else {
        throw TOMLError(.invalidDateTime(lineNumber: lineNumber, reason: "timezone offset must include minutes (format: ±HH:MM)"))
    }

    index += 1
    consumedLength += 1

    guard
        index < range.upperBound,
        bytes[index].isDecimalDigit,
        case let firstMinuteDigit = bytes[index],
        case let nextMinuteIndex = index + 1,
        nextMinuteIndex < range.upperBound,
        bytes[nextMinuteIndex].isDecimalDigit,
        case let secondMinuteDigit = bytes[nextMinuteIndex]
    else {
        throw TOMLError(.invalidDateTime(lineNumber: lineNumber, reason: "timezone offset minute must be exactly 2 digits"))
    }

    let offsetMinute = Int(firstMinuteDigit - CodeUnits.number0) * 10 + Int(secondMinuteDigit - CodeUnits.number0)
    consumedLength += 2

    return (offsetHour, offsetMinute, consumedLength)
}

func literalString(bytes: UnsafeBufferPointer<UInt8>, range: Range<Int>, multiline: Bool) throws(TOMLError) -> String {
    var resultCodeUnits: [UTF8.CodeUnit] = []
    var consecutiveQuotes = 0

    for index in range {
        let codeUnit = bytes[index]
        if codeUnit >= CodeUnits.null && codeUnit <= CodeUnits.backspace || codeUnit >= CodeUnits.lf && codeUnit <= CodeUnits.unitSeparator || codeUnit == CodeUnits.delete {
            if multiline, codeUnit == CodeUnits.lf {
                // Allow LF in multiline literal strings
            } else if multiline, codeUnit == CodeUnits.cr {
                // Only allow CR if followed by LF (CRLF sequence)
                let nextIndex = index + 1
                if nextIndex < range.upperBound, bytes[nextIndex] == CodeUnits.lf {
                    // Allow CRLF sequence - will be processed as separate characters
                } else {
                    throw TOMLError(.invalidCharacter(codeUnit))
                }
            } else {
                throw TOMLError(.invalidCharacter(codeUnit))
            }
        }

        if multiline, codeUnit == CodeUnits.singleQuote {
            consecutiveQuotes += 1
            if consecutiveQuotes > 2 {
                throw TOMLError(.syntax(lineNumber: 0, message: "literal multiline strings cannot contain more than 2 consecutive single quotes"))
            }
        } else {
            consecutiveQuotes = 0
        }

        resultCodeUnits.append(codeUnit)
    }
    return String(decoding: resultCodeUnits, as: UTF8.self)
}

func basicString(bytes: UnsafeBufferPointer<UInt8>, range: Range<Int>, multiline: Bool) throws(TOMLError) -> String {
    let startIndex = range.lowerBound
    let endIndex = range.upperBound
    var resultCodeUnits: [UTF8.CodeUnit] = []
    resultCodeUnits.reserveCapacity(range.count)
    var consecutiveQuotes = 0
    var index = startIndex
    while true {
        if index >= endIndex {
            break
        }

        var ch = bytes[index]
        index += 1
        if ch != CodeUnits.backslash {
            if ch >= CodeUnits.null && ch <= CodeUnits.backspace
                || ch >= CodeUnits.lf && ch <= CodeUnits.unitSeparator || ch == CodeUnits.delete
            {
                if multiline, ch == CodeUnits.lf {
                    // Allow LF in multiline basic strings
                } else if multiline, ch == CodeUnits.cr {
                    // Only allow CR if followed by LF (CRLF sequence)
                    if index < endIndex, bytes[index] == CodeUnits.lf {
                        // Allow CRLF sequence - will be processed as separate characters
                    } else {
                        throw TOMLError(.invalidCharacter(ch))
                    }
                } else {
                    throw TOMLError(.invalidCharacter(ch))
                }
            }

            if multiline, ch == CodeUnits.doubleQuote {
                consecutiveQuotes += 1
                if consecutiveQuotes > 2 {
                    throw TOMLError(
                        .syntax(
                            lineNumber: 0,
                            message:
                            "basic multiline strings cannot contain more than 2 consecutive double quotes"
                        )
                    )
                }
            } else {
                consecutiveQuotes = 0
            }

            resultCodeUnits.append(ch)
            continue
        }

        if index >= endIndex {
            throw TOMLError(.invalidCharacter(CodeUnits.backslash))
        }

        func indexAfterSkippingCharacters(start: Int, endIndex: Int, characters: [UTF8.CodeUnit])
            -> Int
        {
            var index = start
            while index < endIndex {
                if characters.contains(bytes[index]) {
                    index += 1
                } else {
                    break
                }
            }
            return index
        }

        if multiline {
            let afterWhitespace = indexAfterSkippingCharacters(
                start: index, endIndex: endIndex,
                characters: [CodeUnits.space, CodeUnits.tab, CodeUnits.cr]
            )
            if afterWhitespace < endIndex, bytes[afterWhitespace] == CodeUnits.lf {
                index = indexAfterSkippingCharacters(
                    start: index, endIndex: endIndex,
                    characters: [CodeUnits.space, CodeUnits.tab, CodeUnits.cr, CodeUnits.lf]
                )
                continue
            }
        }

        ch = bytes[index]
        index += 1

        if ch == CodeUnits.lowerU || ch == CodeUnits.upperU || ch == CodeUnits.lowerX {
            let hexCount = switch ch {
            case CodeUnits.lowerU: 4
            case CodeUnits.upperU: 8
            case CodeUnits.lowerX: 2
            default: fatalError("Unsupported CodeUnit: \(ch)")
            }
            var ucs: UInt32 = 0
            for _ in 0 ..< hexCount {
                if index >= endIndex {
                    throw TOMLError(.expectedHexCharacters(ch, hexCount))
                }
                ch = bytes[index]
                index += 1
                let v: Int32 =
                    ch.isDecimalDigit
                        ? Int32(ch - CodeUnits.number0)
                        : (ch >= CodeUnits.upperA && ch <= CodeUnits.upperF)
                        ? Int32(ch - CodeUnits.upperA + 10)
                        : (ch >= CodeUnits.lowerA && ch <= CodeUnits.lowerF)
                        ? Int32(ch - CodeUnits.lowerA + 10)
                        : -1
                if v == -1 {
                    throw TOMLError(.invalidHexCharacters(ch))
                }
                ucs = ucs * 16 + UInt32(v)
            }
            guard let scalar = Unicode.Scalar(ucs) else {
                throw TOMLError(.illegalUCSCode(ucs))
            }
            resultCodeUnits.append(contentsOf: scalar.utf8)
            continue
        } else if ch == CodeUnits.lowerB {
            ch = CodeUnits.backspace
        } else if ch == CodeUnits.lowerT {
            ch = CodeUnits.tab
        } else if ch == CodeUnits.lowerF {
            ch = CodeUnits.formfeed
        } else if ch == CodeUnits.lowerR {
            ch = CodeUnits.cr
        } else if ch == CodeUnits.lowerN {
            ch = CodeUnits.lf
        } else if ch == CodeUnits.lowerE {
            ch = CodeUnits.escape
        } else if ch != CodeUnits.doubleQuote, ch != CodeUnits.backslash {
            throw TOMLError(.illegalEscapeCharacter(ch))
        }

        consecutiveQuotes = 0 // Reset count after escape sequence
        resultCodeUnits.append(ch)
    }
    return String(decoding: resultCodeUnits, as: UTF8.self)
}

func scanDate(bytes: UnsafeBufferPointer<UInt8>, range: Range<Int>) -> (Int, Int, Int, Int)? {
    guard let year = scanDigits(bytes: bytes, range: range, n: 4) else {
        return nil
    }

    var index = range.lowerBound
    index += 4

    guard index < range.upperBound, bytes[index] == CodeUnits.minus else {
        return nil
    }

    index += 1
    guard let month = scanDigits(bytes: bytes, range: index ..< range.upperBound, n: 2) else {
        return nil
    }

    index += 2
    guard bytes[index] == CodeUnits.minus else {
        return nil
    }

    index += 1
    guard let day = scanDigits(bytes: bytes, range: index ..< range.upperBound, n: 2) else {
        return nil
    }

    index += 2
    return (year, month, day, index)
}

func scanDigits(bytes: UnsafeBufferPointer<UInt8>, range: Range<Int>, n: Int) -> Int? {
    var result = 0
    var n = n
    var index = range.lowerBound
    while n > 0, index < range.upperBound, bytes[index].isDecimalDigit {
        result = 10 * result + Int(bytes[index]) - Int(CodeUnits.number0)
        index += 1
        n -= 1
    }
    return n != 0 ? nil : result
}

func scanTime(bytes: UnsafeBufferPointer<UInt8>, range: Range<Int>) -> (Int, Int, Int, Int)? {
    guard let hour = scanDigits(bytes: bytes, range: range, n: 2) else {
        return nil
    }

    var index = range.lowerBound

    index += 2
    guard index < range.upperBound, bytes[index] == CodeUnits.colon else {
        return nil
    }

    index += 1
    guard let minute = scanDigits(bytes: bytes, range: index ..< range.upperBound, n: 2) else {
        return nil
    }

    index += 2
    guard index < range.upperBound, bytes[index] == CodeUnits.colon else {
        return (hour, minute, 0, index) // Seconds are optional since 1.1.0. When omitted, :00 seconds is assumed
    }

    index += 1
    guard let second = scanDigits(bytes: bytes, range: index ..< range.upperBound, n: 2) else {
        return nil
    }

    index += 2
    return (hour, minute, second, index)
}

func parseNanoSeconds(bytes: UnsafeBufferPointer<UInt8>, range: Range<Int>, updatedIndex: inout Int) -> UInt32 {
    var unit: Double = 100_000_000
    var result: Double = 0
    var index = range.lowerBound
    while index < range.upperBound, bytes[index].isDecimalDigit {
        result += Double(bytes[index] - CodeUnits.number0) * unit
        index += 1
        unit /= 10
    }
    updatedIndex = index
    return UInt32(result)
}

func scanTimezoneOffset(bytes: UnsafeBufferPointer<UInt8>, range: Range<Int>) -> Int? {
    var index = range.lowerBound
    guard index < range.upperBound, bytes[index] == CodeUnits.plus || bytes[index] == CodeUnits.minus else {
        return nil
    }

    index += 1
    guard let _ = scanDigits(bytes: bytes, range: index ..< range.upperBound, n: 2) else {
        return nil
    }

    index += 2
    guard index < range.upperBound, bytes[index] == CodeUnits.colon else {
        return nil
    }

    index += 1
    guard let _ = scanDigits(bytes: bytes, range: index ..< range.upperBound, n: 2) else {
        return nil
    }
    index += 2
    return index
}

func normalizeKey(bytes: UnsafeBufferPointer<UInt8>, token: Token, keyTransform: (@Sendable (String) -> String)?) throws(TOMLError) -> String {
    var start = token.text.lowerBound
    var end = token.text.upperBound
    if token.kind == .bareKey {
        var str = makeString(bytes: bytes, range: start ..< end)
        if let keyTransform {
            str = keyTransform(str)
        }
        return str
    }

    let ch = bytes[start]
    var result = ""
    if ch == CodeUnits.doubleQuote || ch == CodeUnits.singleQuote {
        if bytes[start + 1] == ch, bytes[start + 2] == ch {
            // Keys cannot be multiline
            throw TOMLError(.badKey(lineNumber: token.lineNumber))
        } else {
            start = start + 1
            end = end - 1
        }

        if ch == CodeUnits.singleQuote {
            result = makeString(bytes: bytes, range: start ..< end)
        } else {
            result = try basicString(bytes: bytes, range: start ..< end, multiline: false)
        }

        return result
    }

    for i in start ..< end {
        let byte = bytes[i]
        if byte >= CodeUnits.number0 && byte <= CodeUnits.number9 || // 0-9
            byte >= CodeUnits.upperA && byte <= CodeUnits.upperZ || // A-Z
            byte >= CodeUnits.lowerA && byte <= CodeUnits.lowerZ || // a-z
            byte == CodeUnits.underscore || // _
            byte == CodeUnits.minus // -
        {
            continue
        }
        throw TOMLError(.badKey(lineNumber: token.lineNumber))
    }

    if let keyTransform {
        return keyTransform(makeString(bytes: bytes, range: start ..< end))
    }

    return makeString(bytes: bytes, range: start ..< end)
}

@inline(__always)
func fastKeyHash(_ key: String) -> Int {
    let offsetBasis: UInt64 = 14_695_981_039_346_656_037
    let prime: UInt64 = 1_099_511_628_211

    if let hash = key.utf8.withContiguousStorageIfAvailable({ buffer -> UInt64 in
        if buffer.count <= 8 {
            return packedKeyHash(buffer)
        }
        var hash = offsetBasis
        for byte in buffer {
            hash ^= UInt64(byte)
            hash &*= prime
        }
        return hash
    }) {
        return Int(truncatingIfNeeded: hash)
    }

    var hash = offsetBasis
    var packed: UInt64 = 0
    var count = 0
    for byte in key.utf8 {
        if count < 8 {
            packed |= UInt64(byte) << (UInt64(count) * 8)
        }
        hash ^= UInt64(byte)
        hash &*= prime
        count += 1
    }
    return Int(truncatingIfNeeded: count <= 8 ? packed : hash)
}

@inline(__always)
private func packedKeyHash(_ buffer: UnsafeBufferPointer<UInt8>) -> UInt64 {
    var packed: UInt64 = 0
    switch buffer.count {
    case 8:
        packed |= UInt64(buffer[7]) << 56
        fallthrough
    case 7:
        packed |= UInt64(buffer[6]) << 48
        fallthrough
    case 6:
        packed |= UInt64(buffer[5]) << 40
        fallthrough
    case 5:
        packed |= UInt64(buffer[4]) << 32
        fallthrough
    case 4:
        packed |= UInt64(buffer[3]) << 24
        fallthrough
    case 3:
        packed |= UInt64(buffer[2]) << 16
        fallthrough
    case 2:
        packed |= UInt64(buffer[1]) << 8
        fallthrough
    case 1:
        packed |= UInt64(buffer[0])
    default:
        break
    }
    return packed
}

private func makeString(bytes: UnsafeBufferPointer<UInt8>, range: Range<Int>) -> String {
    String(decoding: bytes[range], as: UTF8.self)
}

extension Parser {
    func tableValue(tableIndex: Int, keyed: Bool, key: String, keyHash: Int) -> InternalTOMLTable.Value? {
        let table = keyed ? keyTables[tableIndex].table : tables[tableIndex]
        for kv in table.keyValues {
            let kvPair = keyValues[kv]
            if kvPair.keyHash == keyHash, kvPair.key == key {
                return .keyValue(kv)
            }
        }

        for arr in table.arrays {
            let arrPair = keyArrays[arr]
            if arrPair.keyHash == keyHash, arrPair.key == key {
                return .array(arr)
            }
        }

        for table in table.tables {
            let tablePair = keyTables[table]
            if tablePair.keyHash == keyHash, tablePair.key == key {
                return .table(table)
            }
        }

        return nil
    }

    func lookupTable(in tableIndex: Int, keyed: Bool, key: String, keyHash: Int) -> Int? {
        let table = keyed ? keyTables[tableIndex].table : tables[tableIndex]
        for i in 0 ..< table.tables.count {
            let tableIndexAtPosition = table.tables[i]
            let tablePair = keyTables[tableIndexAtPosition]
            if tablePair.keyHash == keyHash, tablePair.key == key {
                return tableIndexAtPosition
            }
        }
        return nil
    }

    func lookupArray(in tableIndex: Int, keyed: Bool, key: String, keyHash: Int) -> Int? {
        let table = keyed ? keyTables[tableIndex].table : tables[tableIndex]
        for i in 0 ..< table.arrays.count {
            let arrayIndex = table.arrays[i]
            let arrPair = keyArrays[arrayIndex]
            if arrPair.keyHash == keyHash, arrPair.key == key {
                return arrayIndex
            }
        }
        return nil
    }

    mutating func walkTablePath() throws(TOMLError) {
        var tableIndex = 0
        var isKeyed = false
        for (key, keyHash, _) in tablePath {
            switch tableValue(tableIndex: tableIndex, keyed: isKeyed, key: key, keyHash: keyHash) {
            case let .table(index):
                tableIndex = index
                isKeyed = true
            case let .array(arrayIndex):
                let array = keyArrays[arrayIndex].array
                guard case .table = array.kind else {
                    throw TOMLError(.syntax(lineNumber: token.lineNumber, message: "array element is not a table"))
                }

                if array.elements.isEmpty {
                    throw TOMLError(.syntax(lineNumber: token.lineNumber, message: "empty array"))
                }

                guard case let .table(_, index) = array.elements.last else {
                    throw TOMLError(.syntax(lineNumber: token.lineNumber, message: "array element is not a table"))
                }

                tableIndex = index
                isKeyed = false
            case .keyValue:
                throw TOMLError(.syntax(lineNumber: token.lineNumber, message: "key-value already exists"))
            default:
                let newTableAddress = keyTables.count
                var newTable = InternalTOMLTable()
                newTable.implicit = true
                newTable.definedByDottedKey = false
                keyTables.append(KeyTablePair(key: key, keyHash: keyHash, table: newTable))

                if isKeyed {
                    keyTables[tableIndex].table.tables.append(newTableAddress)
                } else {
                    tables[tableIndex].tables.append(newTableAddress)
                }
                tableIndex = newTableAddress
                isKeyed = true
            }
        }

        currentTable = tableIndex
        currentTableIsKeyed = isKeyed
    }
}
