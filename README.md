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

TOMLDecoder has a relatively simple set of APIs. Learn more in the [introduction](Documentation/Introduction.md).

[TOML]: https://toml.io/

## Installation

#### With [SwiftPM](https://swift.org/package-manager)

```swift
.package(url: "https://github.com/dduan/TOMLDecoder", from: "0.3.1")
```

## License

MIT. See `LICENSE.md`.
