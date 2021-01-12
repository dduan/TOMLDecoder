struct Traced<Value: Equatable>: Equatable {
    let value: Value
    let index: Substring.Index
}
