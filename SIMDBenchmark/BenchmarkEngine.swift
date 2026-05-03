import Foundation
import simd

enum BenchmarkEngine {
    static let elementCount = 3_072

    static func runScalar(
        iterations requestedIterations: Int,
        configuration: BenchmarkConfiguration,
        shouldCancel: () -> Bool = { false }
    ) -> BenchmarkResult {
        switch configuration.dataType {
        case .float32:
            runFloatingScalar(
                Float.self,
                iterations: requestedIterations,
                configuration: configuration,
                shouldCancel: shouldCancel
            )
        case .float64:
            runFloatingScalar(
                Double.self,
                iterations: requestedIterations,
                configuration: configuration,
                shouldCancel: shouldCancel
            )
        case .int8:
            runIntegerScalar(
                Int8.self,
                iterations: requestedIterations,
                configuration: configuration,
                shouldCancel: shouldCancel
            )
        case .int16:
            runIntegerScalar(
                Int16.self,
                iterations: requestedIterations,
                configuration: configuration,
                shouldCancel: shouldCancel
            )
        case .int32:
            runIntegerScalar(
                Int32.self,
                iterations: requestedIterations,
                configuration: configuration,
                shouldCancel: shouldCancel
            )
        }
    }

    static func runSIMD(
        iterations requestedIterations: Int,
        configuration: BenchmarkConfiguration,
        shouldCancel: () -> Bool = { false }
    ) -> BenchmarkResult {
        switch configuration.dataType {
        case .float32:
            runFloatingSIMD(
                Float.self,
                iterations: requestedIterations,
                configuration: configuration,
                shouldCancel: shouldCancel
            )
        case .float64:
            runFloatingSIMD(
                Double.self,
                iterations: requestedIterations,
                configuration: configuration,
                shouldCancel: shouldCancel
            )
        case .int8:
            runIntegerSIMD(
                Int8.self,
                iterations: requestedIterations,
                configuration: configuration,
                shouldCancel: shouldCancel
            )
        case .int16:
            runIntegerSIMD(
                Int16.self,
                iterations: requestedIterations,
                configuration: configuration,
                shouldCancel: shouldCancel
            )
        case .int32:
            runIntegerSIMD(
                Int32.self,
                iterations: requestedIterations,
                configuration: configuration,
                shouldCancel: shouldCancel
            )
        }
    }

    static func runOptimizedScalar(
        iterations requestedIterations: Int,
        configuration: BenchmarkConfiguration,
        shouldCancel: () -> Bool = { false }
    ) -> BenchmarkResult {
        switch configuration.dataType {
        case .float32:
            runFloatingOptimizedScalar(
                Float.self,
                iterations: requestedIterations,
                configuration: configuration,
                shouldCancel: shouldCancel
            )
        case .float64:
            runFloatingOptimizedScalar(
                Double.self,
                iterations: requestedIterations,
                configuration: configuration,
                shouldCancel: shouldCancel
            )
        case .int8:
            runIntegerOptimizedScalar(
                Int8.self,
                iterations: requestedIterations,
                configuration: configuration,
                shouldCancel: shouldCancel
            )
        case .int16:
            runIntegerOptimizedScalar(
                Int16.self,
                iterations: requestedIterations,
                configuration: configuration,
                shouldCancel: shouldCancel
            )
        case .int32:
            runIntegerOptimizedScalar(
                Int32.self,
                iterations: requestedIterations,
                configuration: configuration,
                shouldCancel: shouldCancel
            )
        }
    }

    @inline(never)
    private static func floatingScalarOp<T>(_ a: T, _ b: T) -> T where T: BinaryFloatingPoint {
        let sum = a * b + a
        let squareRoot = (sum + 1).squareRoot()

        return squareRoot / (squareRoot + 1)
    }

    @inline(never)
    private static func integerScalarOp<T>(_ a: T, _ b: T) -> T where T: FixedWidthInteger & SignedInteger {
        let mixed = (a &* T(31)) &+ (b &* T(17)) &+ (a ^ b)

        return (mixed ^ (mixed &>> 3)) &+ (a &<< 2)
    }

    @inline(never)
    private static func floatingThresholdScalarOp<T>(_ a: T, _ b: T) -> T where T: BinaryFloatingPoint {
        let value = a * b + a
        let threshold = T(512)

        if value > threshold {
            return (value + 1).squareRoot() / (b + 1)
        } else {
            return (threshold - value) * T(0.125) + a
        }
    }

    @inline(never)
    private static func integerThresholdScalarOp<T>(_ a: T, _ b: T) -> T where T: FixedWidthInteger & SignedInteger {
        let mixed = (a &* T(31)) &+ (b &* T(17)) &+ (a ^ b)

        if mixed & T(7) == 0 {
            return mixed &+ (a &<< 1)
        } else {
            return (mixed ^ b) &- (a &>> 2)
        }
    }

    @inline(never)
    private static func floatingBoundsScalarOp<T>(_ a: T, _ b: T, useMinimum: Bool) -> T where T: BinaryFloatingPoint {
        useMinimum ? min(a, b) : max(a, b)
    }

    @inline(never)
    private static func integerBoundsScalarOp<T>(_ a: T, _ b: T, useMinimum: Bool) -> T where T: FixedWidthInteger & SignedInteger {
        useMinimum ? min(a, b) : max(a, b)
    }

    @inline(__always)
    private static func floatingOptimizedScalarOp<T>(_ a: T, _ b: T) -> T where T: BinaryFloatingPoint {
        let sum = a * b + a
        let squareRoot = (sum + 1).squareRoot()

        return squareRoot / (squareRoot + 1)
    }

    @inline(__always)
    private static func integerOptimizedScalarOp<T>(_ a: T, _ b: T) -> T where T: FixedWidthInteger & SignedInteger {
        let mixed = (a &* T(31)) &+ (b &* T(17)) &+ (a ^ b)

        return (mixed ^ (mixed &>> 3)) &+ (a &<< 2)
    }

    @inline(__always)
    private static func floatingThresholdOptimizedScalarOp<T>(_ a: T, _ b: T) -> T where T: BinaryFloatingPoint {
        let value = a * b + a
        let threshold = T(512)

        if value > threshold {
            return (value + 1).squareRoot() / (b + 1)
        } else {
            return (threshold - value) * T(0.125) + a
        }
    }

    @inline(__always)
    private static func integerThresholdOptimizedScalarOp<T>(_ a: T, _ b: T) -> T where T: FixedWidthInteger & SignedInteger {
        let mixed = (a &* T(31)) &+ (b &* T(17)) &+ (a ^ b)

        if mixed & T(7) == 0 {
            return mixed &+ (a &<< 1)
        } else {
            return (mixed ^ b) &- (a &>> 2)
        }
    }

    @inline(__always)
    private static func floatingBoundsOptimizedScalarOp<T>(_ a: T, _ b: T, useMinimum: Bool) -> T where T: BinaryFloatingPoint {
        useMinimum ? min(a, b) : max(a, b)
    }

    @inline(__always)
    private static func integerBoundsOptimizedScalarOp<T>(_ a: T, _ b: T, useMinimum: Bool) -> T where T: FixedWidthInteger & SignedInteger {
        useMinimum ? min(a, b) : max(a, b)
    }

    @inline(never)
    private static func floatingSIMDOp<V>(_ a: V, _ b: V, one: V) -> V where V: SIMD, V.Scalar: BinaryFloatingPoint {
        let sum = a * b + a
        let squareRoot = (sum + one).squareRoot()

        return squareRoot / (squareRoot + one)
    }

    @inline(never)
    private static func integerSIMDOp<V>(_ a: V, _ b: V) -> V where V: SIMD, V.Scalar: FixedWidthInteger & SignedInteger {
        let mixed = (a &* V(repeating: 31)) &+ (b &* V(repeating: 17)) &+ (a ^ b)

        return (mixed ^ (mixed &>> V(repeating: 3))) &+ (a &<< V(repeating: 2))
    }

    @inline(never)
    private static func floatingThresholdSIMDOp<V>(_ a: V, _ b: V, one: V) -> V where V: SIMD, V.Scalar: BinaryFloatingPoint {
        let value = a * b + a
        let threshold = V(repeating: 512)
        let low = (threshold - value) * V(repeating: 0.125) + a
        let high = (value + one).squareRoot() / (b + one)
        var result = low
        result.replace(with: high, where: value .> threshold)

        return result
    }

    @inline(never)
    private static func integerThresholdSIMDOp<V>(_ a: V, _ b: V) -> V where V: SIMD, V.Scalar: FixedWidthInteger & SignedInteger {
        let mixed = (a &* V(repeating: 31)) &+ (b &* V(repeating: 17)) &+ (a ^ b)
        let low = (mixed ^ b) &- (a &>> V(repeating: 2))
        let high = mixed &+ (a &<< V(repeating: 1))
        var result = low
        result.replace(with: high, where: (mixed & V(repeating: 7)) .== V.zero)

        return result
    }

    @inline(never)
    private static func boundsSIMDOp<V>(_ a: V, _ b: V, minimumMask: SIMDMask<V.MaskStorage>) -> V where V: SIMD, V.Scalar: Comparable {
        let aIsLower = a .< b
        var low = b
        var high = a
        low.replace(with: a, where: aIsLower)
        high.replace(with: b, where: aIsLower)

        var result = high
        result.replace(with: low, where: minimumMask)

        return result
    }

    private static func runFloatingScalar<T>(
        _ type: T.Type,
        iterations requestedIterations: Int,
        configuration: BenchmarkConfiguration,
        shouldCancel: () -> Bool
    ) -> BenchmarkResult where T: BinaryFloatingPoint & SIMDScalar {
        switch configuration.algorithm {
        case .arithmetic:
            runFloatingScalarArithmetic(type, iterations: requestedIterations, configuration: configuration, shouldCancel: shouldCancel)
        case .thresholdSelect:
            runFloatingScalarThreshold(type, iterations: requestedIterations, configuration: configuration, shouldCancel: shouldCancel)
        case .reduction:
            runFloatingScalarReduction(type, iterations: requestedIterations, configuration: configuration, shouldCancel: shouldCancel)
        case .boundsMerge:
            runFloatingScalarBounds(type, iterations: requestedIterations, configuration: configuration, shouldCancel: shouldCancel)
        }
    }

    private static func runFloatingScalarArithmetic<T>(
        _ type: T.Type,
        iterations requestedIterations: Int,
        configuration: BenchmarkConfiguration,
        shouldCancel: () -> Bool
    ) -> BenchmarkResult where T: BinaryFloatingPoint & SIMDScalar {
        let iterations = max(requestedIterations, 1)
        var a = makeFloatingScalarInput(type, scale: T(0.1))
        var b = makeFloatingScalarInput(type, scale: T(0.2))
        var c = [T](repeating: 0, count: elementCount)

        var completedIterations = 0
        let start = CFAbsoluteTimeGetCurrent()
        let feedbackWidth = configuration.simdWidth.rawValue

        for _ in 0..<iterations {
            if shouldCancel() {
                break
            }

            for index in 0..<elementCount {
                c[index] = floatingScalarOp(a[index], b[index])
            }

            for lane in 0..<feedbackWidth {
                a[lane] = c[elementCount - feedbackWidth + lane]
                b[lane] = c[lane]
            }

            completedIterations += 1
        }

        let duration = CFAbsoluteTimeGetCurrent() - start

        return BenchmarkResult(
            kind: .scalar,
            configuration: configuration,
            duration: duration,
            requestedIterations: iterations,
            completedIterations: completedIterations,
            checksum: checksum(c),
            wasCancelled: shouldCancel()
        )
    }

    private static func runIntegerScalar<T>(
        _ type: T.Type,
        iterations requestedIterations: Int,
        configuration: BenchmarkConfiguration,
        shouldCancel: () -> Bool
    ) -> BenchmarkResult where T: FixedWidthInteger & SignedInteger & SIMDScalar {
        switch configuration.algorithm {
        case .arithmetic:
            runIntegerScalarArithmetic(type, iterations: requestedIterations, configuration: configuration, shouldCancel: shouldCancel)
        case .thresholdSelect:
            runIntegerScalarThreshold(type, iterations: requestedIterations, configuration: configuration, shouldCancel: shouldCancel)
        case .reduction:
            runIntegerScalarReduction(type, iterations: requestedIterations, configuration: configuration, shouldCancel: shouldCancel)
        case .boundsMerge:
            runIntegerScalarBounds(type, iterations: requestedIterations, configuration: configuration, shouldCancel: shouldCancel)
        }
    }

    private static func runIntegerScalarArithmetic<T>(
        _ type: T.Type,
        iterations requestedIterations: Int,
        configuration: BenchmarkConfiguration,
        shouldCancel: () -> Bool
    ) -> BenchmarkResult where T: FixedWidthInteger & SignedInteger & SIMDScalar {
        let iterations = max(requestedIterations, 1)
        var a = makeIntegerScalarInput(type, step: 3)
        var b = makeIntegerScalarInput(type, step: 5)
        var c = [T](repeating: 0, count: elementCount)

        var completedIterations = 0
        let start = CFAbsoluteTimeGetCurrent()
        let feedbackWidth = configuration.simdWidth.rawValue

        for _ in 0..<iterations {
            if shouldCancel() {
                break
            }

            for index in 0..<elementCount {
                c[index] = integerScalarOp(a[index], b[index])
            }

            for lane in 0..<feedbackWidth {
                a[lane] = c[elementCount - feedbackWidth + lane]
                b[lane] = c[lane]
            }

            completedIterations += 1
        }

        let duration = CFAbsoluteTimeGetCurrent() - start

        return BenchmarkResult(
            kind: .scalar,
            configuration: configuration,
            duration: duration,
            requestedIterations: iterations,
            completedIterations: completedIterations,
            checksum: checksum(c),
            wasCancelled: shouldCancel()
        )
    }

    private static func runFloatingOptimizedScalar<T>(
        _ type: T.Type,
        iterations requestedIterations: Int,
        configuration: BenchmarkConfiguration,
        shouldCancel: () -> Bool
    ) -> BenchmarkResult where T: BinaryFloatingPoint & SIMDScalar {
        switch configuration.algorithm {
        case .arithmetic:
            runFloatingOptimizedScalarArithmetic(type, iterations: requestedIterations, configuration: configuration, shouldCancel: shouldCancel)
        case .thresholdSelect:
            runFloatingOptimizedScalarThreshold(type, iterations: requestedIterations, configuration: configuration, shouldCancel: shouldCancel)
        case .reduction:
            runFloatingOptimizedScalarReduction(type, iterations: requestedIterations, configuration: configuration, shouldCancel: shouldCancel)
        case .boundsMerge:
            runFloatingOptimizedScalarBounds(type, iterations: requestedIterations, configuration: configuration, shouldCancel: shouldCancel)
        }
    }

    private static func runFloatingOptimizedScalarArithmetic<T>(
        _ type: T.Type,
        iterations requestedIterations: Int,
        configuration: BenchmarkConfiguration,
        shouldCancel: () -> Bool
    ) -> BenchmarkResult where T: BinaryFloatingPoint & SIMDScalar {
        let iterations = max(requestedIterations, 1)
        var a = makeFloatingScalarInput(type, scale: T(0.1))
        var b = makeFloatingScalarInput(type, scale: T(0.2))
        var c = [T](repeating: 0, count: elementCount)

        var completedIterations = 0
        let start = CFAbsoluteTimeGetCurrent()
        let feedbackWidth = configuration.simdWidth.rawValue

        for _ in 0..<iterations {
            if shouldCancel() {
                break
            }

            for index in 0..<elementCount {
                c[index] = floatingOptimizedScalarOp(a[index], b[index])
            }

            for lane in 0..<feedbackWidth {
                a[lane] = c[elementCount - feedbackWidth + lane]
                b[lane] = c[lane]
            }

            completedIterations += 1
        }

        let duration = CFAbsoluteTimeGetCurrent() - start

        return BenchmarkResult(
            kind: .optimizedScalar,
            configuration: configuration,
            duration: duration,
            requestedIterations: iterations,
            completedIterations: completedIterations,
            checksum: checksum(c),
            wasCancelled: shouldCancel()
        )
    }

    private static func runIntegerOptimizedScalar<T>(
        _ type: T.Type,
        iterations requestedIterations: Int,
        configuration: BenchmarkConfiguration,
        shouldCancel: () -> Bool
    ) -> BenchmarkResult where T: FixedWidthInteger & SignedInteger & SIMDScalar {
        switch configuration.algorithm {
        case .arithmetic:
            runIntegerOptimizedScalarArithmetic(type, iterations: requestedIterations, configuration: configuration, shouldCancel: shouldCancel)
        case .thresholdSelect:
            runIntegerOptimizedScalarThreshold(type, iterations: requestedIterations, configuration: configuration, shouldCancel: shouldCancel)
        case .reduction:
            runIntegerOptimizedScalarReduction(type, iterations: requestedIterations, configuration: configuration, shouldCancel: shouldCancel)
        case .boundsMerge:
            runIntegerOptimizedScalarBounds(type, iterations: requestedIterations, configuration: configuration, shouldCancel: shouldCancel)
        }
    }

    private static func runIntegerOptimizedScalarArithmetic<T>(
        _ type: T.Type,
        iterations requestedIterations: Int,
        configuration: BenchmarkConfiguration,
        shouldCancel: () -> Bool
    ) -> BenchmarkResult where T: FixedWidthInteger & SignedInteger & SIMDScalar {
        let iterations = max(requestedIterations, 1)
        var a = makeIntegerScalarInput(type, step: 3)
        var b = makeIntegerScalarInput(type, step: 5)
        var c = [T](repeating: 0, count: elementCount)

        var completedIterations = 0
        let start = CFAbsoluteTimeGetCurrent()
        let feedbackWidth = configuration.simdWidth.rawValue

        for _ in 0..<iterations {
            if shouldCancel() {
                break
            }

            for index in 0..<elementCount {
                c[index] = integerOptimizedScalarOp(a[index], b[index])
            }

            for lane in 0..<feedbackWidth {
                a[lane] = c[elementCount - feedbackWidth + lane]
                b[lane] = c[lane]
            }

            completedIterations += 1
        }

        let duration = CFAbsoluteTimeGetCurrent() - start

        return BenchmarkResult(
            kind: .optimizedScalar,
            configuration: configuration,
            duration: duration,
            requestedIterations: iterations,
            completedIterations: completedIterations,
            checksum: checksum(c),
            wasCancelled: shouldCancel()
        )
    }

    private static func runFloatingScalarThreshold<T>(
        _ type: T.Type,
        iterations requestedIterations: Int,
        configuration: BenchmarkConfiguration,
        shouldCancel: () -> Bool
    ) -> BenchmarkResult where T: BinaryFloatingPoint & SIMDScalar {
        let iterations = max(requestedIterations, 1)
        var a = makeFloatingScalarInput(type, scale: T(0.1))
        var b = makeFloatingScalarInput(type, scale: T(0.2))
        var c = [T](repeating: 0, count: elementCount)

        var completedIterations = 0
        let start = CFAbsoluteTimeGetCurrent()
        let feedbackWidth = configuration.simdWidth.rawValue

        for _ in 0..<iterations {
            if shouldCancel() {
                break
            }

            for index in 0..<elementCount {
                c[index] = floatingThresholdScalarOp(a[index], b[index])
            }

            for lane in 0..<feedbackWidth {
                a[lane] = c[elementCount - feedbackWidth + lane]
                b[lane] = c[lane]
            }

            completedIterations += 1
        }

        let duration = CFAbsoluteTimeGetCurrent() - start

        return BenchmarkResult(
            kind: .scalar,
            configuration: configuration,
            duration: duration,
            requestedIterations: iterations,
            completedIterations: completedIterations,
            checksum: checksum(c),
            wasCancelled: shouldCancel()
        )
    }

    private static func runIntegerScalarThreshold<T>(
        _ type: T.Type,
        iterations requestedIterations: Int,
        configuration: BenchmarkConfiguration,
        shouldCancel: () -> Bool
    ) -> BenchmarkResult where T: FixedWidthInteger & SignedInteger & SIMDScalar {
        let iterations = max(requestedIterations, 1)
        var a = makeIntegerScalarInput(type, step: 3)
        var b = makeIntegerScalarInput(type, step: 5)
        var c = [T](repeating: 0, count: elementCount)

        var completedIterations = 0
        let start = CFAbsoluteTimeGetCurrent()
        let feedbackWidth = configuration.simdWidth.rawValue

        for _ in 0..<iterations {
            if shouldCancel() {
                break
            }

            for index in 0..<elementCount {
                c[index] = integerThresholdScalarOp(a[index], b[index])
            }

            for lane in 0..<feedbackWidth {
                a[lane] = c[elementCount - feedbackWidth + lane]
                b[lane] = c[lane]
            }

            completedIterations += 1
        }

        let duration = CFAbsoluteTimeGetCurrent() - start

        return BenchmarkResult(
            kind: .scalar,
            configuration: configuration,
            duration: duration,
            requestedIterations: iterations,
            completedIterations: completedIterations,
            checksum: checksum(c),
            wasCancelled: shouldCancel()
        )
    }

    private static func runFloatingOptimizedScalarThreshold<T>(
        _ type: T.Type,
        iterations requestedIterations: Int,
        configuration: BenchmarkConfiguration,
        shouldCancel: () -> Bool
    ) -> BenchmarkResult where T: BinaryFloatingPoint & SIMDScalar {
        let iterations = max(requestedIterations, 1)
        var a = makeFloatingScalarInput(type, scale: T(0.1))
        var b = makeFloatingScalarInput(type, scale: T(0.2))
        var c = [T](repeating: 0, count: elementCount)

        var completedIterations = 0
        let start = CFAbsoluteTimeGetCurrent()
        let feedbackWidth = configuration.simdWidth.rawValue

        for _ in 0..<iterations {
            if shouldCancel() {
                break
            }

            for index in 0..<elementCount {
                c[index] = floatingThresholdOptimizedScalarOp(a[index], b[index])
            }

            for lane in 0..<feedbackWidth {
                a[lane] = c[elementCount - feedbackWidth + lane]
                b[lane] = c[lane]
            }

            completedIterations += 1
        }

        let duration = CFAbsoluteTimeGetCurrent() - start

        return BenchmarkResult(
            kind: .optimizedScalar,
            configuration: configuration,
            duration: duration,
            requestedIterations: iterations,
            completedIterations: completedIterations,
            checksum: checksum(c),
            wasCancelled: shouldCancel()
        )
    }

    private static func runIntegerOptimizedScalarThreshold<T>(
        _ type: T.Type,
        iterations requestedIterations: Int,
        configuration: BenchmarkConfiguration,
        shouldCancel: () -> Bool
    ) -> BenchmarkResult where T: FixedWidthInteger & SignedInteger & SIMDScalar {
        let iterations = max(requestedIterations, 1)
        var a = makeIntegerScalarInput(type, step: 3)
        var b = makeIntegerScalarInput(type, step: 5)
        var c = [T](repeating: 0, count: elementCount)

        var completedIterations = 0
        let start = CFAbsoluteTimeGetCurrent()
        let feedbackWidth = configuration.simdWidth.rawValue

        for _ in 0..<iterations {
            if shouldCancel() {
                break
            }

            for index in 0..<elementCount {
                c[index] = integerThresholdOptimizedScalarOp(a[index], b[index])
            }

            for lane in 0..<feedbackWidth {
                a[lane] = c[elementCount - feedbackWidth + lane]
                b[lane] = c[lane]
            }

            completedIterations += 1
        }

        let duration = CFAbsoluteTimeGetCurrent() - start

        return BenchmarkResult(
            kind: .optimizedScalar,
            configuration: configuration,
            duration: duration,
            requestedIterations: iterations,
            completedIterations: completedIterations,
            checksum: checksum(c),
            wasCancelled: shouldCancel()
        )
    }

    private static func runFloatingScalarBounds<T>(
        _ type: T.Type,
        iterations requestedIterations: Int,
        configuration: BenchmarkConfiguration,
        shouldCancel: () -> Bool
    ) -> BenchmarkResult where T: BinaryFloatingPoint & SIMDScalar {
        let iterations = max(requestedIterations, 1)
        var a = makeFloatingScalarInput(type, scale: T(0.1))
        var b = makeFloatingScalarInput(type, scale: T(0.2))
        var c = [T](repeating: 0, count: elementCount)

        var completedIterations = 0
        let start = CFAbsoluteTimeGetCurrent()
        let feedbackWidth = configuration.simdWidth.rawValue

        for _ in 0..<iterations {
            if shouldCancel() {
                break
            }

            for index in 0..<elementCount {
                c[index] = floatingBoundsScalarOp(a[index], b[index], useMinimum: boundsLaneUsesMinimum(index % feedbackWidth))
            }

            for lane in 0..<feedbackWidth {
                a[lane] = c[elementCount - feedbackWidth + lane]
                b[lane] = c[lane]
            }

            completedIterations += 1
        }

        let duration = CFAbsoluteTimeGetCurrent() - start

        return BenchmarkResult(
            kind: .scalar,
            configuration: configuration,
            duration: duration,
            requestedIterations: iterations,
            completedIterations: completedIterations,
            checksum: checksum(c),
            wasCancelled: shouldCancel()
        )
    }

    private static func runIntegerScalarBounds<T>(
        _ type: T.Type,
        iterations requestedIterations: Int,
        configuration: BenchmarkConfiguration,
        shouldCancel: () -> Bool
    ) -> BenchmarkResult where T: FixedWidthInteger & SignedInteger & SIMDScalar {
        let iterations = max(requestedIterations, 1)
        var a = makeIntegerScalarInput(type, step: 3)
        var b = makeIntegerScalarInput(type, step: 5)
        var c = [T](repeating: 0, count: elementCount)

        var completedIterations = 0
        let start = CFAbsoluteTimeGetCurrent()
        let feedbackWidth = configuration.simdWidth.rawValue

        for _ in 0..<iterations {
            if shouldCancel() {
                break
            }

            for index in 0..<elementCount {
                c[index] = integerBoundsScalarOp(a[index], b[index], useMinimum: boundsLaneUsesMinimum(index % feedbackWidth))
            }

            for lane in 0..<feedbackWidth {
                a[lane] = c[elementCount - feedbackWidth + lane]
                b[lane] = c[lane]
            }

            completedIterations += 1
        }

        let duration = CFAbsoluteTimeGetCurrent() - start

        return BenchmarkResult(
            kind: .scalar,
            configuration: configuration,
            duration: duration,
            requestedIterations: iterations,
            completedIterations: completedIterations,
            checksum: checksum(c),
            wasCancelled: shouldCancel()
        )
    }

    private static func runFloatingOptimizedScalarBounds<T>(
        _ type: T.Type,
        iterations requestedIterations: Int,
        configuration: BenchmarkConfiguration,
        shouldCancel: () -> Bool
    ) -> BenchmarkResult where T: BinaryFloatingPoint & SIMDScalar {
        let iterations = max(requestedIterations, 1)
        var a = makeFloatingScalarInput(type, scale: T(0.1))
        var b = makeFloatingScalarInput(type, scale: T(0.2))
        var c = [T](repeating: 0, count: elementCount)

        var completedIterations = 0
        let start = CFAbsoluteTimeGetCurrent()
        let feedbackWidth = configuration.simdWidth.rawValue

        for _ in 0..<iterations {
            if shouldCancel() {
                break
            }

            for index in 0..<elementCount {
                c[index] = floatingBoundsOptimizedScalarOp(a[index], b[index], useMinimum: boundsLaneUsesMinimum(index % feedbackWidth))
            }

            for lane in 0..<feedbackWidth {
                a[lane] = c[elementCount - feedbackWidth + lane]
                b[lane] = c[lane]
            }

            completedIterations += 1
        }

        let duration = CFAbsoluteTimeGetCurrent() - start

        return BenchmarkResult(
            kind: .optimizedScalar,
            configuration: configuration,
            duration: duration,
            requestedIterations: iterations,
            completedIterations: completedIterations,
            checksum: checksum(c),
            wasCancelled: shouldCancel()
        )
    }

    private static func runIntegerOptimizedScalarBounds<T>(
        _ type: T.Type,
        iterations requestedIterations: Int,
        configuration: BenchmarkConfiguration,
        shouldCancel: () -> Bool
    ) -> BenchmarkResult where T: FixedWidthInteger & SignedInteger & SIMDScalar {
        let iterations = max(requestedIterations, 1)
        var a = makeIntegerScalarInput(type, step: 3)
        var b = makeIntegerScalarInput(type, step: 5)
        var c = [T](repeating: 0, count: elementCount)

        var completedIterations = 0
        let start = CFAbsoluteTimeGetCurrent()
        let feedbackWidth = configuration.simdWidth.rawValue

        for _ in 0..<iterations {
            if shouldCancel() {
                break
            }

            for index in 0..<elementCount {
                c[index] = integerBoundsOptimizedScalarOp(a[index], b[index], useMinimum: boundsLaneUsesMinimum(index % feedbackWidth))
            }

            for lane in 0..<feedbackWidth {
                a[lane] = c[elementCount - feedbackWidth + lane]
                b[lane] = c[lane]
            }

            completedIterations += 1
        }

        let duration = CFAbsoluteTimeGetCurrent() - start

        return BenchmarkResult(
            kind: .optimizedScalar,
            configuration: configuration,
            duration: duration,
            requestedIterations: iterations,
            completedIterations: completedIterations,
            checksum: checksum(c),
            wasCancelled: shouldCancel()
        )
    }

    private static func runFloatingScalarReduction<T>(
        _ type: T.Type,
        iterations requestedIterations: Int,
        configuration: BenchmarkConfiguration,
        shouldCancel: () -> Bool
    ) -> BenchmarkResult where T: BinaryFloatingPoint & SIMDScalar {
        let iterations = max(requestedIterations, 1)
        var a = makeFloatingScalarInput(type, scale: T(0.1))
        var b = makeFloatingScalarInput(type, scale: T(0.2))
        var c = [T](repeating: 0, count: elementCount)

        var completedIterations = 0
        let start = CFAbsoluteTimeGetCurrent()
        let feedbackWidth = configuration.simdWidth.rawValue
        var partials = [T](repeating: 0, count: feedbackWidth)

        for _ in 0..<iterations {
            if shouldCancel() {
                break
            }

            for lane in 0..<feedbackWidth {
                partials[lane] = 0
            }

            for index in 0..<elementCount {
                let lane = index % feedbackWidth
                partials[lane] += floatingScalarOp(a[index], b[index])
            }

            var total = T.zero

            for lane in 0..<feedbackWidth {
                total += partials[lane]
            }

            c[0] = total
            for lane in 0..<feedbackWidth {
                a[lane] = 0
                b[lane] = 0
            }
            a[0] = total / T(elementCount)
            b[0] = (a[0] + 1).squareRoot()
            completedIterations += 1
        }

        let duration = CFAbsoluteTimeGetCurrent() - start

        return BenchmarkResult(
            kind: .scalar,
            configuration: configuration,
            duration: duration,
            requestedIterations: iterations,
            completedIterations: completedIterations,
            checksum: checksum(c),
            wasCancelled: shouldCancel()
        )
    }

    private static func runIntegerScalarReduction<T>(
        _ type: T.Type,
        iterations requestedIterations: Int,
        configuration: BenchmarkConfiguration,
        shouldCancel: () -> Bool
    ) -> BenchmarkResult where T: FixedWidthInteger & SignedInteger & SIMDScalar {
        let iterations = max(requestedIterations, 1)
        var a = makeIntegerScalarInput(type, step: 3)
        var b = makeIntegerScalarInput(type, step: 5)
        var c = [T](repeating: 0, count: elementCount)

        var completedIterations = 0
        let start = CFAbsoluteTimeGetCurrent()
        let feedbackWidth = configuration.simdWidth.rawValue
        var partials = [T](repeating: 0, count: feedbackWidth)

        for _ in 0..<iterations {
            if shouldCancel() {
                break
            }

            for lane in 0..<feedbackWidth {
                partials[lane] = 0
            }

            for index in 0..<elementCount {
                let lane = index % feedbackWidth
                partials[lane] = partials[lane] &+ integerScalarOp(a[index], b[index])
            }

            var total = T.zero

            for lane in 0..<feedbackWidth {
                total = total &+ partials[lane]
            }

            c[0] = total
            for lane in 0..<feedbackWidth {
                a[lane] = 0
                b[lane] = 0
            }
            a[0] = total
            b[0] = total &>> 3
            completedIterations += 1
        }

        let duration = CFAbsoluteTimeGetCurrent() - start

        return BenchmarkResult(
            kind: .scalar,
            configuration: configuration,
            duration: duration,
            requestedIterations: iterations,
            completedIterations: completedIterations,
            checksum: checksum(c),
            wasCancelled: shouldCancel()
        )
    }

    private static func runFloatingOptimizedScalarReduction<T>(
        _ type: T.Type,
        iterations requestedIterations: Int,
        configuration: BenchmarkConfiguration,
        shouldCancel: () -> Bool
    ) -> BenchmarkResult where T: BinaryFloatingPoint & SIMDScalar {
        let iterations = max(requestedIterations, 1)
        var a = makeFloatingScalarInput(type, scale: T(0.1))
        var b = makeFloatingScalarInput(type, scale: T(0.2))
        var c = [T](repeating: 0, count: elementCount)

        var completedIterations = 0
        let start = CFAbsoluteTimeGetCurrent()
        let feedbackWidth = configuration.simdWidth.rawValue
        var partials = [T](repeating: 0, count: feedbackWidth)

        for _ in 0..<iterations {
            if shouldCancel() {
                break
            }

            for lane in 0..<feedbackWidth {
                partials[lane] = 0
            }

            for index in 0..<elementCount {
                let lane = index % feedbackWidth
                partials[lane] += floatingOptimizedScalarOp(a[index], b[index])
            }

            var total = T.zero

            for lane in 0..<feedbackWidth {
                total += partials[lane]
            }

            c[0] = total
            for lane in 0..<feedbackWidth {
                a[lane] = 0
                b[lane] = 0
            }
            a[0] = total / T(elementCount)
            b[0] = (a[0] + 1).squareRoot()
            completedIterations += 1
        }

        let duration = CFAbsoluteTimeGetCurrent() - start

        return BenchmarkResult(
            kind: .optimizedScalar,
            configuration: configuration,
            duration: duration,
            requestedIterations: iterations,
            completedIterations: completedIterations,
            checksum: checksum(c),
            wasCancelled: shouldCancel()
        )
    }

    private static func runIntegerOptimizedScalarReduction<T>(
        _ type: T.Type,
        iterations requestedIterations: Int,
        configuration: BenchmarkConfiguration,
        shouldCancel: () -> Bool
    ) -> BenchmarkResult where T: FixedWidthInteger & SignedInteger & SIMDScalar {
        let iterations = max(requestedIterations, 1)
        var a = makeIntegerScalarInput(type, step: 3)
        var b = makeIntegerScalarInput(type, step: 5)
        var c = [T](repeating: 0, count: elementCount)

        var completedIterations = 0
        let start = CFAbsoluteTimeGetCurrent()
        let feedbackWidth = configuration.simdWidth.rawValue
        var partials = [T](repeating: 0, count: feedbackWidth)

        for _ in 0..<iterations {
            if shouldCancel() {
                break
            }

            for lane in 0..<feedbackWidth {
                partials[lane] = 0
            }

            for index in 0..<elementCount {
                let lane = index % feedbackWidth
                partials[lane] = partials[lane] &+ integerOptimizedScalarOp(a[index], b[index])
            }

            var total = T.zero

            for lane in 0..<feedbackWidth {
                total = total &+ partials[lane]
            }

            c[0] = total
            for lane in 0..<feedbackWidth {
                a[lane] = 0
                b[lane] = 0
            }
            a[0] = total
            b[0] = total &>> 3
            completedIterations += 1
        }

        let duration = CFAbsoluteTimeGetCurrent() - start

        return BenchmarkResult(
            kind: .optimizedScalar,
            configuration: configuration,
            duration: duration,
            requestedIterations: iterations,
            completedIterations: completedIterations,
            checksum: checksum(c),
            wasCancelled: shouldCancel()
        )
    }

    private static func runFloatingSIMD<T>(
        _ type: T.Type,
        iterations requestedIterations: Int,
        configuration: BenchmarkConfiguration,
        shouldCancel: () -> Bool
    ) -> BenchmarkResult where T: BinaryFloatingPoint & SIMDScalar {
        switch configuration.simdWidth {
        case .simd2:
            runFloatingSIMD(
                SIMD2<T>.self,
                iterations: requestedIterations,
                configuration: configuration,
                shouldCancel: shouldCancel
            )
        case .simd3:
            runFloatingSIMD(
                SIMD3<T>.self,
                iterations: requestedIterations,
                configuration: configuration,
                shouldCancel: shouldCancel
            )
        case .simd4:
            runFloatingSIMD(
                SIMD4<T>.self,
                iterations: requestedIterations,
                configuration: configuration,
                shouldCancel: shouldCancel
            )
        case .simd8:
            runFloatingSIMD(
                SIMD8<T>.self,
                iterations: requestedIterations,
                configuration: configuration,
                shouldCancel: shouldCancel
            )
        case .simd16:
            runFloatingSIMD(
                SIMD16<T>.self,
                iterations: requestedIterations,
                configuration: configuration,
                shouldCancel: shouldCancel
            )
        case .simd32:
            runFloatingSIMD(
                SIMD32<T>.self,
                iterations: requestedIterations,
                configuration: configuration,
                shouldCancel: shouldCancel
            )
        case .simd64:
            runFloatingSIMD(
                SIMD64<T>.self,
                iterations: requestedIterations,
                configuration: configuration,
                shouldCancel: shouldCancel
            )
        }
    }

    private static func runIntegerSIMD<T>(
        _ type: T.Type,
        iterations requestedIterations: Int,
        configuration: BenchmarkConfiguration,
        shouldCancel: () -> Bool
    ) -> BenchmarkResult where T: FixedWidthInteger & SignedInteger & SIMDScalar {
        switch configuration.simdWidth {
        case .simd2:
            runIntegerSIMD(
                SIMD2<T>.self,
                iterations: requestedIterations,
                configuration: configuration,
                shouldCancel: shouldCancel
            )
        case .simd3:
            runIntegerSIMD(
                SIMD3<T>.self,
                iterations: requestedIterations,
                configuration: configuration,
                shouldCancel: shouldCancel
            )
        case .simd4:
            runIntegerSIMD(
                SIMD4<T>.self,
                iterations: requestedIterations,
                configuration: configuration,
                shouldCancel: shouldCancel
            )
        case .simd8:
            runIntegerSIMD(
                SIMD8<T>.self,
                iterations: requestedIterations,
                configuration: configuration,
                shouldCancel: shouldCancel
            )
        case .simd16:
            runIntegerSIMD(
                SIMD16<T>.self,
                iterations: requestedIterations,
                configuration: configuration,
                shouldCancel: shouldCancel
            )
        case .simd32:
            runIntegerSIMD(
                SIMD32<T>.self,
                iterations: requestedIterations,
                configuration: configuration,
                shouldCancel: shouldCancel
            )
        case .simd64:
            runIntegerSIMD(
                SIMD64<T>.self,
                iterations: requestedIterations,
                configuration: configuration,
                shouldCancel: shouldCancel
            )
        }
    }

    private static func runFloatingSIMD<V>(
        _ vectorType: V.Type,
        iterations requestedIterations: Int,
        configuration: BenchmarkConfiguration,
        shouldCancel: () -> Bool
    ) -> BenchmarkResult where V: SIMD, V.Scalar: BinaryFloatingPoint {
        switch configuration.algorithm {
        case .arithmetic:
            runFloatingSIMDArithmetic(vectorType, iterations: requestedIterations, configuration: configuration, shouldCancel: shouldCancel)
        case .thresholdSelect:
            runFloatingSIMDThreshold(vectorType, iterations: requestedIterations, configuration: configuration, shouldCancel: shouldCancel)
        case .reduction:
            runFloatingSIMDReduction(vectorType, iterations: requestedIterations, configuration: configuration, shouldCancel: shouldCancel)
        case .boundsMerge:
            runFloatingSIMDBounds(vectorType, iterations: requestedIterations, configuration: configuration, shouldCancel: shouldCancel)
        }
    }

    private static func runFloatingSIMDArithmetic<V>(
        _ vectorType: V.Type,
        iterations requestedIterations: Int,
        configuration: BenchmarkConfiguration,
        shouldCancel: () -> Bool
    ) -> BenchmarkResult where V: SIMD, V.Scalar: BinaryFloatingPoint {
        let iterations = max(requestedIterations, 1)
        let vectorCount = elementCount / V.scalarCount
        var a = makeFloatingSIMDInput(vectorType, scale: V.Scalar(0.1), vectorCount: vectorCount)
        var b = makeFloatingSIMDInput(vectorType, scale: V.Scalar(0.2), vectorCount: vectorCount)
        var c = [V](repeating: .zero, count: vectorCount)
        let one = V(repeating: 1)

        var completedIterations = 0
        let start = CFAbsoluteTimeGetCurrent()

        for _ in 0..<iterations {
            if shouldCancel() {
                break
            }

            for index in 0..<vectorCount {
                c[index] = floatingSIMDOp(a[index], b[index], one: one)
            }

            a[0] = c[vectorCount - 1]
            b[0] = c[0]
            completedIterations += 1
        }

        let duration = CFAbsoluteTimeGetCurrent() - start

        return BenchmarkResult(
            kind: .simd,
            configuration: configuration,
            duration: duration,
            requestedIterations: iterations,
            completedIterations: completedIterations,
            checksum: checksum(c),
            wasCancelled: shouldCancel()
        )
    }

    private static func runIntegerSIMD<V>(
        _ vectorType: V.Type,
        iterations requestedIterations: Int,
        configuration: BenchmarkConfiguration,
        shouldCancel: () -> Bool
    ) -> BenchmarkResult where V: SIMD, V.Scalar: FixedWidthInteger & SignedInteger {
        switch configuration.algorithm {
        case .arithmetic:
            runIntegerSIMDArithmetic(vectorType, iterations: requestedIterations, configuration: configuration, shouldCancel: shouldCancel)
        case .thresholdSelect:
            runIntegerSIMDThreshold(vectorType, iterations: requestedIterations, configuration: configuration, shouldCancel: shouldCancel)
        case .reduction:
            runIntegerSIMDReduction(vectorType, iterations: requestedIterations, configuration: configuration, shouldCancel: shouldCancel)
        case .boundsMerge:
            runIntegerSIMDBounds(vectorType, iterations: requestedIterations, configuration: configuration, shouldCancel: shouldCancel)
        }
    }

    private static func runIntegerSIMDArithmetic<V>(
        _ vectorType: V.Type,
        iterations requestedIterations: Int,
        configuration: BenchmarkConfiguration,
        shouldCancel: () -> Bool
    ) -> BenchmarkResult where V: SIMD, V.Scalar: FixedWidthInteger & SignedInteger {
        let iterations = max(requestedIterations, 1)
        let vectorCount = elementCount / V.scalarCount
        var a = makeIntegerSIMDInput(vectorType, step: 3, vectorCount: vectorCount)
        var b = makeIntegerSIMDInput(vectorType, step: 5, vectorCount: vectorCount)
        var c = [V](repeating: .zero, count: vectorCount)

        var completedIterations = 0
        let start = CFAbsoluteTimeGetCurrent()

        for _ in 0..<iterations {
            if shouldCancel() {
                break
            }

            for index in 0..<vectorCount {
                c[index] = integerSIMDOp(a[index], b[index])
            }

            a[0] = c[vectorCount - 1]
            b[0] = c[0]
            completedIterations += 1
        }

        let duration = CFAbsoluteTimeGetCurrent() - start

        return BenchmarkResult(
            kind: .simd,
            configuration: configuration,
            duration: duration,
            requestedIterations: iterations,
            completedIterations: completedIterations,
            checksum: checksum(c),
            wasCancelled: shouldCancel()
        )
    }

    private static func runFloatingSIMDThreshold<V>(
        _ vectorType: V.Type,
        iterations requestedIterations: Int,
        configuration: BenchmarkConfiguration,
        shouldCancel: () -> Bool
    ) -> BenchmarkResult where V: SIMD, V.Scalar: BinaryFloatingPoint {
        let iterations = max(requestedIterations, 1)
        let vectorCount = elementCount / V.scalarCount
        var a = makeFloatingSIMDInput(vectorType, scale: V.Scalar(0.1), vectorCount: vectorCount)
        var b = makeFloatingSIMDInput(vectorType, scale: V.Scalar(0.2), vectorCount: vectorCount)
        var c = [V](repeating: .zero, count: vectorCount)
        let one = V(repeating: 1)

        var completedIterations = 0
        let start = CFAbsoluteTimeGetCurrent()

        for _ in 0..<iterations {
            if shouldCancel() {
                break
            }

            for index in 0..<vectorCount {
                c[index] = floatingThresholdSIMDOp(a[index], b[index], one: one)
            }

            a[0] = c[vectorCount - 1]
            b[0] = c[0]
            completedIterations += 1
        }

        let duration = CFAbsoluteTimeGetCurrent() - start

        return BenchmarkResult(
            kind: .simd,
            configuration: configuration,
            duration: duration,
            requestedIterations: iterations,
            completedIterations: completedIterations,
            checksum: checksum(c),
            wasCancelled: shouldCancel()
        )
    }

    private static func runIntegerSIMDThreshold<V>(
        _ vectorType: V.Type,
        iterations requestedIterations: Int,
        configuration: BenchmarkConfiguration,
        shouldCancel: () -> Bool
    ) -> BenchmarkResult where V: SIMD, V.Scalar: FixedWidthInteger & SignedInteger {
        let iterations = max(requestedIterations, 1)
        let vectorCount = elementCount / V.scalarCount
        var a = makeIntegerSIMDInput(vectorType, step: 3, vectorCount: vectorCount)
        var b = makeIntegerSIMDInput(vectorType, step: 5, vectorCount: vectorCount)
        var c = [V](repeating: .zero, count: vectorCount)

        var completedIterations = 0
        let start = CFAbsoluteTimeGetCurrent()

        for _ in 0..<iterations {
            if shouldCancel() {
                break
            }

            for index in 0..<vectorCount {
                c[index] = integerThresholdSIMDOp(a[index], b[index])
            }

            a[0] = c[vectorCount - 1]
            b[0] = c[0]
            completedIterations += 1
        }

        let duration = CFAbsoluteTimeGetCurrent() - start

        return BenchmarkResult(
            kind: .simd,
            configuration: configuration,
            duration: duration,
            requestedIterations: iterations,
            completedIterations: completedIterations,
            checksum: checksum(c),
            wasCancelled: shouldCancel()
        )
    }

    private static func runFloatingSIMDBounds<V>(
        _ vectorType: V.Type,
        iterations requestedIterations: Int,
        configuration: BenchmarkConfiguration,
        shouldCancel: () -> Bool
    ) -> BenchmarkResult where V: SIMD, V.Scalar: BinaryFloatingPoint {
        let iterations = max(requestedIterations, 1)
        let vectorCount = elementCount / V.scalarCount
        var a = makeFloatingSIMDInput(vectorType, scale: V.Scalar(0.1), vectorCount: vectorCount)
        var b = makeFloatingSIMDInput(vectorType, scale: V.Scalar(0.2), vectorCount: vectorCount)
        var c = [V](repeating: .zero, count: vectorCount)
        let minimumMask = makeBoundsMinimumMask(vectorType)

        var completedIterations = 0
        let start = CFAbsoluteTimeGetCurrent()

        for _ in 0..<iterations {
            if shouldCancel() {
                break
            }

            for index in 0..<vectorCount {
                c[index] = boundsSIMDOp(a[index], b[index], minimumMask: minimumMask)
            }

            a[0] = c[vectorCount - 1]
            b[0] = c[0]
            completedIterations += 1
        }

        let duration = CFAbsoluteTimeGetCurrent() - start

        return BenchmarkResult(
            kind: .simd,
            configuration: configuration,
            duration: duration,
            requestedIterations: iterations,
            completedIterations: completedIterations,
            checksum: checksum(c),
            wasCancelled: shouldCancel()
        )
    }

    private static func runIntegerSIMDBounds<V>(
        _ vectorType: V.Type,
        iterations requestedIterations: Int,
        configuration: BenchmarkConfiguration,
        shouldCancel: () -> Bool
    ) -> BenchmarkResult where V: SIMD, V.Scalar: FixedWidthInteger & SignedInteger {
        let iterations = max(requestedIterations, 1)
        let vectorCount = elementCount / V.scalarCount
        var a = makeIntegerSIMDInput(vectorType, step: 3, vectorCount: vectorCount)
        var b = makeIntegerSIMDInput(vectorType, step: 5, vectorCount: vectorCount)
        var c = [V](repeating: .zero, count: vectorCount)
        let minimumMask = makeBoundsMinimumMask(vectorType)

        var completedIterations = 0
        let start = CFAbsoluteTimeGetCurrent()

        for _ in 0..<iterations {
            if shouldCancel() {
                break
            }

            for index in 0..<vectorCount {
                c[index] = boundsSIMDOp(a[index], b[index], minimumMask: minimumMask)
            }

            a[0] = c[vectorCount - 1]
            b[0] = c[0]
            completedIterations += 1
        }

        let duration = CFAbsoluteTimeGetCurrent() - start

        return BenchmarkResult(
            kind: .simd,
            configuration: configuration,
            duration: duration,
            requestedIterations: iterations,
            completedIterations: completedIterations,
            checksum: checksum(c),
            wasCancelled: shouldCancel()
        )
    }

    private static func runFloatingSIMDReduction<V>(
        _ vectorType: V.Type,
        iterations requestedIterations: Int,
        configuration: BenchmarkConfiguration,
        shouldCancel: () -> Bool
    ) -> BenchmarkResult where V: SIMD, V.Scalar: BinaryFloatingPoint {
        let iterations = max(requestedIterations, 1)
        let vectorCount = elementCount / V.scalarCount
        var a = makeFloatingSIMDInput(vectorType, scale: V.Scalar(0.1), vectorCount: vectorCount)
        var b = makeFloatingSIMDInput(vectorType, scale: V.Scalar(0.2), vectorCount: vectorCount)
        var c = [V](repeating: .zero, count: vectorCount)
        let one = V(repeating: 1)

        var completedIterations = 0
        let start = CFAbsoluteTimeGetCurrent()

        for _ in 0..<iterations {
            if shouldCancel() {
                break
            }

            var accumulator = V.zero

            for index in 0..<vectorCount {
                accumulator += floatingSIMDOp(a[index], b[index], one: one)
            }

            let total = horizontalSum(accumulator)
            c[0] = .zero
            c[0][0] = total
            a[0] = .zero
            a[0][0] = total / V.Scalar(elementCount)
            b[0] = .zero
            b[0][0] = (a[0][0] + 1).squareRoot()
            completedIterations += 1
        }

        let duration = CFAbsoluteTimeGetCurrent() - start

        return BenchmarkResult(
            kind: .simd,
            configuration: configuration,
            duration: duration,
            requestedIterations: iterations,
            completedIterations: completedIterations,
            checksum: checksum(c),
            wasCancelled: shouldCancel()
        )
    }

    private static func runIntegerSIMDReduction<V>(
        _ vectorType: V.Type,
        iterations requestedIterations: Int,
        configuration: BenchmarkConfiguration,
        shouldCancel: () -> Bool
    ) -> BenchmarkResult where V: SIMD, V.Scalar: FixedWidthInteger & SignedInteger {
        let iterations = max(requestedIterations, 1)
        let vectorCount = elementCount / V.scalarCount
        var a = makeIntegerSIMDInput(vectorType, step: 3, vectorCount: vectorCount)
        var b = makeIntegerSIMDInput(vectorType, step: 5, vectorCount: vectorCount)
        var c = [V](repeating: .zero, count: vectorCount)

        var completedIterations = 0
        let start = CFAbsoluteTimeGetCurrent()

        for _ in 0..<iterations {
            if shouldCancel() {
                break
            }

            var accumulator = V.zero

            for index in 0..<vectorCount {
                accumulator = accumulator &+ integerSIMDOp(a[index], b[index])
            }

            let total = horizontalWrappingSum(accumulator)
            c[0] = .zero
            c[0][0] = total
            a[0] = .zero
            a[0][0] = total
            b[0] = .zero
            b[0][0] = total &>> 3
            completedIterations += 1
        }

        let duration = CFAbsoluteTimeGetCurrent() - start

        return BenchmarkResult(
            kind: .simd,
            configuration: configuration,
            duration: duration,
            requestedIterations: iterations,
            completedIterations: completedIterations,
            checksum: checksum(c),
            wasCancelled: shouldCancel()
        )
    }

    private static func makeFloatingScalarInput<T>(_ type: T.Type, scale: T) -> [T] where T: BinaryFloatingPoint {
        (0..<elementCount).map { index in
            T(index) * scale
        }
    }

    private static func makeIntegerScalarInput<T>(_ type: T.Type, step: Int) -> [T] where T: FixedWidthInteger {
        (0..<elementCount).map { index in
            T(truncatingIfNeeded: index &* step)
        }
    }

    private static func makeFloatingSIMDInput<V>(
        _ vectorType: V.Type,
        scale: V.Scalar,
        vectorCount: Int
    ) -> [V] where V: SIMD, V.Scalar: BinaryFloatingPoint {
        (0..<vectorCount).map { vectorIndex in
            var vector = V()
            let base = vectorIndex * V.scalarCount

            for lane in 0..<V.scalarCount {
                vector[lane] = V.Scalar(base + lane) * scale
            }

            return vector
        }
    }

    private static func makeIntegerSIMDInput<V>(
        _ vectorType: V.Type,
        step: Int,
        vectorCount: Int
    ) -> [V] where V: SIMD, V.Scalar: FixedWidthInteger {
        (0..<vectorCount).map { vectorIndex in
            var vector = V()
            let base = vectorIndex * V.scalarCount

            for lane in 0..<V.scalarCount {
                vector[lane] = V.Scalar(truncatingIfNeeded: (base + lane) &* step)
            }

            return vector
        }
    }

    private static func boundsLaneUsesMinimum(_ index: Int) -> Bool {
        index & 3 < 2
    }

    private static func makeBoundsMinimumMask<V>(_ vectorType: V.Type) -> SIMDMask<V.MaskStorage> where V: SIMD, V.Scalar: Equatable & ExpressibleByIntegerLiteral {
        var pattern = V()

        for lane in 0..<V.scalarCount {
            pattern[lane] = boundsLaneUsesMinimum(lane) ? 0 : 1
        }

        return pattern .== V(repeating: 0)
    }

    private static func horizontalSum<V>(_ vector: V) -> V.Scalar where V: SIMD, V.Scalar: BinaryFloatingPoint {
        var total = V.Scalar.zero

        for lane in 0..<V.scalarCount {
            total += vector[lane]
        }

        return total
    }

    private static func horizontalWrappingSum<V>(_ vector: V) -> V.Scalar where V: SIMD, V.Scalar: FixedWidthInteger & SignedInteger {
        var total = V.Scalar.zero

        for lane in 0..<V.scalarCount {
            total = total &+ vector[lane]
        }

        return total
    }

    private static func checksum<T>(_ values: [T]) -> Double where T: BinaryFloatingPoint {
        values.reduce(0) { partialResult, value in
            partialResult + Double(value)
        }
    }

    private static func checksum<T>(_ values: [T]) -> Double where T: FixedWidthInteger & SignedInteger {
        values.reduce(0) { partialResult, value in
            partialResult + Double(value)
        }
    }

    private static func checksum<V>(_ values: [V]) -> Double where V: SIMD, V.Scalar: BinaryFloatingPoint {
        var total = 0.0

        for vector in values {
            for lane in 0..<V.scalarCount {
                total += Double(vector[lane])
            }
        }

        return total
    }

    private static func checksum<V>(_ values: [V]) -> Double where V: SIMD, V.Scalar: FixedWidthInteger & SignedInteger {
        var total = 0.0

        for vector in values {
            for lane in 0..<V.scalarCount {
                total += Double(vector[lane])
            }
        }

        return total
    }
}
