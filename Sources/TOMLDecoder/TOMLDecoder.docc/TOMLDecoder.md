# ``TOMLDecoder``

TOML:
"a minimal configuration file format that's easy to read due to obvious semantics".

`TOMLDecoder` is Swift library for decoding [TOML](https://toml.io).
It converts TOML into your `Codable` types
(like `JSONDecoder` for JSON).
It provides fast TOML deserialization
(like `JSONDeserializer` for JSON),
and type-safe access to parsed results.
`TOMLDecoder` implements the TOML 1.1.0 spec.

This library can do 2 things to TOML:
* **Deserialize**:
  convert TOML strings or byte sequences into strongly-typed,
  structured data, and provide access to parts of it.
* **Decode**:
  further convert the structured data into your `Codable` types
  according to your preferences.

There's a topic for each of them below,
with related APIs grouped within.

## Topics

### Quick start

To see TOMLDecoder in action, read:

- <doc:GettingStarted>

### Decoding TOML

You define types that conforms to `Codable`,
and TOMLDecoder can attempt to create instances of your type
from TOML data.
You can configure the decoding strategies to customize
the decoder's behaviors.

- <doc:DecodingTOML>
- ``TOMLDecoder``
- ``TOMLDecoder/isLenient``
- ``TOMLDecoder/Strategy``
- ``TOMLDecoder/KeyStrategy``
- ``TOMLDecoder/TimeIntervalStrategy``
- ``TOMLDecoder/DateStrategy``

### Deserializing TOML

Parse, un-marshal, deserialize.
When TOMLDecoder does this to TOML strings or bytes,
Data type as defined by the TOML specification
is strictly mapped into a data type.

- <doc:DeserializingTOML>
- ``TOMLTable``
- ``TOMLArray``
- ``OffsetDateTime``
- ``LocalDateTime``
- ``LocalDate``
- ``LocalTime``
- ``TOMLError``

### Other resources

- <doc:DevelopingTOMLDecoder>
- <doc:CHANGELOG>
- <doc:VersionedDocs>
