# Decodable, Decoder, JSONDecoder

In Swift, you can make your types encodable and decodable for compatibility with
external representations. Chances are, you've learned about it in the context
of working with JSON.

```swift
// Example: make your `Thing` from some `Data`.
let aThing = try JSONDecoder().decode(Thing.self, from: jsonData)
```

However, for the rest of this document to make more sense, we must draw some
distinction among things.

Let's examine some details from this example.

## `import Foundation`

Though left out from the code, one must import `Foundation` for that example to
work. `JSONDecoder` is part of the _Foundation_ library, which is distinct
from the _standard library_. `PropertyListDecoder` is another decoder that
`Foundation` provides.

The reason these decoders are _not_ part of the standard library is two fold.
First, many useful types such as `Data` and `Date` are part of `Foundation`.
A theoretical decoder defined in the _standard library_ won't be able to support
them (from its point-of-view, `Data` might as well be from any other third-party
library). Secondarily, the logic that converts `Data`, a byte sequence, to
structured, in-memory values such as a `[String: Any]`, lives in `Foundation`
and `JSONDecoder` depends on it (Remember `JSONSerialization`? Yea, good times).

## `Thing` Conforms To `Decodable`

Swift's _standard library_ defines the protocol `Decodable`. `JSONDecoder` only
works with types that conforms to it. To make our lives easier, the Swift
compiler synthesizes conformance for types that:

1. Declares conformance in their definition (`struct Thing: Decodable { … }`).
2. Has stored properties that all conforms to `Decodable` themselves.

Most Swift premitives (`String`, `Int`, `Bool`, `UInt16`, etc) from the standard
library already conforms to `Decodable`.

Most useful types (`Data`, `Date`, etc) from `Foundation` also conforms to
`Decodable`.

## What `Decoder`?

You might be surprised to learn that `JSONDecoder` does _not_ conform to
`Decoder`. Further, these two are far _less_ related than one would expect. Case
in point, here's the definition of `Decodable`:

```swift
public protocol Decodable {
    public init(from decoder: Decoder) throws
}
```

Notice anything unusual? Hint: it's defined in the _standard library_!

So when you customize a type's conformance to `Decodable`, you are using
`Decoder` directly. This has **nothing** to do with `JSONDecoder`, since it's in
`Foundation`, a separate library.

On the flip side, when we talk about things like `DateDecodingStrategy`, that's
very specific to JSON and `JSONDecoder`. The standard library absolutely nothing
about it. In this particular case, the JSON standard does not include a date
value type, so there might be many ways to map a JSON value to
a `Foundation.Date`. A decoder for a different external representation may not
need to provide the same options for this kind of "strategy", or even not have
any for it at all (perhaps that external format has first-class date values 😉).

## Summary

The group of concepts surrounding `Codable` in Swift's standard library are
agnostic to any particular external format. It's really a mechanism for us to
express, if you will, the *schema*s of our types.

`Foundation` provides `(JSON|Property)(De|En)coder` that uses these *schema*s
as hints to translate external representations from/to the actual types.

![](images/Summary.png?raw=true)

Due to differences in format specifiactions, you'll find that not all
`Decodable` types for JSON are appropriate for decoding from TOML content. But
now you know that the choices you made for JSON aren't necerilly the "one true
way".
