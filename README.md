# TOMLDecoder

Swift Decodable for [TOML](https://github.com/toml-lang/toml).

```swift
struct Player: Codable {
    let id: String
    let health: Int64
}

struct Team: Codable {
    let players: [Player]
}

let team = try TOMLDecoder().decode(Team.self, from: team_toml)
```

## Installation

#### With [CocoaPods](http://cocoapods.org/)

```ruby
use_frameworks!

pod "TOMLDecoder"
```

#### With [SwiftPM](https://swift.org/package-manager)

```swift
.package(url: "https://github.com/dduan/TOMLDecoder", from: "0.0.1")
```

#### With [Carthage](https://github.com/Carthage/Carthage)

```
github "dduan/TOMLDecoder"
```

## License

MIT. See `LICENSE.md`.
