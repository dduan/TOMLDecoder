public enum TOMLDeserializer {
    public static func tomlTable(with text: String) throws -> [String: Any] {
        var scalars = text.unicodeScalars[...]
        guard let result = TOMLParser.root.run(&scalars) else {
            throw TOMLError.unknown
        }

        if !scalars.isEmpty {
            throw TOMLError.deserialization(details: [
                DeserializationError.general(.init(text, scalars.startIndex, "Invalid TOML"))
            ])
        }

        let table = try assembleTable(from: result, referenceInput: text)

        return table
    }

    public static func tomlTable<Bytes>(with bytes: Bytes) throws -> [String: Any]
        where Bytes: Collection, Bytes.Element == Unicode.UTF8.CodeUnit
    {
        try tomlTable(with: String(decoding: bytes, as: UTF8.self))
    }
}
