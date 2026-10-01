#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cycle="${1:?cycle number required}"
position="${2:?position required}"
run_name="${3:?run name required}"
output="${4:?run output directory required}"
pristine_server="${5:?pristine server directory required}"
server_dir="${6:?Liberty server directory required}"

export PERF_MODE=direct
exec "$root/performance/run-workload.sh" --one \
  "$PERF_MODE" "$cycle" "$position" "$run_name" "$output" \
  "$pristine_server" "$server_dir"
