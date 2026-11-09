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
# One final report per version tag: the filename carries the podspec
# version and each run overwrites the report for that version.
VERSION=$(grep -E "^\s*s.version" MMTToolForHUD.podspec | grep -oE "[0-9]+\.[0-9]+\.[0-9]+" | head -1)
if [ -z "$VERSION" ]; then
  echo "!! Could not read the version from MMTToolForHUD.podspec"
  exit 1
fi
REPORT_BASE="perf-report-$VERSION"

python3 - "$REPORT_DIR/last-run.log" "$REPORT_DIR" "$REPORT_BASE" << 'EXTRACT'
import os
import sys

log_path, report_dir, base = sys.argv[1], sys.argv[2], sys.argv[3]
log = open(log_path, encoding="utf-8", errors="replace").read()

begin = log.find("===== MMTToolForHUD PERFORMANCE-BEGIN =====")
json_marker = log.find("===== MMTToolForHUD PERFORMANCE-JSON =====")
end = log.find("===== MMTToolForHUD PERFORMANCE-END =====")
if begin == -1 or json_marker == -1 or end == -1:
    print("!! No report found in the log; check %s/last-run.log" % report_dir)
    sys.exit(1)

markdown = log[begin + len("===== MMTToolForHUD PERFORMANCE-BEGIN ====="):json_marker].strip()
payload = log[json_marker + len("===== MMTToolForHUD PERFORMANCE-JSON ====="):end].strip()

md_path = os.path.join(report_dir, base + ".md")
json_path = os.path.join(report_dir, base + ".json")
open(md_path, "w", encoding="utf-8").write(markdown + "\n")
open(json_path, "w", encoding="utf-8").write(payload + "\n")

# Drop superseded timestamped/older reports for this version.
for name in os.listdir(report_dir):
    if name.startswith("perf-report-") and not (name == base + ".md" or name == base + ".json"):
        os.remove(os.path.join(report_dir, name))
        print("    removed superseded %s" % name)

print("==> Report written (one final report per version tag):")
print("    %s" % md_path)
print("    %s" % json_path)
EXTRACT

echo
cat "$REPORT_DIR/$REPORT_BASE.md"
