//  WARNING: This file is generated from TOMLSingleValueDecodingContainer.swift.gyb
//  Do not edit TOMLSingleValueDecodingContainer.swift directly.

import Foundation

struct TOMLSingleValueDecodingContainer: SingleValueDecodingContainer {
    let decoder: _TOMLDecoder
    let token: Token
    let context: TOMLKey

    init(decoder: _TOMLDecoder, token: Token, context: TOMLKey) {
        assert(!decoder.codingPath.isEmpty)
        self.token = token
        self.decoder = decoder
        self.context = context
    }

    var codingPath: [CodingKey] { decoder.codingPath }

    @inline(__always)
    func decode(_: Bool.Type) throws -> Bool {
        try token.unpackBool(context: context)
    }

    @inline(__always)
    func decode(_: String.Type) throws -> String {
        try token.unpackString(context: context)
    }

    @inline(__always)
    func decode(_: Double.Type) throws -> Double {
        try token.unpackFloat(context: context)
    }

    @inline(__always)
    func decode(_: Int64.Type) throws -> Int64 {
        try token.unpackInteger(context: context)
    }

    func decode(_: Float.Type) throws -> Float {
        fatalError()
    }

    @inline(__always)
    func decode(_: Int.Type) throws -> Int {
        fatalError()
    }

    @inline(__always)
    func decode(_: Int8.Type) throws -> Int8 {
        fatalError()
    }

    @inline(__always)
    func decode(_: Int16.Type) throws -> Int16 {
        fatalError()
    }

    @inline(__always)
    func decode(_: Int32.Type) throws -> Int32 {
        fatalError()
    }

    @inline(__always)
    func decode(_: UInt.Type) throws -> UInt {
        fatalError()
    }

    @inline(__always)
    func decode(_: UInt8.Type) throws -> UInt8 {
        fatalError()
    }

    @inline(__always)
    func decode(_: UInt16.Type) throws -> UInt16 {
        fatalError()
    }

    @inline(__always)
    func decode(_: UInt32.Type) throws -> UInt32 {
        fatalError()
    }

    @inline(__always)
    func decode(_: UInt64.Type) throws -> UInt64 {
        fatalError()
    }

    @inline(__always)
    func decode<T>(_: T.Type) throws -> T where T: Decodable {
        fatalError()
    }

    func decodeNil() -> Bool {
        false
    }
}
