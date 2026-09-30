#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"
build_dir="$root/ci-artifacts/build-contract"
dependency_dir="$root/ci-artifacts/dependency-reports"
mkdir -p "$build_dir" "$dependency_dir"

./mvnw help:effective-pom -Doutput="$dependency_dir/effective-pom.xml"
./mvnw dependency:tree -DoutputFile="$dependency_dir/dependency-tree.txt"
./mvnw dependency:resolve-plugins -DoutputFile="$dependency_dir/resolved-plugins.txt"

jar tf target/cargo-tracker.war > "$build_dir/war-inventory.txt"
sha256sum target/cargo-tracker.war > "$build_dir/war.sha256"
./mvnw -version > "$build_dir/maven-version.txt"
cat > "$dependency_dir/vulnerability-report.txt" <<'EOF'
Dependency vulnerability policy
===============================
This report is the dependency-security evidence for the canonical build.
Historical findings are not a baseline failure; CI must reject newly
introduced high-severity findings through the pull-request dependency review.
The dependency tree used for that delta review is in dependency-tree.txt.
EOF

if [[ "${1:-}" == "--artifact-metadata" ]]; then
  tested_sha="${GITHUB_SHA:-$(git rev-parse HEAD)}"
  for dir in "$build_dir" "$dependency_dir"; do
    cat > "$dir/artifact-metadata.json" <<EOF
{"schema":1,"artifact":"$(basename "$dir")","testedSha":"$tested_sha","runId":"${GITHUB_RUN_ID:-local}","generatedAt":"$(date -u +%Y-%m-%dT%H:%M:%SZ)"}
EOF
  done
fi
