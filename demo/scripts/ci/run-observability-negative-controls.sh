#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"
out="$root/ci-artifacts/compatibility-contract/observability-negative-controls.txt"
mkdir -p "$root/target"
tmp="$(mktemp -d "$root/target/observability-negative-controls.XXXXXX")"
mkdir -p "$(dirname "$out")"
: > "$out"
trap 'rm -rf "$tmp"' EXIT

if ./scripts/ci/run-observability-check.sh \
  --probe-collector http://127.0.0.1:1/ 1 > "$tmp/collector-unavailable.log" 2>&1; then
  echo "collector-unavailable: unexpected success" >> "$out"
  exit 1
fi
if ! grep -Fq "collector unavailable:" "$tmp/collector-unavailable.log"; then
  echo "collector-unavailable: missing explicit diagnostic" >> "$out"
  cat "$tmp/collector-unavailable.log" >&2
  exit 1
fi
echo "collector-unavailable: explicit bounded health diagnostic" >> "$out"

if OBSERVABILITY_OUTPUT_DIR="$tmp/otel" \
  OBSERVABILITY_LIBERTY_OUTPUT_DIR="$tmp/liberty" \
  OBSERVABILITY_FORCE_FAILURE_AFTER_COLLECTOR=1 \
  ./scripts/ci/run-observability-check.sh > "$tmp/collector-cleanup.log" 2>&1; then
  echo "collector-cleanup: forced failure unexpectedly succeeded" >> "$out"
  exit 1
fi
if ! grep -Fq "forced diagnostic failure after Collector health check" \
  "$tmp/collector-cleanup.log"; then
  echo "collector-cleanup: forced failure did not produce its diagnostic" >> "$out"
  cat "$tmp/collector-cleanup.log" >&2
  exit 1
fi
collector_name="$(cat "$tmp/otel/collector-name.txt")"
if docker ps -a --format '{{.Names}}' | grep -Fxq "$collector_name"; then
  echo "collector-cleanup: Collector container remained after failure" >> "$out"
  exit 1
fi
if ! grep -Fq "Liberty was not started" "$tmp/liberty/observability-diagnostic.txt"; then
  echo "collector-cleanup: failure unexpectedly entered the Liberty lifecycle" >> "$out"
  exit 1
fi
echo "collector-cleanup: Collector stopped and removed; Liberty lifecycle was not entered" >> "$out"

python3 scripts/ci/verify-observability.py --self-test >> "$out"

mkdir -p "$tmp/secret-fixture"
printf '%s\n' 'api_key=fixture-secret-never-retained' > "$tmp/secret-fixture/synthetic.txt"
if ./scripts/ci/redact-artifacts.sh --check-only "$tmp/secret-fixture" \
  > "$tmp/secret-check.log" 2>&1; then
  echo "secret-pattern: unexpected success" >> "$out"
  exit 1
fi
if ! grep -Fq "secret-like content found" "$tmp/secret-check.log"; then
  echo "secret-pattern: missing explicit diagnostic" >> "$out"
  cat "$tmp/secret-check.log" >&2
  exit 1
fi
./scripts/ci/redact-artifacts.sh "$tmp/secret-fixture" >> "$out"
./scripts/ci/redact-artifacts.sh --check-only "$tmp/secret-fixture" >> "$out"
if grep -Fq "fixture-secret-never-retained" "$tmp/secret-fixture/synthetic.txt"; then
  echo "secret-pattern: redaction left fixture secret behind" >> "$out"
  exit 1
fi
echo "secret-like artifact content: rejected, redacted, and rechecked" >> "$out"
for diagnostic in \
  collector-unavailable \
  collector-cleanup \
  "incompatible instrumentation" \
  "missing telemetry" \
  "broken correlation" \
  "invalid request lacks diagnostic signal" \
  "secret-like artifact content"; do
  if ! grep -Fq "$diagnostic" "$out"; then
    echo "missing observability negative-control evidence: $diagnostic" >&2
    exit 1
  fi
done
