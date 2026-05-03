struct BenchmarkConfiguration: Equatable, Sendable {
    var algorithm: BenchmarkAlgorithm
    var dataType: BenchmarkDataType
    var simdWidth: BenchmarkSIMDWidth

    var scalarTitle: String {
        "Scalar \(dataType.title)"
    }

    var simdTitle: String {
        "\(simdWidth.title)<\(dataType.title)>"
    }

    var comparisonTitle: String {
        "\(algorithm.title): \(scalarTitle) vs \(simdTitle)"
    }
}

enum BenchmarkDataType: String, CaseIterable, Identifiable, Sendable {
    case float32
    case float64
    case int8
    case int16
    case int32

    var id: Self { self }

    var title: String {
        switch self {
        case .float32:
            "Float"
        case .float64:
            "Double"
        case .int8:
            "Int8"
        case .int16:
            "Int16"
        case .int32:
            "Int32"
        }
    }
}

enum BenchmarkSIMDWidth: Int, CaseIterable, Identifiable, Sendable {
    case simd2 = 2
    case simd3 = 3
    case simd4 = 4
    case simd8 = 8
    case simd16 = 16
    case simd32 = 32
    case simd64 = 64

    var id: Self { self }

    var title: String {
        "SIMD\(rawValue)"
    }
}
