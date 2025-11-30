public struct CanadaFeatureCollection: Codable {
    var type: ObjType
    var features: [Feature]

    public enum ObjType: String, Codable {
        case featureCollection = "FeatureCollection"
        case feature = "Feature"
        case polygon = "Polygon"
    }

    public struct Feature: Codable {
        var type: ObjType
        var properties: [String: String]
        var geometry: Geometry
    }

    public struct Geometry: Codable {
        public struct Coordinate: Codable {
            var latitude: Double
            var longitude: Double

            public init(from decoder: any Decoder) throws {
                var container = try decoder.unkeyedContainer()
                latitude = try container.decode(Double.self)
                longitude = try container.decode(Double.self)
            }

            public func encode(to encoder: any Encoder) throws {
                var container = encoder.unkeyedContainer()
                try container.encode(latitude)
                try container.encode(longitude)
            }
        }

        var type: ObjType
        var coordinates: [[Coordinate]]
    }
}
