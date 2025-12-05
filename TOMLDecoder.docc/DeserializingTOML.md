# How to Deserialize TOML

Learn how TOMLDecoder converts TOML into structured data.

## Overview

TOML is a text-based document format
consisted of different leaf data types like an integer,
or a local date;
and structural types like a table or an array.
If these sounds unfamiliar to you,
head over to [toml.io](https://toml.io) to read up on it.

To represent information in a TOML document in Swift,
we need a set of Swift types to represent each data type in TOML,
and some logic that converts the TOML text into these data type
according to the rules defined by the TOML specification.
The conversion process is referred to as deserializing the data,
or de-marshalling the data,
or parsing the data.

TOML decoder picks a set of Swift types to represent each TOML data type.
It also handles the parsing/deserializing/de-marshalling for you.
This article explains both aspects of the library.

_This may sound overly complicated.
and you only care about getting your `Codable`s.
In that case, checkout <doc:DecodingTOML>_.

## Representing TOML data types

`TOMLDecoder` has two separate layers of APIs.
The lower layer deals with deserialization.
We sometimes refer to it as the parser.
Each TOML type has a definite, unambiguous counterpart in Swift.
Under no circumstances
will the correspondence between the TOML and Swift types change.
TOMLDecoder APIs in this layer reflects this strongly typed relation.

### The Definitive List of TOML-to-Swift Types

For each data type defined in TOML,
there's a Swift type,
either from the standard library,
or from TOMLDecoder.
Here they are.

| TOML             | Swift              |
| ---------------- | ------------------ |
| Boolean          | `Swift.Bool`       |
| Integer          | `Swift.Int64`      |
| Float            | `Swift.Double`     |
| String           | `Swift.String`     |
| Offset Date-time | ``OffsetDateTime`` |
| Local Date-time  | ``LocalDateTime``  |
| Local Date       | ``LocalDate``      |
| Local Time       | ``LocalTime``      |
| Array            | ``TOMLArray``      |
| Table            | ``TOMLTable``      |

TOML keys are always represented by `Swift.String`

In TOML, structural types compose with each other.
The same data structure may be written in different forms.
After deserialization,
the structures all end up becoming ``TOMLArray``s or ``TOMLTable``s.
There's no special Swift type for "inline tables"
(it's just a ``TOMLTable``), or
"arrays of tables" (an ``TOMLArray`` can contain ``TOMLTable``s).

The Swift types representing date and time are provided by TOMLDecoder.

``OffsetDateTime``, and ``LocalDateTime`` are composed of
``LocalDate`` and ``LocalTime``.
Therefore, the APIs allows retrieving a ``LocalDate`` or a ``LocalTime``
from the larger data types,
if you explicitly specify it as a preference.
These are the only exceptions for type safety in the parser.


### Typed APIs

The APIs for the parser reflects strong type relations.

The root of a TOML document is always a table.
Therefore, the entry point for deserialization is ``TOMLTable``.
To parse a TOML document,
create a ``TOMLTable`` with data for it.

```swift
let tomlString = """
answer = 42
questions = ["why?", "how?", "ya?"]
"""

let rootTable = try TOMLTable(source: tomlString)
```

As promised,
to retrieve values from the table,
one must specify which TOML type they expect.
And as a result,
they'll get the value with the corresponding Swift type.

```swift
let hello = try rootTable.integer(forKey: "answer")
```

This method will fail
if the value for `answer` is not an integer,
or if the key doesn't exist in the table.
And the return value is a `Int64`.

As the only other structural type,
``TOMLArray`` has similar design when it comes to types.

```swift
// A table can contain an array as a value
let questions: TOMLArray = try rootTable.array(forKey: "questions")
let question2 = try questions.string(atIndex: 1)
```

## The Deserialization Process

Next,
let's talk a little about the deserialization process.
This knowledge may be useless if all you care about
is to get the job done.
But sometimes, you need the job done with high run-time efficiency.
Knowing how TOMLDecoder parses TOML can help with that.

TOMLDecoder tries to parse a TOML document in 2 phases.

Phase 1 involves analyzing the structure of the document:
where are the keys and values,
what structure contain what, etc.
It's *kind of* like lexical scope analysis,
if you know what that is.
If anything is obviously wrong,
then an error will be thrown.
This process happens when you call
``/TOMLDecoder/TOMLTable/init(source:)-(String)``.

Phase 2 is the final validation of individual leaf values.
During this phase,
the text representing leaf values like dates, floats, etc,
are analyzed to full fidelity,
and once they are known to be flawless,
they become the concrete Swift values.
This phase differs from the first because it
works with your *intent*:
Are you expecting an offset-date time?
Ok, now we validate with the rules for it on these bytes.

The 2 phase approach aims to minimize the amount of work
needed for parsing.
In practice,
the boundary between the 2 aren't as clear cut as stated.
But, it helps.

Since both phase contains failure points,
the APIs for them requres you to `try`.

```swift
// Phase 1
let rootTable = try TOMLTable(source: tomlString)
// Phase 2
let answer = try rootTable.integer(forKey: "answer")
```

If anything goes wrong, a ``TOMLError`` is thrown.

## Forget your types! I want Swift!

Well, you can't really ignore the leaf types.

BUT, you can replace all the structural types
with `[String: Any]`s and `[Any]`s by using
the respective `init`s provided by TOMLDecoder.

```swift
// rootTable: TOMLTable
let bigDict: [String: Any] = try Dictionary(rootTable)
// answers: TOMLArray
let answers: [Any] = try Array(answers)
```

By now,
you should understand the consequences of doing so.

Firstly,
The non-structural `Any`s in these resulting Swift collections
will still be values of their corresponding type.
Continuing the old example,
`bigDict["answer"] as? Int64` is `Optional(42)`.

The good news is, all the `TOMLArray`s and `TOMLTable`s
are replaced by `[Any]` and `[String: Any]`.
This is a recursive process.

Secondly,
every field in the table will have been validated during this process.
And if any of them are found to be invalid,
the process would have resulted in an error.
So, yes,
doing this is really expensive.
