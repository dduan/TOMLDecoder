# ``TOMLDecoder``

TOML: 
"a minimal configuration file format that's easy to read due to obvious semantics".

`TOMLDecoder` is Swift library for decoding [TOML](https://toml.io).
It converts TOML into your `Codable` types
(like `JSONDecoder` for JSON).
It provides fast TOML deserialization
(like `JSONDeserializer` for JSON),
and type-safe access to parsed results.
`TOMLDecoder` implements the TOML 1.0 spec.

This library can do 2 things to TOML:
* <doc:DeserializingTOML>:
  convert TOML strings or byte sequences into strongly-typed,
  structured data, and provide access to parts of it.
* <doc:DecodingTOML>:
  further convert the strutured data into your `Codeble` types
  according to your preferences.
   
You may need to accomplish only one,
or both,
of these tasks.
There's a topic for each of them below,
with related APIs grouped within.

## Topics

### Quick start

To see TOMLDecoder in action, read:

- <doc:GettingStarted>

### Decoding TOML

- <doc:DecodingTOML>
- ``TOMLDecoder``
- ``TOMLDecoder/Strategy``

### Deserializing TOML

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