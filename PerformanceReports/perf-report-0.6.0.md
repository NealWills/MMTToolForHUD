# MMTToolForHUD performance report

Generated: 2026-11-09 15.19.25 · Device: arm64

| Benchmark | Iterations | Average | Max | Budget | Status |
|---|---:|---:|---:|---:|---|
| showLoading + layout + dismiss (per cycle) | 50 | 0.591ms | 1.154ms | 15.0ms | PASS |
| updateProgress (per call) | 200 | 0.373ms | 0.902ms | 2.0ms | PASS |
| preferredSize with long text (per call) | 500 | 0.049ms | 0.118ms | 1.0ms | PASS |
| toast present + remove (per cycle) | 100 | 0.523ms | 0.839ms | 5.0ms | PASS |

Memory footprint delta after stress cycles: 3680 KB (informational, no budget).
