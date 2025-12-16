struct Parser {
    var token = Token.empty
    var cursor = 0
    var currentLineNumber = 1
    var currentTable = 0
    var currentTableIsKeyed = false
    var tablePath: [(String, Token)] = []
    var tables: [InternalTOMLTable] = [InternalTOMLTable()]
    var arrays: [InternalTOMLArray] = []
    var keyTables: [KeyTablePair] = []
    var keyArrays: [KeyArrayPair] = []
    var keyValues: [KeyValuePair] = []
    var keyTransform: (@Sendable (String) -> String)?
}
