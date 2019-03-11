# TOML In Swift

TOML stands for _Tom's Obvious, Minimal Language_.

From its specification:

> TOML aims to be a minimal configuration file format that's easy to read due to
> obvious semantics. TOML is designed to map unambiguously to a hash table. TOML
> should be easy to parse into data structures in a wide variety of languages.

The rest of the document assumes you are familiar with [TOML v0.5.0][0].
Additionally, it'll make more sense if you [know the distinctions][2] among
`Decodable`, `Docoder`, and `JSONDecoder`.

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

TOML [defines][0] a set of well-defined types for values. For example, integers
are signed and 64-bit. Date, time and so-called "offset Date-Time" have distinct
definitions. Internally, TOMLDecoder uses the following Swift types to represent
them in memory:

| TOML             | Swift                   |
| -                | -                       |
| String           | `Swift.String`          |
| Integer          | `Swift.Int64`           |
| Float            | `Swift.Double`          |
| Boolean          | `Swift.Bool`            |
| Local Time       | `NetTime.LocalTime`     |
| Local Date       | `NetTime.LocalDate`     |
| Local Date-Time  | `NetTime.LocalDateTime` |
| Offset Date-Time | `NetTime.DateTime`      |
| Array            | `Swift.[Any]`           |
| Table            | `Swift.[String: Any]`   |

Let's see how to best choose types for properties in your own `Decodable`.

#### Date and Time

In Foundation, a Date represents a point in time. It maps directly to the
concept of "Offset Date-time" in TOML. However, the rest of the date/time types
can/should not be decoded as `Date` as they lack a relationship to a fix-point
in time (is `2019-03-10 17:30:00` local time or UTC time?). The proper way to
represent such information in your own type, therefore, is to use
`DateComponents` from Foundation, or one of the matching types from NetTime.

The types from [NetTime][1] library are created to losslessly deserialize RFC
3339 timestamps (which is required for TOML date/time types). They conform to
`Decodable`. So you may use them directly as properties of your own decodable
object, as an alternative to `Foundation.Date`.

In case you only want to use the NetTime types for some reason (performance,
lossless details from RFC 3339 fields, etc), you may use the `.strict` strategy
for date decoding:

```swift
decoder.dateDecodingStrategy = .strict
```

With this setting, decoding will fail if `Date` or `DateComponents` are
requested.

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

The `.numberDecodingStrategy` property on a TOMLDecoder controls behaviors for
decoding numbers. It's default value, `NumberDecodingStrategy.normal`, means the
decoder will try its best to convert the TOML number to a number type from Swift
standard library, despite the underlying value can only be an `Int64` or
a `Double`.

When only use the actual underlying numebers are desired, you can set the
`.strict` number decoding strategy, in which case integers are only allowed to
be decoded as `Int64` and floats `Double`:

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

TOMLDecoder leverages [TOMLDeserializer][3] to convert TOML text to structured
in-memory representation such as `[String: Any]`, `Int64`, `DateTime`, etc. If
you, for some reason, find that `Decodable` is unnecessary or insufficient for
your needs (for example, Foundation is not available on your platform), you can
use [TOMLDeserializer][3] directly.

[0]: https://github.com/toml-lang/toml/blob/master/versions/en/toml-v0.5.0.md
[1]: https://github.com/dduan/NetTime
[2]: AboutJSONDecoder.md
[3]: https://github.com/dduan/TOMLDeserializer
