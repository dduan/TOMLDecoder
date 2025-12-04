# How to Decode TOML

Learn how to convert TOML into your Codable types.

## Overview

Swift's standard library defines the `Encodable`,
and `Decodable` protocol.
Combined, they form the superset, `Codable` protocol.
If your types conforms to `Decodable`, or `Codable`,
`TOMLDecoder` can create instances of your types from TOML data.

The API for doing so is very similar to the `JSONDecoder` API from `Fonudation`.

```swift
struct Config: Codable { 
    let title: String
    ...
}
let toml: String = """
title = "TOML Example"
...
""""

try TOMLDecoder().decode(Config.self, from: toml)

print(config.title) // "TOML Example"
```

