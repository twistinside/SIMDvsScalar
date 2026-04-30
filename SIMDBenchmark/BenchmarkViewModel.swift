import Foundation
import Observation

@MainActor
@Observable
final class BenchmarkViewModel {
    var iterationCount = 100_000
    var scalarResult: BenchmarkResult?
    var simdResult: BenchmarkResult?
    var isRunning = false
    var isStopping = false

    @ObservationIgnored private let runner = BenchmarkRunner()
    @ObservationIgnored private var currentRunID = UUID()
    @ObservationIgnored private var runningTask: Task<Void, Never>?

    var canRun: Bool {
        !isRunning && iterationCount > 0
    }

    var results: [BenchmarkResult] {
        [scalarResult, simdResult].compactMap { $0 }
    }

    var speedup: Double? {
        guard let scalarResult, let simdResult, simdResult.duration > 0 else {
            return nil
        }

        return scalarResult.duration / simdResult.duration
    }

    deinit {
        runningTask?.cancel()
    }

    func run(_ kind: BenchmarkKind) {
        start(.single(kind))
    }

    func runBoth() {
        start(.both)
    }

    func stop() {
        isStopping = true
        runningTask?.cancel()
    }

    func clampIterations() {
        iterationCount = max(iterationCount, 1)
    }

    private func start(_ mode: BenchmarkMode) {
        runningTask?.cancel()

        let runID = UUID()
        let iterations = max(iterationCount, 1)
        currentRunID = runID
        iterationCount = iterations
        isRunning = true
        isStopping = false

        switch mode {
        case .single(.scalar):
            scalarResult = nil
        case .single(.simd):
            simdResult = nil
        case .both:
            scalarResult = nil
            simdResult = nil
        }

        runningTask = Task { [mode, iterations, runner] in
            let outcome = await runner.perform(mode, iterations: iterations)
            finish(runID: runID, outcome: outcome)
        }
    }

    private func finish(runID: UUID, outcome: BenchmarkOutcome) {
        guard runID == currentRunID else {
            return
        }

        if let scalarResult = outcome.scalarResult {
            self.scalarResult = scalarResult
        }

        if let simdResult = outcome.simdResult {
            self.simdResult = simdResult
        }

        isRunning = false
        isStopping = false
        runningTask = nil
    }
}
