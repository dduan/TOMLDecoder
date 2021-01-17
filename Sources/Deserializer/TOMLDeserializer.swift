public enum TOMLDeserializer {
    public static func tomlTable(with text: String) throws -> [String: Any] {
        var input = text[...]
        let topLevelEntries = topLevels(&input)
        let table = try assembleTable(from: topLevelEntries, referenceInput: text)

        if !input.isEmpty {
            throw DeserializationError.general(.init(text, input.startIndex, "Invalid TOML"))
        }

        return table
    }

    public static func tomlTable<Bytes>(with bytes: Bytes) throws -> [String: Any]
        where Bytes: Collection, Bytes.Element == Unicode.UTF8.CodeUnit
    {
        try tomlTable(with: String(decoding: bytes, as: UTF8.self))
    }
}
