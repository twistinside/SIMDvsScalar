# SIMDBenchmark

Small macOS proof of concept for comparing scalar `Float` math with `SIMD4<Float>` over the same number of lanes.

The shared scheme launches in Release so the benchmark reflects optimized code rather than Debug-only overhead.

Build from the command line:

```sh
xcodebuild -project SIMDBenchmark.xcodeproj -scheme SIMDBenchmark -destination 'platform=macOS' build
```
