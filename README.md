# TOMLDecoder

A fast, Swift-native, minimal dependency library
that fully implements [TOML](https://toml.io/) spec 1.0.

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


Read the documentation to learn more:

- for [0.4.0](https://dduan.github.io/TOMLDecoder/0.4.x/documentation/tomldecoder/), the latest release
- for [the main branch](https://dduan.github.io/TOMLDecoder/main/documentation/tomldecoder/)

## License

MIT. See `LICENSE.md`.
