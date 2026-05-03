import Foundation
import Observation

@MainActor
@Observable
final class BenchmarkViewModel {
    var iterationCount = 100_000
    var algorithm = BenchmarkAlgorithm.arithmetic {
        didSet {
            clearResults()
        }
    }
    var dataType = BenchmarkDataType.float32 {
        didSet {
            clearResults()
        }
    }
    var simdWidth = BenchmarkSIMDWidth.simd4 {
        didSet {
            clearResults()
        }
    }
    var scalarResult: BenchmarkResult?
    var optimizedScalarResult: BenchmarkResult?
    var simdResult: BenchmarkResult?
    var matrixResults: [BenchmarkMatrixResult] = []
    var matrixProgress = 0
    var matrixTotal = 0
    var matrixStatus = ""
    var didCopyCSV = false
    var isMatrixRunning = false
    var isRunning = false
    var isStopping = false

    @ObservationIgnored let hardwareProfile = BenchmarkHardwareProfile.current
    @ObservationIgnored let buildProfile = BenchmarkBuildProfile.current
    @ObservationIgnored private let runner = BenchmarkRunner()
    @ObservationIgnored private var currentRunID = UUID()
    @ObservationIgnored private var runningTask: Task<Void, Never>?

    var canRun: Bool {
        !isRunning && iterationCount > 0
    }

    var configuration: BenchmarkConfiguration {
        BenchmarkConfiguration(algorithm: algorithm, dataType: dataType, simdWidth: simdWidth)
    }

    var results: [BenchmarkResult] {
        [scalarResult, optimizedScalarResult, simdResult].compactMap { $0 }
    }

    var speedup: Double? {
        guard let scalarResult, let simdResult, simdResult.duration > 0 else {
            return nil
        }

        return scalarResult.duration / simdResult.duration
    }

    var optimizedScalarSpeedup: Double? {
        guard let scalarResult, let optimizedScalarResult, optimizedScalarResult.duration > 0 else {
            return nil
        }

        return scalarResult.duration / optimizedScalarResult.duration
    }

    var simdVsOptimizedScalarSpeedup: Double? {
        guard let optimizedScalarResult, let simdResult, simdResult.duration > 0 else {
            return nil
        }

        return optimizedScalarResult.duration / simdResult.duration
    }

    var matrixCSV: String {
        let header = BenchmarkHardwareProfile.csvHeader + BenchmarkBuildProfile.csvHeader + [
            "algorithm",
            "data_type",
            "simd_type",
            "element_count",
            "requested_iterations",
            "scalar_completed_iterations",
            "optimized_scalar_completed_iterations",
            "simd_completed_iterations",
            "scalar_seconds",
            "optimized_scalar_seconds",
            "simd_seconds",
            "scalar_seconds_per_iteration",
            "optimized_scalar_seconds_per_iteration",
            "simd_seconds_per_iteration",
            "scalar_elements_per_second",
            "optimized_scalar_elements_per_second",
            "simd_elements_per_second",
            "simd_vs_scalar_speedup",
            "optimized_scalar_vs_scalar_speedup",
            "simd_vs_optimized_scalar_speedup",
            "scalar_checksum",
            "optimized_scalar_checksum",
            "simd_checksum",
            "simd_checksum_delta",
            "optimized_scalar_checksum_delta",
            "scalar_cancelled",
            "optimized_scalar_cancelled",
            "simd_cancelled"
        ]

        return ([header] + matrixResults.map { hardwareProfile.csvFields + buildProfile.csvFields + $0.csvFields })
            .map { fields in
                fields.map(escapeCSVField).joined(separator: ",")
            }
            .joined(separator: "\n")
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

    func runAllCombinations() {
        startMatrix()
    }

    func markCSVWasCopied() {
        didCopyCSV = true
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
        let configuration = configuration
        currentRunID = runID
        iterationCount = iterations
        isMatrixRunning = false
        isRunning = true
        isStopping = false

        switch mode {
        case .single(.scalar):
            scalarResult = nil
        case .single(.optimizedScalar):
            optimizedScalarResult = nil
        case .single(.simd):
            simdResult = nil
        case .both:
            scalarResult = nil
            optimizedScalarResult = nil
            simdResult = nil
        }

        runningTask = Task { [mode, iterations, runner, configuration] in
            let outcome = await runner.perform(mode, iterations: iterations, configuration: configuration)
            finish(runID: runID, outcome: outcome)
        }
    }

    private func startMatrix() {
        runningTask?.cancel()

        let runID = UUID()
        let iterations = max(iterationCount, 1)
        let configurations = BenchmarkDataType.allCases.flatMap { dataType in
            BenchmarkAlgorithm.allCases.flatMap { algorithm in
                BenchmarkSIMDWidth.allCases.map { simdWidth in
                    BenchmarkConfiguration(algorithm: algorithm, dataType: dataType, simdWidth: simdWidth)
                }
            }
        }

        currentRunID = runID
        iterationCount = iterations
        matrixResults = []
        matrixProgress = 0
        matrixTotal = configurations.count
        matrixStatus = "Starting"
        didCopyCSV = false
        isMatrixRunning = true
        isRunning = true
        isStopping = false

        runningTask = Task { [iterations, runner, configurations] in
            for configuration in configurations {
                if Task.isCancelled {
                    break
                }

                matrixStatus = configuration.comparisonTitle

                let outcome = await runner.perform(.both, iterations: iterations, configuration: configuration)

                if Task.isCancelled || runID != currentRunID {
                    break
                }

                if let scalarResult = outcome.scalarResult,
                   let optimizedScalarResult = outcome.optimizedScalarResult,
                   let simdResult = outcome.simdResult {
                    didCopyCSV = false
                    matrixResults.append(
                        BenchmarkMatrixResult(
                            configuration: configuration,
                            scalarResult: scalarResult,
                            optimizedScalarResult: optimizedScalarResult,
                            simdResult: simdResult
                        )
                    )
                }

                matrixProgress += 1
            }

            finishMatrix(runID: runID)
        }
    }

    private func finish(runID: UUID, outcome: BenchmarkOutcome) {
        guard runID == currentRunID else {
            return
        }

        if let scalarResult = outcome.scalarResult {
            self.scalarResult = scalarResult
        }

        if let optimizedScalarResult = outcome.optimizedScalarResult {
            self.optimizedScalarResult = optimizedScalarResult
        }

        if let simdResult = outcome.simdResult {
            self.simdResult = simdResult
        }

        isRunning = false
        isMatrixRunning = false
        isStopping = false
        runningTask = nil
    }

    private func finishMatrix(runID: UUID) {
        guard runID == currentRunID else {
            return
        }

        matrixStatus = isStopping || Task.isCancelled ? "Stopped" : "Complete"
        isRunning = false
        isMatrixRunning = false
        isStopping = false
        runningTask = nil
    }

    private func clearResults() {
        scalarResult = nil
        optimizedScalarResult = nil
        simdResult = nil
    }

    private func escapeCSVField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
        } else {
            field
        }
    }
}
