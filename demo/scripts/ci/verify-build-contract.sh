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
