# MMTToolForHUD performance report

Generated: 2026-11-10 11.16.53 · Device: arm64

| Benchmark | Iterations | Average | Max | Budget | Status |
|---|---:|---:|---:|---:|---|
| showLoading + layout + dismiss (per cycle) | 50 | 0.591ms | 0.849ms | 15.0ms | PASS |
| updateProgress (per call) | 200 | 0.381ms | 0.993ms | 2.0ms | PASS |
| preferredSize with long text (per call) | 500 | 0.049ms | 0.113ms | 1.0ms | PASS |
| toast present + remove (per cycle) | 100 | 0.524ms | 0.774ms | 5.0ms | PASS |

Memory footprint delta after stress cycles: 4097 KB (informational, no budget).
