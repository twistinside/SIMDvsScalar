import Foundation

struct BenchmarkResult: Identifiable, Sendable {
    let kind: BenchmarkKind
    let duration: TimeInterval
    let requestedIterations: Int
    let completedIterations: Int
    let checksum: Float
    let wasCancelled: Bool

    var id: BenchmarkKind { kind }
    var label: String { kind.title }

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
