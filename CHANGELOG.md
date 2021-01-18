## master

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
