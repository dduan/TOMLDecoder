import Foundation

struct _TOMLDecoder: Decoder {
    enum Container {
        case keyed(TOMLTable)
        case unkeyed(TOMLArray)
    }

    let container: Container
    let codingPath: [CodingKey]
    let strategy: TOMLDecoder.Strategy
    let isLenient: Bool
    let userInfo: [CodingUserInfoKey : Any] = [:]

    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        guard case .keyed(let table) = container else {
            throw DecodingError.valueNotFound(
                KeyedDecodingContainer<Key>.self,
                DecodingError.Context(
                    codingPath: self.codingPath,
                    debugDescription:
                        "Cannot get keyed decoding container -- found \(Swift.type(of: self.container)) instead."
                ))
        }

        return KeyedDecodingContainer(TOMLKeyedDecodingContainer(referencing: self, wrapping: table))
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        guard case .unkeyed(let array) = container else {
            throw DecodingError.valueNotFound(
                UnkeyedDecodingContainer.self,
                DecodingError.Context(
                    codingPath: self.codingPath,
                    debugDescription:
                        "Cannot get unkeyed decoding container -- found \(Swift.type(of: self.container)) instead."
                ))
        }

        return TOMLUnkeyedDecodingContainer(referencing: self, wrapping: array)
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        throw DecodingError.typeMismatch(
            SingleValueDecodingContainer.self,
            DecodingError.Context(
                codingPath: self.codingPath,
                debugDescription:
                    "Top level TOML container is always a table (keyed container), not a single value."
            ))
    }

    init(referencing container: Container, at codingPath: [CodingKey] = [], strategy: TOMLDecoder.Strategy, isLenient: Bool) {
        self.container = container
        self.codingPath = codingPath
        self.strategy = strategy
        self.isLenient = isLenient
    }
}

extension TimeInterval {
    init(from offsetDateTime: OffsetDateTime, strategy: TOMLDecoder.Strategy.OffsetDateTime) throws {
        switch strategy {
        case .intervalSince1970:
            self = offsetDateTime.timeIntervalSince1970
        case .intervalSince2001:
            self = offsetDateTime.timeIntervalSince2001
        default:
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: [],
                debugDescription: "Invalid strategy \(strategy) for OffsetDateTime conversion to TimeInterval"
            ))
        }
    }
}
