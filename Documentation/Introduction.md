# TOML In Swift

TOML stands for _Tom's Obvious, Minimal Language_.

From its specification:

> TOML aims to be a minimal configuration file format that's easy to read due to
> obvious semantics. TOML is designed to map unambiguously to a hash table. TOML
> should be easy to parse into data structures in a wide variety of languages.

The rest of the document assumes you are familiar with [TOML][0].
Additionally, it'll make more sense if you [know the distinctions][2] among
`Decodable`, `Docoder`, and `JSONDecoder`.

TOMLDecoder is compliant with TOML spec 1.0.

## Decoding TOML

### Overview

For the most part, TOMLDecoder should "just work" with your
`Decodable/Codable` types:

```swift
struct Player: Codable {
    let id: String
    let joinDate: Date
    let level: Int
}

let toml = """
id = "33968bc5c8a95"
join_date = 2019-03-10 17:40:00-07:00
level = 0xdeadbeef
"""

let decoder = TOMLDecoder()
decoder.keyDecodingStrategy = .convertFromSnakeCase // same as JSONDecoder
let p = try decoder.decode(Player.self, from: toml) // `Data` would work too
```

### Decoding Strategies

TOML [has][0] a set of well-defined types for values. For example, integers
are signed and 64-bit. Date, time and so-called "offset Date-Time" have distinct
definitions. Internally, TOMLDecoder uses the following Swift types to represent
them in memory:

| TOML             | Swift                       |
| -                | -                           |
| String           | `Swift.String`              |
| Integer          | `Swift.Int64`               |
| Float            | `Swift.Double`              |
| Boolean          | `Swift.Bool`                |
| Local Time       | `Foundation.DateComponents` |
| Local Date       | `Foundation.DateComponents` |
| Local Date-Time  | `Foundation.DateComponents` |
| Offset Date-Time | `Foundation.Date`           |
| Array            | `Swift.[Any]`               |
| Table            | `Swift.[String: Any]`       |

Let's see how to best choose types for properties in your own `Decodable`.

#### Date and Time

In Foundation, a Date represents a point in time. It maps directly to the
concept of "Offset Date-time" in TOML. However, the rest of the date/time types
can/should not be decoded as `Date` as they lack a relationship to a fix-point
in time (is `2019-03-10 17:30:00` local time or UTC time?). The proper way to
represent such information, therefore, is to use `DateComponents` from
Foundation.

#### Data

There's no such thing as "data" in TOML. But you may occasionally need to embed
a image or something. When you ask TOMLDecoder to decode a `Data`, the expected
underlying value from TOML will be a `String` in base64 format.  Otherwise
you'll get an error.

You may also choose to decode manually. In that case you'll need to set
a TOMLDecoder's' `.dataDecodingStratgy` to `.custom`:

```swift
decoder.dataDecodingStrategy = .custom { (decoder: Decocder) -> Data in
    // get the data however you want
}
```

#### Numbers

`.numberDecodingStrategy` property on an instance of TOMLDecoder controls
behaviors for decoding numbers. Its default value,
`NumberDecodingStrategy.lenient`, means the decoder will try its best to convert
the TOML number to a number type from Swift standard library or NSNumber, from
its underlying value that can only be an `Int64` or `Double`.

Using only the underlying `Int64` or `Double` has the advantage of preserving
most precision. If this is desirable, you can set the `.strict` number decoding
strategy, in which case integers are only allowed to be decoded as `Int64` and
floats `Double`:

```swift
decoder.numberDecodingStrategy = .strict
```

#### Keys

TOMLDecoder provides the exact same options as JSONDecoder for converting keys
for keyed containers. As demonstrated in a example eariler in this document, the
most useful strategy is perhaps `.convertFromSnakeCase`:

```swift
decoder.keyDecodingStrategy = .convertFromSnakeCase
```

You may use a custom strategy:
```swift
decoder.keyDecodingStrategy = .custom
{ (codingPath: [CodingKey]) -> CodingKey in
    // convert it to your heart's content.
}
```

## Deserializing TOML

When you decode bytes or string to your `Codable`, behind the scenes,
the first step `TOMLDecoder` takes is to parse the input to a `[String: Any]`
value that contains all the TOML values in the right data type, organized into
the right shape. This is what `JSONSerialization` does for JSON.

You can perform this step yourself:

```swift
let tomlString = """
[Person]
let firstName = "Elon"
let lastName = "Musk"
"""

let toml: [String: Any] = try JSONDecoder.tomlTable(from: tomlString)

(toml["Person"] as? [String: String])?["firstName"] // Optional("Elon")
```

[0]: https://toml.io/
[2]: AboutJSONDecoder.md
