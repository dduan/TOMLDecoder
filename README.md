# TOMLDecoder

TOML parser for your Swift `Codable`s.

```swift
struct Team: Codable {
    struct Player: Codable {
        let id: String
        let health: Int
        let joinDate: Date
    }

    let players: [Player]
}

let team = try TOMLDecoder().decode(Team.self, from: tomlData)
```

Learn more in the [introduction](Documentation/Introduction.md).

[TOML]: https://toml.io/

## Installation

#### With [SwiftPM](https://swift.org/package-manager)

```swift
.package(url: "https://github.com/dduan/TOMLDecoder", from: "0.1.6")
```

## License

MIT. See `LICENSE.md`.
