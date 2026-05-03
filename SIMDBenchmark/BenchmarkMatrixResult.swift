import Foundation

struct BenchmarkMatrixResult: Identifiable, Sendable {
    let configuration: BenchmarkConfiguration
    let scalarResult: BenchmarkResult
    let optimizedScalarResult: BenchmarkResult
    let simdResult: BenchmarkResult

    var id: String {
        "\(configuration.algorithm.rawValue)-\(configuration.dataType.rawValue)-\(configuration.simdWidth.rawValue)"
    }

    var speedup: Double {
        simdResult.duration > 0 ? scalarResult.duration / simdResult.duration : 0
    }

    var optimizedScalarSpeedup: Double {
        optimizedScalarResult.duration > 0 ? scalarResult.duration / optimizedScalarResult.duration : 0
    }

    var simdVsOptimizedScalarSpeedup: Double {
        simdResult.duration > 0 ? optimizedScalarResult.duration / simdResult.duration : 0
    }

    var checksumDelta: Double {
        abs(scalarResult.checksum - simdResult.checksum)
    }

    var optimizedScalarChecksumDelta: Double {
        abs(scalarResult.checksum - optimizedScalarResult.checksum)
    }

    var csvFields: [String] {
        [
            configuration.algorithm.title,
            configuration.dataType.title,
            configuration.simdWidth.title,
            "\(BenchmarkEngine.elementCount)",
            "\(scalarResult.requestedIterations)",
            "\(scalarResult.completedIterations)",
            "\(optimizedScalarResult.completedIterations)",
            "\(simdResult.completedIterations)",
            format(scalarResult.duration),
            format(optimizedScalarResult.duration),
            format(simdResult.duration),
            format(scalarResult.perIteration),
            format(optimizedScalarResult.perIteration),
            format(simdResult.perIteration),
            format(scalarResult.elementsPerSecond),
            format(optimizedScalarResult.elementsPerSecond),
            format(simdResult.elementsPerSecond),
            format(speedup),
            format(optimizedScalarSpeedup),
            format(simdVsOptimizedScalarSpeedup),
            format(scalarResult.checksum),
            format(optimizedScalarResult.checksum),
            format(simdResult.checksum),
            format(checksumDelta),
            format(optimizedScalarChecksumDelta),
            "\(scalarResult.wasCancelled)",
            "\(optimizedScalarResult.wasCancelled)",
            "\(simdResult.wasCancelled)"
        ]
    }

    private func format(_ value: Double) -> String {
        String(format: "%.12g", value)
    }
}
