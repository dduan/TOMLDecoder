@Sendable
func snakeCasify(_ stringKey: String) -> String {
    guard !stringKey.isEmpty else { return stringKey }

    // Find the first non-underscore character
    guard let firstNonUnderscore = stringKey.firstIndex(where: { $0 != "_" }) else {
        // Reached the end without finding an _
        return stringKey
    }

    // Find the last non-underscore character
    var lastNonUnderscore = stringKey.index(before: stringKey.endIndex)
    while lastNonUnderscore > firstNonUnderscore, stringKey[lastNonUnderscore] == "_" {
        stringKey.formIndex(before: &lastNonUnderscore)
    }

    let keyRange = firstNonUnderscore ... lastNonUnderscore
    let leadingUnderscoreRange = stringKey.startIndex ..< firstNonUnderscore
    let trailingUnderscoreRange = stringKey.index(after: lastNonUnderscore) ..< stringKey.endIndex

    let components = stringKey[keyRange].split(separator: "_")
    let joinedString: String = if components.count == 1 {
        // No underscores in key, leave the word as is - maybe already camel cased
        String(stringKey[keyRange])
    } else {
        ([components[0].lowercased()] + components[1...].map(\.capitalized)).joined()
    }

    // Do a cheap isEmpty check before creating and appending potentially empty strings
    let result: String = if leadingUnderscoreRange.isEmpty, trailingUnderscoreRange.isEmpty {
        joinedString
    } else if !leadingUnderscoreRange.isEmpty, !trailingUnderscoreRange.isEmpty {
        // Both leading and trailing underscores
        String(stringKey[leadingUnderscoreRange]) + joinedString + String(stringKey[trailingUnderscoreRange])
    } else if !leadingUnderscoreRange.isEmpty {
        // Just leading
        String(stringKey[leadingUnderscoreRange]) + joinedString
    } else {
        // Just trailing
        joinedString + String(stringKey[trailingUnderscoreRange])
    }
    return result
}
