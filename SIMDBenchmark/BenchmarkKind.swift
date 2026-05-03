enum BenchmarkKind: String, CaseIterable, Identifiable, Sendable {
    case scalar
    case optimizedScalar
    case simd

    var id: Self { self }
}
