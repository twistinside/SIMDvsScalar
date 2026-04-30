import Foundation
import simd

enum BenchmarkEngine {
    static let elementCount = 1024

    private static let lanesPerVector = 4

    @inline(never)
    private static func scalarOp(_ a: Float, _ b: Float) -> Float {
        let sum = a * b + a
        let squareRoot = sqrtf(abs(sum) + 1)

        return squareRoot / (squareRoot + 1)
    }

    static func runScalar(
        iterations requestedIterations: Int,
        shouldCancel: () -> Bool = { false }
    ) -> BenchmarkResult {
        let iterations = max(requestedIterations, 1)
        var a = makeScalarInput(scale: 0.1)
        var b = makeScalarInput(scale: 0.2)
        var c = [Float](repeating: 0, count: elementCount)

        var completedIterations = 0
        let start = CFAbsoluteTimeGetCurrent()

        for _ in 0..<iterations {
            if shouldCancel() {
                break
            }

            for index in 0..<elementCount {
                c[index] = scalarOp(a[index], b[index])
            }

            a[0] = c[elementCount - 1]
            b[0] = c[0]
            completedIterations += 1
        }

        let duration = CFAbsoluteTimeGetCurrent() - start

        return BenchmarkResult(
            kind: .scalar,
            duration: duration,
            requestedIterations: iterations,
            completedIterations: completedIterations,
            checksum: checksum(c),
            wasCancelled: shouldCancel()
        )
    }

    static func runSIMD(
        iterations requestedIterations: Int,
        shouldCancel: () -> Bool = { false }
    ) -> BenchmarkResult {
        let iterations = max(requestedIterations, 1)
        let vectorCount = elementCount / lanesPerVector
        var a = makeSIMDInput(scale: 0.1, vectorCount: vectorCount)
        var b = makeSIMDInput(scale: 0.2, vectorCount: vectorCount)
        var c = [SIMD4<Float>](repeating: .zero, count: vectorCount)
        let ones = SIMD4<Float>(repeating: 1)

        var completedIterations = 0
        let start = CFAbsoluteTimeGetCurrent()

        for _ in 0..<iterations {
            if shouldCancel() {
                break
            }

            for index in 0..<vectorCount {
                let sum = a[index] * b[index] + a[index]
                let squareRoot = (abs(sum) + ones).squareRoot()
                c[index] = squareRoot / (squareRoot + ones)
            }

            a[0] = c[vectorCount - 1]
            b[0] = c[0]
            completedIterations += 1
        }

        let duration = CFAbsoluteTimeGetCurrent() - start

        return BenchmarkResult(
            kind: .simd,
            duration: duration,
            requestedIterations: iterations,
            completedIterations: completedIterations,
            checksum: checksum(c),
            wasCancelled: shouldCancel()
        )
    }

    private static func makeScalarInput(scale: Float) -> [Float] {
        (0..<elementCount).map { index in
            Float(index) * scale
        }
    }

    private static func makeSIMDInput(scale: Float, vectorCount: Int) -> [SIMD4<Float>] {
        (0..<vectorCount).map { vectorIndex in
            let base = vectorIndex * lanesPerVector
            let lanes = SIMD4<Float>(
                Float(base),
                Float(base + 1),
                Float(base + 2),
                Float(base + 3)
            )

            return lanes * SIMD4<Float>(repeating: scale)
        }
    }

    private static func checksum(_ values: [Float]) -> Float {
        values.reduce(0, +)
    }

    private static func checksum(_ values: [SIMD4<Float>]) -> Float {
        values.reduce(0) { partialResult, vector in
            partialResult + vector.x + vector.y + vector.z + vector.w
        }
    }
}
