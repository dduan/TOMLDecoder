struct Parser {
    var token = Token.empty
    var currentTable = 0
    var currentTableIsKeyed = false
    var tablePath: [(String, Token)] = []
    var tables: [InternalTOMLTable] = [InternalTOMLTable()]
    var arrays: [InternalTOMLArray] = []
    var keyTables: [InternalTOMLTable] = []
    var keyTableKeys: [String] = []
    var keyArrays: [InternalTOMLArray] = []
    var keyArrayKeys: [String] = []
    var keyValues: [KeyValuePair] = []
    var keyTransform: (@Sendable (String) -> String)?
}
