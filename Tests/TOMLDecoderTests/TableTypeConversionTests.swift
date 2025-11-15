import Testing
@testable import TOMLDecoder

@Suite
struct TableTypeConversionTests {
    @Test(.tags(.integer, .table))
    func `integer as Int8 by key`() throws {
        struct Test: Decodable {
            let number: Int8
        }

        let toml = """
        number = 123
        """
        let result = try TOMLDecoder().decode(Test.self, from: toml)

        #expect(result.number == 123)
    }

    @Test(.tags(.integer, .table))
    func `integer as Int16 by key`() throws {
        struct Test: Decodable {
            let number: Int16
        }

        let toml = """
        number = 12345
        """
        let result = try TOMLDecoder().decode(Test.self, from: toml)

        #expect(result.number == 12345)
    }

    @Test(.tags(.integer, .table))
    func `integer as Int32 by key`() throws {
        struct Test: Decodable {
            let number: Int32
        }

        let toml = """
        number = 1234567
        """
        let result = try TOMLDecoder().decode(Test.self, from: toml)

        #expect(result.number == 1234567)
    }

    @Test(.tags(.integer, .table))
    func `integer as UInt8`() throws {
        struct Test: Decodable {
            let number: UInt8
        }

        let toml = """
        number = 200
        """
        let result = try TOMLDecoder().decode(Test.self, from: toml)

        #expect(result.number == 200)
    }

    @Test(.tags(.integer, .table))
    func `integer as UInt16`() throws {
        struct Test: Decodable {
            let number: UInt16
        }

        let toml = """
        number = 50000
        """
        let result = try TOMLDecoder().decode(Test.self, from: toml)

        #expect(result.number == 50000)
    }

    @Test(.tags(.integer, .table))
    func `integer as UInt32`() throws {
        struct Test: Decodable {
            let number: UInt32
        }

        let toml = """
        number = 3000000
        """
        let result = try TOMLDecoder().decode(Test.self, from: toml)

        #expect(result.number == 3000000)
    }

    @Test(.tags(.integer, .table))
    func `integer as UInt64 by key`() throws {
        struct Test: Decodable {
            let number: UInt64
        }

        let toml = """
        number = 9223372036854775807
        """
        let result = try TOMLDecoder().decode(Test.self, from: toml)

        #expect(result.number == 9223372036854775807)
    }

    @Test(.tags(.float, .table))
    func `float as Double by key`() throws {
        struct Test: Decodable {
            let number: Double
        }

        let toml = """
        number = 3.14159
        """
        let result = try TOMLDecoder().decode(Test.self, from: toml)

        #expect(result.number == 3.14159)
    }

    @Test(.tags(.float, .table))
    func `float as Float by key`() throws {
        struct Test: Decodable {
            let number: Float
        }

        let toml = """
        number = 2.718
        """
        let result = try TOMLDecoder().decode(Test.self, from: toml)

        #expect(result.number == 2.718)
    }

    @Test(.tags(.integer, .table))
    func `integer as Int by key`() throws {
        struct Test: Decodable {
            let number: Int
        }

        let toml = """
        number = 42
        """
        let result = try TOMLDecoder().decode(Test.self, from: toml)

        #expect(result.number == 42)
    }

    @Test(.tags(.integer, .table))
    func `integer as UInt by key`() throws {
        struct Test: Decodable {
            let number: UInt
        }

        let toml = """
        number = 100
        """
        let result = try TOMLDecoder().decode(Test.self, from: toml)

        #expect(result.number == 100)
    }
}
