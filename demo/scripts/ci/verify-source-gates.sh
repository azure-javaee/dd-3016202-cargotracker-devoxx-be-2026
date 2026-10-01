#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"
evidence="$root/ci-artifacts/source-gates"
fixture_root="$root/src/test/java/org/eclipse/cargotracker/sourcegates"
production_fixture="$root/src/main/java/org/eclipse/cargotracker/analysis"
mkdir -p "$evidence"
started="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
trap 'rm -rf "$fixture_root" "$production_fixture"' EXIT

run_gate() {
  local name="$1"
  shift
  local start end
  start="$(date +%s)"
  "$@" 2>&1 | tee "$evidence/$name.log"
  end="$(date +%s)"
  printf '%s\t%s\n' "$name" "$((end - start))" >> "$evidence/durations.tsv"
}

: > "$evidence/durations.tsv"
run_gate compiler "./mvnw" '-P!openliberty' -DskipTests clean compile
run_gate test-compiler "./mvnw" '-P!openliberty' -DskipTests test-compile
run_gate spotbugs "./mvnw" '-P!openliberty' -DskipTests verify
cp target/spotbugsXml.xml "$evidence/spotbugs.xml"

python3 - "$evidence/spotbugs.xml" "$evidence/spotbugs.tsv" <<'PY'
import sys
from xml.etree import ElementTree

root = ElementTree.parse(sys.argv[1]).getroot()
with open(sys.argv[2], "w", encoding="utf-8") as output:
    output.write("priority\trank\tcategory\tpattern\tclass\tline\tmessage\n")
    for bug in root.findall(".//BugInstance"):
        source = bug.find("SourceLine")
        output.write("\t".join([
            bug.get("priority", ""),
            bug.get("rank", ""),
            bug.get("category", ""),
            bug.get("type", ""),
            bug.get("classname", ""),
            source.get("start", "") if source is not None else "",
            (bug.findtext("LongMessage") or bug.findtext("ShortMessage") or "").replace("\t", " "),
        ]) + "\n")
PY

mkdir -p "$fixture_root"
cat > "$fixture_root/FormattingFailure.java" <<'EOF'
package org.eclipse.cargotracker.sourcegates;
public class FormattingFailure { }
EOF
if "./mvnw" spotless:check > "$evidence/formatting-negative.log" 2>&1; then
  echo "formatting fixture unexpectedly passed" >&2
  exit 1
fi
grep -E "FormattingFailure|spotless:apply" "$evidence/formatting-negative.log"
rm -rf "$fixture_root"

mkdir -p "$fixture_root"
cat > "$fixture_root/CompilerFailure.java" <<'EOF'
package org.eclipse.cargotracker.sourcegates;
import org.eclipse.cargotracker.domain.model.cargo.Cargo;
public class CompilerFailure {
    String invoke(Cargo cargo) {
        return cargo.agentInventedMethod("not-real");
    }
}
EOF
if "./mvnw" '-P!openliberty' -DskipTests test-compile > "$evidence/compiler-negative.log" 2>&1; then
  echo "compiler fixture unexpectedly passed" >&2
  exit 1
fi
grep -E "CompilerFailure|cannot find symbol|agentInventedMethod" "$evidence/compiler-negative.log"
rm -rf "$fixture_root"

mkdir -p "$production_fixture"
cat > "$production_fixture/AnalyzerFailureFixture.java" <<'EOF'
package org.eclipse.cargotracker.analysis;
public class AnalyzerFailureFixture {
    public int dereferenceNull() {
        Object value = null;
        return value.hashCode();
    }
}
EOF
if "./mvnw" '-P!openliberty' -DskipTests clean verify > "$evidence/analyzer-negative.log" 2>&1; then
  echo "analyzer fixture unexpectedly passed" >&2
  exit 1
fi
grep -F "AnalyzerFailureFixture" "$evidence/analyzer-negative.log"
grep -F "NP_ALWAYS_NULL" "$evidence/analyzer-negative.log"
grep -E "(High|Medium|Low):.*NP_ALWAYS_NULL" "$evidence/analyzer-negative.log"
rm -rf "$production_fixture"
rm -rf "$root/target/classes/org/eclipse/cargotracker/analysis"

ended="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
python3 - "$evidence" "$started" "$ended" <<'PY'
import hashlib
import json
import os
import pathlib
import sys

directory = pathlib.Path(sys.argv[1])
metadata = {
    "schema": 1,
    "concern": "formatting, compiler, and static-analysis source gates",
    "name": "source-gates",
    "repository": os.environ["GITHUB_REPOSITORY"],
    "ref": os.environ["GITHUB_REF"],
    "sha": os.environ["GITHUB_SHA"],
    "workflow": os.environ["GITHUB_WORKFLOW"],
    "run": os.environ["GITHUB_RUN_ID"],
    "attempt": os.environ["GITHUB_RUN_ATTEMPT"],
    "url": f"{os.environ['GITHUB_SERVER_URL']}/{os.environ['GITHUB_REPOSITORY']}/actions/runs/{os.environ['GITHUB_RUN_ID']}",
    "job": os.environ["GITHUB_JOB"],
    "event": os.environ["GITHUB_EVENT_NAME"],
    "pr": os.environ.get("CI_PR_NUMBER", "not-applicable"),
    "runner": {"os": os.environ["RUNNER_OS"], "architecture": os.environ["RUNNER_ARCH"]},
    "tools": {
        "java": os.popen("java -version 2>&1").read().splitlines()[0],
        "maven": os.popen("./mvnw -version").read().splitlines()[0],
        "spotbugs": {"engine": "4.10.4", "mavenPlugin": "4.10.4.1"},
    },
    "startedAt": sys.argv[2],
    "endedAt": sys.argv[3],
    "commands": [
        "./mvnw '-P!openliberty' -DskipTests clean compile",
        "./mvnw '-P!openliberty' -DskipTests test-compile",
        "./mvnw '-P!openliberty' -DskipTests verify",
        "./mvnw spotless:check (formatting fixture)",
        "./mvnw '-P!openliberty' -DskipTests test-compile (compiler fixture)",
        "./mvnw '-P!openliberty' -DskipTests verify (SpotBugs fixture)",
    ],
}
metadata["files"] = [
    {"path": file.relative_to(directory).as_posix(),
     "bytes": file.stat().st_size,
     "sha256": hashlib.sha256(file.read_bytes()).hexdigest()}
    for file in sorted(directory.rglob("*"))
    if file.is_file() and file.name != "artifact-metadata.json"
]
(directory / "artifact-metadata.json").write_text(json.dumps(metadata, indent=2) + "\n")
PY
