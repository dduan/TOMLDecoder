# Changelog

Kids call this "release notes" these days.

## In Development

This release introduces source-breaking changes from 0.3.x.

The lower-level parser APIs and architecture are introduced with an
eye towards an eventual 1.0 release.

### API change overview

At the highest level, TOMLDecoder still serves the role of providing
a `Swift.Decoder` implementation for the TOML language. A TOML table
can be transformed directly to a Swift `Codable`, similar to what
`Foundation.JSONDecoder` does for JSON.

#### Breaking changes

* `TOMLDecoder` is no longer an `open class`. It's now a struct.
* Decoding strategies are represented and stored differently.
* `Deserializer` is removed. Its functionalities are subsumed by
  new APIs.

#### New APIs

* A set of types to represent offset date-time, local date/time.
* `TOMLArray` and `TOMLTable` represent parsed TOML tables and arrays.
* Strongly typed access to fields e.g. `.string(forKey: "foo")` or
  `.integer(atIndex: 0)`.

### Infrastructure improvements

The full toml-lang/toml-test suite is now imported as unit tests.

A new documentation site:
https://dduan.github.io/TOMLDecoder/documentation/tomldecoder/

## 0.3.2

- Improved runtime performance for decoding by using less containers while
  assembling decoded values (#65)
- Fixed a leap year calculation bug (#66)
- Fixed .superDecoder (#68)

## 0.3.1

- Fixed a bug where extending table via dotted key was not allowed (#54)
- Declare support for Swift 6
- Add experimental support for building with Bazel

## 0.3.0

- Lowercase "z" is now accepted as zero-timezone-offset indicator
- Space is no longer accepted as an escaped character
- Hex/Octal/Binary numbers with no digits surrounding `_` is considered invalid
- Comments or whitespace at start of document no longer causes parsing failure
- TOML with invalid UTF-8 byte sequence will be rejected. Previously these have
  been decoded with the replacement character (U-FFFD).
- Local date with a trailing `T` such as `2023-04-16T` is considered invalid.
- Day with value `00` is invalid.
- Allow defining super table after it has been implicitly defined. For example,
  one could define `[a.b.c]`, then later `[a]`.
- Using dotted keys to add up to a previously header-defined table is now
  invalid. For example, use `[a.b.c]` to create the table, and later have
  `b.c =` under `[a]`.
- A standalone carriage return is no longer considered a valid newline
- Inline tables are now immutable
- Mutating array of tables that were implicitly created (e.g. `a = [{}]`) is now
  invalid
- Keys with spaces in between segments are now valid
- Multiline strings can now have 1 or two quotes as valid content
- Local date with a comment (`1970-01-01 # some comment`) is now accepted
- Control characters (except tabs) in comments are now invalid
- Escaped CRLF character in multiline string is properly handled

## 0.2.2

- Fixed a bug when parsing float decimals (#47)
- Add support for Windows

## 0.2.1

- Include a new type `DeserializationError`. It contains information regarding
  deserialization.
- Improve error reporting. After encountering one error, the parser will
  discard characters until new line, and attempt to parse another top-level
  expression. This is more deterministic compared to previous recovery attempts.
- Add more specific errors regarding missing pieces at closing position. For
  example, string missing closing quotes, or table missing closing bracket.
  These errors will cause the parser to report detailed error message.
- Fix a bug where newline characters sometimes are considered valid as part of
  basic string content.

## 0.2.0

- Rewritten from scratch to support TOML 1.0
- Remove support for CocoaPods and Carthage
- Remove dependency on NetTime, parser returns `Foundation.Date` and
  `Foundation.DateComponents` instead.
- Remove SwiftPM dependency on the `TOMLDeserializer` package. It has been
  merged into the same project.
- Improved error reporting: a parsing error won't cause parsing to stop.
  Instead, the parser will attempt to parse as much as possible and report all
  errors it encounters.

## 0.1.6

- Fixed an issue where failure in single value decoding results in a crash (#19)
- Restored Carthage support (#21, #22)
