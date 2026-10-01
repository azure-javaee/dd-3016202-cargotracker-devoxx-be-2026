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

mkdir -p "$tmp/unsafe-telemetry"
python3 - "$tmp/unsafe-telemetry/metrics.json" <<'PY'
import json
import sys

document = {
    "resourceMetrics": [
        {
            "scopeMetrics": [
                {
                    "metrics": [
                        {
                            "histogram": {
                                "dataPoints": [
                                    {
                                        "exemplars": [
                                            {
                                                "filteredAttributes": [
                                                    {
                                                        "key": "url.query",
                                                        "value": {
                                                            "stringValue": "trackingId=<REDACTED>"
                                                        },
                                                    }
                                                ]
                                            }
                                        ]
                                    }
                                ]
                            }
                        }
                    ]
                }
            ]
        }
    ]
}
with open(sys.argv[1], "w") as output:
    json.dump(document, output)
    output.write("\n")
PY
if ./scripts/ci/redact-artifacts.sh --check-only "$tmp/unsafe-telemetry" \
  > "$tmp/unsafe-telemetry-check.log" 2>&1; then
  echo "unsafe-exemplar: final artifact redaction unexpectedly passed" >> "$out"
  exit 1
fi
if ! grep -Fq "artifact redaction failed" "$tmp/unsafe-telemetry-check.log"; then
  echo "unsafe-exemplar: final artifact scanner missed the injected query/cargo identifier" >> "$out"
  cat "$tmp/unsafe-telemetry-check.log" >&2
  exit 1
fi
echo "unsafe-exemplar: query attribute rejected by final artifact scan" >> "$out"
printf '%s\n' '{"cargoTrackingId":"ABC123"}' > "$tmp/unsafe-telemetry/metrics.json"
if ./scripts/ci/redact-artifacts.sh --check-only "$tmp/unsafe-telemetry" \
  > "$tmp/unsafe-cargo-check.log" 2>&1; then
  echo "unsafe-cargo-id: final artifact redaction unexpectedly passed" >> "$out"
  exit 1
fi
if ! grep -Fq "seeded cargo identifier" "$tmp/unsafe-cargo-check.log"; then
  echo "unsafe-cargo-id: final artifact scanner missed the seeded tracking ID" >> "$out"
  cat "$tmp/unsafe-cargo-check.log" >&2
  exit 1
fi
echo "unsafe-cargo-id: seeded tracking ID rejected by final artifact scan" >> "$out"

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
  "unsafe-exemplar" \
  "unsafe-cargo-id" \
  "secret-like artifact content"; do
  if ! grep -Fq "$diagnostic" "$out"; then
    echo "missing observability negative-control evidence: $diagnostic" >&2
    exit 1
  fi
done
