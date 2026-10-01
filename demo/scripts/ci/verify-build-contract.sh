#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"
require_file() {
  if [[ ! -s "$1" ]]; then
    echo "missing or empty contract output: $1" >&2
    exit 1
  fi
}
for path in \
  target/cargo-tracker.war \
  ci-artifacts/build-contract/war-inventory.txt \
  ci-artifacts/build-contract/war.sha256 \
  ci-artifacts/dependency-reports/effective-pom.xml \
  ci-artifacts/dependency-reports/dependency-tree.txt \
  ci-artifacts/dependency-reports/resolved-plugins.txt \
  ci-artifacts/dependency-reports/vulnerability-report.txt \
  ci-artifacts/dependency-reports/vulnerability-report.json \
  ci-artifacts/dependency-reports/baseline-vulnerability-report.json \
  ci-artifacts/build-contract/enforcer-negative-controls.txt \
  ci-artifacts/build-contract/artifact-metadata.json \
  ci-artifacts/dependency-reports/artifact-metadata.json \
  ci-artifacts/compatibility-contract/compatibility-report.txt \
  ci-artifacts/compatibility-contract/negative-controls.txt \
  ci-artifacts/compatibility-contract/liberty-deploy.log \
  ci-artifacts/compatibility-contract/liberty-start.log \
  ci-artifacts/compatibility-contract/liberty-stop.log \
  ci-artifacts/compatibility-contract/liberty-messages-excerpt.txt \
  ci-artifacts/compatibility-contract/readiness.json \
  ci-artifacts/compatibility-contract/artifact-metadata.json \
  ci-artifacts/compatibility-contract/safety-net-negative-controls.txt \
  ci-artifacts/compatibility-contract/observability-negative-controls.txt \
  ci-artifacts/test-reports-unit/artifact-metadata.json \
  ci-artifacts/test-reports-liberty/artifact-metadata.json \
  ci-artifacts/liberty-logs/observability-access.log \
  ci-artifacts/liberty-logs/artifact-metadata.json \
  ci-artifacts/otel-telemetry/traces.json \
  ci-artifacts/otel-telemetry/metrics.json \
  ci-artifacts/otel-telemetry/collector.log \
  ci-artifacts/otel-telemetry/request-transcript.jsonl \
  ci-artifacts/otel-telemetry/redaction-check.txt \
  ci-artifacts/otel-telemetry/otel-collector-config.yaml \
  ci-artifacts/otel-telemetry/versions.properties \
  ci-artifacts/otel-telemetry/artifact-metadata.json; do
  require_file "$path"
done
if ! sha256sum --check ci-artifacts/build-contract/war.sha256; then
  echo "WAR checksum verification failed: ci-artifacts/build-contract/war.sha256" >&2
  exit 1
fi
python3 - "$root" <<'PY'
import hashlib
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
required = {
    "concern", "name", "repository", "ref", "sha", "workflow", "run",
    "attempt", "url", "job", "event", "pr", "runner", "tools",
    "startedAt", "endedAt", "commands", "files",
}
for path in (
    root / "ci-artifacts/build-contract/artifact-metadata.json",
    root / "ci-artifacts/dependency-reports/artifact-metadata.json",
    root / "ci-artifacts/compatibility-contract/artifact-metadata.json",
    root / "ci-artifacts/test-reports-unit/artifact-metadata.json",
    root / "ci-artifacts/test-reports-liberty/artifact-metadata.json",
    root / "ci-artifacts/liberty-logs/artifact-metadata.json",
    root / "ci-artifacts/otel-telemetry/artifact-metadata.json",
):
    data = json.loads(path.read_text())
    def require(condition, message):
        if not condition:
            raise SystemExit(f"{path}: {message}")
    require(data.get("schema") == 1, "schema must be 1")
    require(required <= data.keys(), "metadata keys are incomplete")
    require(data["commands"] and data["files"], "commands/files inventory is empty")
    if path.parent.name == "otel-telemetry":
        pins = dict(
            line.split("=", 1)
            for line in (root / "observability/versions.properties").read_text().splitlines()
        )
        require(data.get("redactionResult") == "passed", "redaction did not pass")
        require(
            data["tools"].get("openTelemetryJavaAgent")
            == pins.get("otel.javaagent.version"),
            "OpenTelemetry Java agent version is not pinned",
        )
        require(
            data["tools"].get("openTelemetryJavaAgentSha256")
            == pins.get("otel.javaagent.sha256"),
            "OpenTelemetry Java agent checksum is not pinned",
        )
        require(
            data["tools"].get("openTelemetryCollectorImage")
            == pins.get("otel.collector.image"),
            "OpenTelemetry Collector image is not pinned",
        )
    for entry in data["files"]:
        file_path = path.parent / entry["path"]
        require(file_path.is_file(), f"missing inventoried file: {file_path}")
        require(entry["bytes"] == file_path.stat().st_size, f"size mismatch: {file_path}")
        require(
            entry["sha256"] == hashlib.sha256(file_path.read_bytes()).hexdigest(),
            f"checksum mismatch: {file_path}",
        )

for path in (
    root / "ci-artifacts/dependency-reports/vulnerability-report.json",
    root / "ci-artifacts/dependency-reports/baseline-vulnerability-report.json",
):
    data = json.loads(path.read_text())
    if len(data.get("baselineSha", "")) != 40:
        raise SystemExit(f"{path}: baselineSha must be a 40-character SHA")
PY
