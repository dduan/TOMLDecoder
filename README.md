# TOMLDecoder

Decode your values from [TOML v0.5.0][] contents.

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

Supported platforms: iOS, Linux, macOS, tvOS and watchOS.

Learn more in the [introduction](Documentation/Introduction.md).

[TOML v0.5.0]: https://github.com/toml-lang/toml/blob/master/versions/en/toml-v0.5.0.md

## Installation

#### With [CocoaPods](http://cocoapods.org/)

```ruby
use_frameworks!

pod "TOMLDecoder"
```

#### With [SwiftPM](https://swift.org/package-manager)

```swift
.package(url: "https://github.com/dduan/TOMLDecoder", from: "0.1.6")
```

#### With [Carthage](https://github.com/Carthage/Carthage)

```
github "dduan/TOMLDecoder"
```

## License

MIT. See `LICENSE.md`.
