public struct PokemonData: Codable, Equatable {
    public let pokemon: [Pokemon]
}

public struct Pokemon: Codable, Equatable {
    public let id: Int
    public let num: String
    public let name: String
    public let img: String
    public let type: [String]
    public let height: String
    public let weight: String
    public let candy: String
    public let candyCount: Int?
    public let egg: String
    public let spawnChance: Double
    public let avgSpawns: Double
    public let spawnTime: String
    public let multipliers: [Double]?
    public let weaknesses: [String]
    public let nextEvolution: [Evolution]?
    public let prevEvolution: [Evolution]?

    enum CodingKeys: String, CodingKey {
        case id, num, name, img, type, height, weight, candy, egg, weaknesses, multipliers
        case candyCount = "candy_count"
        case spawnChance = "spawn_chance"
        case avgSpawns = "avg_spawns"
        case spawnTime = "spawn_time"
        case nextEvolution = "next_evolution"
        case prevEvolution = "prev_evolution"
    }
}

public struct Evolution: Codable, Equatable {
    public let num: String
    public let name: String
}
