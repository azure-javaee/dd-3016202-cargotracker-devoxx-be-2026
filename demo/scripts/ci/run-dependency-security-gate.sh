#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"
report="$root/ci-artifacts/dependency-reports/vulnerability-report.json"
summary="$root/ci-artifacts/dependency-reports/vulnerability-report.txt"
mkdir -p "$(dirname "$report")"

if [[ "${CI_EVENT:-}" == "pull_request" ]]; then
  : "${CI_BASE_SHA:?CI_BASE_SHA is required for pull-request dependency comparison}"
  gh api \
    -H 'Accept: application/vnd.github+json' \
    "repos/${GITHUB_REPOSITORY}/dependency-graph/compare/${CI_BASE_SHA}...${GITHUB_SHA}" \
    > "$report"
  jq -e 'type == "object"' "$report" >/dev/null
  if jq -e '
      [.changed_dependencies[]?, .removed_dependencies[]?]
      | map(.vulnerabilities[]? | select((.severity // "") | ascii_downcase == "high" or ascii_downcase == "critical"))
      | length > 0
    ' "$report" >/dev/null; then
    echo "new high-severity dependency findings detected" >&2
    exit 1
  fi
else
  gh api \
    -H 'Accept: application/vnd.github+json' \
    "repos/${GITHUB_REPOSITORY}/dependency-graph/sbom" \
    > "$report"
  jq -e '.sbom and (.sbom.packages | length > 0)' "$report" >/dev/null
fi

jq . "$report" > "$summary"
