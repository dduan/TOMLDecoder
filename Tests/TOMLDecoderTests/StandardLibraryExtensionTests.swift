import Testing
import TOMLDecoder

@Suite
struct StandardLibraryExtensionTests {
    @Test func `TOMLArray as Collection`() throws {
        let toml = """
        numbers = [false,1, 2.0, "three"]
        """
        let result = try TOMLTable(source: toml).array(forKey: "numbers")
        for _ in result {}
        #expect(result[0] as? Bool == false)
        #expect(result[1] as? Int64 == 1)
        #expect(result[2] as? Double == 2.0)
        #expect(result[3] as? String == "three")
    }

    @Test func `TOMLTable as Collection`() throws {
        let toml = """
        a = false
        b = 1
        c = 2.0
        d = "three"
        """
        let result = Dictionary(uniqueKeysWithValues: try TOMLTable(source: toml).map { ($0, $1) })
        #expect(result["a"] as? Bool == false)
        #expect(result["b"] as? Int64 == 1)
        #expect(result["c"] as? Double == 2.0)
        #expect(result["d"] as? String == "three")
    }
}
