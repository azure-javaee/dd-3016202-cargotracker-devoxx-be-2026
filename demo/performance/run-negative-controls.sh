#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
scratch="$(mktemp -d "${RUNNER_TEMP:-/tmp}/cargo-tracker-performance-controls.XXXXXX")"
trap 'rm -rf "$scratch"' EXIT

if [[ -z "${JAVA_HOME:-}" || ! -f "$JAVA_HOME/release" ]]; then
  echo "Java 17 JAVA_HOME is required for performance negative controls" >&2
  exit 1
fi

expect_rejection() {
  local name="$1"
  local expected="$2"
  shift 2
  local output="$scratch/$name"
  mkdir -p "$output/artifacts"
  if env \
    -u JAVA_TOOL_OPTIONS -u _JAVA_OPTIONS -u JDK_JAVA_OPTIONS \
    -u JAVA_OPTS -u JVM_ARGS -u MAVEN_OPTS \
    -u JAZ_IGNORE_USER_TUNING -u JAZ_BYPASS -u JAZ_DRY_RUN \
    -u JAZ_EXIT_WITHOUT_FLUSH \
    "JAVA_HOME=$JAVA_HOME" \
    "RUNNER_TEMP=$scratch" \
    "PERFORMANCE_ARTIFACT_ROOT=$output/artifacts" \
    "$@" \
    "$root/performance/run-workload.sh" > "$output/transcript.txt" 2>&1; then
    echo "performance harness accepted prohibited input: $name" >&2
    exit 1
  fi
  if ! grep -Fq "$expected" "$output/transcript.txt"; then
    echo "performance harness rejected $name for an unexpected reason" >&2
    cat "$output/transcript.txt" >&2
    exit 1
  fi
  if find "$output/artifacts" -name jaz-download.log -print -quit | grep -q .; then
    echo "performance harness started installation before rejecting $name" >&2
    exit 1
  fi
  printf 'expected rejection passed: %s\n' "$name"
}

expect_rejection heap-tuning \
  'user-provided JVM tuning is not allowed (JAVA_TOOL_OPTIONS)' \
  JAVA_TOOL_OPTIONS=-Xmx256m
expect_rejection ignore-user-tuning \
  'JAZ_IGNORE_USER_TUNING must not be set for the comparison' \
  JAZ_IGNORE_USER_TUNING=1
expect_rejection external-bypass \
  'JAZ launcher variables must be controlled by the harness' \
  JAZ_BYPASS=1
expect_rejection external-dry-run \
  'JAZ launcher variables must be controlled by the harness' \
  JAZ_DRY_RUN=1
expect_rejection external-exit-without-flush \
  'JAZ launcher variables must be controlled by the harness' \
  JAZ_EXIT_WITHOUT_FLUSH=1
