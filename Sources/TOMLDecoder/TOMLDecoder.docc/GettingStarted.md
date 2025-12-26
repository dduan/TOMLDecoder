# Getting Started

From zero to decoding TOML with TOMLDecoder, a minimal example.

## Install

### via SwiftPM

TOMLDecoder is a Swift package with minimal dependencies.

Let's assume you are starting with a [SwiftPM](https://docs.swift.org/swiftpm/documentation/packagemanagerdocs/) project.

Add the following to your package dependencies:

```swift
.package(url: "https://github.com/dduan/TOMLDecoder", exactly: "0.4.2")),
```


In a target's dependencies, add:

```swift
.product(name: "TOMLDecoder", package: "TOMLDecoder"),
```

Run `swift build`.
You may have to update your package's `platforms` if you see a related error.

### via Bazel Central Registry

You can use TOMLDecoder from the Bazel Central Registry.
Include it in your MODULE.bazel

```
bazel_dep(name = 'swift-tomldecoder', version = '0.4.1')
```

And add `@swift-tomldecoder//:TOMLDecoder` as a dependency to your target as needed.


## Using TOMLDecoder

### Decoding TOML

TOMLDecoder can turn TOML into your types that conforms to `Swift.Codable`.

```swift
import TOMLDecoder

let tomlString = """
title = "TOML example"

[owner]
name = "Tom Preston-Werner"
dob = 1979-05-27T07:32:00-08:00

[database]
enabled = true
ports = [ 8000, 8001, 8002 ]
temp_targets = { cpu = 79.5, case = 72.0 }
"""

// A normal `Codable` or `Decodable` type.
struct Config: Codable {
    let title: String
    let owner: Owner
    let database: Database

    struct Owner: Codable {
        let name: String
        let dob: Date
    }

    struct Database: Codable {
        var enabled: Bool
        var ports: [Int]
        var tempTargets: [String: Double]
    }
}

let config = try TOMLDecoder().decode(Config.self, from: tomlString)

print(config.owner.name) // Tom Preston-Werner
```


### Parsing for specific fields

If you don't need,
or can't,
work with `Codable`,
you can use the lower-level APIs to deserialize TOML.

```swift
// TOML is always a table at the root
let rootTable = try TOMLTable(source: tomlString)

// Get the `owner` table. It's a TOMLTable
let owner = try rootTable.table(forKey: "owner")

// Get a string from `owner`
print(try owner.string(forKey: "name")) // Tom Preston-Werner
```
