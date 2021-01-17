public enum DeserializationError: Error {
    case structural(Description)
    case value(Description)
    case conflictingValue(Description)
    case general(Description)
    indirect case compound([Error])
    public struct Description {
        let line: Int
        let column: Int
        let text: String
    }
}

extension DeserializationError.Description: CustomStringConvertible {
    public var description: String {
        "|\(line), \(column)| \(text)"
    }
}

extension DeserializationError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .structural(let error):
            return "Structure \(error)"
        case .value(let error):
            return "Value \(error)"
        case .conflictingValue(let error):
            return "Conflict \(error)"
        case .general(let error):
            return "\(error)"
        case .compound(let details):
            let output = ["Deserialization failure:"]
            return details
                .reduce(into: output) { $0.append(String(describing: $1)) }
                .joined(separator: "\n    * ")
                + "\n"
        }
    }
}

extension DeserializationError.Description {
    static func locate(index: String.Index, reference: String) -> (Int, Int) {
        let endIndex = index.samePosition(in: reference) ?? reference.startIndex
        var line = 1
        var column = 1
        var i = reference.startIndex
        while i < endIndex {
            if reference[i] == "\n" {
                line += 1
                column = 0
            }

            column += 1
            reference.formIndex(after: &i)
        }

        return (line, column)
    }

    init(_ reference: String, _ index: String.Index, _ text: String) {
        (line, column) = Self.locate(index: index, reference: reference)
        self.text = text
    }
}
