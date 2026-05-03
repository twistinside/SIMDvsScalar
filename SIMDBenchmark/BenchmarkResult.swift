import Foundation

struct BenchmarkResult: Identifiable, Sendable {
    let kind: BenchmarkKind
    let configuration: BenchmarkConfiguration
    let duration: TimeInterval
    let requestedIterations: Int
    let completedIterations: Int
    let checksum: Double
    let wasCancelled: Bool

    var id: BenchmarkKind { kind }

    var label: String {
        switch kind {
        case .scalar:
            configuration.scalarTitle
        case .optimizedScalar:
            "Optimized \(configuration.scalarTitle)"
        case .simd:
            configuration.simdTitle
        }
    }

    var perIteration: TimeInterval {
        completedIterations > 0 ? duration / Double(completedIterations) : 0
    }

    var processedElements: Int {
        completedIterations * BenchmarkEngine.elementCount
    }

    var elementsPerSecond: Double {
        duration > 0 ? Double(processedElements) / duration : 0
    }
}
