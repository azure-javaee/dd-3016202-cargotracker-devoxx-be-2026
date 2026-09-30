#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"
test -s target/cargo-tracker.war
test -s ci-artifacts/build-contract/war-inventory.txt
test -s ci-artifacts/build-contract/war.sha256
sha256sum --check ci-artifacts/build-contract/war.sha256
test -s ci-artifacts/dependency-reports/effective-pom.xml
test -s ci-artifacts/dependency-reports/dependency-tree.txt
test -s ci-artifacts/dependency-reports/resolved-plugins.txt
test -s ci-artifacts/dependency-reports/vulnerability-report.txt
test -s ci-artifacts/dependency-reports/vulnerability-report.json
test -s ci-artifacts/dependency-reports/baseline-vulnerability-report.json
test -s ci-artifacts/build-contract/enforcer-negative-controls.txt
test -s ci-artifacts/build-contract/artifact-metadata.json
test -s ci-artifacts/dependency-reports/artifact-metadata.json
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
):
    data = json.loads(path.read_text())
    assert data.get("schema") == 1
    assert required <= data.keys()
    assert data["commands"] and data["files"]
    for entry in data["files"]:
        file_path = path.parent / entry["path"]
        assert file_path.is_file() and entry["bytes"] == file_path.stat().st_size
        assert entry["sha256"] == hashlib.sha256(file_path.read_bytes()).hexdigest()
PY
