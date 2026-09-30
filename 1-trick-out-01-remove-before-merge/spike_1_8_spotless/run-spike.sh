#!/usr/bin/env bash

set -euo pipefail

WORKTREE="/home/edburns/workareas/dd-3016202-cargotracker-devoxx-be-2026-02"
SPIKE="${WORKTREE}/1-trick-out-01-remove-before-merge/spike_1_8_spotless"
SCRATCH="${SPIKE}/scratch"
LOG_DIRECTORY="${SPIKE}/logs"
INVENTORY_DIRECTORY="${SPIKE}/inventories"
SUMMARY_FILE="${SPIKE}/run-summary.tsv"
HISTORICAL_BASELINE="1fd1c340fa56c6c77a601d2fbba20294afa46dd9"
PROPOSED_BASELINE="$(git -C "${WORKTREE}" rev-parse HEAD)"

export JAVA_HOME="/usr/lib/jvm/msopenjdk-17-amd64"
export ANT_HOME="/usr/share/ant"
export M2_HOME="/usr/share/maven"
export PATH="${M2_HOME}/bin:${ANT_HOME}/bin:${JAVA_HOME}/bin:${PATH}"

mkdir -p "${SCRATCH}" "${LOG_DIRECTORY}" "${INVENTORY_DIRECTORY}"
rm -rf "${SCRATCH}/historical-clean"
rm -rf "${SCRATCH}/proposed-clean"
rm -rf "${SCRATCH}/whole-tree"
rm -rf "${SCRATCH}/historical-fixture"
rm -rf "${SCRATCH}/proposed-fixture"
rm -rf "${SCRATCH}/advanced-malformed-baseline"
rm -f "${LOG_DIRECTORY}"/*.txt "${INVENTORY_DIRECTORY}"/*.txt

printf 'case\tpolicy\tfixture\tbaseline\tcheck_status\tapply_status\tchanged_java_files\tadded_lines\tdeleted_lines\tcheck_log\tapply_log\tinventory\n' > "${SUMMARY_FILE}"

configure_policy() {
  local pom="$1"
  local policy="$2"

  python3 - "${pom}" "${policy}" "${HISTORICAL_BASELINE}" "${PROPOSED_BASELINE}" <<'PY'
from pathlib import Path
import sys
import xml.etree.ElementTree as ET

pom = Path(sys.argv[1])
policy = sys.argv[2]
historical = sys.argv[3]
proposed = sys.argv[4]

ET.register_namespace("", "http://maven.apache.org/POM/4.0.0")
ET.register_namespace("xsi", "http://www.w3.org/2001/XMLSchema-instance")
namespace = "http://maven.apache.org/POM/4.0.0"
q = lambda name: f"{{{namespace}}}{name}"

tree = ET.parse(pom)
root = tree.getroot()
for plugin in root.findall(f".//{q('plugin')}"):
    artifact_id = plugin.find(q("artifactId"))
    if artifact_id is None or artifact_id.text != "spotless-maven-plugin":
        continue
    configuration = plugin.find(q("configuration"))
    ratchet = configuration.find(q("ratchetFrom"))
    if policy == "whole-tree":
        if ratchet is not None:
            configuration.remove(ratchet)
    else:
        if ratchet is None:
            ratchet = ET.SubElement(configuration, q("ratchetFrom"))
        ratchet.text = historical if policy == "historical" else proposed
    break
else:
    raise SystemExit("Spotless plugin not found")

ET.indent(tree, space="\t")
tree.write(pom, encoding="UTF-8", xml_declaration=True)
PY
}

add_failure_fixture() {
  local clone="$1"
  local fixture="${clone}/demo/src/test/java/org/eclipse/cargotracker/spotlessspike/BadFormatting.java"
  local cargo="${clone}/demo/src/main/java/org/eclipse/cargotracker/domain/model/cargo/Cargo.java"

  mkdir -p "$(dirname "${fixture}")"
  cat > "${fixture}" <<'JAVA'
package org.eclipse.cargotracker.spotlessspike;

public class BadFormatting {
public String value( ){return "bad";}
}
JAVA

  python3 - "${cargo}" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()
old = "public class Cargo implements Serializable {"
new = "public  class   Cargo implements Serializable {"
if old not in text:
    raise SystemExit(f"Expected declaration not found in {path}")
path.write_text(text.replace(old, new, 1))
PY

  git -C "${clone}" add \
    "demo/src/main/java/org/eclipse/cargotracker/domain/model/cargo/Cargo.java" \
    "demo/src/test/java/org/eclipse/cargotracker/spotlessspike/BadFormatting.java"
}

run_case() {
  local sequence="$1"
  local case_name="$2"
  local policy="$3"
  local fixture="$4"
  local clone="${SCRATCH}/${case_name}"
  local timestamp
  local check_log
  local apply_log
  local inventory
  local check_status
  local apply_status
  local changed_java_files
  local added_lines
  local deleted_lines
  local baseline

  git clone --shared --quiet "${WORKTREE}" "${clone}"
  git -C "${clone}" checkout --quiet "${PROPOSED_BASELINE}"
  configure_policy "${clone}/demo/pom.xml" "${policy}"

  if [[ "${fixture}" == "yes" ]]; then
    add_failure_fixture "${clone}"
  fi

  case "${policy}" in
    historical) baseline="${HISTORICAL_BASELINE}" ;;
    proposed) baseline="${PROPOSED_BASELINE}" ;;
    whole-tree) baseline="none" ;;
    *) printf 'Unknown policy: %s\n' "${policy}" >&2; exit 1 ;;
  esac

  timestamp="$(date +%Y%m%d-%H%M)"
  check_log="${LOG_DIRECTORY}/${timestamp}-${sequence}-${case_name}-check-job-logs.txt"
  apply_log="${LOG_DIRECTORY}/${timestamp}-${sequence}-${case_name}-apply-job-logs.txt"
  inventory="${INVENTORY_DIRECTORY}/${case_name}.txt"

  set +e
  (
    cd "${clone}/demo"
    ./mvnw --batch-mode --no-transfer-progress spotless:check
  ) 2>&1 | tee "${check_log}"
  check_status="${PIPESTATUS[0]}"

  (
    cd "${clone}/demo"
    ./mvnw --batch-mode --no-transfer-progress spotless:apply
  ) 2>&1 | tee "${apply_log}"
  apply_status="${PIPESTATUS[0]}"
  set -e

  changed_java_files="$(
    git -C "${clone}" diff --name-only HEAD -- 'demo/src/**/*.java' | wc -l
  )"
  read -r added_lines deleted_lines < <(
    git -C "${clone}" diff --numstat HEAD -- 'demo/src/**/*.java' |
      awk '{added += $1; deleted += $2} END {print added + 0, deleted + 0}'
  )

  {
    printf 'case=%s\n' "${case_name}"
    printf 'policy=%s\n' "${policy}"
    printf 'fixture=%s\n' "${fixture}"
    printf 'baseline=%s\n' "${baseline}"
    printf 'check_status=%s\n' "${check_status}"
    printf 'apply_status=%s\n' "${apply_status}"
    printf 'changed_java_files=%s\n' "${changed_java_files}"
    printf 'added_lines=%s\n' "${added_lines}"
    printf 'deleted_lines=%s\n' "${deleted_lines}"
    printf '\n[changed Java files after apply]\n'
    git -C "${clone}" diff --name-status HEAD -- 'demo/src/**/*.java'
    printf '\n[Java diff statistics after apply]\n'
    git -C "${clone}" diff --numstat HEAD -- 'demo/src/**/*.java'
    printf '\n[Spotless configuration]\n'
    grep -A12 -B2 '<artifactId>spotless-maven-plugin</artifactId>' \
      "${clone}/demo/pom.xml"
  } > "${inventory}"

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "${case_name}" \
    "${policy}" \
    "${fixture}" \
    "${baseline}" \
    "${check_status}" \
    "${apply_status}" \
    "${changed_java_files}" \
    "${added_lines}" \
    "${deleted_lines}" \
    "${check_log#${SPIKE}/}" \
    "${apply_log#${SPIKE}/}" \
    "${inventory#${SPIKE}/}" >> "${SUMMARY_FILE}"
}

run_advanced_malformed_baseline_case() {
  local sequence="06"
  local case_name="advanced-malformed-baseline"
  local clone="${SCRATCH}/${case_name}"
  local timestamp
  local check_log
  local apply_log
  local inventory
  local check_status
  local apply_status
  local advanced_baseline

  git clone --shared --quiet "${WORKTREE}" "${clone}"
  git -C "${clone}" checkout --quiet "${PROPOSED_BASELINE}"
  add_failure_fixture "${clone}"
  git -C "${clone}" \
    -c user.name="Spotless Spike" \
    -c user.email="spotless-spike@example.invalid" \
    commit --quiet -m "Synthetic malformed baseline"
  advanced_baseline="$(git -C "${clone}" rev-parse HEAD)"

  python3 - "${clone}/demo/pom.xml" "${HISTORICAL_BASELINE}" "${advanced_baseline}" <<'PY'
from pathlib import Path
import sys

pom = Path(sys.argv[1])
historical = sys.argv[2]
advanced = sys.argv[3]
text = pom.read_text()
if historical not in text:
    raise SystemExit("Historical ratchet not found")
pom.write_text(text.replace(historical, advanced, 1))
PY

  timestamp="$(date +%Y%m%d-%H%M)"
  check_log="${LOG_DIRECTORY}/${timestamp}-${sequence}-${case_name}-check-job-logs.txt"
  apply_log="${LOG_DIRECTORY}/${timestamp}-${sequence}-${case_name}-apply-job-logs.txt"
  inventory="${INVENTORY_DIRECTORY}/${case_name}.txt"

  set +e
  (
    cd "${clone}/demo"
    ./mvnw --batch-mode --no-transfer-progress spotless:check
  ) 2>&1 | tee "${check_log}"
  check_status="${PIPESTATUS[0]}"

  (
    cd "${clone}/demo"
    ./mvnw --batch-mode --no-transfer-progress spotless:apply
  ) 2>&1 | tee "${apply_log}"
  apply_status="${PIPESTATUS[0]}"
  set -e

  {
    printf 'case=%s\n' "${case_name}"
    printf 'policy=advanced-to-malformed-commit\n'
    printf 'fixture=committed-before-ratchet\n'
    printf 'baseline=%s\n' "${advanced_baseline}"
    printf 'check_status=%s\n' "${check_status}"
    printf 'apply_status=%s\n' "${apply_status}"
    printf '\n[committed malformed Java files]\n'
    git -C "${clone}" show --name-status --format= "${advanced_baseline}" -- \
      'demo/src/**/*.java'
    printf '\n[Java changes after apply]\n'
    git -C "${clone}" diff --name-status HEAD -- 'demo/src/**/*.java'
  } > "${inventory}"

  printf '%s\t%s\t%s\t%s\t%s\t%s\t0\t0\t0\t%s\t%s\t%s\n' \
    "${case_name}" \
    "advanced-to-malformed-commit" \
    "committed-before-ratchet" \
    "${advanced_baseline}" \
    "${check_status}" \
    "${apply_status}" \
    "${check_log#${SPIKE}/}" \
    "${apply_log#${SPIKE}/}" \
    "${inventory#${SPIKE}/}" >> "${SUMMARY_FILE}"
}

run_case 01 historical-clean historical no
run_case 02 proposed-clean proposed no
run_case 03 whole-tree whole-tree no
run_case 04 historical-fixture historical yes
run_case 05 proposed-fixture proposed yes
run_advanced_malformed_baseline_case

rm -rf "${SCRATCH}/historical-clean"
rm -rf "${SCRATCH}/proposed-clean"
rm -rf "${SCRATCH}/whole-tree"
rm -rf "${SCRATCH}/historical-fixture"
rm -rf "${SCRATCH}/proposed-fixture"
rm -rf "${SCRATCH}/advanced-malformed-baseline"
