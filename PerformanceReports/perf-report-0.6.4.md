# MMTToolForHUD performance report

Generated: 2026-11-27 10.41.17 · Device: arm64

| Benchmark | Iterations | Average | Max | Budget | Status |
|---|---:|---:|---:|---:|---|
| showLoading + layout + dismiss (per cycle) | 50 | 0.320ms | 0.375ms | 15.0ms | PASS |
| updateProgress (per call) | 200 | 0.205ms | 0.507ms | 2.0ms | PASS |
| preferredSize with long text (per call) | 500 | 0.045ms | 0.094ms | 1.0ms | PASS |
| toast present + remove (per cycle) | 100 | 0.312ms | 0.456ms | 5.0ms | PASS |

Memory footprint delta after stress cycles: 4064 KB (informational, no budget).
