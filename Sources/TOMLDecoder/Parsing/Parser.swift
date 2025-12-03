struct Parser {
    var token = Token.empty
    var currentTable = 0
    var tablePath: [(String, Token)] = []
    var tables: [InternalTOMLTable] = [InternalTOMLTable()]
    var arrays: [InternalTOMLArray] = []
    var keyValues: [KeyValuePair] = []
    var keyTransform: (@Sendable (String) -> String)?
}
