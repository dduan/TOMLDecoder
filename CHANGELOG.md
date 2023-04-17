## master

- Lowercase "z" is now accepted as zero-timezone-offset indicator
- Space is no longer accepted as an escaped character
- Hex/Octal/Binary numbers with no digits surrounding `_` is considered invalid
- Comments or whitespace at start of document no longer causes parsing failure
- TOML with invalid UTF-8 byte sequence will be rejected. Previously these have
  been decoded with the replacement character (U-FFFD).
- Local date with a trailing `T` such as `2023-04-16T` is considered invalid.
- Day with value `00` is invalid.

## 0.2.2

- Fixed a bug when parsing float decimals (#47)
- Add support for Windows

## 0.2.1

- Include a new type `DeserializationError`. It contains information regarding
  deserialization.
- Improve error reporting. After encountering one error, the parser will
  disgard characters until new line, and attempt to parse another top-level
  expression. This is more determinastic compared to previous recovery attempts.
- Add more specific errors regarding missing pices at closing position. For
  example, string missing closing quotes, or table missing closing bracket.
  These errors will cause the parser to report detailed error message.
- Fix a bug where newline characters sometimes are considered valid as part of
  basic string content.

## 0.2.0

- Rewritten from scratch to support TOML 1.0
- Remove support for CocoaPods and Carthage
- Remove dependency on NetTime, parser returns `Foundation.Date` and
  `Foundation.DateComponents` instead.
- Remove SwiftPM dependency on the `TOMLDeserializer` packege. It has been
  merged into the same project.
- Improved error reporting: a parsing error won't cause parsing to stop.
  Instead, the parser will attempt to parse as much as possible and report all
  errors it encounters.

## 0.1.6

- Fixed an issue where failure in single value decoding results in a crash (#19)
- Restored Carthage support (#21, #22)
