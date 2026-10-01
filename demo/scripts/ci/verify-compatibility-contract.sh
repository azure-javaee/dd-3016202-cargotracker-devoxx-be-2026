#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"
report_dir="$root/ci-artifacts/compatibility-contract"
mkdir -p "$report_dir"

check_contract() {
  local check_root="$1"
  python3 - "$check_root" <<'PY'
import pathlib
import re
import sys
import xml.etree.ElementTree as ET

root = pathlib.Path(sys.argv[1])
ns = {"m": "http://maven.apache.org/POM/4.0.0"}
pom = ET.parse(root / "pom.xml").getroot()
def text(path):
    node = pom.find(path, ns)
    return node.text.strip() if node is not None and node.text else None
assert text("m:properties/m:maven.compiler.release") == "17", \
    "compatibility boundary: compiler release must be 17"
assert text("m:properties/m:javaee_api.version") == "7.0", \
    "compatibility boundary: Java EE API version must be 7.0"
javaee = [
    d for d in pom.findall("m:dependencies/m:dependency", ns)
    if d.findtext("m:groupId", namespaces=ns) == "javax" and
    d.findtext("m:artifactId", namespaces=ns) == "javaee-api" and
    d.findtext("m:version", namespaces=ns) in ("7.0", "${javaee_api.version}")
]
assert len(javaee) == 1 and javaee[0].findtext("m:scope", namespaces=ns) == "provided", \
    "compatibility boundary: javax:javaee-api:7.0 must be provided"
assert text("m:packaging") == "war", \
    "compatibility boundary: packaging must be war"
assert text("m:build/m:finalName") == "cargo-tracker", \
    "compatibility boundary: WAR final name must be cargo-tracker"

server = (root / "src/main/liberty/config/server.xml").read_text()
assert "<feature>javaee-7.0</feature>" in server, \
    "compatibility boundary: Open Liberty must provide javaee-7.0"
assert 'location="cargo-tracker.war"' in server, \
    "compatibility boundary: Liberty WAR location must be cargo-tracker.war"
assert 'contextRoot="/cargo-tracker"' in server, \
    "compatibility boundary: Liberty context root must be /cargo-tracker"

banned = ("jakarta.", "org.springframework", "fish.payara", "org.wildfly",
          "org.jboss.as", "org.apache.tomcat")
for dependency in pom.findall(".//m:dependency", ns):
    group = dependency.findtext("m:groupId", namespaces=ns)
    artifact = dependency.findtext("m:artifactId", namespaces=ns)
    assert group and artifact, "compatibility boundary: dependency coordinates are incomplete"
    coordinate = f"{group}:{artifact}"
    assert not coordinate.startswith(banned), \
        f"compatibility boundary: forbidden direct dependency {coordinate}"
for path in (root / "src/main").rglob("*.java"):
    for number, line in enumerate(path.read_text().splitlines(), 1):
        if re.match(r"\s*import\s+jakarta\.", line):
            raise AssertionError(
                f"compatibility boundary: forbidden production Jakarta import "
                f"{path.relative_to(root)}:{number}")
PY
}

if [[ "${1:-}" == "--check-only" ]]; then
  [[ "${2:-}" == "--root" && -n "${3:-}" ]] || {
    echo "usage: $0 --check-only --root PATH" >&2
    exit 2
  }
  check_contract "$3"
  exit 0
fi

check_contract "$root"
{
  echo "compiler release: 17"
  echo "Java EE API: javax:javaee-api:7.0 (provided)"
  echo "packaging: war; final name: cargo-tracker"
  echo "Open Liberty feature: javaee-7.0"
  echo "deployment: cargo-tracker.war at /cargo-tracker"
  echo "production source scan: no jakarta.* imports"
  java -version 2>&1
} | tee "$report_dir/compatibility-report.txt"
./mvnw -version 2>&1 | tee "$report_dir/maven-version.txt"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/src/main/liberty/config" "$tmp/src/main/java/example"
cp pom.xml "$tmp/pom.xml"
cp src/main/liberty/config/server.xml "$tmp/src/main/liberty/config/server.xml"

run_negative() {
  local name="$1" expression="$2" diagnostic="$3"
  cp pom.xml "$tmp/pom.xml"
  cp src/main/liberty/config/server.xml "$tmp/src/main/liberty/config/server.xml"
  rm -f "$tmp/src/main/java/example/BadImport.java"
  python3 - "$tmp" "$expression" <<'PY'
import pathlib, sys
root = pathlib.Path(sys.argv[1])
expression = sys.argv[2]
pom = root / "pom.xml"
text = pom.read_text()
def replace_once(old, new):
    global text
    if text.count(old) != 1:
        raise SystemExit(f"fixture boundary not found exactly once: {old}")
    text = text.replace(old, new, 1)
if expression == "jakarta-dependency":
    text = text.replace("</dependencies>", "<dependency><groupId>jakarta.platform</groupId><artifactId>jakarta.jakartaee-api</artifactId><version>10.0.0</version></dependency></dependencies>", 1)
elif expression == "release":
    replace_once("<maven.compiler.release>17</maven.compiler.release>", "<maven.compiler.release>21</maven.compiler.release>")
elif expression == "jar":
    replace_once("<packaging>war</packaging>", "<packaging>jar</packaging>")
elif expression == "renamed-war":
    replace_once("<finalName>cargo-tracker</finalName>", "<finalName>other-name</finalName>")
elif expression == "spring":
    text = text.replace("</dependencies>", "<dependency><groupId>org.springframework</groupId><artifactId>spring-core</artifactId><version>6.0.0</version></dependency></dependencies>", 1)
pom.write_text(text)
server = root / "src/main/liberty/config/server.xml"
if expression == "feature":
    server.write_text(server.read_text().replace("<feature>javaee-7.0</feature>", "<feature>jakartaee-10.0</feature>"))
if expression == "jakarta-import":
    (root / "src/main/java/example/BadImport.java").write_text(
        "package example;\nimport jakarta.ws.rs.GET;\nclass BadImport {}\n")
PY
  if "$0" --check-only --root "$tmp" > "$tmp/$name.log" 2>&1 ||
     ! grep -q "$diagnostic" "$tmp/$name.log"; then
    echo "negative control failed: $name" >&2
    cat "$tmp/$name.log" >&2
    exit 1
  fi
  printf '%s: rejected with %s\n' "$name" "$diagnostic"
}

{
  run_negative jakarta-import jakarta-import "forbidden production Jakarta import"
  run_negative jakarta-dependency jakarta-dependency "forbidden direct dependency"
  run_negative release release "compiler release must be 17"
  run_negative jar jar "packaging must be war"
  run_negative renamed-war renamed-war "WAR final name must be cargo-tracker"
  run_negative spring spring "forbidden direct dependency"
  run_negative feature feature "javaee-7.0"
} | tee "$report_dir/negative-controls.txt"
