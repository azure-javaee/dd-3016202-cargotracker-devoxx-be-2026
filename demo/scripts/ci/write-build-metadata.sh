#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"
build_dir="$root/ci-artifacts/build-contract"
dependency_dir="$root/ci-artifacts/dependency-reports"
mkdir -p "$build_dir" "$dependency_dir"

if [[ "${1:-}" != "--artifact-metadata" ]]; then
  ./mvnw help:effective-pom -Doutput="$dependency_dir/effective-pom.xml"
  ./mvnw dependency:tree -DoutputFile="$dependency_dir/dependency-tree.txt"
  ./mvnw dependency:resolve-plugins -DoutputFile="$dependency_dir/resolved-plugins.txt"
  jar tf target/cargo-tracker.war > "$build_dir/war-inventory.txt"
  sha256sum target/cargo-tracker.war > "$build_dir/war.sha256"
  ./mvnw -version > "$build_dir/maven-version.txt"

  if [[ ! -s "$dependency_dir/vulnerability-report.json" ]]; then
    echo "vulnerability gate did not produce a report" >&2
    exit 1
  fi
fi

if [[ "${1:-}" == "--artifact-metadata" ]]; then
  python3 - "$root" <<'PY'
import hashlib
import json
import os
import pathlib
import subprocess
import sys
from datetime import datetime, timezone
from xml.etree import ElementTree

root = pathlib.Path(sys.argv[1])
required_env = [
    "GITHUB_REPOSITORY", "GITHUB_REF", "GITHUB_SHA", "GITHUB_WORKFLOW",
    "GITHUB_RUN_ID", "GITHUB_RUN_ATTEMPT", "GITHUB_SERVER_URL",
    "GITHUB_EVENT_NAME", "RUNNER_OS", "RUNNER_ARCH", "JAVA_HOME",
]
missing = [name for name in required_env if not os.environ.get(name)]
if missing:
    raise SystemExit("missing CI metadata: " + ", ".join(missing))

started = os.environ.get("CI_STARTED_AT")
if not started:
    raise SystemExit("CI_STARTED_AT is required")
pom = ElementTree.parse(root / "pom.xml").getroot()
ns = {"m": "http://maven.apache.org/POM/4.0.0"}
liberty = pom.find(".//m:liberty.runtime.version", ns)
java = subprocess.check_output(["java", "-version"], stderr=subprocess.STDOUT, text=True)
maven = subprocess.check_output(["./mvnw", "-version"], text=True)
tools = {
    "java": java.splitlines()[0],
    "maven": maven.splitlines()[0],
    "openLibertyRuntime": liberty.text if liberty is not None else None,
}
if not all(tools.values()):
    raise SystemExit("unable to resolve required tool versions")

commands = [line for line in os.environ.get("CI_COMMANDS", "").splitlines() if line]
if not commands:
    raise SystemExit("CI_COMMANDS is required")
pr = os.environ.get("GITHUB_EVENT_NAME") == "pull_request"
if pr:
    pr_number = os.environ.get("CI_PR_NUMBER", "")
    if not pr_number.isdigit() or int(pr_number) <= 0:
        raise SystemExit("CI_PR_NUMBER must be a positive integer for pull requests")
base_url = f"{os.environ['GITHUB_SERVER_URL']}/{os.environ['GITHUB_REPOSITORY']}"
metadata = {
    "schema": 1,
    "concern": "build reproducibility and dependency security",
    "name": None,
    "repository": os.environ["GITHUB_REPOSITORY"],
    "ref": os.environ["GITHUB_REF"],
    "sha": os.environ["GITHUB_SHA"],
    "workflow": os.environ["GITHUB_WORKFLOW"],
    "run": os.environ["GITHUB_RUN_ID"],
    "attempt": os.environ["GITHUB_RUN_ATTEMPT"],
    "url": f"{base_url}/actions/runs/{os.environ['GITHUB_RUN_ID']}",
    "job": os.environ.get("GITHUB_JOB", "build"),
    "event": os.environ["GITHUB_EVENT_NAME"],
    "pr": os.environ.get("CI_PR_NUMBER", "not-applicable") if pr else "not-applicable",
    "runner": {"os": os.environ["RUNNER_OS"], "architecture": os.environ["RUNNER_ARCH"]},
    "tools": tools,
    "startedAt": started,
    "endedAt": os.environ.get("CI_ENDED_AT", datetime.now(timezone.utc).isoformat()),
    "commands": commands,
}
for directory, name in ((root / "ci-artifacts/build-contract", "build-contract"),
                        (root / "ci-artifacts/dependency-reports", "dependency-reports")):
    metadata["name"] = name
    files = []
    for file in sorted(directory.rglob("*")):
        if file.is_file() and file.name != "artifact-metadata.json":
            files.append({
                "path": file.relative_to(directory).as_posix(),
                "bytes": file.stat().st_size,
                "sha256": hashlib.sha256(file.read_bytes()).hexdigest(),
            })
    if not files:
        raise SystemExit(f"empty artifact: {name}")
    metadata["files"] = files
    (directory / "artifact-metadata.json").write_text(json.dumps(metadata, indent=2) + "\n")
PY
fi
