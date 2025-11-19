import Testing
@testable import TOMLDecoder

@Suite
struct ArrayTypeConversionTests {
    @Test(.tags(.integer, .array))
    func `array of integers as Int array by key`() throws {
        struct Test: Decodable {
            let numbers: [Int]
        }

        let toml = """
        numbers = [10, 20, 30]
        """
        let decoder = TOMLDecoder()
        let result = try decoder.decode(Test.self, from: toml)

        #expect(result.numbers == [10, 20, 30])
    }

    @Test(.tags(.integer, .array))
    func `array of integers as Int8 array by key`() throws {
        struct Test: Decodable {
            let numbers: [Int8]
        }

        let toml = """
        numbers = [1, 2, 3]
        """
        let decoder = TOMLDecoder()
        let result = try decoder.decode(Test.self, from: toml)

        #expect(result.numbers == [1, 2, 3])
    }

    @Test(.tags(.integer, .array))
    func `array of integers as Int16 array by key`() throws {
        struct Test: Decodable {
            let numbers: [Int16]
        }

        let toml = """
        numbers = [100, 200, 300]
        """
        let decoder = TOMLDecoder()
        let result = try decoder.decode(Test.self, from: toml)

        #expect(result.numbers == [100, 200, 300])
    }

    @Test(.tags(.integer, .array))
    func `array of integers as Int32 array by key`() throws {
        struct Test: Decodable {
            let numbers: [Int32]
        }

        let toml = """
        numbers = [10000, 20000, 30000]
        """
        let decoder = TOMLDecoder()
        let result = try decoder.decode(Test.self, from: toml)

        #expect(result.numbers == [10000, 20000, 30000])
    }

    @Test(.tags(.integer, .array))
    func `array of integers as Int64 array by key`() throws {
        struct Test: Decodable {
            let numbers: [Int64]
        }

        let toml = """
        numbers = [1000000, 2000000, 3000000]
        """
        let decoder = TOMLDecoder()
        let result = try decoder.decode(Test.self, from: toml)

        #expect(result.numbers == [1_000_000, 2_000_000, 3_000_000])
    }

    @Test(.tags(.integer, .array))
    func `array of integers as UInt array by key`() throws {
        struct Test: Decodable {
            let numbers: [UInt]
        }

        let toml = """
        numbers = [50, 60, 70]
        """
        let decoder = TOMLDecoder()
        let result = try decoder.decode(Test.self, from: toml)

        #expect(result.numbers == [50, 60, 70])
    }

    @Test(.tags(.integer, .array))
    func `array of integers as UInt8 array by key`() throws {
        struct Test: Decodable {
            let numbers: [UInt8]
        }

        let toml = """
        numbers = [10, 20, 30]
        """
        let decoder = TOMLDecoder()
        let result = try decoder.decode(Test.self, from: toml)

        #expect(result.numbers == [10, 20, 30])
    }

    @Test(.tags(.integer, .array))
    func `array of integers as UInt16 array by key`() throws {
        struct Test: Decodable {
            let numbers: [UInt16]
        }

        let toml = """
        numbers = [1000, 2000, 3000]
        """
        let decoder = TOMLDecoder()
        let result = try decoder.decode(Test.self, from: toml)

        #expect(result.numbers == [1000, 2000, 3000])
    }

    @Test(.tags(.integer, .array))
    func `array of integers as UInt32 array by key`() throws {
        struct Test: Decodable {
            let numbers: [UInt32]
        }

        let toml = """
        numbers = [100000, 200000, 300000]
        """
        let decoder = TOMLDecoder()
        let result = try decoder.decode(Test.self, from: toml)

        #expect(result.numbers == [100_000, 200_000, 300_000])
    }

    @Test(.tags(.integer, .array))
    func `array of integers as UInt64 array by key`() throws {
        struct Test: Decodable {
            let numbers: [UInt64]
        }

        let toml = """
        numbers = [5000000, 6000000, 7000000]
        """
        let decoder = TOMLDecoder()
        let result = try decoder.decode(Test.self, from: toml)

        #expect(result.numbers == [5_000_000, 6_000_000, 7_000_000])
    }

    @Test(.tags(.float, .array))
    func `array of floats as Float array by key`() throws {
        struct Test: Decodable {
            let numbers: [Float]
        }

        let toml = """
        numbers = [1.5, 2.7, 3.14]
        """
        let decoder = TOMLDecoder()
        let result = try decoder.decode(Test.self, from: toml)

        #expect(result.numbers == [1.5, 2.7, 3.14])
    }
}
