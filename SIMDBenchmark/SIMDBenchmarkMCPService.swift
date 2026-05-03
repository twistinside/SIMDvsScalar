import Foundation

final class SIMDBenchmarkMCPService: @unchecked Sendable {
    static let protocolVersion = "2025-06-18"

    private let supportedProtocolVersions = [
        "2025-06-18",
        "2025-03-26",
        "2024-11-05"
    ]
    private let encoderOptions: JSONSerialization.WritingOptions = [.sortedKeys]

    func handleLine(_ line: String) -> Data? {
        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedLine.isEmpty, let data = trimmedLine.data(using: .utf8) else {
            return nil
        }

        return handleMessageData(data)
    }

    func handleMessageData(_ data: Data) -> Data? {
        guard
            let jsonObject = try? JSONSerialization.jsonObject(with: data),
            let message = jsonObject as? [String: Any]
        else {
            return makeError(id: NSNull(), code: -32700, message: "Parse error")
        }

        guard let method = message["method"] as? String else {
            return makeError(id: message["id"] ?? NSNull(), code: -32600, message: "Invalid request")
        }

        let id = message["id"]

        do {
            switch method {
            case "initialize":
                guard let id else {
                    return nil
                }

                return makeResult(id: id, result: initializeResult(from: message["params"]))
            case "notifications/initialized":
                return nil
            case "ping":
                guard let id else {
                    return nil
                }

                return makeResult(id: id, result: [:])
            case "tools/list":
                guard let id else {
                    return nil
                }

                return makeResult(id: id, result: ["tools": tools])
            case "tools/call":
                guard let id else {
                    return nil
                }

                let result = try callTool(params: message["params"])
                return makeResult(id: id, result: result)
            default:
                guard let id else {
                    return nil
                }

                return makeError(id: id, code: -32601, message: "Method not found")
            }
        } catch let error as MCPError {
            return makeError(id: id ?? NSNull(), code: error.code, message: error.message, data: error.data)
        } catch {
            return makeError(id: id ?? NSNull(), code: -32603, message: error.localizedDescription)
        }
    }

    private func initializeResult(from params: Any?) -> [String: Any] {
        let requestedVersion = ((params as? [String: Any])?["protocolVersion"] as? String)
        let selectedVersion = requestedVersion.flatMap { version in
            supportedProtocolVersions.contains(version) ? version : nil
        } ?? Self.protocolVersion

        return [
            "protocolVersion": selectedVersion,
            "capabilities": [
                "tools": [
                    "listChanged": false
                ]
            ],
            "serverInfo": [
                "name": "simd-benchmark",
                "title": "SIMD Benchmark",
                "version": "1.0.0"
            ],
            "instructions": "Use the benchmark tools to run scalar, optimized scalar, or SIMD variants over several game-oriented algorithms and Float, Double, Int8, Int16, and Int32 data. Results are computed locally by the same benchmark engine used by the app."
        ]
    }

    private var tools: [[String: Any]] {
        [
            [
                "name": "run_benchmark",
                "title": "Run Benchmark",
                "description": "Run one benchmark variant for an algorithm and data type. Use variant scalar, optimized_scalar, simd2, simd3, simd4, simd8, simd16, simd32, or simd64. The result includes hardware and build-chain metadata.",
                "inputSchema": [
                    "type": "object",
                    "properties": [
                        "iterations": [
                            "type": "integer",
                            "minimum": 1,
                            "description": "Number of benchmark iterations to run."
                        ],
                        "algorithm": [
                            "type": "string",
                            "enum": BenchmarkAlgorithm.allCases.map(\.rawValue),
                            "description": "Algorithm to run. Defaults to arithmetic."
                        ],
                        "data_type": [
                            "type": "string",
                            "enum": BenchmarkDataType.allCases.map(\.rawValue),
                            "description": "Element data type."
                        ],
                        "variant": [
                            "type": "string",
                            "enum": BenchmarkVariant.schemaValues,
                            "description": "Implementation to run."
                        ],
                        "comparison_simd_width": [
                            "type": "string",
                            "enum": BenchmarkSIMDWidth.schemaValues,
                            "description": "Optional scalar feedback width when variant is scalar. Defaults to simd4."
                        ]
                    ],
                    "required": ["iterations", "data_type", "variant"],
                    "additionalProperties": false
                ]
            ],
            [
                "name": "run_comparison",
                "title": "Run Scalar/SIMD Comparison",
                "description": "Run scalar, optimized scalar, and a selected SIMD width for one algorithm and data type. The result includes hardware and build-chain metadata.",
                "inputSchema": [
                    "type": "object",
                    "properties": [
                        "iterations": [
                            "type": "integer",
                            "minimum": 1,
                            "description": "Number of benchmark iterations to run."
                        ],
                        "algorithm": [
                            "type": "string",
                            "enum": BenchmarkAlgorithm.allCases.map(\.rawValue),
                            "description": "Algorithm to run. Defaults to arithmetic."
                        ],
                        "data_type": [
                            "type": "string",
                            "enum": BenchmarkDataType.allCases.map(\.rawValue),
                            "description": "Element data type."
                        ],
                        "simd_width": [
                            "type": "string",
                            "enum": BenchmarkSIMDWidth.schemaValues,
                            "description": "SIMD width to compare against scalar."
                        ]
                    ],
                    "required": ["iterations", "data_type", "simd_width"],
                    "additionalProperties": false
                ]
            ],
            [
                "name": "run_all_benchmarks",
                "title": "Run All Benchmarks",
                "description": "Run every algorithm, data type, and SIMD width combination, including scalar, optimized scalar, and SIMD results for each row. The result includes hardware and build-chain metadata.",
                "inputSchema": [
                    "type": "object",
                    "properties": [
                        "iterations": [
                            "type": "integer",
                            "minimum": 1,
                            "description": "Number of benchmark iterations to run for each combination."
                        ],
                        "algorithm": [
                            "type": "string",
                            "enum": BenchmarkAlgorithm.allCases.map(\.rawValue),
                            "description": "Optional algorithm filter. If omitted, every algorithm is included."
                        ]
                    ],
                    "required": ["iterations"],
                    "additionalProperties": false
                ]
            ]
        ]
    }

    private func callTool(params: Any?) throws -> [String: Any] {
        guard
            let params = params as? [String: Any],
            let name = params["name"] as? String
        else {
            throw MCPError.invalidParams("tools/call requires a tool name.")
        }

        let arguments = params["arguments"] as? [String: Any] ?? [:]

        switch name {
        case "run_benchmark":
            return try toolResult(runBenchmark(arguments: arguments))
        case "run_comparison":
            return try toolResult(runComparison(arguments: arguments))
        case "run_all_benchmarks":
            return try toolResult(runAllBenchmarks(arguments: arguments))
        default:
            throw MCPError.invalidParams("Unknown tool '\(name)'.")
        }
    }

    private func runBenchmark(arguments: [String: Any]) throws -> [String: Any] {
        let iterations = try parseIterations(arguments["iterations"])
        let algorithm = try BenchmarkAlgorithm.parse(arguments["algorithm"], default: .arithmetic)
        let dataType = try BenchmarkDataType.parse(arguments["data_type"])
        let variant = try BenchmarkVariant.parse(arguments["variant"])
        let hardwareProfile = BenchmarkHardwareProfile.current
        let buildProfile = BenchmarkBuildProfile.current

        switch variant {
        case .scalar:
            let simdWidth = try BenchmarkSIMDWidth.parse(arguments["comparison_simd_width"], default: .simd4)
            let configuration = BenchmarkConfiguration(algorithm: algorithm, dataType: dataType, simdWidth: simdWidth)
            let result = BenchmarkEngine.runScalar(iterations: iterations, configuration: configuration)

            return [
                "tool": "run_benchmark",
                "iterations": iterations,
                "algorithm": algorithm.rawValue,
                "data_type": dataType.rawValue,
                "variant": "scalar",
                "comparison_simd_width": simdWidth.schemaValue,
                "hardware": hardwareProfile.mcpObject,
                "build": buildProfile.mcpObject,
                "result": result.mcpObject
            ]
        case .optimizedScalar:
            let simdWidth = try BenchmarkSIMDWidth.parse(arguments["comparison_simd_width"], default: .simd4)
            let configuration = BenchmarkConfiguration(algorithm: algorithm, dataType: dataType, simdWidth: simdWidth)
            let result = BenchmarkEngine.runOptimizedScalar(iterations: iterations, configuration: configuration)

            return [
                "tool": "run_benchmark",
                "iterations": iterations,
                "algorithm": algorithm.rawValue,
                "data_type": dataType.rawValue,
                "variant": "optimized_scalar",
                "comparison_simd_width": simdWidth.schemaValue,
                "hardware": hardwareProfile.mcpObject,
                "build": buildProfile.mcpObject,
                "result": result.mcpObject
            ]
        case .simd(let simdWidth):
            let configuration = BenchmarkConfiguration(algorithm: algorithm, dataType: dataType, simdWidth: simdWidth)
            let result = BenchmarkEngine.runSIMD(iterations: iterations, configuration: configuration)

            return [
                "tool": "run_benchmark",
                "iterations": iterations,
                "algorithm": algorithm.rawValue,
                "data_type": dataType.rawValue,
                "variant": simdWidth.schemaValue,
                "hardware": hardwareProfile.mcpObject,
                "build": buildProfile.mcpObject,
                "result": result.mcpObject
            ]
        }
    }

    private func runComparison(arguments: [String: Any]) throws -> [String: Any] {
        let iterations = try parseIterations(arguments["iterations"])
        let algorithm = try BenchmarkAlgorithm.parse(arguments["algorithm"], default: .arithmetic)
        let dataType = try BenchmarkDataType.parse(arguments["data_type"])
        let simdWidth = try BenchmarkSIMDWidth.parse(arguments["simd_width"])
        let matrixResult = runMatrixRow(iterations: iterations, algorithm: algorithm, dataType: dataType, simdWidth: simdWidth)

        return comparisonObject(
            tool: "run_comparison",
            iterations: iterations,
            matrixResult: matrixResult,
            includeRuntimeContext: true
        )
    }

    private func runAllBenchmarks(arguments: [String: Any]) throws -> [String: Any] {
        let iterations = try parseIterations(arguments["iterations"])
        let algorithms = try parseAlgorithmFilter(arguments["algorithm"])
        let hardwareProfile = BenchmarkHardwareProfile.current
        let buildProfile = BenchmarkBuildProfile.current
        let matrixResults = algorithms.flatMap { algorithm in
            BenchmarkDataType.allCases.flatMap { dataType in
                BenchmarkSIMDWidth.allCases.map { simdWidth in
                    runMatrixRow(iterations: iterations, algorithm: algorithm, dataType: dataType, simdWidth: simdWidth)
                }
            }
        }

        return [
            "tool": "run_all_benchmarks",
            "iterations": iterations,
            "element_count": BenchmarkEngine.elementCount,
            "hardware": hardwareProfile.mcpObject,
            "build": buildProfile.mcpObject,
            "row_count": matrixResults.count,
            "results": matrixResults.map { comparisonObject(tool: nil, iterations: iterations, matrixResult: $0) },
            "csv": matrixCSV(results: matrixResults, hardwareProfile: hardwareProfile, buildProfile: buildProfile)
        ]
    }

    private func runMatrixRow(
        iterations: Int,
        algorithm: BenchmarkAlgorithm,
        dataType: BenchmarkDataType,
        simdWidth: BenchmarkSIMDWidth
    ) -> BenchmarkMatrixResult {
        let configuration = BenchmarkConfiguration(algorithm: algorithm, dataType: dataType, simdWidth: simdWidth)
        let scalarResult = BenchmarkEngine.runScalar(iterations: iterations, configuration: configuration)
        let optimizedScalarResult = BenchmarkEngine.runOptimizedScalar(iterations: iterations, configuration: configuration)
        let simdResult = BenchmarkEngine.runSIMD(iterations: iterations, configuration: configuration)

        return BenchmarkMatrixResult(
            configuration: configuration,
            scalarResult: scalarResult,
            optimizedScalarResult: optimizedScalarResult,
            simdResult: simdResult
        )
    }

    private func comparisonObject(
        tool: String?,
        iterations: Int,
        matrixResult: BenchmarkMatrixResult,
        includeRuntimeContext: Bool = false
    ) -> [String: Any] {
        var object: [String: Any] = [
            "iterations": iterations,
            "algorithm": matrixResult.configuration.algorithm.rawValue,
            "algorithm_title": matrixResult.configuration.algorithm.title,
            "data_type": matrixResult.configuration.dataType.rawValue,
            "data_type_title": matrixResult.configuration.dataType.title,
            "simd_width": matrixResult.configuration.simdWidth.schemaValue,
            "simd_title": matrixResult.configuration.simdWidth.title,
            "element_count": BenchmarkEngine.elementCount,
            "scalar": matrixResult.scalarResult.mcpObject,
            "optimized_scalar": matrixResult.optimizedScalarResult.mcpObject,
            "simd": matrixResult.simdResult.mcpObject,
            "simd_vs_scalar_speedup": matrixResult.speedup,
            "optimized_scalar_vs_scalar_speedup": matrixResult.optimizedScalarSpeedup,
            "simd_vs_optimized_scalar_speedup": matrixResult.simdVsOptimizedScalarSpeedup,
            "simd_checksum_delta": matrixResult.checksumDelta,
            "optimized_scalar_checksum_delta": matrixResult.optimizedScalarChecksumDelta
        ]

        if let tool {
            object["tool"] = tool
        }

        if includeRuntimeContext {
            object["hardware"] = BenchmarkHardwareProfile.current.mcpObject
            object["build"] = BenchmarkBuildProfile.current.mcpObject
        }

        return object
    }

    private func matrixCSV(
        results: [BenchmarkMatrixResult],
        hardwareProfile: BenchmarkHardwareProfile,
        buildProfile: BenchmarkBuildProfile
    ) -> String {
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

        return ([header] + results.map { hardwareProfile.csvFields + buildProfile.csvFields + $0.csvFields })
            .map { fields in
                fields.map(escapeCSVField).joined(separator: ",")
            }
            .joined(separator: "\n")
    }

    private func toolResult(_ object: [String: Any]) throws -> [String: Any] {
        let textData = try JSONSerialization.data(
            withJSONObject: object,
            options: [.prettyPrinted, .sortedKeys]
        )
        let text = String(data: textData, encoding: .utf8) ?? "{}"

        return [
            "content": [
                [
                    "type": "text",
                    "text": text
                ]
            ],
            "structuredContent": object,
            "isError": false
        ]
    }

    private func parseIterations(_ value: Any?) throws -> Int {
        if let value = value as? Int {
            return max(value, 1)
        }

        if let value = value as? NSNumber {
            return max(value.intValue, 1)
        }

        if let value = value as? String, let iterations = Int(value) {
            return max(iterations, 1)
        }

        throw MCPError.invalidParams("iterations must be a positive integer.")
    }

    private func parseAlgorithmFilter(_ value: Any?) throws -> [BenchmarkAlgorithm] {
        guard let value else {
            return BenchmarkAlgorithm.allCases
        }

        return [try BenchmarkAlgorithm.parse(value)]
    }

    private func escapeCSVField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
        } else {
            field
        }
    }

    private func makeResult(id: Any, result: [String: Any]) -> Data? {
        makeJSONObject([
            "jsonrpc": "2.0",
            "id": id,
            "result": result
        ])
    }

    private func makeError(id: Any, code: Int, message: String, data: Any? = nil) -> Data? {
        var error: [String: Any] = [
            "code": code,
            "message": message
        ]

        if let data {
            error["data"] = data
        }

        return makeJSONObject([
            "jsonrpc": "2.0",
            "id": id,
            "error": error
        ])
    }

    private func makeJSONObject(_ object: [String: Any]) -> Data? {
        guard JSONSerialization.isValidJSONObject(object) else {
            return nil
        }

        return try? JSONSerialization.data(withJSONObject: object, options: encoderOptions)
    }
}

private enum BenchmarkVariant {
    case scalar
    case optimizedScalar
    case simd(BenchmarkSIMDWidth)

    static var schemaValues: [String] {
        ["scalar", "optimized_scalar"] + BenchmarkSIMDWidth.schemaValues
    }

    static func parse(_ value: Any?) throws -> BenchmarkVariant {
        guard let rawValue = value as? String else {
            throw MCPError.invalidParams("variant must be one of: \(schemaValues.joined(separator: ", ")).")
        }

        let normalized = rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if normalized == "scalar" {
            return .scalar
        }

        if normalized == "optimized_scalar" || normalized == "optimized-scalar" || normalized == "optimizedscalar" {
            return .optimizedScalar
        }

        return .simd(try BenchmarkSIMDWidth.parse(normalized))
    }
}

private extension BenchmarkAlgorithm {
    static func parse(_ value: Any?, default defaultValue: BenchmarkAlgorithm? = nil) throws -> BenchmarkAlgorithm {
        guard let value else {
            if let defaultValue {
                return defaultValue
            }

            throw MCPError.invalidParams("algorithm must be one of: \(allCases.map(\.rawValue).joined(separator: ", ")).")
        }

        guard let rawValue = value as? String else {
            throw MCPError.invalidParams("algorithm must be one of: \(allCases.map(\.rawValue).joined(separator: ", ")).")
        }

        let normalized = rawValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: " ", with: "_")

        if let algorithm = allCases.first(where: { $0.rawValue.lowercased() == normalized }) {
            return algorithm
        }

        if let algorithm = allCases.first(where: { $0.title.lowercased().replacingOccurrences(of: " ", with: "_") == normalized }) {
            return algorithm
        }

        throw MCPError.invalidParams("Unsupported algorithm '\(rawValue)'.")
    }
}

private extension BenchmarkDataType {
    static func parse(_ value: Any?) throws -> BenchmarkDataType {
        guard let rawValue = value as? String else {
            throw MCPError.invalidParams("data_type must be one of: \(allCases.map(\.rawValue).joined(separator: ", ")).")
        }

        let normalized = rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if let dataType = BenchmarkDataType(rawValue: normalized) {
            return dataType
        }

        if let dataType = allCases.first(where: { $0.title.lowercased() == normalized }) {
            return dataType
        }

        throw MCPError.invalidParams("Unsupported data_type '\(rawValue)'.")
    }
}

extension BenchmarkSIMDWidth {
    static var schemaValues: [String] {
        allCases.map(\.schemaValue)
    }

    var schemaValue: String {
        "simd\(rawValue)"
    }

    static func parse(_ value: Any?, default defaultValue: BenchmarkSIMDWidth? = nil) throws -> BenchmarkSIMDWidth {
        guard let value else {
            if let defaultValue {
                return defaultValue
            }

            throw MCPError.invalidParams("simd_width must be one of: \(schemaValues.joined(separator: ", ")).")
        }

        if let width = value as? Int {
            if let simdWidth = BenchmarkSIMDWidth(rawValue: width) {
                return simdWidth
            }

            throw MCPError.invalidParams("Unsupported simd_width '\(width)'.")
        }

        if let width = value as? NSNumber {
            if let simdWidth = BenchmarkSIMDWidth(rawValue: width.intValue) {
                return simdWidth
            }

            throw MCPError.invalidParams("Unsupported simd_width '\(width)'.")
        }

        guard let rawValue = value as? String else {
            throw MCPError.invalidParams("simd_width must be one of: \(schemaValues.joined(separator: ", ")).")
        }

        let normalized = rawValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "simd", with: "")

        guard let width = Int(normalized), let simdWidth = BenchmarkSIMDWidth(rawValue: width) else {
            throw MCPError.invalidParams("Unsupported simd_width '\(rawValue)'.")
        }

        return simdWidth
    }
}

private extension BenchmarkResult {
    var mcpObject: [String: Any] {
        [
            "kind": kind.rawValue,
            "label": label,
            "algorithm": configuration.algorithm.rawValue,
            "algorithm_title": configuration.algorithm.title,
            "data_type": configuration.dataType.rawValue,
            "data_type_title": configuration.dataType.title,
            "simd_width": configuration.simdWidth.schemaValue,
            "simd_title": configuration.simdWidth.title,
            "element_count": BenchmarkEngine.elementCount,
            "requested_iterations": requestedIterations,
            "completed_iterations": completedIterations,
            "duration_seconds": duration,
            "seconds_per_iteration": perIteration,
            "processed_elements": processedElements,
            "elements_per_second": elementsPerSecond,
            "checksum": checksum,
            "was_cancelled": wasCancelled
        ]
    }
}

private extension BenchmarkHardwareProfile {
    var mcpObject: [String: Any] {
        [
            "chip_name": chipName,
            "model_identifier": modelIdentifier,
            "architecture": architecture,
            "os_version": osVersion,
            "word_bits": wordBits,
            "pointer_bits": pointerBits,
            "general_purpose_register_count": optional(generalPurposeRegisterCount),
            "general_purpose_register_bits": optional(generalPurposeRegisterBits),
            "simd_register_count": optional(simdRegisterCount),
            "simd_register_bits": optional(simdRegisterBits),
            "simd_instruction_set": simdInstructionSet,
            "physical_cpu_count": optional(physicalCPUCount),
            "logical_cpu_count": optional(logicalCPUCount),
            "memory_bytes": optional(memoryBytes),
            "cache_line_bytes": optional(cacheLineBytes),
            "l1_data_cache_bytes": optional(l1DataCacheBytes),
            "l1_instruction_cache_bytes": optional(l1InstructionCacheBytes),
            "l2_cache_bytes": optional(l2CacheBytes),
            "l3_cache_bytes": optional(l3CacheBytes)
        ]
    }

    private func optional(_ value: Int?) -> Any {
        value.map { $0 as Any } ?? NSNull()
    }
}

private extension BenchmarkBuildProfile {
    var mcpObject: [String: Any] {
        [
            "build_configuration": buildConfiguration,
            "optimization_profile": optimizationProfile,
            "compiled_architecture": compiledArchitecture,
            "swift_compiler_version": swiftCompilerVersion,
            "xcode_version": xcodeVersion,
            "developer_directory": developerDirectory,
            "macos_sdk_version": macOSSDKVersion,
            "macos_sdk_path": macOSSDKPath
        ]
    }
}

private struct MCPError: Error {
    let code: Int
    let message: String
    let data: String?

    static func invalidParams(_ message: String, data: String? = nil) -> MCPError {
        MCPError(code: -32602, message: message, data: data)
    }
}
