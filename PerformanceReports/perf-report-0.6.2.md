# MMTToolForHUD performance report

Generated: 2026-11-09 16.24.48 · Device: arm64

| Benchmark | Iterations | Average | Max | Budget | Status |
|---|---:|---:|---:|---:|---|
| showLoading + layout + dismiss (per cycle) | 50 | 0.593ms | 0.936ms | 15.0ms | PASS |
| updateProgress (per call) | 200 | 0.366ms | 0.814ms | 2.0ms | PASS |
| preferredSize with long text (per call) | 500 | 0.050ms | 0.140ms | 1.0ms | PASS |
| toast present + remove (per cycle) | 100 | 0.532ms | 0.755ms | 5.0ms | PASS |

Memory footprint delta after stress cycles: 3680 KB (informational, no budget).
