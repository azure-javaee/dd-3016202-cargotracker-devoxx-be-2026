#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"
report="$root/ci-artifacts/dependency-reports/vulnerability-report.json"
baseline_report="$root/ci-artifacts/dependency-reports/baseline-vulnerability-report.json"
summary="$root/ci-artifacts/dependency-reports/vulnerability-report.txt"
scanner_version="11.1.0"
data_dir="${DEPENDENCY_CHECK_DATA_DIR:-$HOME/.dependency-check-data}"
mkdir -p "$(dirname "$report")"
mkdir -p "$data_dir"

if [[ "${CI_EVENT:-}" == "pull_request" ]]; then
  : "${CI_BASE_SHA:?CI_BASE_SHA is required for pull-request dependency comparison}"
  git cat-file -e "$CI_BASE_SHA:demo/pom.xml"
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
timeout --signal=TERM --kill-after=30s 8m ./mvnw "org.owasp:dependency-check-maven:${scanner_version}:aggregate" \
  -Dformat=JSON -DfailOnError=true -DskipTestScope=true \
  -DfailBuildOnCVSS=11 -DoutputDirectory="$root/ci-artifacts/dependency-reports" \
  -DdataDirectory="$data_dir" -DautoUpdate=true
mv "$root/ci-artifacts/dependency-reports/dependency-check-report.json" "$report"
if [[ ! -s "$report" ]]; then
  echo "ERROR: vulnerability report is missing or empty" >&2
  exit 1
fi

if [[ "${CI_EVENT:-}" == "pull_request" ]]; then
  cp -a "$data_dir" "$tmp/baseline-data"
  git show "$CI_BASE_SHA:demo/pom.xml" > "$tmp/pom.xml"
  timeout --signal=TERM --kill-after=30s 8m ./mvnw -f "$tmp/pom.xml" "org.owasp:dependency-check-maven:${scanner_version}:aggregate" \
    -Dformat=JSON -DfailOnError=true -DskipTestScope=true \
    -DfailBuildOnCVSS=11 -DoutputDirectory="$tmp/baseline" \
    -DdataDirectory="$tmp/baseline-data" -DautoUpdate=false
  cp "$tmp/baseline/dependency-check-report.json" "$baseline_report"
  jq -r '[.dependencies[]?.vulnerabilities[]? | select(((.severity // "") | ascii_downcase) as $severity | $severity == "high" or $severity == "critical") | .name] | unique[]?' \
    "$report" | sort -u > "$tmp/current-high"
  jq -r '[.dependencies[]?.vulnerabilities[]? | select(((.severity // "") | ascii_downcase) as $severity | $severity == "high" or $severity == "critical") | .name] | unique[]?' \
    "$tmp/baseline/dependency-check-report.json" | sort -u > "$tmp/baseline-high"
  comm -23 "$tmp/current-high" "$tmp/baseline-high" > "$tmp/new-high"
  {
    echo "OWASP Dependency-Check ${scanner_version}"
    echo "Historical findings are retained; only new HIGH/CRITICAL identifiers fail."
    echo "Current HIGH/CRITICAL: $(wc -l < "$tmp/current-high")"
    echo "Baseline HIGH/CRITICAL: $(wc -l < "$tmp/baseline-high")"
    echo "New HIGH/CRITICAL:"
    cat "$tmp/new-high"
  } > "$summary"
  if [[ -s "$tmp/new-high" ]]; then
    echo "new high-severity dependency findings detected" >&2
    exit 1
  fi
else
  cp -- "$report" "$baseline_report"
  {
    echo "OWASP Dependency-Check ${scanner_version}"
    echo "No comparison baseline is available for this event; baseline report mirrors the current scan."
  } > "$summary"
fi

jq -e '.dependencies | type == "array"' "$report" >/dev/null
