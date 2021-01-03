struct Traced<Value, Index> {
    let value: Value
    let index: Index
}

extension Traced: Equatable where Value: Equatable, Index: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.index == rhs.index && lhs.value == lhs.value
    }
}
