#!/usr/bin/env bash

set -euo pipefail

WORKTREE="/home/edburns/workareas/dd-3016202-cargotracker-devoxx-be-2026-02"
DEMO="${WORKTREE}/demo"
SPIKE="${WORKTREE}/1-trick-out-01-remove-before-merge/spike_1_3_validation_tier_selection"
MAVEN_REPOSITORY="${SPIKE}/maven-repository"
LOG_DIRECTORY="${SPIKE}/logs"
INVENTORY_DIRECTORY="${SPIKE}/inventories"
SUMMARY_FILE="${SPIKE}/run-summary.tsv"

export JAVA_HOME="/usr/lib/jvm/msopenjdk-17-amd64"
export ANT_HOME="/usr/share/ant"
export M2_HOME="/usr/share/maven"
export PATH="${M2_HOME}/bin:${ANT_HOME}/bin:${JAVA_HOME}/bin:${PATH}"

mkdir -p "${MAVEN_REPOSITORY}" "${LOG_DIRECTORY}" "${INVENTORY_DIRECTORY}"

printf 'phase\ttier\tcommand\texit_status\telapsed_seconds\trepository_bytes_before\trepository_bytes_after\trepository_delta_bytes\tdownload_lines\ttests\tfailures\terrors\tskipped\tliberty_directory\tliberty_bytes\tliberty_create_markers\tliberty_start_markers\tlog\tinventory\n' > "${SUMMARY_FILE}"

run_tier() {
  local phase="$1"
  local sequence="$2"
  local tier="$3"
  shift 3

  local timestamp
  local log
  local inventory
  local start
  local end
  local status
  local repository_bytes_before
  local repository_bytes_after
  local repository_delta_bytes
  local download_lines
  local liberty_directory
  local liberty_bytes
  local liberty_create_markers
  local liberty_start_markers
  local tests
  local failures
  local errors
  local skipped
  local command_text

  timestamp="$(date +%Y%m%d-%H%M)"
  log="${LOG_DIRECTORY}/${timestamp}-${sequence}-${phase}-${tier}-job-logs.txt"
  inventory="${INVENTORY_DIRECTORY}/${phase}-${tier}.txt"
  command_text="./mvnw -Dmaven.repo.local=${MAVEN_REPOSITORY} $*"
  repository_bytes_before="$(du -sb "${MAVEN_REPOSITORY}" | cut -f1)"
  start="$(date +%s)"

  set +e
  (
    cd "${DEMO}"
    /usr/bin/time -v ./mvnw \
      --batch-mode \
      --no-transfer-progress \
      -Dmaven.repo.local="${MAVEN_REPOSITORY}" \
      "$@"
  ) 2>&1 | tee "${log}"
  status="${PIPESTATUS[0]}"
  set -e

  end="$(date +%s)"
  repository_bytes_after="$(du -sb "${MAVEN_REPOSITORY}" | cut -f1)"
  repository_delta_bytes="$((repository_bytes_after - repository_bytes_before))"
  download_lines="$(grep -Ec 'Downloading from|Downloaded from' "${log}" || true)"

  if [[ -d "${DEMO}/target/liberty" ]]; then
    liberty_directory="yes"
    liberty_bytes="$(du -sb "${DEMO}/target/liberty" | cut -f1)"
  else
    liberty_directory="no"
    liberty_bytes="0"
  fi

  liberty_create_markers="$(grep -Eic 'liberty-maven-plugin[^:]*:.*create|Creating Liberty|Liberty installation directory' "${log}" || true)"
  liberty_start_markers="$(grep -Eic 'CWWKF0011I|server .* started|Launching .*server|arquillian.*container.*start' "${log}" || true)"

  read -r tests failures errors skipped < <(
    python3 - "${DEMO}/target/surefire-reports" <<'PY'
from pathlib import Path
import sys
import xml.etree.ElementTree as ET

directory = Path(sys.argv[1])
totals = {"tests": 0, "failures": 0, "errors": 0, "skipped": 0}
for report in directory.glob("TEST-*.xml") if directory.exists() else []:
    root = ET.parse(report).getroot()
    for key in totals:
        totals[key] += int(root.attrib.get(key, 0))
print(totals["tests"], totals["failures"], totals["errors"], totals["skipped"])
PY
  )

  {
    printf 'phase=%s\n' "${phase}"
    printf 'tier=%s\n' "${tier}"
    printf 'command=%s\n' "${command_text}"
    printf 'exit_status=%s\n' "${status}"
    printf 'elapsed_seconds=%s\n' "$((end - start))"
    printf 'maven_repository_bytes_before=%s\n' "${repository_bytes_before}"
    printf 'maven_repository_bytes_after=%s\n' "${repository_bytes_after}"
    printf 'maven_repository_delta_bytes=%s\n' "${repository_delta_bytes}"
    printf 'download_log_lines=%s\n' "${download_lines}"
    printf 'tests=%s\nfailures=%s\nerrors=%s\nskipped=%s\n' \
      "${tests}" "${failures}" "${errors}" "${skipped}"
    printf 'liberty_directory=%s\n' "${liberty_directory}"
    printf 'liberty_bytes=%s\n' "${liberty_bytes}"
    printf 'liberty_create_markers=%s\n' "${liberty_create_markers}"
    printf 'liberty_start_markers=%s\n' "${liberty_start_markers}"
    printf '\n[target top-level]\n'
    if [[ -d "${DEMO}/target" ]]; then
      find "${DEMO}/target" -mindepth 1 -maxdepth 2 -printf '%y %p %s bytes\n' | sort
    else
      printf 'target directory absent\n'
    fi
    printf '\n[surefire reports]\n'
    if [[ -d "${DEMO}/target/surefire-reports" ]]; then
      find "${DEMO}/target/surefire-reports" -maxdepth 1 -type f -printf '%f %s bytes\n' | sort
    else
      printf 'surefire reports absent\n'
    fi
    printf '\n[liberty top-level]\n'
    if [[ -d "${DEMO}/target/liberty" ]]; then
      find "${DEMO}/target/liberty" -mindepth 1 -maxdepth 3 -printf '%y %p %s bytes\n' | sort
    else
      printf 'liberty directory absent\n'
    fi
  } > "${inventory}"

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "${phase}" \
    "${tier}" \
    "${command_text}" \
    "${status}" \
    "$((end - start))" \
    "${repository_bytes_before}" \
    "${repository_bytes_after}" \
    "${repository_delta_bytes}" \
    "${download_lines}" \
    "${tests}" \
    "${failures}" \
    "${errors}" \
    "${skipped}" \
    "${liberty_directory}" \
    "${liberty_bytes}" \
    "${liberty_create_markers}" \
    "${liberty_start_markers}" \
    "${log#${SPIKE}/}" \
    "${inventory#${SPIKE}/}" >> "${SUMMARY_FILE}"

  return 0
}

run_sequence() {
  local phase="$1"
  local base_sequence="$2"

  rm -rf "${DEMO}/target"

  run_tier "${phase}" "$((base_sequence + 0))" environment -version
  run_tier "${phase}" "$((base_sequence + 1))" formatting spotless:check
  run_tier "${phase}" "$((base_sequence + 2))" test clean test
  run_tier "${phase}" "$((base_sequence + 3))" package clean package --file pom.xml
  run_tier "${phase}" "$((base_sequence + 4))" verify -Popenliberty verify
}

if find "${MAVEN_REPOSITORY}" -mindepth 1 -print -quit | grep -q .; then
  printf 'Refusing to start: isolated Maven repository is not empty: %s\n' \
    "${MAVEN_REPOSITORY}" >&2
  exit 1
fi

run_sequence cold 1
run_sequence warm 6
