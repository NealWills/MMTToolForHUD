# MMTToolForHUD performance report

Generated: 2026-11-09 15.21.48 · Device: arm64

| Benchmark | Iterations | Average | Max | Budget | Status |
|---|---:|---:|---:|---:|---|
| showLoading + layout + dismiss (per cycle) | 50 | 0.567ms | 0.745ms | 15.0ms | PASS |
| updateProgress (per call) | 200 | 0.369ms | 0.843ms | 2.0ms | PASS |
| preferredSize with long text (per call) | 500 | 0.049ms | 0.146ms | 1.0ms | PASS |
| toast present + remove (per cycle) | 100 | 0.527ms | 0.908ms | 5.0ms | PASS |

Memory footprint delta after stress cycles: 3744 KB (informational, no budget).
