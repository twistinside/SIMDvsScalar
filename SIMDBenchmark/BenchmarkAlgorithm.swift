enum BenchmarkAlgorithm: String, CaseIterable, Identifiable, Sendable {
    case arithmetic
    case thresholdSelect
    case reduction
    case boundsMerge

    var id: Self { self }

    var title: String {
        switch self {
        case .arithmetic:
            "Arithmetic"
        case .thresholdSelect:
            "Threshold Select"
        case .reduction:
            "Reduction"
        case .boundsMerge:
            "Bounds Merge"
        }
    }

    var shortTitle: String {
        switch self {
        case .arithmetic:
            "Arithmetic"
        case .thresholdSelect:
            "Threshold"
        case .reduction:
            "Reduction"
        case .boundsMerge:
            "Bounds"
        }
    }
}
