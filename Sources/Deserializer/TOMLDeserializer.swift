public enum TOMLDeserializer {
    public static func tomlTable(with text: String) throws -> [String: Any] {
        var input = text[...]
        let topLevelEntries = topLevels(&input)
        let table = try assembleTable(from: topLevelEntries, referenceInput: text)

        if !input.isEmpty {
            throw DeserializationError.general(.init(text, input.startIndex, "Invalid TOML"))
        }

        return table.stripped
    }

    public static func tomlTable<Bytes>(with bytes: Bytes) throws -> [String: Any]
        where Bytes: Collection, Bytes.Element == Unicode.UTF8.CodeUnit
    {
        guard let string = String(bytes: bytes, encoding: .utf8) else {
            throw DeserializationError.value(.init(line: 1, column: 1, text: "Contains invalid UTF-8 sequence"))
        }
        return try tomlTable(with: string)
    }
}
