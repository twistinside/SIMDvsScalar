import AppKit
import SwiftUI

struct ContentView: View {
    @State private var model = BenchmarkViewModel()
    @State private var isHardwareExpanded = false
    @State private var isBuildExpanded = false
    let mcpServerController: SIMDBenchmarkMCPServerController

    var body: some View {
        @Bindable var model = model
        @Bindable var mcpServerController = mcpServerController

        VStack(alignment: .leading, spacing: 12) {
            HeaderBar(
                title: "SIMD Benchmark",
                subtitle: model.configuration.comparisonTitle,
                chipName: model.hardwareProfile.chipName,
                mcpServerController: mcpServerController
            )

            BenchmarkControls(
                algorithm: $model.algorithm,
                dataType: $model.dataType,
                simdWidth: $model.simdWidth,
                iterationCount: $model.iterationCount,
                isRunning: model.isRunning
            )

            RunToolbar(
                canRun: model.canRun,
                isRunning: model.isRunning,
                isStopping: model.isStopping,
                runScalar: { model.run(.scalar) },
                runOptimizedScalar: { model.run(.optimizedScalar) },
                runSIMD: { model.run(.simd) },
                runSet: { model.runBoth() },
                runAll: { model.runAllCombinations() },
                stop: { model.stop() }
            )

            if model.isRunning {
                RunStatusView(
                    isStopping: model.isStopping,
                    status: model.isMatrixRunning ? model.matrixStatus : "Running",
                    progress: model.matrixProgress,
                    total: model.matrixTotal,
                    isMatrixRunning: model.isMatrixRunning
                )
            }

            ResultsPanel(
                results: model.results,
                speedup: model.speedup,
                optimizedScalarSpeedup: model.optimizedScalarSpeedup,
                simdVsOptimizedScalarSpeedup: model.simdVsOptimizedScalarSpeedup
            )

            MatrixResultsPanel(
                results: model.matrixResults,
                progress: model.matrixProgress,
                total: model.matrixTotal,
                status: model.matrixStatus,
                isRunning: model.isMatrixRunning,
                didCopyCSV: model.didCopyCSV
            ) {
                copyToPasteboard(model.matrixCSV)
                model.markCSVWasCopied()
            }

            HardwareProfilePanel(
                profile: model.hardwareProfile,
                isExpanded: $isHardwareExpanded
            )

            BuildProfilePanel(
                buildProfile: model.buildProfile,
                isExpanded: $isBuildExpanded
            )
        }
        .padding(18)
        .frame(minWidth: 900, idealWidth: 980)
        .background(Color(nsColor: .windowBackgroundColor))
        .onChange(of: model.iterationCount) {
            model.clampIterations()
        }
    }

    private func copyToPasteboard(_ value: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
    }
}

private struct HeaderBar: View {
    let title: String
    let subtitle: String
    let chipName: String
    @Bindable var mcpServerController: SIMDBenchmarkMCPServerController

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Text(title)
                .font(.title2.weight(.semibold))

            Text(subtitle)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer()

            MCPServerControl(controller: mcpServerController)

            Label(chipName, systemImage: "cpu")
                .labelStyle(.titleAndIcon)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}

private struct MCPServerControl: View {
    @Bindable var controller: SIMDBenchmarkMCPServerController

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Toggle("MCP Server", isOn: $controller.isEnabled)
                .toggleStyle(.switch)
                .help("Expose the local MCP benchmark endpoint on 127.0.0.1.")

            Text(controller.statusText)
                .font(.caption)
                .foregroundStyle(statusStyle)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: 190, alignment: .leading)
                .help(controller.errorMessage ?? controller.statusText)
        }
        .controlSize(.small)
    }

    private var statusStyle: AnyShapeStyle {
        controller.errorMessage == nil ? AnyShapeStyle(.secondary) : AnyShapeStyle(.red)
    }
}

private struct BenchmarkControls: View {
    @Binding var algorithm: BenchmarkAlgorithm
    @Binding var dataType: BenchmarkDataType
    @Binding var simdWidth: BenchmarkSIMDWidth
    @Binding var iterationCount: Int
    let isRunning: Bool

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 14) {
            LabeledContent("Algorithm") {
                Picker("Algorithm", selection: $algorithm) {
                    ForEach(BenchmarkAlgorithm.allCases) { algorithm in
                        Text(algorithm.title)
                            .tag(algorithm)
                    }
                }
                .labelsHidden()
                .frame(width: 166)
            }

            LabeledContent("Data") {
                Picker("Data Type", selection: $dataType) {
                    ForEach(BenchmarkDataType.allCases) { dataType in
                        Text(dataType.title)
                            .tag(dataType)
                    }
                }
                .labelsHidden()
                .frame(width: 130)
            }

            LabeledContent("SIMD") {
                Picker("SIMD Type", selection: $simdWidth) {
                    ForEach(BenchmarkSIMDWidth.allCases) { simdWidth in
                        Text(simdWidth.title)
                            .tag(simdWidth)
                    }
                }
                .labelsHidden()
                .frame(width: 126)
            }

            LabeledContent("Iterations") {
                TextField("Iterations", value: $iterationCount, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .monospacedDigit()
                    .frame(width: 112)
            }

            LabeledContent("Elements") {
                Text(BenchmarkEngine.elementCount, format: .number)
                    .monospacedDigit()
                    .frame(minWidth: 74, alignment: .leading)
            }
        }
        .disabled(isRunning)
        .controlSize(.small)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct RunToolbar: View {
    let canRun: Bool
    let isRunning: Bool
    let isStopping: Bool
    let runScalar: () -> Void
    let runOptimizedScalar: () -> Void
    let runSIMD: () -> Void
    let runSet: () -> Void
    let runAll: () -> Void
    let stop: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button("Scalar", systemImage: "function", action: runScalar)
                .disabled(!canRun)
            Button("Opt Scalar", systemImage: "gauge", action: runOptimizedScalar)
                .disabled(!canRun)
            Button("SIMD", systemImage: "cpu", action: runSIMD)
                .disabled(!canRun)

            Divider()
                .frame(height: 18)

            Button("Run Set", systemImage: "play.fill", action: runSet)
                .buttonStyle(.borderedProminent)
                .disabled(!canRun)

            Button("Run All", systemImage: "tablecells", action: runAll)
                .disabled(!canRun)

            if isRunning {
                Button(isStopping ? "Stopping" : "Stop", systemImage: "stop.fill", action: stop)
                    .disabled(isStopping)
                    .tint(.red)
            }
        }
        .controlSize(.small)
    }
}

private struct RunStatusView: View {
    let isStopping: Bool
    let status: String
    let progress: Int
    let total: Int
    let isMatrixRunning: Bool

    var body: some View {
        HStack(spacing: 10) {
            ProgressView()
                .controlSize(.small)

            Text(isStopping ? "Stopping" : status)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            if isMatrixRunning && total > 0 {
                ProgressView(value: Double(progress), total: Double(total))
                    .frame(maxWidth: 220)

                Text("\(progress) / \(total)")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .controlSize(.small)
    }
}

private struct ResultsPanel: View {
    let results: [BenchmarkResult]
    let speedup: Double?
    let optimizedScalarSpeedup: Double?
    let simdVsOptimizedScalarSpeedup: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Selected Results", systemImage: "chart.bar.xaxis")

            if results.isEmpty {
                EmptyStateText("Run a selected benchmark to compare scalar, optimized scalar, and SIMD timings.")
            } else {
                VStack(spacing: 0) {
                    ResultHeaderRow()

                    ForEach(results) { result in
                        Divider()
                        CompactResultRow(result: result)
                    }
                }
                .padding(.vertical, 6)
                .background(.quaternary.opacity(0.35), in: .rect(cornerRadius: 8))
            }

            if speedup != nil || optimizedScalarSpeedup != nil || simdVsOptimizedScalarSpeedup != nil {
                HStack(spacing: 8) {
                    if let speedup {
                        SpeedupPill(label: "SIMD / Scalar", speedup: speedup)
                    }

                    if let optimizedScalarSpeedup {
                        SpeedupPill(label: "Opt / Scalar", speedup: optimizedScalarSpeedup)
                    }

                    if let simdVsOptimizedScalarSpeedup {
                        SpeedupPill(label: "SIMD / Opt", speedup: simdVsOptimizedScalarSpeedup)
                    }
                }
            }
        }
    }
}

private struct MatrixResultsPanel: View {
    let results: [BenchmarkMatrixResult]
    let progress: Int
    let total: Int
    let status: String
    let isRunning: Bool
    let didCopyCSV: Bool
    let copyCSV: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                SectionHeader(title: "All Combinations", systemImage: "tablecells")

                Spacer()

                if total > 0 {
                    Text("\(progress) / \(total)")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                Button(didCopyCSV ? "Copied" : "Copy CSV", systemImage: "doc.on.doc", action: copyCSV)
                    .disabled(results.isEmpty)
                    .controlSize(.small)
            }

            if isRunning && total > 0 {
                ProgressView(value: Double(progress), total: Double(total))
                    .controlSize(.small)
            }

            if results.isEmpty {
                EmptyStateText("Run all combinations to collect the full matrix.")
            } else {
                HStack(spacing: 8) {
                    MetricPill(label: "Rows", value: results.count.formatted(.number))
                    MetricPill(label: "Fastest", value: formatSpeedup(results.map(\.speedup).max() ?? 0))
                    MetricPill(label: "Slowest", value: formatSpeedup(results.map(\.speedup).min() ?? 0))
                    MetricPill(label: "Opt best", value: formatSpeedup(results.map(\.optimizedScalarSpeedup).max() ?? 0))

                    if !status.isEmpty {
                        Text(status)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary.opacity(0.35), in: .rect(cornerRadius: 8))
            }
        }
    }

    private func formatSpeedup(_ value: Double) -> String {
        "\(value.formatted(.number.precision(.fractionLength(2))))x"
    }
}

private struct HardwareProfilePanel: View {
    let profile: BenchmarkHardwareProfile
    @Binding var isExpanded: Bool

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 5) {
                HardwareMetricRow(
                    firstLabel: "Model",
                    firstValue: profile.modelIdentifier,
                    secondLabel: "OS",
                    secondValue: profile.osVersion
                )

                HardwareMetricRow(
                    firstLabel: "Arch",
                    firstValue: profile.architecture,
                    secondLabel: "Word / Ptr",
                    secondValue: "\(profile.wordBits) / \(profile.pointerBits)-bit"
                )

                HardwareMetricRow(
                    firstLabel: "SIMD regs",
                    firstValue: formatRegisterCount(profile.simdRegisterCount, profile.simdRegisterBits),
                    secondLabel: "GPRs",
                    secondValue: formatRegisterCount(profile.generalPurposeRegisterCount, profile.generalPurposeRegisterBits)
                )

                HardwareMetricRow(
                    firstLabel: "SIMD ISA",
                    firstValue: profile.simdInstructionSet,
                    secondLabel: "CPU cores",
                    secondValue: formatCPUCount(profile.physicalCPUCount, profile.logicalCPUCount)
                )

                HardwareMetricRow(
                    firstLabel: "Memory",
                    firstValue: formatBytes(profile.memoryBytes),
                    secondLabel: "Cache line",
                    secondValue: formatBytes(profile.cacheLineBytes)
                )

                HardwareMetricRow(
                    firstLabel: "L1D / L1I",
                    firstValue: "\(formatBytes(profile.l1DataCacheBytes)) / \(formatBytes(profile.l1InstructionCacheBytes))",
                    secondLabel: "L2 / L3",
                    secondValue: "\(formatBytes(profile.l2CacheBytes)) / \(formatBytes(profile.l3CacheBytes))"
                )
            }
            .padding(.top, 8)
        } label: {
            HStack(spacing: 8) {
                Label("Hardware", systemImage: "cpu")
                    .fontWeight(.semibold)

                Text(profile.chipName)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(10)
        .background(.quaternary.opacity(0.35), in: .rect(cornerRadius: 8))
    }

    private func formatRegisterCount(_ count: Int?, _ bits: Int?) -> String {
        guard let count, let bits else {
            return "Unknown"
        }

        return "\(count) x \(bits)-bit"
    }

    private func formatCPUCount(_ physical: Int?, _ logical: Int?) -> String {
        switch (physical, logical) {
        case let (physical?, logical?):
            "\(physical) / \(logical)"
        case let (physical?, nil):
            "\(physical)"
        case let (nil, logical?):
            "\(logical)"
        case (nil, nil):
            "Unknown"
        }
    }

    private func formatBytes(_ bytes: Int?) -> String {
        guard let bytes else {
            return "Unknown"
        }

        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .memory)
    }
}

private struct BuildProfilePanel: View {
    let buildProfile: BenchmarkBuildProfile
    @Binding var isExpanded: Bool

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 5) {
                HardwareMetricRow(
                    firstLabel: "Build",
                    firstValue: buildProfile.buildConfiguration,
                    secondLabel: "Opt",
                    secondValue: buildProfile.optimizationProfile
                )

                HardwareMetricRow(
                    firstLabel: "Arch",
                    firstValue: buildProfile.compiledArchitecture,
                    secondLabel: "SDK",
                    secondValue: buildProfile.macOSSDKVersion
                )

                HardwareMetricRow(
                    firstLabel: "Compiler",
                    firstValue: firstLine(buildProfile.swiftCompilerVersion),
                    secondLabel: "Xcode",
                    secondValue: firstLine(buildProfile.xcodeVersion)
                )

                HardwareMetricRow(
                    firstLabel: "Dev dir",
                    firstValue: buildProfile.developerDirectory,
                    secondLabel: "SDK path",
                    secondValue: buildProfile.macOSSDKPath
                )
            }
            .padding(.top, 8)
        } label: {
            HStack(spacing: 8) {
                Label("Build", systemImage: "hammer")
                    .fontWeight(.semibold)

                Text(buildProfile.optimizationProfile)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(10)
        .background(.quaternary.opacity(0.35), in: .rect(cornerRadius: 8))
    }

    private func firstLine(_ value: String) -> String {
        value.components(separatedBy: .newlines).first ?? value
    }
}

private struct SectionHeader: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.headline)
    }
}

private struct EmptyStateText: View {
    let value: String

    init(_ value: String) {
        self.value = value
    }

    var body: some View {
        Text(value)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(.quaternary.opacity(0.25), in: .rect(cornerRadius: 8))
    }
}

private struct ResultHeaderRow: View {
    var body: some View {
        HStack(spacing: 12) {
            TableHeader("Variant", width: 168, alignment: .leading)
            TableHeader("Total", width: 78, alignment: .trailing)
            TableHeader("Iteration", width: 86, alignment: .trailing)
            TableHeader("Throughput", width: 104, alignment: .trailing)
            TableHeader("Checksum", width: 82, alignment: .trailing)
            TableHeader("Done", width: 86, alignment: .trailing)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 3)
    }
}

private struct CompactResultRow: View {
    let result: BenchmarkResult

    var body: some View {
        HStack(spacing: 12) {
            Label(result.label, systemImage: iconName)
                .fontWeight(.semibold)
                .lineLimit(1)
                .frame(width: 168, alignment: .leading)

            MetricText(formatTime(result.duration), width: 78)
            MetricText(formatTime(result.perIteration), width: 86)
            MetricText("\(formatCount(result.elementsPerSecond))/s", width: 104)
            MetricText(result.checksum.formatted(.number.precision(.fractionLength(3))), width: 82)

            HStack(spacing: 4) {
                Text(result.completedIterations.formatted(.number))
                    .monospacedDigit()

                if result.wasCancelled {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
            }
            .frame(width: 86, alignment: .trailing)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
    }

    private var iconName: String {
        switch result.kind {
        case .scalar:
            "function"
        case .optimizedScalar:
            "gauge"
        case .simd:
            "cpu"
        }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        if seconds < 0.001 {
            "\(formatNumber(seconds * 1_000_000)) us"
        } else if seconds < 1 {
            "\(formatNumber(seconds * 1_000)) ms"
        } else {
            "\(seconds.formatted(.number.precision(.fractionLength(3)))) s"
        }
    }

    private func formatNumber(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(2)))
    }

    private func formatCount(_ value: Double) -> String {
        value.formatted(.number.notation(.compactName).precision(.fractionLength(2)))
    }
}

private struct HardwareMetricRow: View {
    let firstLabel: String
    let firstValue: String
    let secondLabel: String
    let secondValue: String

    var body: some View {
        GridRow {
            Text(firstLabel)
                .foregroundStyle(.secondary)

            Text(firstValue)
                .lineLimit(1)

            Text(secondLabel)
                .foregroundStyle(.secondary)

            Text(secondValue)
                .lineLimit(1)
        }
    }
}

private struct SpeedupPill: View {
    let label: String
    let speedup: Double

    var body: some View {
        MetricPill(
            label: label,
            value: "\(speedup.formatted(.number.precision(.fractionLength(2))))x",
            valueStyle: speedup > 1 ? .green : .orange
        )
    }
}

private struct MetricPill: View {
    let label: String
    let value: String
    var valueStyle: Color = .primary

    var body: some View {
        HStack(spacing: 6) {
            Text(label)
                .foregroundStyle(.secondary)

            Text(value)
                .foregroundStyle(valueStyle)
                .monospacedDigit()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.quaternary.opacity(0.35), in: .capsule)
    }
}

private struct TableHeader: View {
    let label: String
    let width: CGFloat
    let alignment: Alignment

    init(_ label: String, width: CGFloat, alignment: Alignment) {
        self.label = label
        self.width = width
        self.alignment = alignment
    }

    var body: some View {
        Text(label)
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
            .frame(width: width, alignment: alignment)
    }
}

private struct MetricText: View {
    let value: String
    let width: CGFloat

    init(_ value: String, width: CGFloat) {
        self.value = value
        self.width = width
    }

    var body: some View {
        Text(value)
            .monospacedDigit()
            .lineLimit(1)
            .frame(width: width, alignment: .trailing)
    }
}

#Preview {
    ContentView(
        mcpServerController: SIMDBenchmarkMCPServerController(startPersistedServer: false)
    )
}
