actor BenchmarkRunner {
    func perform(_ mode: BenchmarkMode, iterations: Int) -> BenchmarkOutcome {
        switch mode {
        case .single(.scalar):
            return BenchmarkOutcome(
                scalarResult: BenchmarkEngine.runScalar(iterations: iterations) {
                    Task.isCancelled
                }
            )
        case .single(.simd):
            return BenchmarkOutcome(
                simdResult: BenchmarkEngine.runSIMD(iterations: iterations) {
                    Task.isCancelled
                }
            )
        case .both:
            let scalarResult = BenchmarkEngine.runScalar(iterations: iterations) {
                Task.isCancelled
            }

            let simdResult: BenchmarkResult? = if Task.isCancelled {
                nil
            } else {
                BenchmarkEngine.runSIMD(iterations: iterations) {
                    Task.isCancelled
                }
            }

            return BenchmarkOutcome(
                scalarResult: scalarResult,
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
    var scalarResult: BenchmarkResult?
    var simdResult: BenchmarkResult?
}
