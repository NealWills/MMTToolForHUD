#!/bin/bash
#
# Runs the MMTToolForHUD performance benchmarks on a simulator and writes
# JSON + Markdown reports into PerformanceReports/.
#
# Usage: scripts/run-performance-tests.sh ["iPhone 16 Pro"]

set -euo pipefail
cd "$(dirname "$0")/.."

SIMULATOR_NAME="${1:-iPhone 16 Pro}"
REPORT_DIR="$(pwd)/PerformanceReports"
mkdir -p "$REPORT_DIR"

# Prefer an already-booted simulator (by UDID) for stable destination
# matching; fall back to matching by name.
DESTINATION="platform=iOS Simulator,name=$SIMULATOR_NAME"
BOOTED_UDID=$(xcrun simctl list devices | grep "Booted" | head -1 | grep -oE "[0-9A-F-]{36}")
if [ -n "$BOOTED_UDID" ]; then
  DESTINATION="id=$BOOTED_UDID"
  echo "==> Using booted simulator UDID $BOOTED_UDID"
else
  echo "==> No booted simulator; matching by name '$SIMULATOR_NAME'"
fi

echo "==> Reports will be written to $REPORT_DIR"

set -o pipefail
xcodebuild test \
  -workspace Example/MMTToolForHUD.xcworkspace \
  -scheme MMTToolForHUD-Example \
  -destination "$DESTINATION" \
  -only-testing:MMTToolForHUD_Tests/MMTToolForHUDPerformanceTests \
  2>&1 | tee "$REPORT_DIR/last-run.log" | grep -E "Test Case|PERFORMANCE|error:|Executed|TEST (SUCCEEDED|FAILED)" || true

echo
STAMP=$(date "+%Y-%m-%d %H.%M.%S")
python3 - "$REPORT_DIR/last-run.log" "$REPORT_DIR" "$STAMP" << 'EXTRACT'
import sys

log_path, report_dir, stamp = sys.argv[1], sys.argv[2], sys.argv[3]
log = open(log_path, encoding="utf-8", errors="replace").read()

begin = log.find("===== MMTToolForHUD PERFORMANCE-BEGIN =====")
json_marker = log.find("===== MMTToolForHUD PERFORMANCE-JSON =====")
end = log.find("===== MMTToolForHUD PERFORMANCE-END =====")
if begin == -1 or json_marker == -1 or end == -1:
    print("!! No report found in the log; check %s/last-run.log" % report_dir)
    sys.exit(1)

markdown = log[begin + len("===== MMTToolForHUD PERFORMANCE-BEGIN ====="):json_marker].strip()
payload = log[json_marker + len("===== MMTToolForHUD PERFORMANCE-JSON ====="):end].strip()

md_path = "%s/perf-report-%s.md" % (report_dir, stamp)
json_path = "%s/perf-report-%s.json" % (report_dir, stamp)
open(md_path, "w", encoding="utf-8").write(markdown + "\n")
open(json_path, "w", encoding="utf-8").write(payload + "\n")
print("==> Report written:")
print("    %s" % md_path)
print("    %s" % json_path)
EXTRACT

echo
cat "$REPORT_DIR/perf-report-$STAMP.md"
