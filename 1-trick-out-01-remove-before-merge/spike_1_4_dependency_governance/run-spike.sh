#!/usr/bin/env bash

set -euo pipefail

WORKTREE="/home/edburns/workareas/dd-3016202-cargotracker-devoxx-be-2026-02"
DEMO="${WORKTREE}/demo"
SPIKE="${WORKTREE}/1-trick-out-01-remove-before-merge/spike_1_4_dependency_governance"
GENERATED_DIRECTORY="${SPIKE}/generated-poms"
LOG_DIRECTORY="${SPIKE}/logs"
SUMMARY_FILE="${SPIKE}/run-summary.tsv"
ENFORCER_VERSION="3.6.3"

export JAVA_HOME="/usr/lib/jvm/msopenjdk-17-amd64"
export ANT_HOME="/usr/share/ant"
export M2_HOME="/usr/share/maven"
export PATH="${M2_HOME}/bin:${ANT_HOME}/bin:${JAVA_HOME}/bin:${PATH}"

mkdir -p "${GENERATED_DIRECTORY}" "${LOG_DIRECTORY}"
rm -f "${GENERATED_DIRECTORY}"/*.xml "${LOG_DIRECTORY}"/*.txt

printf 'case\trule\tprofile\texpected\texit_status\toutcome\tlog\tpom\n' > "${SUMMARY_FILE}"

generate_pom() {
  local output_name="$1"
  local rule_xml="$2"
  local mutation="${3:-none}"

  python3 - "${DEMO}/pom.xml" "${GENERATED_DIRECTORY}/${output_name}.xml" \
    "${ENFORCER_VERSION}" "${rule_xml}" "${mutation}" <<'PY'
from pathlib import Path
import sys
import xml.etree.ElementTree as ET

source = Path(sys.argv[1])
destination = Path(sys.argv[2])
enforcer_version = sys.argv[3]
rule_xml = sys.argv[4]
mutation = sys.argv[5]

ET.register_namespace("", "http://maven.apache.org/POM/4.0.0")
ET.register_namespace("xsi", "http://www.w3.org/2001/XMLSchema-instance")
namespace = "http://maven.apache.org/POM/4.0.0"
q = lambda name: f"{{{namespace}}}{name}"

tree = ET.parse(source)
project = tree.getroot()

if mutation == "duplicate-dependency":
    dependencies = project.find(q("dependencies"))
    dependency = ET.SubElement(dependencies, q("dependency"))
    ET.SubElement(dependency, q("groupId")).text = "joda-time"
    ET.SubElement(dependency, q("artifactId")).text = "joda-time"
    ET.SubElement(dependency, q("version")).text = "2.12.7"
elif mutation == "banned-dependency":
    dependencies = project.find(q("dependencies"))
    dependency = ET.SubElement(dependencies, q("dependency"))
    ET.SubElement(dependency, q("groupId")).text = "jakarta.platform"
    ET.SubElement(dependency, q("artifactId")).text = "jakarta.jakartaee-api"
    ET.SubElement(dependency, q("version")).text = "10.0.0"
    ET.SubElement(dependency, q("scope")).text = "provided"
elif mutation == "repository":
    repositories = ET.SubElement(project, q("repositories"))
    repository = ET.SubElement(repositories, q("repository"))
    ET.SubElement(repository, q("id")).text = "unapproved-example"
    ET.SubElement(repository, q("url")).text = "https://repo.example.invalid/maven2"
elif mutation == "pin-demo-plugins":
    build = project.find(q("build"))
    plugins = build.find(q("plugins"))
    for artifact_id, version in (
        ("maven-clean-plugin", "3.2.0"),
        ("maven-resources-plugin", "3.3.1"),
    ):
        plugin = ET.SubElement(plugins, q("plugin"))
        ET.SubElement(plugin, q("groupId")).text = "org.apache.maven.plugins"
        ET.SubElement(plugin, q("artifactId")).text = artifact_id
        ET.SubElement(plugin, q("version")).text = version
elif mutation == "pin-demo-plugins-and-add-unversioned-plugin":
    build = project.find(q("build"))
    plugins = build.find(q("plugins"))
    for artifact_id, version in (
        ("maven-clean-plugin", "3.2.0"),
        ("maven-resources-plugin", "3.3.1"),
    ):
        plugin = ET.SubElement(plugins, q("plugin"))
        ET.SubElement(plugin, q("groupId")).text = "org.apache.maven.plugins"
        ET.SubElement(plugin, q("artifactId")).text = artifact_id
        ET.SubElement(plugin, q("version")).text = version
    plugin = ET.SubElement(plugins, q("plugin"))
    ET.SubElement(plugin, q("groupId")).text = "org.codehaus.mojo"
    ET.SubElement(plugin, q("artifactId")).text = "build-helper-maven-plugin"
elif mutation != "none":
    raise SystemExit(f"Unknown mutation: {mutation}")

build = project.find(q("build"))
plugins = build.find(q("plugins"))
plugin = ET.SubElement(plugins, q("plugin"))
ET.SubElement(plugin, q("groupId")).text = "org.apache.maven.plugins"
ET.SubElement(plugin, q("artifactId")).text = "maven-enforcer-plugin"
ET.SubElement(plugin, q("version")).text = enforcer_version
executions = ET.SubElement(plugin, q("executions"))
execution = ET.SubElement(executions, q("execution"))
ET.SubElement(execution, q("id")).text = "spike-rule"
ET.SubElement(execution, q("phase")).text = "validate"
goals = ET.SubElement(execution, q("goals"))
ET.SubElement(goals, q("goal")).text = "enforce"
configuration = ET.SubElement(execution, q("configuration"))
rules = ET.SubElement(configuration, q("rules"))
rules.append(ET.fromstring(rule_xml))

ET.indent(tree, space="\t")
tree.write(destination, encoding="UTF-8", xml_declaration=True)
PY
}

run_case() {
  local sequence="$1"
  local case_name="$2"
  local rule="$3"
  local profile="$4"
  local expected="$5"
  local pom_name="$6"
  local timestamp
  local log
  local status
  local outcome
  local -a profile_arguments=()

  timestamp="$(date +%Y%m%d-%H%M)"
  log="${LOG_DIRECTORY}/${timestamp}-${sequence}-${case_name}-job-logs.txt"
  if [[ "${profile}" != "default" ]]; then
    profile_arguments+=("-P${profile}")
  fi

  set +e
  (
    cd "${DEMO}"
    ./mvnw \
      --batch-mode \
      --no-transfer-progress \
      --file "${GENERATED_DIRECTORY}/${pom_name}.xml" \
      "${profile_arguments[@]}" \
      validate
  ) 2>&1 | tee "${log}"
  status="${PIPESTATUS[0]}"
  set -e

  if [[ ("${expected}" == "pass" && "${status}" -eq 0) ||
        ("${expected}" == "fail" && "${status}" -ne 0) ]]; then
    outcome="as-expected"
  else
    outcome="unexpected"
  fi

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "${case_name}" \
    "${rule}" \
    "${profile}" \
    "${expected}" \
    "${status}" \
    "${outcome}" \
    "${log#${SPIKE}/}" \
    "generated-poms/${pom_name}.xml" >> "${SUMMARY_FILE}"
}

generate_pom require-java-version \
  '<requireJavaVersion><version>[17,18)</version><message>Build requires JDK 17.</message></requireJavaVersion>'
generate_pom reject-java-version \
  '<requireJavaVersion><version>[99,100)</version><message>Negative control: current JDK must be rejected.</message></requireJavaVersion>'
generate_pom require-maven-version \
  '<requireMavenVersion><version>[3.9.9,4.0.0)</version><message>Build requires Maven 3.9.9 through 3.x.</message></requireMavenVersion>'
generate_pom reject-maven-version \
  '<requireMavenVersion><version>[99,100)</version><message>Negative control: current Maven must be rejected.</message></requireMavenVersion>'
generate_pom require-plugin-versions \
  '<requirePluginVersions><banLatest>true</banLatest><banRelease>true</banRelease><banSnapshots>true</banSnapshots><phases>clean,validate,compile,test,package,verify</phases><unCheckedPluginList>org.apache.maven.plugins:maven-install-plugin,org.apache.maven.plugins:maven-site-plugin,org.apache.maven.plugins:maven-deploy-plugin</unCheckedPluginList></requirePluginVersions>'
generate_pom selected-plugin-version-policy \
  '<requirePluginVersions><banLatest>true</banLatest><banRelease>true</banRelease><banSnapshots>true</banSnapshots><phases>clean,validate,compile,test,package,verify</phases><unCheckedPluginList>org.apache.maven.plugins:maven-install-plugin,org.apache.maven.plugins:maven-site-plugin,org.apache.maven.plugins:maven-deploy-plugin</unCheckedPluginList></requirePluginVersions>' pin-demo-plugins
generate_pom reject-unversioned-plugin \
  '<requirePluginVersions><banLatest>true</banLatest><banRelease>true</banRelease><banSnapshots>true</banSnapshots><phases>clean,validate,compile,test,package,verify</phases><unCheckedPluginList>org.apache.maven.plugins:maven-install-plugin,org.apache.maven.plugins:maven-site-plugin,org.apache.maven.plugins:maven-deploy-plugin</unCheckedPluginList></requirePluginVersions>' pin-demo-plugins-and-add-unversioned-plugin
generate_pom dependency-convergence \
  '<dependencyConvergence><uniqueVersions>true</uniqueVersions></dependencyConvergence>'
generate_pom require-upper-bound-deps \
  '<requireUpperBoundDeps><uniqueVersions>true</uniqueVersions><excludedScopes><excludedScope>none</excludedScope></excludedScopes></requireUpperBoundDeps>'
generate_pom no-duplicate-declarations \
  '<banDuplicatePomDependencyVersions/>'
generate_pom reject-duplicate-declaration \
  '<banDuplicatePomDependencyVersions/>' duplicate-dependency
generate_pom banned-dependencies \
  '<bannedDependencies><searchTransitive>false</searchTransitive><excludes><exclude>jakarta.*:*</exclude><exclude>org.springframework*:*</exclude><exclude>fish.payara*:*</exclude><exclude>org.wildfly*:*</exclude><exclude>org.jboss.as:*</exclude><exclude>org.apache.tomcat*:*</exclude></excludes><message>Jakarta, Spring, or non-Liberty application-server dependencies require an explicit architecture decision.</message></bannedDependencies>'
generate_pom reject-banned-dependency \
  '<bannedDependencies><searchTransitive>false</searchTransitive><excludes><exclude>jakarta.*:*</exclude><exclude>org.springframework*:*</exclude><exclude>fish.payara*:*</exclude><exclude>org.wildfly*:*</exclude><exclude>org.jboss.as:*</exclude><exclude>org.apache.tomcat*:*</exclude></excludes><message>Jakarta, Spring, or non-Liberty application-server dependencies require an explicit architecture decision.</message></bannedDependencies>' banned-dependency
generate_pom no-project-repositories \
  '<requireNoRepositories><banRepositories>true</banRepositories><banPluginRepositories>true</banPluginRepositories><allowedRepositories><allowedRepository>central</allowedRepository></allowedRepositories><allowedPluginRepositories><allowedPluginRepository>central</allowedPluginRepository></allowedPluginRepositories></requireNoRepositories>'
generate_pom reject-project-repository \
  '<requireNoRepositories><banRepositories>true</banRepositories><banPluginRepositories>true</banPluginRepositories><allowedRepositories><allowedRepository>central</allowedRepository></allowedRepositories><allowedPluginRepositories><allowedPluginRepository>central</allowedPluginRepository></allowedPluginRepositories></requireNoRepositories>' repository

run_case 01 java-version requireJavaVersion default pass require-java-version
run_case 02 java-version-negative-control requireJavaVersion default fail reject-java-version
run_case 03 maven-version requireMavenVersion default pass require-maven-version
run_case 04 maven-version-negative-control requireMavenVersion default fail reject-maven-version
run_case 05 plugin-versions-baseline requirePluginVersions default fail require-plugin-versions
run_case 06 plugin-versions-selected-policy requirePluginVersions default pass selected-plugin-version-policy
run_case 07 plugin-versions-negative-control requirePluginVersions default fail reject-unversioned-plugin
run_case 08 convergence-openliberty dependencyConvergence default pass dependency-convergence
run_case 09 upper-bound-openliberty requireUpperBoundDeps default pass require-upper-bound-deps
run_case 10 duplicate-declarations banDuplicatePomDependencyVersions default pass no-duplicate-declarations
run_case 11 duplicate-declarations-negative-control banDuplicatePomDependencyVersions default fail reject-duplicate-declaration
run_case 12 banned-dependencies bannedDependencies default pass banned-dependencies
run_case 13 banned-dependencies-negative-control bannedDependencies default fail reject-banned-dependency
run_case 14 project-repositories requireNoRepositories default pass no-project-repositories
run_case 15 project-repositories-negative-control requireNoRepositories default fail reject-project-repository

if grep -q $'\tunexpected\t' "${SUMMARY_FILE}"; then
  printf 'One or more cases produced an unexpected outcome. See %s\n' "${SUMMARY_FILE}" >&2
  exit 1
fi
