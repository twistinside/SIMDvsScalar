actor BenchmarkRunner {
    func perform(
        _ mode: BenchmarkMode,
        iterations: Int,
        configuration: BenchmarkConfiguration
    ) -> BenchmarkOutcome {
        switch mode {
        case .single(.scalar):
            return BenchmarkOutcome(
                scalarResult: BenchmarkEngine.runScalar(iterations: iterations, configuration: configuration) {
                    Task.isCancelled
                }
            )
        case .single(.optimizedScalar):
            return BenchmarkOutcome(
                optimizedScalarResult: BenchmarkEngine.runOptimizedScalar(iterations: iterations, configuration: configuration) {
                    Task.isCancelled
                }
            )
        case .single(.simd):
            return BenchmarkOutcome(
                simdResult: BenchmarkEngine.runSIMD(iterations: iterations, configuration: configuration) {
                    Task.isCancelled
                }
            )
        case .both:
            let scalarResult = BenchmarkEngine.runScalar(iterations: iterations, configuration: configuration) {
                Task.isCancelled
            }

            let optimizedScalarResult: BenchmarkResult? = if Task.isCancelled {
                nil
            } else {
                BenchmarkEngine.runOptimizedScalar(iterations: iterations, configuration: configuration) {
                    Task.isCancelled
                }
            }

            let simdResult: BenchmarkResult? = if Task.isCancelled {
                nil
            } else {
                BenchmarkEngine.runSIMD(iterations: iterations, configuration: configuration) {
                    Task.isCancelled
                }
            }

            return BenchmarkOutcome(
                scalarResult: scalarResult,
                optimizedScalarResult: optimizedScalarResult,
                simdResult: simdResult
            )
        }
    }
}

enum BenchmarkMode: Sendable {
    case single(BenchmarkKind)
    case both
}

struct BenchmarkOutcome: Sendable {
    var scalarResult: BenchmarkResult? = nil
    var optimizedScalarResult: BenchmarkResult? = nil
    var simdResult: BenchmarkResult? = nil
}
