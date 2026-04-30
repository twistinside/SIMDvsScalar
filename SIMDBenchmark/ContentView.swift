import SwiftUI

struct ContentView: View {
    @State private var model = BenchmarkViewModel()

    var body: some View {
        @Bindable var model = model

        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("SIMD Benchmark")
                    .font(.title2.weight(.semibold))

                Text("Scalar Float vs SIMD4<Float>")
                    .foregroundStyle(.secondary)
            }

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                GridRow {
                    Text("Iterations")
                        .foregroundStyle(.secondary)

                    TextField("Iterations", value: $model.iterationCount, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .monospacedDigit()
                        .frame(width: 140)
                        .onSubmit {
                            model.clampIterations()
                        }
                }

                GridRow {
                    Text("Elements")
                        .foregroundStyle(.secondary)

                    Text(BenchmarkEngine.elementCount, format: .number)
                        .monospacedDigit()
                }
            }

            HStack(spacing: 10) {
                Button("Run Scalar", systemImage: "function") {
                    model.run(.scalar)
                }
                .disabled(!model.canRun)

                Button("Run SIMD", systemImage: "cpu") {
                    model.run(.simd)
                }
                .disabled(!model.canRun)

                Button("Run Both", systemImage: "play.fill") {
                    model.runBoth()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!model.canRun)

                if model.isRunning {
                    Button(model.isStopping ? "Stopping" : "Stop", systemImage: "stop.fill") {
                        model.stop()
                    }
                    .disabled(model.isStopping)
                    .tint(.red)
                }
            }

            if model.isRunning {
                ProgressView {
                    Text(model.isStopping ? "Stopping" : "Running")
                }
            }

            ResultsPanel(results: model.results, speedup: model.speedup)
        }
        .padding(24)
        .frame(minWidth: 560, idealWidth: 620)
        .onChange(of: model.iterationCount) {
            model.clampIterations()
        }
    }
}

private struct ResultsPanel: View {
    let results: [BenchmarkResult]
    let speedup: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if results.isEmpty {
                Text("No results yet")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
            } else {
                ForEach(results) { result in
                    ResultRow(result: result)

                    if result.id != results.last?.id {
                        Divider()
                    }
                }
            }

            if let speedup {
                Divider()

                HStack {
                    Label("Speedup", systemImage: "bolt.fill")
                        .fontWeight(.semibold)

                    Spacer()

                    Text("\(speedup.formatted(.number.precision(.fractionLength(2))))x")
                        .font(.title3.monospacedDigit())
                        .foregroundStyle(speedup > 1 ? .green : .orange)
                }
                .padding(.vertical, 12)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.quaternary.opacity(0.35), in: .rect(cornerRadius: 8))
    }
}

private struct ResultRow: View {
    let result: BenchmarkResult

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(result.label, systemImage: result.kind == .simd ? "cpu" : "function")
                    .fontWeight(.semibold)

                Spacer()

                if result.wasCancelled {
                    Text("Cancelled")
                        .foregroundStyle(.orange)
                }
            }

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 6) {
                MetricRow(
                    firstLabel: "Total",
                    firstValue: formatTime(result.duration),
                    secondLabel: "Per iteration",
                    secondValue: formatTime(result.perIteration)
                )

                MetricRow(
                    firstLabel: "Throughput",
                    firstValue: "\(formatCount(result.elementsPerSecond)) elem/s",
                    secondLabel: "Checksum",
                    secondValue: result.checksum.formatted(.number.precision(.fractionLength(3)))
                )

                MetricRow(
                    firstLabel: "Completed",
                    firstValue: result.completedIterations.formatted(.number),
                    secondLabel: "Requested",
                    secondValue: result.requestedIterations.formatted(.number)
                )
            }
        }
        .padding(.vertical, 12)
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

private struct MetricRow: View {
    let firstLabel: String
    let firstValue: String
    let secondLabel: String
    let secondValue: String

    var body: some View {
        GridRow {
            Text(firstLabel)
                .foregroundStyle(.secondary)

            Text(firstValue)
                .monospacedDigit()

            Text(secondLabel)
                .foregroundStyle(.secondary)

            Text(secondValue)
                .monospacedDigit()
        }
    }
}

#Preview {
    ContentView()
}
