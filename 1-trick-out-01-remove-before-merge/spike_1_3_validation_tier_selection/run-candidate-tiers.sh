#!/usr/bin/env bash

set -euo pipefail

WORKTREE="/home/edburns/workareas/dd-3016202-cargotracker-devoxx-be-2026-02"
DEMO="${WORKTREE}/demo"
SPIKE="${WORKTREE}/1-trick-out-01-remove-before-merge/spike_1_3_validation_tier_selection"
RUN_LABEL="${RUN_LABEL:-candidate}"
MAVEN_REPOSITORY="${MAVEN_REPOSITORY_OVERRIDE:-${SPIKE}/maven-repository}"
LOG_DIRECTORY="${SPIKE}/${RUN_LABEL}-logs"
INVENTORY_DIRECTORY="${SPIKE}/${RUN_LABEL}-inventories"
SUMMARY_FILE="${SPIKE}/${RUN_LABEL}-summary.tsv"

export JAVA_HOME="/usr/lib/jvm/msopenjdk-17-amd64"
export ANT_HOME="/usr/share/ant"
export M2_HOME="/usr/share/maven"
export PATH="${M2_HOME}/bin:${ANT_HOME}/bin:${JAVA_HOME}/bin:${PATH}"

mkdir -p "${MAVEN_REPOSITORY}" "${LOG_DIRECTORY}" "${INVENTORY_DIRECTORY}"

printf 'tier\tcommand\texit_status\telapsed_seconds\trepository_delta_bytes\ttests\tfailures\terrors\tskipped\tliberty_directory\tliberty_start_markers\twar_exists\tlog\tinventory\n' > "${SUMMARY_FILE}"

run_candidate() {
  local sequence="$1"
  local tier="$2"
  shift 2

  local timestamp
  local log
  local inventory
  local start
  local end
  local status
  local repository_before
  local repository_after
  local liberty_directory
  local liberty_start_markers
  local war_exists
  local tests
  local failures
  local errors
  local skipped
  local command_text

  rm -rf "${DEMO}/target"

  timestamp="$(date +%Y%m%d-%H%M)"
  log="${LOG_DIRECTORY}/${timestamp}-${sequence}-${tier}-job-logs.txt"
  inventory="${INVENTORY_DIRECTORY}/${tier}.txt"
  command_text="./mvnw -Dmaven.repo.local=${MAVEN_REPOSITORY} $*"
  repository_before="$(du -sb "${MAVEN_REPOSITORY}" | cut -f1)"
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
  repository_after="$(du -sb "${MAVEN_REPOSITORY}" | cut -f1)"

  if [[ -d "${DEMO}/target/liberty" ]]; then
    liberty_directory="yes"
  else
    liberty_directory="no"
  fi

  liberty_start_markers="$(grep -Eic 'CWWKF0011I|server .* started|Launching .*server' "${log}" || true)"

  if [[ -f "${DEMO}/target/cargo-tracker.war" ]]; then
    war_exists="yes"
  else
    war_exists="no"
  fi

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
    printf 'tier=%s\ncommand=%s\nexit_status=%s\nelapsed_seconds=%s\n' \
      "${tier}" "${command_text}" "${status}" "$((end - start))"
    printf 'maven_repository_delta_bytes=%s\n' "$((repository_after - repository_before))"
    printf 'tests=%s\nfailures=%s\nerrors=%s\nskipped=%s\n' \
      "${tests}" "${failures}" "${errors}" "${skipped}"
    printf 'liberty_directory=%s\nliberty_start_markers=%s\nwar_exists=%s\n' \
      "${liberty_directory}" "${liberty_start_markers}" "${war_exists}"
    printf '\n[target top-level]\n'
    if [[ -d "${DEMO}/target" ]]; then
      find "${DEMO}/target" -mindepth 1 -maxdepth 2 -printf '%y %p %s bytes\n' | sort
    else
      printf 'target directory absent\n'
    fi
  } > "${inventory}"

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "${tier}" \
    "${command_text}" \
    "${status}" \
    "$((end - start))" \
    "$((repository_after - repository_before))" \
    "${tests}" \
    "${failures}" \
    "${errors}" \
    "${skipped}" \
    "${liberty_directory}" \
    "${liberty_start_markers}" \
    "${war_exists}" \
    "${log#${SPIKE}/}" \
    "${inventory#${SPIKE}/}" >> "${SUMMARY_FILE}"
}

run_candidate 1 build-contract \
  '-P!openliberty' -DskipTests clean compile

run_candidate 2 unit \
  '-P!openliberty' \
  -Dtest=CargoTest,ItineraryTest,RouteSpecificationTest,HandlingEventTest,HandlingHistoryTest \
  clean test

run_candidate 3 integration \
  -Popenliberty -Dtest=BookingServiceTest clean test

run_candidate 4 deployable-package \
  '-P!openliberty' -DskipTests clean package
