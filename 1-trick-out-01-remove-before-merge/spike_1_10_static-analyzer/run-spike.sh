#!/usr/bin/env bash

set -euo pipefail

WORKTREE="/home/edburns/workareas/dd-3016202-cargotracker-devoxx-be-2026-02"
SPIKE="${WORKTREE}/1-trick-out-01-remove-before-merge/spike_1_10_static-analyzer"
SCRATCH="${SPIKE}/scratch"
LOG_DIRECTORY="${SPIKE}/logs"
REPORT_DIRECTORY="${SPIKE}/reports"
SUMMARY_FILE="${SPIKE}/run-summary.tsv"
SPOTBUGS_PLUGIN_VERSION="4.10.4.1"
PMD_PLUGIN_VERSION="3.28.0"
HEAD_SHA="$(git -C "${WORKTREE}" rev-parse HEAD)"

export JAVA_HOME="/usr/lib/jvm/msopenjdk-17-amd64"
export ANT_HOME="/usr/share/ant"
export M2_HOME="/usr/share/maven"
export PATH="${M2_HOME}/bin:${ANT_HOME}/bin:${JAVA_HOME}/bin:${PATH}"

mkdir -p "${SCRATCH}" "${LOG_DIRECTORY}" "${REPORT_DIRECTORY}"
rm -rf "${SCRATCH}/spotbugs" "${SCRATCH}/pmd"
rm -f "${LOG_DIRECTORY}"/*.txt "${REPORT_DIRECTORY}"/*

printf 'tool\tphase\texit_status\telapsed_seconds\tfindings\treport\tlog\n' > "${SUMMARY_FILE}"

prepare_clone() {
  local tool="$1"
  local clone="${SCRATCH}/${tool}"

  git clone --shared --quiet "${WORKTREE}" "${clone}"
  git -C "${clone}" checkout --quiet "${HEAD_SHA}"
}

inject_plugin() {
  local tool="$1"
  local clone="${SCRATCH}/${tool}"

  python3 - "${clone}/demo/pom.xml" "${tool}" \
    "${SPOTBUGS_PLUGIN_VERSION}" "${PMD_PLUGIN_VERSION}" <<'PY'
from pathlib import Path
import sys
import xml.etree.ElementTree as ET

pom = Path(sys.argv[1])
tool = sys.argv[2]
spotbugs_version = sys.argv[3]
pmd_version = sys.argv[4]

ET.register_namespace("", "http://maven.apache.org/POM/4.0.0")
ET.register_namespace("xsi", "http://www.w3.org/2001/XMLSchema-instance")
namespace = "http://maven.apache.org/POM/4.0.0"
q = lambda name: f"{{{namespace}}}{name}"

tree = ET.parse(pom)
project = tree.getroot()
plugins = project.find(f"{q('build')}/{q('plugins')}")
plugin = ET.SubElement(plugins, q("plugin"))
configuration = ET.SubElement(plugin, q("configuration"))

if tool == "spotbugs":
    ET.SubElement(plugin, q("groupId")).text = "com.github.spotbugs"
    ET.SubElement(plugin, q("artifactId")).text = "spotbugs-maven-plugin"
    ET.SubElement(plugin, q("version")).text = spotbugs_version
    ET.SubElement(configuration, q("effort")).text = "Max"
    ET.SubElement(configuration, q("threshold")).text = "Low"
    ET.SubElement(configuration, q("excludeFilterFile")).text = (
        "${project.basedir}/config/spotbugs-exclude.xml"
    )
    ET.SubElement(configuration, q("xmlOutput")).text = "true"
    ET.SubElement(configuration, q("xmlOutputDirectory")).text = (
        "${project.build.directory}/analyzer-reports"
    )
    ET.SubElement(configuration, q("failOnError")).text = "true"
elif tool == "pmd":
    ET.SubElement(plugin, q("groupId")).text = "org.apache.maven.plugins"
    ET.SubElement(plugin, q("artifactId")).text = "maven-pmd-plugin"
    ET.SubElement(plugin, q("version")).text = pmd_version
    rulesets = ET.SubElement(configuration, q("rulesets"))
    ET.SubElement(rulesets, q("ruleset")).text = (
        "${project.basedir}/config/pmd-ruleset.xml"
    )
    ET.SubElement(configuration, q("failOnViolation")).text = "false"
    ET.SubElement(configuration, q("printFailingErrors")).text = "true"
    ET.SubElement(configuration, q("includeTests")).text = "false"
    ET.SubElement(configuration, q("linkXRef")).text = "false"
else:
    raise SystemExit(f"Unknown tool: {tool}")

ET.indent(tree, space="\t")
tree.write(pom, encoding="UTF-8", xml_declaration=True)
PY

  mkdir -p "${clone}/demo/config"
  if [[ "${tool}" == "spotbugs" ]]; then
    cat > "${clone}/demo/config/spotbugs-exclude.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<FindBugsFilter>
	<Match>
		<Or>
			<Bug category="MALICIOUS_CODE"/>
			<Bug category="BAD_PRACTICE"/>
			<Bug category="STYLE"/>
			<Bug category="I18N"/>
			<Bug category="PERFORMANCE"/>
		</Or>
	</Match>
</FindBugsFilter>
XML
  else
    cat > "${clone}/demo/config/pmd-ruleset.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<ruleset name="Cargo Tracker focused correctness and security"
	xmlns="http://pmd.sourceforge.net/ruleset/2.0.0"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://pmd.sourceforge.net/ruleset/2.0.0 https://pmd.sourceforge.io/ruleset_2_0_0.xsd">
	<description>
		Correctness and security rules only. Formatting remains owned by Spotless.
	</description>
	<rule ref="category/java/errorprone.xml/AssignmentInOperand"/>
	<rule ref="category/java/errorprone.xml/AvoidCatchingNPE"/>
	<rule ref="category/java/errorprone.xml/CloseResource"/>
	<rule ref="category/java/errorprone.xml/ConstructorCallsOverridableMethod"/>
	<rule ref="category/java/errorprone.xml/NonSerializableClass"/>
	<rule ref="category/java/errorprone.xml/SimpleDateFormatNeedsLocale"/>
	<rule ref="category/java/errorprone.xml/UnusedNullCheckInEquals"/>
	<rule ref="category/java/errorprone.xml/UseLocaleWithCaseConversions"/>
	<rule ref="category/java/security.xml"/>
</ruleset>
XML
  fi
}

add_fixture() {
  local clone="$1"
  local fixture="${clone}/demo/src/main/java/org/eclipse/cargotracker/analysis/AnalyzerFailureFixture.java"

  mkdir -p "$(dirname "${fixture}")"
  cat > "${fixture}" <<'JAVA'
package org.eclipse.cargotracker.analysis;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;

public final class AnalyzerFailureFixture {

    public int dereferenceNull() {
        Object value = null;
        return value.hashCode();
    }

    public int leakResource(Path path) throws IOException {
        InputStream input = Files.newInputStream(path);
        return input.read();
    }
}
JAVA
}

count_findings() {
  local tool="$1"
  local report="$2"

  python3 - "${tool}" "${report}" <<'PY'
import sys
import xml.etree.ElementTree as ET

tool, report = sys.argv[1:]
root = ET.parse(report).getroot()
if tool == "spotbugs":
    print(len(root.findall("BugInstance")))
else:
    print(sum(1 for element in root.iter() if element.tag.endswith("violation")))
PY
}

run_analysis() {
  local tool="$1"
  local phase="$2"
  local sequence="$3"
  local clone="${SCRATCH}/${tool}"
  local timestamp
  local log
  local start
  local end
  local status
  local source_report
  local destination_report
  local findings
  local -a goals

  if [[ "${tool}" == "spotbugs" ]]; then
    goals=(compile com.github.spotbugs:spotbugs-maven-plugin:${SPOTBUGS_PLUGIN_VERSION}:spotbugs)
    source_report="${clone}/demo/target/spotbugsXml.xml"
  else
    goals=(compile org.apache.maven.plugins:maven-pmd-plugin:${PMD_PLUGIN_VERSION}:pmd)
    source_report="${clone}/demo/target/pmd.xml"
  fi

  timestamp="$(date +%Y%m%d-%H%M)"
  log="${LOG_DIRECTORY}/${timestamp}-${sequence}-${tool}-${phase}-job-logs.txt"
  destination_report="${REPORT_DIRECTORY}/${tool}-${phase}.xml"
  start="$(date +%s)"

  set +e
  (
    cd "${clone}/demo"
    ./mvnw --batch-mode --no-transfer-progress "${goals[@]}"
  ) 2>&1 | tee "${log}"
  status="${PIPESTATUS[0]}"
  set -e

  end="$(date +%s)"
  if [[ ! -f "${source_report}" ]]; then
    printf 'Expected report missing: %s\n' "${source_report}" >&2
    exit 1
  fi
  cp "${source_report}" "${destination_report}"
  findings="$(count_findings "${tool}" "${destination_report}")"

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "${tool}" \
    "${phase}" \
    "${status}" \
    "$((end - start))" \
    "${findings}" \
    "${destination_report#${SPIKE}/}" \
    "${log#${SPIKE}/}" >> "${SUMMARY_FILE}"
}

write_findings_tsv() {
  python3 - "${REPORT_DIRECTORY}" <<'PY'
from pathlib import Path
import csv
import sys
import xml.etree.ElementTree as ET

reports = Path(sys.argv[1])

for report in sorted(reports.glob("spotbugs-*.xml")):
    phase = report.stem.removeprefix("spotbugs-")
    root = ET.parse(report).getroot()
    output = reports / f"spotbugs-{phase}-findings.tsv"
    with output.open("w", newline="") as stream:
        writer = csv.writer(stream, delimiter="\t")
        writer.writerow(["priority", "rank", "category", "type", "class", "source", "line", "message"])
        for bug in root.findall("BugInstance"):
            clazz = bug.find("Class")
            source = bug.find("SourceLine")
            message = bug.findtext("LongMessage", default="")
            writer.writerow([
                bug.get("priority", ""),
                bug.get("rank", ""),
                bug.get("category", ""),
                bug.get("type", ""),
                clazz.get("classname", "") if clazz is not None else "",
                source.get("sourcepath", "") if source is not None else "",
                source.get("start", "") if source is not None else "",
                message.replace("\t", " ").replace("\n", " "),
            ])

for report in sorted(reports.glob("pmd-*.xml")):
    phase = report.stem.removeprefix("pmd-")
    root = ET.parse(report).getroot()
    output = reports / f"pmd-{phase}-findings.tsv"
    with output.open("w", newline="") as stream:
        writer = csv.writer(stream, delimiter="\t")
        writer.writerow(["priority", "ruleset", "rule", "file", "beginline", "endline", "message"])
        for file_element in (element for element in root.iter() if element.tag.endswith("file")):
            for violation in (element for element in file_element if element.tag.endswith("violation")):
                writer.writerow([
                    violation.get("priority", ""),
                    violation.get("ruleset", ""),
                    violation.get("rule", ""),
                    file_element.get("name", ""),
                    violation.get("beginline", ""),
                    violation.get("endline", ""),
                    (violation.text or "").strip().replace("\t", " ").replace("\n", " "),
                ])
PY
}

prepare_clone spotbugs
inject_plugin spotbugs
run_analysis spotbugs baseline 01
add_fixture "${SCRATCH}/spotbugs"
run_analysis spotbugs fixture 02

prepare_clone pmd
inject_plugin pmd
run_analysis pmd baseline 03
add_fixture "${SCRATCH}/pmd"
run_analysis pmd fixture 04

write_findings_tsv

if ! grep -q 'AnalyzerFailureFixture' "${REPORT_DIRECTORY}/spotbugs-fixture-findings.tsv"; then
  printf 'SpotBugs did not detect the failure fixture.\n' >&2
  exit 1
fi
if ! grep -q 'AnalyzerFailureFixture' "${REPORT_DIRECTORY}/pmd-fixture-findings.tsv"; then
  printf 'PMD did not detect the failure fixture.\n' >&2
  exit 1
fi

rm -rf "${SCRATCH}/spotbugs" "${SCRATCH}/pmd"
