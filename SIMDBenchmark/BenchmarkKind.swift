enum BenchmarkKind: String, CaseIterable, Identifiable, Sendable {
    case scalar
    case simd

    var id: Self { self }

    var title: String {
        switch self {
        case .scalar:
            "Scalar Float"
        case .simd:
            "SIMD4<Float>"
        }
    }
}
