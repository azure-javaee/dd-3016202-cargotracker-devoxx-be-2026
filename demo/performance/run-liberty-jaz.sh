#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mode="${1:?jaz mode required: bypass or tuned}"
cycle="${2:?cycle number required}"
position="${3:?position required}"
run_name="${4:?run name required}"
output="${5:?run output directory required}"
pristine_server="${6:?pristine server directory required}"
server_dir="${7:?Liberty server directory required}"

case "$mode" in
  bypass|tuned) ;;
  *)
    echo "jaz mode must be bypass or tuned" >&2
    exit 2
    ;;
esac

export PERF_MODE="$mode"
exec "$root/performance/run-workload.sh" --one \
  "$PERF_MODE" "$cycle" "$position" "$run_name" "$output" \
  "$pristine_server" "$server_dir"
