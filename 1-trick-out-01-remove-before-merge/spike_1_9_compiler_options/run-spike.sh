#!/usr/bin/env bash

set -euo pipefail

WORKTREE="/home/edburns/workareas/dd-3016202-cargotracker-devoxx-be-2026-02"
SPIKE="${WORKTREE}/1-trick-out-01-remove-before-merge/spike_1_9_compiler_options"
SCRATCH="${SPIKE}/scratch"
LOG_DIRECTORY="${SPIKE}/logs"
INVENTORY_DIRECTORY="${SPIKE}/inventories"
MAVEN_REPOSITORY="${SPIKE}/maven-repository"
SUMMARY_FILE="${SPIKE}/run-summary.tsv"
WARNINGS_FILE="${SPIKE}/warnings.tsv"
BASELINE="$(git -C "${WORKTREE}" rev-parse HEAD)"

export JAVA_HOME="/usr/lib/jvm/msopenjdk-17-amd64"
export ANT_HOME="/usr/share/ant"
export M2_HOME="/usr/share/maven"
export PATH="${M2_HOME}/bin:${ANT_HOME}/bin:${JAVA_HOME}/bin:${PATH}"

mkdir -p \
  "${SCRATCH}" \
  "${LOG_DIRECTORY}" \
  "${INVENTORY_DIRECTORY}" \
  "${MAVEN_REPOSITORY}"

rm -rf "${SCRATCH}/xlint-all"
rm -rf "${SCRATCH}/xlint-all-werror"
rm -rf "${SCRATCH}/xlint-clean-subset"
rm -rf "${SCRATCH}/type-failure"
rm -rf "${SCRATCH}/category-"*
rm -f "${LOG_DIRECTORY}"/*.txt "${INVENTORY_DIRECTORY}"/*.txt

printf 'case\tlint_arguments\texpected_status\tactual_status\telapsed_seconds\twarning_count\tlog\tinventory\n' > "${SUMMARY_FILE}"

configure_compiler() {
  local pom="$1"
  shift

  python3 - "${pom}" "$@" <<'PY'
from pathlib import Path
import sys
import xml.etree.ElementTree as ET

pom = Path(sys.argv[1])
arguments = sys.argv[2:]

ET.register_namespace("", "http://maven.apache.org/POM/4.0.0")
ET.register_namespace("xsi", "http://www.w3.org/2001/XMLSchema-instance")
namespace = "http://maven.apache.org/POM/4.0.0"
q = lambda name: f"{{{namespace}}}{name}"

tree = ET.parse(pom)
root = tree.getroot()

for plugin in root.findall(f".//{q('plugin')}"):
    artifact_id = plugin.find(q("artifactId"))
    if artifact_id is None or artifact_id.text != "maven-compiler-plugin":
        continue

    configuration = plugin.find(q("configuration"))
    if configuration is None:
        configuration = ET.SubElement(plugin, q("configuration"))

    show_warnings = configuration.find(q("showWarnings"))
    if show_warnings is None:
        show_warnings = ET.SubElement(configuration, q("showWarnings"))
    show_warnings.text = "true"

    existing = configuration.find(q("compilerArgs"))
    if existing is not None:
        configuration.remove(existing)

    compiler_args = ET.SubElement(configuration, q("compilerArgs"))
    for argument in arguments:
        arg = ET.SubElement(compiler_args, q("arg"))
        arg.text = argument
    break
else:
    raise SystemExit("maven-compiler-plugin not found")

ET.indent(tree, space="\t")
tree.write(pom, encoding="UTF-8", xml_declaration=True)
PY
}

clone_case() {
  local case_name="$1"
  local clone="${SCRATCH}/${case_name}"

  git clone --shared --quiet "${WORKTREE}" "${clone}"
  git -C "${clone}" checkout --quiet "${BASELINE}"
  printf '%s\n' "${clone}"
}

run_compile_case() {
  local sequence="$1"
  local case_name="$2"
  local expected_status="$3"
  shift 3
  local arguments=("$@")
  local clone
  local timestamp
  local log
  local inventory
  local start
  local end
  local status
  local warning_count
  local argument_text

  clone="$(clone_case "${case_name}")"
  configure_compiler "${clone}/demo/pom.xml" "${arguments[@]}"

  timestamp="$(date +%Y%m%d-%H%M)"
  log="${LOG_DIRECTORY}/${timestamp}-${sequence}-${case_name}-job-logs.txt"
  inventory="${INVENTORY_DIRECTORY}/${case_name}.txt"
  argument_text="${arguments[*]}"
  start="$(date +%s)"

  set +e
  (
    cd "${clone}/demo"
    /usr/bin/time -v ./mvnw \
      --batch-mode \
      --no-transfer-progress \
      -Dmaven.repo.local="${MAVEN_REPOSITORY}" \
      '-P!openliberty' \
      -DskipTests \
      clean compile
  ) 2>&1 | tee "${log}"
  status="${PIPESTATUS[0]}"
  set -e

  end="$(date +%s)"
  warning_count="$(grep -Ec '^\[WARNING\] .*\.java:\[[0-9]+,[0-9]+\] ' "${log}" || true)"

  {
    printf 'case=%s\n' "${case_name}"
    printf 'baseline=%s\n' "${BASELINE}"
    printf 'compiler_arguments=%s\n' "${argument_text}"
    printf 'expected_status=%s\n' "${expected_status}"
    printf 'actual_status=%s\n' "${status}"
    printf 'elapsed_seconds=%s\n' "$((end - start))"
    printf 'warning_count=%s\n' "${warning_count}"
    printf '\n[compiler configuration]\n'
    grep -A20 -B2 '<artifactId>maven-compiler-plugin</artifactId>' \
      "${clone}/demo/pom.xml"
    printf '\n[warning lines]\n'
    grep -E '^\[WARNING\] .*\.java:\[[0-9]+,[0-9]+\] ' \
      "${log}" || true
  } > "${inventory}"

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "${case_name}" \
    "${argument_text}" \
    "${expected_status}" \
    "${status}" \
    "$((end - start))" \
    "${warning_count}" \
    "${log#${SPIKE}/}" \
    "${inventory#${SPIKE}/}" >> "${SUMMARY_FILE}"
}

add_type_failure_fixture() {
  local clone="$1"
  local fixture="${clone}/demo/src/main/java/org/eclipse/cargotracker/compiler/TypeFailureFixture.java"

  mkdir -p "$(dirname "${fixture}")"
  cat > "${fixture}" <<'JAVA'
package org.eclipse.cargotracker.compiler;

import org.eclipse.cargotracker.domain.model.cargo.Cargo;

public final class TypeFailureFixture {
  private TypeFailureFixture() {}

  public static String callInventedApi(Cargo cargo) {
    return cargo.agentInventedMethod("not-real");
  }
}
JAVA
}

run_type_failure_case() {
  local sequence="99"
  local case_name="type-failure"
  local clone
  local timestamp
  local log
  local inventory
  local status

  clone="$(clone_case "${case_name}")"
  configure_compiler "${clone}/demo/pom.xml" "-Xlint:all"
  add_type_failure_fixture "${clone}"

  timestamp="$(date +%Y%m%d-%H%M)"
  log="${LOG_DIRECTORY}/${timestamp}-${sequence}-${case_name}-job-logs.txt"
  inventory="${INVENTORY_DIRECTORY}/${case_name}.txt"

  set +e
  (
    cd "${clone}/demo"
    /usr/bin/time -v ./mvnw \
      --batch-mode \
      --no-transfer-progress \
      -Dmaven.repo.local="${MAVEN_REPOSITORY}" \
      '-P!openliberty' \
      -DskipTests \
      clean compile
  ) 2>&1 | tee "${log}"
  status="${PIPESTATUS[0]}"
  set -e

  {
    printf 'case=%s\n' "${case_name}"
    printf 'expected_status=nonzero\n'
    printf 'actual_status=%s\n' "${status}"
    printf '\n[fixture]\n'
    cat "${clone}/demo/src/main/java/org/eclipse/cargotracker/compiler/TypeFailureFixture.java"
    printf '\n[compiler diagnostic]\n'
    grep -A8 -B3 'agentInventedMethod\|cannot find symbol' "${log}" || true
  } > "${inventory}"

  if [[ "${status}" -eq 0 ]]; then
    printf 'Type-failure fixture unexpectedly compiled\n' >&2
    exit 1
  fi
}

timestamp="$(date +%Y%m%d-%H%M)"
javac --help-lint 2>&1 |
  tee "${LOG_DIRECTORY}/${timestamp}-00-javac-help-lint-job-logs.txt"

run_compile_case 01 xlint-all 0 "-Xlint:all"

python3 - "${LOG_DIRECTORY}" "${WARNINGS_FILE}" <<'PY'
from pathlib import Path
import csv
import re
import sys

log_directory = Path(sys.argv[1])
output = Path(sys.argv[2])
log = next(log_directory.glob("*-01-xlint-all-job-logs.txt"))
pattern = re.compile(
    r"^\[WARNING\] (?P<path>.+\.java):\[(?P<line>\d+),(?P<column>\d+)\] "
    r"(?P<message>.*)$"
)
rows = []
for line in log.read_text(errors="replace").splitlines():
    match = pattern.match(line)
    if match:
        row = match.groupdict()
        message = row["message"]
        if "has no definition of serialVersionUID" in message:
            row["category"] = "serial"
        elif message.startswith("found raw type:"):
            row["category"] = "rawtypes"
        else:
            raise SystemExit(f"Unclassified compiler warning: {line}")
        rows.append(row)

with output.open("w", newline="") as stream:
    writer = csv.DictWriter(
        stream,
        fieldnames=["category", "path", "line", "column", "message"],
        delimiter="\t",
    )
    writer.writeheader()
    for row in rows:
        writer.writerow(
            {
                "category": row["category"],
                "path": row["path"].split("/demo/", 1)[-1],
                "line": row["line"],
                "column": row["column"],
                "message": row["message"],
            }
        )
PY

mapfile -t categories < <(
  tail -n +2 "${WARNINGS_FILE}" | cut -f1 | sort -u
)

run_compile_case 02 xlint-all-werror nonzero "-Xlint:all" "-Werror"

sequence=10
for category in "${categories[@]}"; do
  run_compile_case \
    "${sequence}" \
    "category-${category}" \
    nonzero \
    "-Xlint:${category}" \
    "-Werror"
  sequence=$((sequence + 1))
done

if [[ "${#categories[@]}" -gt 0 ]]; then
  disabled="$(
    printf '%s\n' "${categories[@]}" |
      sed 's/^/-/' |
      paste -sd, -
  )"
  clean_subset="-Xlint:all,${disabled}"
else
  clean_subset="-Xlint:all"
fi

run_compile_case 90 xlint-clean-subset 0 "${clean_subset}" "-Werror"
run_type_failure_case
