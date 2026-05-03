# SIMDBenchmark

Small macOS proof of concept for comparing conservative scalar code, optimized scalar code, and explicit Swift SIMD vectors over the same input sizes.

The app benchmarks `Float`, `Double`, `Int8`, `Int16`, and `Int32` data with `SIMD2`, `SIMD3`, `SIMD4`, `SIMD8`, `SIMD16`, `SIMD32`, and `SIMD64`. Each benchmark processes 3,072 elements per iteration and reports total time, time per iteration, throughput, completed iterations, checksum, and speedup ratios.

Supported algorithms:

- `arithmetic`: floating-point or integer arithmetic kernels.
- `thresholdSelect`: branch/select-style threshold kernels.
- `reduction`: reduction kernels that accumulate a single checksum-like result.
- `boundsMerge`: min/max merge kernels.

The shared scheme launches in Release by default so measurements reflect optimized code rather than Debug-only overhead. The project targets macOS 14 or newer.

## Build and Run

Open the project in Xcode:

```sh
open SIMDBenchmark.xcodeproj
```

Select the `SIMDBenchmark` scheme and run it on `My Mac`.

Build from the command line:

```sh
xcodebuild -project SIMDBenchmark.xcodeproj -scheme SIMDBenchmark -destination 'platform=macOS' build
```

## Using the App

1. Choose an `Algorithm`, `Data` type, `SIMD` width, and `Iterations` count.
2. Use `Scalar`, `Opt Scalar`, or `SIMD` to run one implementation for the selected configuration.
3. Use `Run Set` to run scalar, optimized scalar, and SIMD for the selected configuration.
4. Use `Run All` to run every algorithm, data type, and SIMD width combination with the current iteration count. A full matrix is 140 rows.
5. Use `Stop` to cancel a long-running selected or matrix run.
6. Use `Copy CSV` after `Run All` to copy the matrix results to the clipboard.
7. Turn `MCP Server` on only when a local MCP client needs to run benchmarks over HTTP. The setting is persisted between launches.

The selected-results panel shows per-variant timings and checksums. The all-combinations panel summarizes matrix progress and fastest/slowest speedups. The `Hardware` and `Build` disclosure panels show the runtime CPU/cache/register profile plus compiler, SDK, Xcode, architecture, and optimization metadata that are also included in exported CSV and MCP results.

## Full Benchmark Results

Captured May 3, 2026 through the MCP `run_all_benchmarks` tool with `10,000` iterations per row and `3,072` elements per iteration. The full matrix contains `140` rows: 4 algorithms x 5 data types x 7 SIMD widths.

Hardware/build context: Apple M4 Max (`Mac16,6`), `arm64`, `ARM ASIMD/NEON`, 32 x 128-bit SIMD registers, Apple Swift version 6.3.2 (swiftlang-6.3.2.1.108 clang-2100.1.1.101), Xcode 26.5, -O expected from project Release configuration.

Duration columns are total milliseconds for the full 10,000-iteration run. `SIMD / Scalar` and `SIMD / Opt` are speedup ratios from the same row. All SIMD and optimized-scalar checksum deltas were `0`.

### Arithmetic

| Data | Width | Scalar ms | Opt ms | SIMD ms | SIMD / Scalar | SIMD / Opt |
|---|---:|---:|---:|---:|---:|---:|
| Float | SIMD2 | 25.93 | 5.878 | 12.50 | 2.07x | 0.47x |
| Float | SIMD3 | 26.37 | 6.006 | 16.44 | 1.60x | 0.37x |
| Float | SIMD4 | 25.91 | 6.212 | 6.277 | 4.13x | 0.99x |
| Float | SIMD8 | 26.27 | 6.127 | 6.167 | 4.26x | 0.99x |
| Float | SIMD16 | 26.08 | 6.093 | 6.465 | 4.03x | 0.94x |
| Float | SIMD32 | 26.55 | 6.056 | 758.97 | 0.0350x | 0.0080x |
| Float | SIMD64 | 28.69 | 6.246 | 1596.69 | 0.0180x | 0.0039x |
| Double | SIMD2 | 27.24 | 12.01 | 12.34 | 2.21x | 0.97x |
| Double | SIMD3 | 27.28 | 11.62 | 16.72 | 1.63x | 0.69x |
| Double | SIMD4 | 27.26 | 11.90 | 12.21 | 2.23x | 0.98x |
| Double | SIMD8 | 27.34 | 11.72 | 12.47 | 2.19x | 0.94x |
| Double | SIMD16 | 27.53 | 12.27 | 16.16 | 1.70x | 0.76x |
| Double | SIMD32 | 27.55 | 12.06 | 1477.84 | 0.0186x | 0.0082x |
| Double | SIMD64 | 27.23 | 12.11 | 3507.22 | 0.0078x | 0.0035x |
| Int8 | SIMD2 | 23.10 | 0.9929 | 19.45 | 1.19x | 0.0510x |
| Int8 | SIMD3 | 23.20 | 0.9540 | 15.55 | 1.49x | 0.0614x |
| Int8 | SIMD4 | 23.59 | 1.007 | 7.899 | 2.99x | 0.13x |
| Int8 | SIMD8 | 23.31 | 1.007 | 3.066 | 7.60x | 0.33x |
| Int8 | SIMD16 | 23.32 | 0.9741 | 1.497 | 15.58x | 0.65x |
| Int8 | SIMD32 | 23.74 | 1.080 | 338.77 | 0.0701x | 0.0032x |
| Int8 | SIMD64 | 23.55 | 1.209 | 861.24 | 0.0273x | 0.0014x |
| Int16 | SIMD2 | 23.26 | 2.074 | 15.51 | 1.50x | 0.13x |
| Int16 | SIMD3 | 23.30 | 2.067 | 14.30 | 1.63x | 0.14x |
| Int16 | SIMD4 | 23.37 | 2.096 | 5.743 | 4.07x | 0.36x |
| Int16 | SIMD8 | 23.18 | 2.048 | 2.920 | 7.94x | 0.70x |
| Int16 | SIMD16 | 23.59 | 2.040 | 2.192 | 10.76x | 0.93x |
| Int16 | SIMD32 | 23.34 | 2.140 | 494.67 | 0.0472x | 0.0043x |
| Int16 | SIMD64 | 23.69 | 2.285 | 1291.39 | 0.0183x | 0.0018x |
| Int32 | SIMD2 | 23.31 | 3.995 | 11.65 | 2.00x | 0.34x |
| Int32 | SIMD3 | 23.43 | 3.901 | 10.47 | 2.24x | 0.37x |
| Int32 | SIMD4 | 23.63 | 4.017 | 5.844 | 4.04x | 0.69x |
| Int32 | SIMD8 | 23.34 | 3.889 | 4.385 | 5.32x | 0.89x |
| Int32 | SIMD16 | 23.47 | 4.126 | 4.091 | 5.74x | 1.01x |
| Int32 | SIMD32 | 23.45 | 3.870 | 750.22 | 0.0313x | 0.0052x |
| Int32 | SIMD64 | 23.61 | 3.976 | 2126.68 | 0.0111x | 0.0019x |

### Threshold Select

| Data | Width | Scalar ms | Opt ms | SIMD ms | SIMD / Scalar | SIMD / Opt |
|---|---:|---:|---:|---:|---:|---:|
| Float | SIMD2 | 27.49 | 7.695 | 21.07 | 1.30x | 0.37x |
| Float | SIMD3 | 27.64 | 8.008 | 32.64 | 0.85x | 0.25x |
| Float | SIMD4 | 27.56 | 7.899 | 10.62 | 2.60x | 0.74x |
| Float | SIMD8 | 27.37 | 7.972 | 49.41 | 0.55x | 0.16x |
| Float | SIMD16 | 27.56 | 7.630 | 82.21 | 0.34x | 0.0928x |
| Float | SIMD32 | 27.45 | 7.752 | 1267.35 | 0.0217x | 0.0061x |
| Float | SIMD64 | 27.88 | 7.959 | 2784.95 | 0.0100x | 0.0029x |
| Double | SIMD2 | 28.30 | 17.22 | 21.08 | 1.34x | 0.82x |
| Double | SIMD3 | 27.93 | 16.52 | 27.39 | 1.02x | 0.60x |
| Double | SIMD4 | 28.02 | 23.47 | 23.32 | 1.20x | 1.01x |
| Double | SIMD8 | 28.00 | 23.07 | 79.31 | 0.35x | 0.29x |
| Double | SIMD16 | 28.13 | 16.99 | 150.52 | 0.19x | 0.11x |
| Double | SIMD32 | 28.33 | 23.07 | 2284.73 | 0.0124x | 0.0101x |
| Double | SIMD64 | 28.49 | 17.27 | 5974.12 | 0.0048x | 0.0029x |
| Int8 | SIMD2 | 23.38 | 1.549 | 22.65 | 1.03x | 0.0684x |
| Int8 | SIMD3 | 23.38 | 1.505 | 19.30 | 1.21x | 0.0780x |
| Int8 | SIMD4 | 23.62 | 1.508 | 10.22 | 2.31x | 0.15x |
| Int8 | SIMD8 | 23.63 | 1.543 | 40.48 | 0.58x | 0.0381x |
| Int8 | SIMD16 | 23.36 | 1.575 | 56.42 | 0.41x | 0.0279x |
| Int8 | SIMD32 | 23.39 | 1.633 | 592.85 | 0.0395x | 0.0028x |
| Int8 | SIMD64 | 23.63 | 1.803 | 1292.27 | 0.0183x | 0.0014x |
| Int16 | SIMD2 | 23.48 | 2.983 | 18.33 | 1.28x | 0.16x |
| Int16 | SIMD3 | 23.42 | 2.900 | 18.86 | 1.24x | 0.15x |
| Int16 | SIMD4 | 23.44 | 2.931 | 7.316 | 3.20x | 0.40x |
| Int16 | SIMD8 | 23.40 | 2.926 | 40.16 | 0.58x | 0.0729x |
| Int16 | SIMD16 | 23.41 | 2.926 | 61.38 | 0.38x | 0.0477x |
| Int16 | SIMD32 | 23.53 | 3.086 | 854.57 | 0.0275x | 0.0036x |
| Int16 | SIMD64 | 23.63 | 3.146 | 1937.82 | 0.0122x | 0.0016x |
| Int32 | SIMD2 | 23.38 | 5.875 | 15.85 | 1.47x | 0.37x |
| Int32 | SIMD3 | 23.34 | 5.994 | 12.49 | 1.87x | 0.48x |
| Int32 | SIMD4 | 23.45 | 5.869 | 7.781 | 3.01x | 0.75x |
| Int32 | SIMD8 | 23.32 | 5.920 | 44.04 | 0.53x | 0.13x |
| Int32 | SIMD16 | 23.26 | 5.822 | 77.47 | 0.30x | 0.0752x |
| Int32 | SIMD32 | 23.28 | 5.811 | 1285.37 | 0.0181x | 0.0045x |
| Int32 | SIMD64 | 23.59 | 5.902 | 3172.09 | 0.0074x | 0.0019x |

### Reduction

| Data | Width | Scalar ms | Opt ms | SIMD ms | SIMD / Scalar | SIMD / Opt |
|---|---:|---:|---:|---:|---:|---:|
| Float | SIMD2 | 29.09 | 25.83 | 13.55 | 2.15x | 1.91x |
| Float | SIMD3 | 28.66 | 27.83 | 17.31 | 1.66x | 1.61x |
| Float | SIMD4 | 27.95 | 27.53 | 6.733 | 4.15x | 4.09x |
| Float | SIMD8 | 27.73 | 28.10 | 12.94 | 2.14x | 2.17x |
| Float | SIMD16 | 27.92 | 30.28 | 10.16 | 2.75x | 2.98x |
| Float | SIMD32 | 27.53 | 28.57 | 924.60 | 0.0298x | 0.0309x |
| Float | SIMD64 | 28.04 | 30.18 | 1891.12 | 0.0148x | 0.0160x |
| Double | SIMD2 | 29.57 | 28.82 | 12.98 | 2.28x | 2.22x |
| Double | SIMD3 | 29.90 | 28.95 | 40.82 | 0.73x | 0.71x |
| Double | SIMD4 | 28.86 | 29.83 | 26.11 | 1.11x | 1.14x |
| Double | SIMD8 | 28.36 | 29.10 | 19.92 | 1.42x | 1.46x |
| Double | SIMD16 | 28.68 | 30.36 | 17.81 | 1.61x | 1.70x |
| Double | SIMD32 | 29.01 | 28.58 | 1771.50 | 0.0164x | 0.0161x |
| Double | SIMD64 | 29.54 | 28.29 | 4097.41 | 0.0072x | 0.0069x |
| Int8 | SIMD2 | 30.04 | 33.15 | 53.85 | 0.56x | 0.62x |
| Int8 | SIMD3 | 30.18 | 31.18 | 18.59 | 1.62x | 1.68x |
| Int8 | SIMD4 | 29.74 | 30.25 | 28.54 | 1.04x | 1.06x |
| Int8 | SIMD8 | 29.96 | 29.55 | 12.89 | 2.32x | 2.29x |
| Int8 | SIMD16 | 30.32 | 30.04 | 6.870 | 4.41x | 4.37x |
| Int8 | SIMD32 | 30.08 | 29.98 | 414.17 | 0.0726x | 0.0724x |
| Int8 | SIMD64 | 30.27 | 30.33 | 980.48 | 0.0309x | 0.0309x |
| Int16 | SIMD2 | 31.19 | 38.21 | 19.33 | 1.61x | 1.98x |
| Int16 | SIMD3 | 31.55 | 26.63 | 16.42 | 1.92x | 1.62x |
| Int16 | SIMD4 | 31.44 | 26.41 | 27.19 | 1.16x | 0.97x |
| Int16 | SIMD8 | 31.49 | 25.79 | 13.37 | 2.35x | 1.93x |
| Int16 | SIMD16 | 31.30 | 25.71 | 9.566 | 3.27x | 2.69x |
| Int16 | SIMD32 | 31.13 | 25.72 | 608.51 | 0.0511x | 0.0423x |
| Int16 | SIMD64 | 31.65 | 25.87 | 1462.37 | 0.0216x | 0.0177x |
| Int32 | SIMD2 | 31.20 | 24.66 | 17.25 | 1.81x | 1.43x |
| Int32 | SIMD3 | 31.40 | 25.47 | 22.63 | 1.39x | 1.13x |
| Int32 | SIMD4 | 31.42 | 24.92 | 27.32 | 1.15x | 0.91x |
| Int32 | SIMD8 | 31.22 | 24.59 | 18.97 | 1.65x | 1.30x |
| Int32 | SIMD16 | 31.17 | 24.83 | 9.577 | 3.25x | 2.59x |
| Int32 | SIMD32 | 31.25 | 24.83 | 916.20 | 0.0341x | 0.0271x |
| Int32 | SIMD64 | 31.37 | 24.99 | 2434.02 | 0.0129x | 0.0103x |

### Bounds Merge

| Data | Width | Scalar ms | Opt ms | SIMD ms | SIMD / Scalar | SIMD / Opt |
|---|---:|---:|---:|---:|---:|---:|
| Float | SIMD2 | 23.03 | 15.55 | 11.46 | 2.01x | 1.36x |
| Float | SIMD3 | 23.21 | 15.60 | 10.39 | 2.23x | 1.50x |
| Float | SIMD4 | 23.17 | 15.76 | 5.820 | 3.98x | 2.71x |
| Float | SIMD8 | 23.51 | 15.93 | 57.10 | 0.41x | 0.28x |
| Float | SIMD16 | 23.34 | 15.64 | 105.59 | 0.22x | 0.15x |
| Float | SIMD32 | 23.49 | 15.91 | 794.66 | 0.0296x | 0.0200x |
| Float | SIMD64 | 23.75 | 16.07 | 1380.59 | 0.0172x | 0.0116x |
| Double | SIMD2 | 23.37 | 15.84 | 11.66 | 2.00x | 1.36x |
| Double | SIMD3 | 23.30 | 15.82 | 8.215 | 2.84x | 1.93x |
| Double | SIMD4 | 23.34 | 15.84 | 5.898 | 3.96x | 2.69x |
| Double | SIMD8 | 23.41 | 15.80 | 105.14 | 0.22x | 0.15x |
| Double | SIMD16 | 23.43 | 15.81 | 163.03 | 0.14x | 0.0970x |
| Double | SIMD32 | 23.64 | 15.85 | 1404.51 | 0.0168x | 0.0113x |
| Double | SIMD64 | 23.78 | 16.07 | 2958.41 | 0.0080x | 0.0054x |
| Int8 | SIMD2 | 23.54 | 15.83 | 28.81 | 0.82x | 0.55x |
| Int8 | SIMD3 | 23.46 | 15.90 | 27.92 | 0.84x | 0.57x |
| Int8 | SIMD4 | 23.28 | 15.81 | 22.44 | 1.04x | 0.70x |
| Int8 | SIMD8 | 23.65 | 15.97 | 60.50 | 0.39x | 0.26x |
| Int8 | SIMD16 | 23.43 | 15.68 | 56.16 | 0.42x | 0.28x |
| Int8 | SIMD32 | 23.83 | 15.80 | 486.85 | 0.0489x | 0.0324x |
| Int8 | SIMD64 | 23.64 | 15.71 | 534.19 | 0.0443x | 0.0294x |
| Int16 | SIMD2 | 23.44 | 15.95 | 25.03 | 0.94x | 0.64x |
| Int16 | SIMD3 | 23.56 | 15.80 | 19.98 | 1.18x | 0.79x |
| Int16 | SIMD4 | 23.61 | 15.90 | 15.61 | 1.51x | 1.02x |
| Int16 | SIMD8 | 23.68 | 15.98 | 50.53 | 0.47x | 0.32x |
| Int16 | SIMD16 | 23.32 | 15.81 | 67.60 | 0.35x | 0.23x |
| Int16 | SIMD32 | 23.45 | 15.88 | 524.49 | 0.0447x | 0.0303x |
| Int16 | SIMD64 | 23.67 | 16.14 | 777.44 | 0.0304x | 0.0208x |
| Int32 | SIMD2 | 23.21 | 15.72 | 16.58 | 1.40x | 0.95x |
| Int32 | SIMD3 | 23.54 | 15.50 | 16.21 | 1.45x | 0.96x |
| Int32 | SIMD4 | 23.59 | 15.85 | 13.49 | 1.75x | 1.17x |
| Int32 | SIMD8 | 23.68 | 15.78 | 59.88 | 0.40x | 0.26x |
| Int32 | SIMD16 | 23.37 | 15.74 | 110.76 | 0.21x | 0.14x |
| Int32 | SIMD32 | 23.52 | 15.76 | 795.27 | 0.0296x | 0.0198x |
| Int32 | SIMD64 | 23.95 | 16.11 | 1404.86 | 0.0171x | 0.0115x |

## MCP Server

The app can expose a local MCP HTTP endpoint:

```text
http://127.0.0.1:8765/mcp
```

The MCP server is off by default. Turn on `MCP Server` in the app header to bind the endpoint, and turn it off when you are done. The endpoint is bound only to loopback and is available only while the app is running and the toggle is enabled. MCP clients that support Streamable HTTP or URL-based MCP servers can configure a server named `simd-benchmark` with that URL.

Risks and mitigations:

- Loopback binding prevents other machines on the network from connecting directly.
- Keeping the server off by default removes the listening port unless you explicitly enable it.
- While enabled, local processes can attempt HTTP requests. Leave it off unless you are actively using an MCP client.
- Browser CORS access is limited to loopback origins such as `localhost` and `127.0.0.1`; requests with non-loopback `Origin` headers are rejected before any MCP tool runs.
- MCP calls can consume CPU by running benchmarks and can expose local hardware/build metadata in results.

Health check:

```sh
curl http://127.0.0.1:8765/health
```

The MCP server supports protocol version `2025-06-18` and accepts JSON-RPC `POST` requests at `/mcp`. It exposes these tools:

- `run_benchmark`: run one implementation variant for one algorithm and data type.
- `run_comparison`: run scalar, optimized scalar, and one selected SIMD width for one algorithm and data type.
- `run_all_benchmarks`: run the full matrix, or the matrix filtered to one algorithm, and return structured JSON plus CSV.

Common argument values:

- `algorithm`: `arithmetic`, `thresholdSelect`, `reduction`, or `boundsMerge`. Defaults to `arithmetic` where optional.
- `data_type`: `float32`, `float64`, `int8`, `int16`, or `int32`.
- `simd_width`: `simd2`, `simd3`, `simd4`, `simd8`, `simd16`, `simd32`, or `simd64`.
- `variant`: `scalar`, `optimized_scalar`, `simd2`, `simd3`, `simd4`, `simd8`, `simd16`, `simd32`, or `simd64`.
- `iterations`: positive integer. Very small counts are useful for smoke tests; larger counts give cleaner timing signal.

Example direct tool call with `curl`:

```sh
curl -s http://127.0.0.1:8765/mcp \
  -H 'Content-Type: application/json' \
  -H 'MCP-Protocol-Version: 2025-06-18' \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/call",
    "params": {
      "name": "run_comparison",
      "arguments": {
        "algorithm": "arithmetic",
        "data_type": "float32",
        "simd_width": "simd4",
        "iterations": 10000
      }
    }
  }'
```

Example full matrix for one algorithm:

```sh
curl -s http://127.0.0.1:8765/mcp \
  -H 'Content-Type: application/json' \
  -H 'MCP-Protocol-Version: 2025-06-18' \
  -d '{
    "jsonrpc": "2.0",
    "id": 2,
    "method": "tools/call",
    "params": {
      "name": "run_all_benchmarks",
      "arguments": {
        "algorithm": "boundsMerge",
        "iterations": 1000
      }
    }
  }'
```

Tool results include `structuredContent` with hardware and build metadata, selected configuration, timing fields, throughput, speedup ratios, checksums, checksum deltas, completed iteration counts, cancellation flags, and CSV output for `run_all_benchmarks`.
