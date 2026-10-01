#!/usr/bin/env python3
import hashlib
import json
import os
import pathlib
import re
import subprocess
import sys
import xml.etree.ElementTree as ElementTree
from datetime import datetime, timezone


root = pathlib.Path(__file__).resolve().parents[2]
otel_dir = root / "ci-artifacts/otel-telemetry"
liberty_dir = root / "ci-artifacts/liberty-logs"
required_environment = (
    "GITHUB_REPOSITORY",
    "GITHUB_REF",
    "GITHUB_SHA",
    "GITHUB_WORKFLOW",
    "GITHUB_RUN_ID",
    "GITHUB_RUN_ATTEMPT",
    "GITHUB_SERVER_URL",
    "GITHUB_EVENT_NAME",
    "GITHUB_JOB",
    "RUNNER_OS",
    "RUNNER_ARCH",
    "JAVA_HOME",
)
missing = [name for name in required_environment if not os.environ.get(name)]
if missing:
    raise SystemExit("missing CI metadata: " + ", ".join(missing))

otel_dir.mkdir(parents=True, exist_ok=True)
liberty_dir.mkdir(parents=True, exist_ok=True)
commands_file = otel_dir / "commands.txt"
if not commands_file.is_file() or not commands_file.read_text().strip():
    raise SystemExit("observability command transcript is missing")
commands = [line for line in commands_file.read_text().splitlines() if line]

redaction = subprocess.run(
    [
        str(root / "scripts/ci/redact-artifacts.sh"),
        "--check-only",
        str(otel_dir),
        str(liberty_dir),
    ],
    check=False,
    capture_output=True,
    text=True,
)
if redaction.returncode:
    raise SystemExit(redaction.stderr.strip() or "secret-like artifact content detected")
(otel_dir / "redaction-check.txt").write_text(
    "redaction and secret-pattern check passed\n" + redaction.stdout
)

release_file = pathlib.Path(os.environ["JAVA_HOME"]) / "release"
release_text = release_file.read_text()
java_match = re.search(r'^JAVA_VERSION="([^"]+)"$', release_text, re.MULTILINE)
if not java_match or not java_match.group(1).startswith("17"):
    raise SystemExit("Java 17 version could not be verified from JAVA_HOME")
maven_wrapper = (root.parent / ".mvn/wrapper/maven-wrapper.properties").read_text()
maven_match = re.search(r"apache-maven-([0-9.]+)-bin\.zip", maven_wrapper)
if not maven_match:
    raise SystemExit("Maven Wrapper distribution version could not be resolved")
pom = ElementTree.parse(root / "pom.xml").getroot()
namespace = {"m": "http://maven.apache.org/POM/4.0.0"}
liberty_element = pom.find(".//m:liberty.runtime.version", namespace)
if liberty_element is None or not liberty_element.text:
    raise SystemExit("Open Liberty runtime version could not be resolved")

event_is_pr = os.environ["GITHUB_EVENT_NAME"] == "pull_request"
pr_number = os.environ.get("CI_PR_NUMBER", "")
if event_is_pr and (not pr_number.isdigit() or int(pr_number) <= 0):
    raise SystemExit("CI_PR_NUMBER must be a positive integer for pull requests")
base_url = (
    f"{os.environ['GITHUB_SERVER_URL']}/{os.environ['GITHUB_REPOSITORY']}"
)
started = os.environ.get("CI_STARTED_AT")
if not started:
    raise SystemExit("CI_STARTED_AT is required")
ended = os.environ.get("CI_ENDED_AT") or datetime.now(timezone.utc).isoformat()
versions = {}
for line in (root / "observability/versions.properties").read_text().splitlines():
    key, separator, version = line.partition("=")
    if separator:
        versions[key] = version
agent_version = versions.get("otel.javaagent.version")
collector_image = versions.get("otel.collector.image")
if not agent_version or not versions.get("otel.javaagent.sha256") or not collector_image:
    raise SystemExit("OpenTelemetry version pins are incomplete")
metadata_template = {
    "schema": 1,
    "concern": "OpenTelemetry runtime observability",
    "repository": os.environ["GITHUB_REPOSITORY"],
    "ref": os.environ["GITHUB_REF"],
    "sha": os.environ["GITHUB_SHA"],
    "workflow": os.environ["GITHUB_WORKFLOW"],
    "run": os.environ["GITHUB_RUN_ID"],
    "attempt": os.environ["GITHUB_RUN_ATTEMPT"],
    "url": f"{base_url}/actions/runs/{os.environ['GITHUB_RUN_ID']}",
    "job": os.environ["GITHUB_JOB"],
    "event": os.environ["GITHUB_EVENT_NAME"],
    "pr": pr_number if event_is_pr else "not-applicable",
    "runner": {
        "os": os.environ["RUNNER_OS"],
        "architecture": os.environ["RUNNER_ARCH"],
    },
    "tools": {
        "java": java_match.group(1),
        "maven": maven_match.group(1),
        "openLibertyRuntime": liberty_element.text,
        "openTelemetryJavaAgent": agent_version,
        "openTelemetryJavaAgentSha256": versions["otel.javaagent.sha256"],
        "openTelemetryCollectorImage": collector_image,
    },
    "startedAt": started,
    "endedAt": ended,
    "commands": commands,
    "redactionResult": "passed",
}

for directory, name in (
    (otel_dir, "otel-telemetry"),
    (liberty_dir, "liberty-logs"),
):
    files = []
    for file in sorted(directory.rglob("*")):
        if file.is_file() and file.name != "artifact-metadata.json":
            content = file.read_bytes()
            files.append(
                {
                    "path": file.relative_to(directory).as_posix(),
                    "bytes": len(content),
                    "sha256": hashlib.sha256(content).hexdigest(),
                }
            )
    if not files:
        raise SystemExit(f"empty artifact inventory: {name}")
    metadata = dict(metadata_template)
    metadata["name"] = name
    metadata["concern"] = (
        "OpenTelemetry traces and JVM metrics"
        if name == "otel-telemetry"
        else "bounded Open Liberty diagnostics correlated with telemetry"
    )
    metadata["files"] = files
    (directory / "artifact-metadata.json").write_text(
        json.dumps(metadata, indent=2) + "\n"
    )
