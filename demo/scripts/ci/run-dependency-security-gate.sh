#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"
repo_root="$(git rev-parse --show-toplevel)"
report="$root/ci-artifacts/dependency-reports/vulnerability-report.json"
baseline_report="$root/ci-artifacts/dependency-reports/baseline-vulnerability-report.json"
summary="$root/ci-artifacts/dependency-reports/vulnerability-report.txt"
dependency_plugin_version="3.7.0"
mkdir -p "$(dirname "$report")"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

write_inventory() {
  local pom="$1" output="$2"
  ./mvnw -f "$pom" \
    "org.apache.maven.plugins:maven-dependency-plugin:${dependency_plugin_version}:tree" \
    -DoutputType=json -Dverbose=false -DoutputFile="$output"
  jq -e 'type == "object" and (.groupId and .artifactId and .children)' "$output" >/dev/null
}

base_sha="${CI_BASE_SHA:-}"
if [[ "$base_sha" =~ ^0+$ ]]; then
  base_sha=""
fi
if [[ -z "$base_sha" ]]; then
  candidates=()
  if default_ref="$(git symbolic-ref --quiet refs/remotes/origin/HEAD)"; then
    candidates+=("${default_ref#refs/remotes/}")
  fi
  candidates+=("origin/edburns/dd-3016202-cargotracker-devoxx-be-2026-01")
  for candidate in "${candidates[@]}"; do
    if git rev-parse --verify "$candidate" >/dev/null 2>&1; then
      base_sha="$(git merge-base HEAD "$candidate")"
      break
    fi
  done
fi
if [[ -z "$base_sha" ]]; then
  echo "ERROR: unable to determine a dependency baseline SHA" >&2
  exit 1
fi
git cat-file -e "$base_sha:demo/pom.xml"
write_inventory "$root/pom.xml" "$tmp/current-tree.json"
mkdir -p "$tmp/base-root"
git -C "$repo_root" archive "$base_sha" | tar -x -C "$tmp/base-root"
write_inventory "$tmp/base-root/demo/pom.xml" "$tmp/base-tree.json"

python3 - "$tmp/current-tree.json" "$tmp/base-tree.json" "$tmp/current.json" "$tmp/base.json" <<'PY'
import json, pathlib, sys

def flatten(node, result):
    if node.get("groupId") and node.get("artifactId") and node.get("version"):
        result.append({
            "groupId": node["groupId"],
            "artifactId": node["artifactId"],
            "type": node.get("type", "jar"),
            "classifier": node.get("classifier", ""),
            "version": node["version"],
        })
    for child in node.get("children", []):
        flatten(child, result)

for source, destination in zip(sys.argv[1:3], sys.argv[3:]):
    values = []
    flatten(json.loads(pathlib.Path(source).read_text()), values)
    unique = {tuple(item.values()): item for item in values}
    pathlib.Path(destination).write_text(json.dumps(sorted(unique.values(),
        key=lambda item: tuple(item.values())), indent=2) + "\n")
PY

python3 - "$tmp/current.json" "$tmp/base.json" "$tmp/new.json" <<'PY'
import json, pathlib, sys
current = {tuple(item.values()): item for item in json.loads(pathlib.Path(sys.argv[1]).read_text())}
base = {tuple(item.values()): item for item in json.loads(pathlib.Path(sys.argv[2]).read_text())}
new = [current[key] for key in sorted(set(current) - set(base))]
pathlib.Path(sys.argv[3]).write_text(json.dumps(new, indent=2) + "\n")
PY

python3 - "$tmp/new.json" "$report" "$baseline_report" "$summary" "$tmp/current.json" "$tmp/base.json" <<'PY'
import json, pathlib, subprocess, sys, urllib.parse

new_path, report_path, baseline_path, summary_path, current_path, base_path = sys.argv[1:]
new = json.loads(pathlib.Path(new_path).read_text())
advisories = []
for coordinate in new:
    affects = f'{coordinate["groupId"]}:{coordinate["artifactId"]}@{coordinate["version"]}'
    for severity in ("high", "critical"):
        query = urllib.parse.urlencode({
            "ecosystem": "maven", "affects": affects, "severity": severity,
            "per_page": "100",
        })
        result = subprocess.run(["gh", "api", f"advisories?{query}"],
                                check=False, capture_output=True, text=True)
        if result.returncode:
            raise SystemExit(f"advisory query failed for {affects} ({severity}): {result.stderr}")
        try:
            values = json.loads(result.stdout)
        except json.JSONDecodeError as error:
            raise SystemExit(f"invalid advisory response for {affects}: {error}")
        if not isinstance(values, list):
            raise SystemExit(f"unexpected advisory response for {affects}")
        advisories.append({"coordinate": coordinate, "severity": severity,
                           "results": values})

payload = {
    "schema": 1,
    "scanner": {"name": "GitHub Advisory Database REST API", "endpoint": "/advisories",
                "ecosystem": "maven"},
    "policy": "Fail only for newly introduced HIGH or CRITICAL advisories.",
    "currentInventory": json.loads(pathlib.Path(current_path).read_text()),
    "baselineInventory": json.loads(pathlib.Path(base_path).read_text()),
    "newCoordinates": new,
    "advisories": advisories,
}
pathlib.Path(report_path).write_text(json.dumps(payload, indent=2) + "\n")
pathlib.Path(baseline_path).write_text(json.dumps({
    "schema": 1, "scanner": payload["scanner"],
    "baselineInventory": payload["baselineInventory"],
}, indent=2) + "\n")
matches = [item for item in advisories if item["results"]]
pathlib.Path(summary_path).write_text(
    "GitHub Advisory Database Maven delta gate\n"
    "New coordinates: %d\n"
    "HIGH/CRITICAL advisory queries with matches: %d\n"
    % (len(new), len(matches)))
if matches:
    raise SystemExit("new HIGH/CRITICAL Maven advisory detected")
PY
