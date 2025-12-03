* Factor out the guts of the parser.
* The guts can be gyb'd for a `Span<UInt8>` version and a `UnsafeBufferPointer<UInt8>` version.
* Both version uses the same `Token` type.
* Therefore there won't be two `TOMLDocument` types.
* use `if #available` to choose which `TOMLDocument.init` to call based on OS versions.
