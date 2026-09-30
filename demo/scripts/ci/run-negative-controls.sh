#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"
out="$root/ci-artifacts/build-contract/enforcer-negative-controls.txt"
mkdir -p "$(dirname "$out")"
: > "$out"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
cp pom.xml "$tmp/pom.xml"
run_case() {
  local name="$1" expression="$2" diagnostic="$3"
  cp pom.xml "$tmp/pom.xml"
  python3 - "$tmp/pom.xml" "$expression" <<'PY'
import pathlib, sys
p = pathlib.Path(sys.argv[1])
text = p.read_text()
expression = sys.argv[2]
if expression == "java":
    text = text.replace("<version>[17,18)</version>", "<version>[99,100)</version>", 1)
elif expression == "maven":
    text = text.replace("<version>[3.9.9,4.0.0)</version>", "<version>[99,100)</version>", 1)
elif expression == "plugin":
    text = text.replace("</plugins>", "<plugin><groupId>org.codehaus.mojo</groupId><artifactId>build-helper-maven-plugin</artifactId></plugin></plugins>", 1)
elif expression == "duplicate":
    marker = "\n\t</dependencies>\n\n\t<build>"
    addition = "\n\t\t<dependency><groupId>joda-time</groupId><artifactId>joda-time</artifactId><version>2.10.6</version></dependency>"
    text = text.replace(marker, addition + marker, 1)
elif expression == "banned":
    marker = "\n\t</dependencies>\n\n\t<build>"
    addition = "<dependency><groupId>org.springframework</groupId><artifactId>spring-core</artifactId><version>6.0.0</version></dependency>"
    text = text.replace(marker, "\n\t\t" + addition + marker, 1)
elif expression == "repository":
    text = text.replace("<dependencyManagement>", "<repositories><repository><id>evil</id><url>https://example.invalid</url></repository></repositories><dependencyManagement>", 1)
elif expression == "convergence":
    marker = "\n\t</dependencies>\n\n\t<build>"
    addition = "<dependency><groupId>org.apache.httpcomponents</groupId><artifactId>httpclient</artifactId><version>4.5.13</version></dependency><dependency><groupId>org.apache.httpcomponents</groupId><artifactId>httpcore</artifactId><version>4.4.1</version></dependency>"
    text = text.replace(marker, "\n\t\t" + addition + marker, 1)
p.write_text(text)
PY
  set +e
  ./mvnw -f "$tmp/pom.xml" '-P!openliberty' validate > "$tmp/$name.log" 2>&1
  status=$?
  set -e
  if [[ $status -eq 0 ]] || ! grep -qi "$diagnostic" "$tmp/$name.log"; then
    echo "$name FAILED" >> "$out"
    echo "negative control failed: $name (expected diagnostic: $diagnostic)" >&2
    cat "$tmp/$name.log" >&2
    exit 1
  fi
  {
    printf '%s: nonzero with %s\n' "$name" "$diagnostic"
    printf '%s\n' "--- $name bounded Maven diagnostic ---"
    grep -i -C 4 "$diagnostic" "$tmp/$name.log" | tail -n 40
    printf '%s\n' "--- end $name diagnostic ---"
  } >> "$out"
}
run_case java java "RequireJavaVersion"
run_case maven maven "RequireMavenVersion"
run_case plugin plugin "requirePluginVersions"
run_case duplicate duplicate "duplicate"
run_case banned banned "BannedDependencies"
run_case repository repository "RequireNoRepositories"
run_case convergence convergence "Dependency convergence"
fixture="$tmp/BadFormatting.java"
mkdir -p "$root/src/main/java/org/eclipse/cargotracker/ci"
fixture="$root/src/main/java/org/eclipse/cargotracker/ci/BadFormatting.java"
printf 'package org.eclipse.cargotracker.ci; public class BadFormatting { public static void main(String[] args) { } }\\n' > "$fixture"
trap 'git reset --quiet "$fixture" 2>/dev/null || true; rm -rf "$tmp" "$fixture" "$root/src/main/java/org/eclipse/cargotracker/ci"' EXIT
git add "$fixture"
set +e
./mvnw spotless:check > "$tmp/formatting.log" 2>&1
status=$?
set -e
if [[ $status -eq 0 ]] || ! grep -q "BadFormatting.java" "$tmp/formatting.log"; then
  echo "formatting FAILED" >> "$out"
  cat "$tmp/formatting.log" >&2
  exit 1
fi
printf '%s\n' 'formatting: nonzero with BadFormatting.java' >> "$out"
printf '%s\n' 'checksum: corrupted WAR rejected by sha256sum --check' >> "$out"
cp "$root/target/cargo-tracker.war" "$tmp/cargo-tracker.war"
printf 'corrupt' >> "$tmp/cargo-tracker.war"
sha256sum "$root/target/cargo-tracker.war" | sed "s#${root}/##" > "$tmp/cargo-tracker.sha256"
sed -i "s#target/cargo-tracker.war#$tmp/cargo-tracker.war#" "$tmp/cargo-tracker.sha256"
if sha256sum --check "$tmp/cargo-tracker.sha256" >/dev/null 2>&1; then
  echo "checksum FAILED" >> "$out"
  exit 1
fi
printf '%s\n' 'advisory: known-vulnerable log4j coordinate rejected by HIGH/CRITICAL queries' >> "$out"
for severity in high critical; do
  query="advisories?ecosystem=maven&affects=org.apache.logging.log4j%3Alog4j-core%402.14.1&severity=${severity}&per_page=100"
  if ! gh api "$query" > "$tmp/advisory-${severity}.json" 2> "$tmp/advisory.log" ||
    ! jq -e 'type == "array" and length > 0' "$tmp/advisory-${severity}.json" >/dev/null; then
    echo "advisory FAILED: known vulnerable coordinate was not rejected for $severity" >> "$out"
    cat "$tmp/advisory.log" >&2
    exit 1
  fi
done
