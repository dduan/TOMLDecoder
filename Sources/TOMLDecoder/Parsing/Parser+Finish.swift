extension Parser {
    consuming func finish(source: String) -> TOMLDocument {
        var tables: [InternalTOMLTable] = []
        var arrays: [InternalTOMLArray] = []
        var keyTables: [KeyTablePair] = []
        var keyArrays: [KeyArrayPair] = []
        var keyValues: [KeyValuePair] = []

        swap(&tables, &self.tables)
        swap(&arrays, &self.arrays)
        swap(&keyTables, &self.keyTables)
        swap(&keyArrays, &self.keyArrays)
        swap(&keyValues, &self.keyValues)

        return TOMLDocument(
            source: source,
            tables: tables,
            arrays: arrays,
            keyTables: keyTables,
            keyArrays: keyArrays,
            keyValues: keyValues
        )
    }
}
