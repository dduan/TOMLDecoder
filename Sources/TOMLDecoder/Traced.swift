struct Traced<Value: Equatable & Hashable>: Equatable, Hashable {
    let value: Value
    let index: Substring.Index
}
