package struct CanadaFeatureCollection: Codable {
    var type: ObjType
    var features: [Feature]

    package enum ObjType: String, Codable {
        case featureCollection = "FeatureCollection"
        case feature = "Feature"
        case polygon = "Polygon"
    }

    package struct Feature: Codable {
        var type: ObjType
        var properties: [String: String]
        var geometry: Geometry
    }

    package struct Geometry: Codable {
        package struct Coordinate: Codable {
            var latitude: Double
            var longitude: Double

            package init(from decoder: any Decoder) throws {
                var container = try decoder.unkeyedContainer()
                latitude = try container.decode(Double.self)
                longitude = try container.decode(Double.self)
            }

            package func encode(to encoder: any Encoder) throws {
                var container = encoder.unkeyedContainer()
                try container.encode(latitude)
                try container.encode(longitude)
            }
        }

        var type: ObjType
        var coordinates: [[Coordinate]]
    }
}
