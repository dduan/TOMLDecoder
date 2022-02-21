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
.package(url: "https://github.com/dduan/TOMLDecoder", from: "0.2.1")
```

### With Nix flake

Use as a `buildInputs` for [swift-builders](https://github.com/dduan/swift-builders). For example, your
flake.nix for an executable could look like:

```nix
{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs";
    swift.url = "github:dduan/swift-builders";
    TOMLDecoder.url = "github:dduan/TOMLDecoder";
  };
  outputs = { self, nixpkgs, swift, flake-utils, TOMLDecoder }:
    with swift.lib;
    flake-utils.lib.eachSystem swiftPlatforms (system: {
      defaultPackage = mkExecutable (nixpkgs.legacyPackages.${system}) {
        version = "1.0.0";
        src = ./.;
        target = "helloTOML";
        buildInputs = [
          TOMLDecoder.defaultPackage.${system}
        ];
      };
    });
}
```

## License

MIT. See `LICENSE.md`.
