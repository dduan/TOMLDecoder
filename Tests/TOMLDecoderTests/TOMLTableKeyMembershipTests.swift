import Testing
import TOMLDecoder

private let toml = """
a = 1
b = 1988-03-29

[c.e.o]
first_name = "Tim"

[[players]]

id = "abc"
health = 123

[[players]]

id = "cde"
health = 456
"""
@Suite
struct TOMLTableKeyMembershipTests {
    @Test
    func `all keys for root table`() throws {
        let table = try TOMLTable(source: toml)
        #expect(table.allKeys == ["a", "b", "players", "c"])
    }

    @Test
    func `root table key contains`() throws {
        let table = try TOMLTable(source: toml)
        #expect(table.allKeys == ["a", "b", "players", "c"])
        #expect(table.contains(key: "a"))
        #expect(table.contains(key: "players"))
        #expect(table.contains(key: "c"))
        #expect(!table.contains(key: "d"))
    }
}
