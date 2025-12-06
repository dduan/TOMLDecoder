import Foundation

final class _TOMLDecoder: Decoder {
    enum Container {
        case keyed(TOMLTable)
        case unkeyed(TOMLArray)
    }

    let container: Container
    var codingPath: [CodingKey]
    let strategy: TOMLDecoder.Strategy
    let isLenient: Bool
    let userInfo: [CodingUserInfoKey: Any] = [:]
    var token = Token.empty

    var source: String {
        switch container {
        case let .keyed(table):
            table.source.source
        case let .unkeyed(array):
            array.source.source
        }
    }

    func container<Key>(keyedBy _: Key.Type) throws -> KeyedDecodingContainer<Key> where Key: CodingKey {
        guard case let .keyed(table) = container else {
            throw DecodingError.valueNotFound(
                KeyedDecodingContainer<Key>.self,
                DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription:
                    "Cannot get keyed decoding container -- found \(Swift.type(of: container)) instead.",
                ),
            )
        }

        return KeyedDecodingContainer(TOMLKeyedDecodingContainer(referencing: self, wrapping: table))
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        guard case let .unkeyed(array) = container else {
            throw DecodingError.valueNotFound(
                UnkeyedDecodingContainer.self,
                DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription:
                    "Cannot get unkeyed decoding container -- found \(Swift.type(of: container)) instead.",
                ),
            )
        }

        return TOMLUnkeyedDecodingContainer(referencing: self, wrapping: array)
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        self
    }

    init(referencing container: Container, at codingPath: [CodingKey] = [], strategy: TOMLDecoder.Strategy, isLenient: Bool) {
        self.container = container
        self.codingPath = codingPath
        self.strategy = strategy
        self.isLenient = isLenient
    }
}

extension TimeInterval {
    init(from offsetDateTime: OffsetDateTime, strategy: TOMLDecoder.TimeIntervalStrategy) throws {
        switch strategy {
        case .since1970:
            self = offsetDateTime.timeIntervalSince1970
        case .since2001:
            self = offsetDateTime.timeIntervalSince2001
        }
    }
}
