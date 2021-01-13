# TOMLDecoder

| Swift 5.3 & 5.3.1 |
|-|
|[![Amazon Linux 2](https://github.com/dduan/TOMLDecoder/workflows/Amazon%20Linux%202/badge.svg)](https://github.com/dduan/TOMLDecoder/actions?query=workflow%3A%22Amazon+Linux+2%22)|
|[![CentOS 8](https://github.com/dduan/TOMLDecoder/workflows/CentOS%208/badge.svg)](https://github.com/dduan/TOMLDecoder/actions?query=workflow%3A%22CentOS+8%22)|
|[![macOS 11.15](https://github.com/dduan/TOMLDecoder/workflows/macOS%2011.15/badge.svg)](https://github.com/dduan/TOMLDecoder/actions?query=workflow%3A%22macOS+11.15%22)|
|[![Ubuntu Bionic](https://github.com/dduan/TOMLDecoder/workflows/Ubuntu%20Bionic/badge.svg)](https://github.com/dduan/TOMLDecoder/actions?query=workflow%3A%22Ubuntu+Bionic%22)|
|[![Ubuntu Focal](https://github.com/dduan/TOMLDecoder/workflows/Ubuntu%20Focal/badge.svg)](https://github.com/dduan/TOMLDecoder/actions?query=workflow%3A%22Ubuntu+Focal%22)|


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
.package(url: "https://github.com/dduan/TOMLDecoder", from: "0.1.6")
```

## License

MIT. See `LICENSE.md`.
