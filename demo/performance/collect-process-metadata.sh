#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
demo_root="$root"
mode="${1:-}"
shift || true

find_server_pids() {
  local server_dir="$1"
  local jar proc executable index
  local -a process_args
  jar="$(realpath -m "$server_dir/../../../bin/tools/ws-server.jar")"
  for proc in /proc/[0-9]*; do
    [[ -r "$proc/cmdline" && -e "$proc/exe" ]] || continue
    executable="$(readlink -f "$proc/exe" 2>/dev/null)" || continue
    [[ "${executable##*/}" == java ]] || continue
    process_args=()
    mapfile -d '' -t process_args < "$proc/cmdline" 2>/dev/null || true
    for ((index = 0; index + 2 < ${#process_args[@]}; index++)); do
      if [[ "${process_args[index]}" == -jar \
        && "${process_args[index + 1]}" == "$jar" \
        && "${process_args[index + 2]}" == defaultServer ]]; then
        printf '%s\n' "${proc##*/}"
        break
      fi
    done
  done
}

sample_selected_pid() {
  local server_dir="$1" output="$2" server_pid_file="$3" start_ns="$4"
  local pid rss_kb stat cpu_ticks elapsed_ms
  local -a pids stat_fields
  pid="$(cat "$server_pid_file")"
  if [[ ! "$pid" =~ ^[0-9]+$ ]]; then
    echo "selected Liberty PID file is invalid" >&2
    exit 1
  fi
  mapfile -t pids < <(find_server_pids "$server_dir")
  if (( ${#pids[@]} != 1 )); then
    printf 'expected one Liberty JVM for %s, found %s\n' \
      "$server_dir" "${#pids[@]}" >&2
    exit 1
  fi
  if [[ "${pids[0]}" != "$pid" ]]; then
    printf 'Liberty JVM PID changed unexpectedly: selected %s, found %s\n' \
      "$pid" "${pids[0]}" >&2
    exit 1
  fi
  if [[ ! -r "/proc/$pid/status" || ! -r "/proc/$pid/stat" ]]; then
    printf 'selected Liberty JVM %s disappeared during sampling\n' "$pid" >&2
    exit 1
  fi
  rss_kb="$(awk '/^VmRSS:/ { print $2 }' "/proc/$pid/status")"
  stat="$(sed 's/^[^)]*) //' "/proc/$pid/stat")"
  read -r -a stat_fields <<< "$stat"
  # After stripping "pid (comm) ", zero-based indexes 11 and 12 are utime/stime.
  cpu_ticks="$((stat_fields[11] + stat_fields[12]))"
  elapsed_ms="$((( $(date +%s%N) - start_ns) / 1000000))"
  printf '%s\t%s\t%s\t%s\n' "$elapsed_ms" "$pid" "$rss_kb" "$cpu_ticks" >> "$output"
}

case "$mode" in
  host)
    output="${1:?output directory required}"
    mkdir -p "$output"
    {
      printf 'captured_at_utc\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
      printf 'hostname\t%s\n' "$(hostname)"
      printf 'architecture\t%s\n' "$(uname -m)"
      printf 'logical_cpus\t%s\n' "$(getconf _NPROCESSORS_ONLN)"
      printf 'memory_total_kb\t%s\n' "$(awk '/^MemTotal:/ { print $2 }' /proc/meminfo)"
      if command -v lscpu >/dev/null 2>&1; then
        printf '\n[cpu]\n'
        lscpu
      fi
      printf '\n[operating-system]\n'
      cat /etc/os-release
      printf '\n[kernel]\n'
      uname -a
      printf '\n[cgroup-membership]\n'
      cat /proc/self/cgroup
      printf '\n[cgroup-view]\n'
      for file in \
        /sys/fs/cgroup/cgroup.controllers \
        /sys/fs/cgroup/cpu.max \
        /sys/fs/cgroup/cpu.stat \
        /sys/fs/cgroup/memory.max \
        /sys/fs/cgroup/memory.current \
        /sys/fs/cgroup/memory.events \
        /sys/fs/cgroup/memory/memory.limit_in_bytes \
        /sys/fs/cgroup/cpu/cpu.cfs_quota_us \
        /sys/fs/cgroup/cpu/cpu.cfs_period_us; do
        if [[ -r "$file" ]]; then
          printf '\n[%s]\n' "$file"
          cat "$file"
        fi
      done
      while IFS=: read -r hierarchy controllers membership; do
        if [[ "$hierarchy" == 0 ]]; then
          mounts=("/sys/fs/cgroup${membership}")
        else
          IFS=, read -r -a controller_names <<< "$controllers"
          mounts=()
          for controller in "${controller_names[@]}"; do
            mounts+=("/sys/fs/cgroup/$controller${membership}")
          done
        fi
        for mount in "${mounts[@]}"; do
          for name in cpu.max cpu.stat memory.max memory.current memory.events \
            cpu.cfs_quota_us cpu.cfs_period_us memory.limit_in_bytes; do
            file="$mount/$name"
            if [[ -r "$file" ]]; then
              printf '\n[cgroup-member:%s]\n' "$file"
              cat "$file"
            fi
          done
        done
      done < /proc/self/cgroup
    } > "$output/runner-environment.txt"
    ;;
  jfr-profile)
    source_profile="${1:?JDK profile required}"
    target_profile="${2:?target profile required}"
    python3 - "$source_profile" "$target_profile" <<'PY'
import pathlib
import sys
import xml.etree.ElementTree as ET

source = pathlib.Path(sys.argv[1])
target = pathlib.Path(sys.argv[2])
if not source.is_file():
    raise SystemExit(f"JDK JFR profile is missing: {source}")
tree = ET.parse(source)
events = {
    "jdk.JVMInformation",
    "jdk.InitialSystemProperty",
    "jdk.OSInformation",
    "jdk.InitialEnvironmentVariable",
    "jdk.SystemProcess",
}
found = set()
for event in tree.iter("event"):
    if event.get("name") in events:
        event.set("enabled", "false")
        found.add(event.get("name"))
missing = sorted(events - found)
if missing:
    raise SystemExit("JFR profile omitted required redactions: " + ", ".join(missing))
target.parent.mkdir(parents=True, exist_ok=True)
tree.write(target, encoding="UTF-8", xml_declaration=True)
ET.parse(target)
print(f"redacted JFR profile written: {target}")
PY
    ;;
  find-server-pid)
    server_dir="${1:?server directory required}"
    mapfile -t pids < <(find_server_pids "$server_dir")
    if [[ "${#pids[@]}" -ne 1 ]]; then
      printf 'expected one Liberty JVM for %s, found %s\n' "$server_dir" "${#pids[@]}" >&2
      exit 1
    fi
    printf '%s\n' "${pids[0]}"
    ;;
  list-server-pids)
    find_server_pids "${1:?server directory required}"
    ;;
  verify-jvm-option)
    command_file="${1:?JVM command-line file required}"
    expected_option="${2:?expected JVM option required}"
    if ! grep -Fq -- "$expected_option" "$command_file"; then
      printf 'effective JVM command line omitted required option: %s\n' \
        "$expected_option" >&2
      exit 1
    fi
    ;;
  sample-server)
    server_dir="${1:?server directory required}"
    output="${2:?sample output required}"
    stop_file="${3:?sampler stop file required}"
    interval="${4:-0.2}"
    server_pid_file="${5:?server PID file required}"
    printf 'elapsed_ms\tpid\trss_kb\tcpu_ticks\n' > "$output"
    start_ns="$(date +%s%N)"
    while [[ ! -e "$stop_file" ]]; do
      if [[ ! -s "$server_pid_file" ]]; then
        sleep "$interval"
        continue
      fi
      sample_selected_pid "$server_dir" "$output" "$server_pid_file" "$start_ns"
      sleep "$interval"
    done
    if [[ -s "$server_pid_file" ]]; then
      sample_selected_pid "$server_dir" "$output" "$server_pid_file" "$start_ns"
    fi
    [[ "$(wc -l < "$output")" -gt 1 ]]
    ;;
  ancestry)
    pid="${1:?process id required}"
    output="${2:?output file required}"
    printf 'pid\tppid\tcommand\n' > "$output"
    current="$pid"
    while [[ "$current" -gt 1 ]]; do
      row="$(ps -o pid=,ppid=,comm= -p "$current" || true)"
      [[ -n "$row" ]] || break
      read -r row_pid parent command <<< "$row"
      printf '%s\t%s\t%s\n' "$row_pid" "$parent" "$command" >> "$output"
      current="$parent"
    done
    ;;
  summarize)
    summary_kind="${1:?summary operation required}"
    shift
    python3 - "$demo_root" "$summary_kind" "$@" <<'PY'
import csv
import hashlib
import json
import math
import os
import pathlib
import re
import statistics
import subprocess
import sys
import xml.etree.ElementTree as ET
from datetime import datetime, timezone

root = pathlib.Path(sys.argv[1])
kind = sys.argv[2]
args = sys.argv[3:]


def percentile(values, fraction):
    if not values:
        return None
    values = sorted(values)
    position = (len(values) - 1) * fraction
    low = math.floor(position)
    high = math.ceil(position)
    if low == high:
        return values[low]
    return values[low] * (high - position) + values[high] * (position - low)


def parse_heap(path):
    if not path.is_file():
        return None
    text = path.read_text(errors="replace")
    match = re.search(r"garbage-first heap.*?used\s+([0-9]+)K", text, re.IGNORECASE | re.DOTALL)
    if not match:
        match = re.search(r"heap.*?used\s+([0-9]+)K", text, re.IGNORECASE | re.DOTALL)
    return int(match.group(1)) if match else None


def parse_gc(path):
    if not path.is_file():
        return 0, 0.0
    pauses = []
    for line in path.read_text(errors="replace").splitlines():
        if "Pause " not in line:
            continue
        match = re.search(r"([0-9]+(?:\.[0-9]+)?)ms(?:\s|$)", line)
        if match:
            pauses.append(float(match.group(1)))
    return len(pauses), sum(pauses)


def summarize_run(directory):
    result_path = directory / "run-summary.json"
    if not result_path.is_file():
        raise SystemExit(f"run summary missing: {directory}")
    return json.loads(result_path.read_text())


if kind == "summarize-run":
    directory = pathlib.Path(args[0])
    state = json.loads((directory / "run-state.json").read_text())
    sample_file = directory / "process-samples.tsv"
    samples = []
    if sample_file.is_file():
        with sample_file.open() as stream:
            samples = list(csv.DictReader(stream, delimiter="\t"))
    rss_values = [int(row["rss_kb"]) for row in samples if row.get("rss_kb", "").isdigit()]
    cpu_ticks = [
        int(row["cpu_ticks"]) for row in samples if row.get("cpu_ticks", "").isdigit()
    ]
    ticks_per_second = os.sysconf("SC_CLK_TCK")
    cpu_seconds = (
        (cpu_ticks[-1] - cpu_ticks[0]) / ticks_per_second if len(cpu_ticks) > 1 else None
    )
    requests = []
    request_file = directory / "requests.tsv"
    if request_file.is_file():
        with request_file.open() as stream:
            requests = list(csv.DictReader(stream, delimiter="\t"))
    warmup_file = directory / "warmup.tsv"
    warmups = []
    if warmup_file.is_file():
        with warmup_file.open() as stream:
            warmups = list(csv.DictReader(stream, delimiter="\t"))
    timings = [
        float(row["duration_ms"])
        for row in requests
        if row.get("duration_ms") and row.get("status") == "200"
    ]
    gc_log = next(iter(sorted(directory.glob("gc-*.log"))), None)
    gc_count, gc_total_ms = parse_gc(gc_log) if gc_log else (0, 0.0)
    recording = directory / "recording.jfr"
    gc_bytes = gc_log.stat().st_size if gc_log and gc_log.is_file() else 0
    summary = {
        **state,
        "endedAt": datetime.now(timezone.utc).isoformat(),
        "requestCount": len(timings),
        "warmupCount": len(warmups),
        "requestMinMs": min(timings) if timings else None,
        "requestMedianMs": statistics.median(timings) if timings else None,
        "requestP90Ms": percentile(timings, 0.90),
        "requestP95Ms": percentile(timings, 0.95),
        "requestP99Ms": percentile(timings, 0.99),
        "requestMaxMs": max(timings) if timings else None,
        "requestCvPercent": (
            statistics.pstdev(timings) / statistics.mean(timings) * 100
            if len(timings) > 1 and statistics.mean(timings)
            else 0.0
        ),
        "peakRssKb": max(rss_values) if rss_values else None,
        "cpuSeconds": cpu_seconds,
        "heapBeforeKb": parse_heap(directory / "heap-before.txt"),
        "heapAfterKb": parse_heap(directory / "heap-after.txt"),
        "gcPauseCount": gc_count,
        "gcPauseTotalMs": gc_total_ms,
        "gcLogBytes": gc_bytes,
        "jfrBytes": recording.stat().st_size if recording.is_file() else 0,
        "sampleCount": len(samples),
    }
    (directory / "run-summary.json").write_text(json.dumps(summary, indent=2) + "\n")
    if state.get("status") == "PASS":
        errors = []
        required = (
            summary["requestCount"] == 30
            and summary["sampleCount"] > 0
            and summary["peakRssKb"] is not None
            and summary["cpuSeconds"] is not None
            and summary["heapBeforeKb"] is not None
            and summary["heapAfterKb"] is not None
            and summary["gcLogBytes"] > 0
            and summary["jfrBytes"] > 0
        )
        if not required:
            errors.append("required performance diagnostics did not parse")
        if summary["warmupCount"] != 5 or summary["startupMs"] is None \
          or summary["startupMs"] > 90000:
            errors.append("readiness, warm-up, or startup bound failed")
        if summary["totalMs"] > 120000 or summary["cleanupStatus"] != 0:
            errors.append("repetition duration or cleanup bound failed")
        if summary["peakRssKb"] is not None \
          and summary["peakRssKb"] > 2 * 1024 * 1024:
            errors.append(f"peak RSS exceeded 2 GiB: {summary['peakRssKb']} KiB")
        if errors:
            summary["status"] = "FAIL"
            summary["gateErrors"] = errors
        else:
            summary["status"] = "PASS"
    (directory / "run-summary.json").write_text(json.dumps(summary, indent=2) + "\n")
    if summary.get("gateErrors"):
        raise SystemExit(f"{directory}: " + "; ".join(summary["gateErrors"]))
    print(f"{summary.get('status', 'FAIL')}: {directory}")
elif kind == "summarize-all":
    artifact_root = pathlib.Path(
        os.environ.get("PERFORMANCE_ARTIFACT_ROOT", str(root / "ci-artifacts"))
    )
    artifact_roots = {
        "direct": artifact_root / "performance-java",
        "bypass": artifact_root / "performance-jaz-bypassed",
        "tuned": artifact_root / "performance-jaz-tuned",
    }
    comparison = artifact_root / "performance-comparison"
    runs = []
    for mode, mode_artifact_root in artifact_roots.items():
        mode_runs = []
        for directory in sorted(mode_artifact_root.glob("cycle-*-*-*")):
            run = summarize_run(directory)
            run["mode"] = mode
            run["directory"] = directory
            mode_runs.append(run)
            runs.append(run)
        if len(mode_runs) != 5:
            raise SystemExit(f"expected five {mode} repetitions, found {len(mode_runs)}")
        if any(run.get("status") != "PASS" for run in mode_runs):
            raise SystemExit(f"one or more {mode} repetitions failed")

    flag_values = {}
    for mode, mode_artifact_root in artifact_roots.items():
        for directory in sorted(mode_artifact_root.glob("cycle-*-*-*")):
            with (directory / "selected-jvm-flags.tsv").open() as stream:
                values = {
                    row["flag"]: row["value"]
                    for row in csv.DictReader(stream, delimiter="\t")
                }
            flag_values[(mode, directory.name)] = values
            if mode in ("direct", "bypass"):
                expected = {
                    "MinHeapFreeRatio": "40",
                    "MaxHeapFreeRatio": "70",
                    "G1PeriodicGCInterval": "0",
                    "UseG1GC": "true",
                }
                for flag, value in expected.items():
                    if values.get(flag) != value:
                        raise SystemExit(
                            f"{mode} has unexpected JVM policy {flag}="
                            f"{values.get(flag)} in {directory.name}"
                        )
                if values.get("G1UseTimeBasedHeapSizing") == "true":
                    raise SystemExit(f"{mode} unexpectedly enabled tuned G1 sizing")
    direct_heaps = [
        values["MaxHeapSize"]
        for (mode, _), values in flag_values.items()
        if mode == "direct"
    ]
    bypass_heaps = [
        values["MaxHeapSize"]
        for (mode, _), values in flag_values.items()
        if mode == "bypass"
    ]
    tuned_heaps = [
        values["MaxHeapSize"]
        for (mode, _), values in flag_values.items()
        if mode == "tuned"
    ]
    if len(set(direct_heaps)) != 1 or direct_heaps != bypass_heaps:
        raise SystemExit("direct and bypassed runs did not retain identical default heap policy")
    if any(heap == direct_heaps[0] for heap in tuned_heaps):
        raise SystemExit("tuned jaz did not select a distinct maximum heap")

    fields = (
        "cycle", "position", "mode", "startupMs", "requestCount", "requestMinMs",
        "requestMedianMs", "requestP90Ms", "requestP95Ms", "requestP99Ms",
        "requestMaxMs", "requestCvPercent", "peakRssKb", "cpuSeconds",
        "heapBeforeKb", "heapAfterKb", "gcPauseCount", "gcPauseTotalMs",
        "totalMs", "jfrBytes", "gcLogBytes", "status",
    )

    def format_value(value):
        if value is None:
            return "MISSING"
        if isinstance(value, float):
            return f"{value:.3f}"
        return str(value)

    with (comparison / "run-summary.tsv").open("w") as stream:
        stream.write("\t".join(fields) + "\n")
        for run in sorted(runs, key=lambda item: (item["cycle"], item["position"])):
            stream.write("\t".join(format_value(run.get(field)) for field in fields) + "\n")

    mode_metrics = (
        "startupMs", "requestMedianMs", "peakRssKb", "cpuSeconds",
        "heapBeforeKb", "heapAfterKb", "gcPauseCount", "gcPauseTotalMs", "totalMs",
    )
    with (comparison / "mode-summary.tsv").open("w") as stream:
        stream.write("mode\tmetric\tmedian\tmin\tmax\tcv_percent\n")
        for mode in ("direct", "bypass", "tuned"):
            mode_runs = [run for run in runs if run["mode"] == mode]
            for metric in mode_metrics:
                values = [float(run[metric]) for run in mode_runs if run.get(metric) is not None]
                if len(values) != 5:
                    raise SystemExit(f"unparseable {metric} values for {mode}")
                mean = statistics.mean(values)
                cv = statistics.pstdev(values) / mean * 100 if mean else 0.0
                stream.write(
                    f"{mode}\t{metric}\t{statistics.median(values):.3f}\t"
                    f"{min(values):.3f}\t{max(values):.3f}\t{cv:.3f}\n"
                )

    with (comparison / "paired-comparison.tsv").open("w") as stream:
        stream.write(
            "cycle\tmetric\tdirect\tbypass\tbypass_delta_percent\ttuned\t"
            "tuned_delta_percent\n"
        )
        for cycle in range(1, 6):
            cycle_runs = {run["mode"]: run for run in runs if run["cycle"] == cycle}
            for metric in ("startupMs", "requestMedianMs", "peakRssKb", "cpuSeconds", "totalMs"):
                direct = float(cycle_runs["direct"][metric])
                bypass = float(cycle_runs["bypass"][metric])
                tuned = float(cycle_runs["tuned"][metric])
                bypass_delta = (bypass / direct - 1) * 100 if direct else 0.0
                tuned_delta = (tuned / direct - 1) * 100 if direct else 0.0
                stream.write(
                    f"{cycle}\t{metric}\t{direct:.3f}\t{bypass:.3f}\t"
                    f"{bypass_delta:.3f}\t{tuned:.3f}\t{tuned_delta:.3f}\n"
                )

    for mode, mode_artifact_root in artifact_roots.items():
        mode_runs = [run for run in runs if run["mode"] == mode]
        with (mode_artifact_root / "run-summary.tsv").open("w") as stream:
            stream.write("\t".join(fields) + "\n")
            for run in sorted(mode_runs, key=lambda item: (item["cycle"], item["position"])):
                stream.write(
                    "\t".join(format_value(run.get(field)) for field in fields) + "\n"
                )
        with (mode_artifact_root / "mode-summary.tsv").open("w") as stream:
            stream.write("metric\tmedian\tmin\tmax\tcv_percent\n")
            for metric in mode_metrics:
                values = [float(run[metric]) for run in mode_runs]
                mean = statistics.mean(values)
                cv = statistics.pstdev(values) / mean * 100 if mean else 0.0
                stream.write(
                    f"{metric}\t{statistics.median(values):.3f}\t{min(values):.3f}\t"
                    f"{max(values):.3f}\t{cv:.3f}\n"
                )
    print(f"summarized {len(runs)} performance repetitions")
elif kind == "write-artifact-metadata":
    artifact_root = pathlib.Path(
        os.environ.get("PERFORMANCE_ARTIFACT_ROOT", str(root / "ci-artifacts"))
    )
    required_environment = (
        "GITHUB_REPOSITORY", "GITHUB_REF", "GITHUB_SHA", "GITHUB_WORKFLOW",
        "GITHUB_RUN_ID", "GITHUB_RUN_ATTEMPT", "GITHUB_SERVER_URL",
        "GITHUB_EVENT_NAME", "GITHUB_JOB", "RUNNER_OS", "RUNNER_ARCH", "JAVA_HOME",
        "PERFORMANCE_STARTED_AT",
    )
    missing = [name for name in required_environment if not os.environ.get(name)]
    if missing:
        raise SystemExit("missing performance metadata: " + ", ".join(missing))
    version_text = (pathlib.Path(os.environ["JAVA_HOME"]) / "release").read_text()
    java_match = re.search(r'^JAVA_VERSION="([^"]+)"$', version_text, re.MULTILINE)
    if not java_match or not java_match.group(1).startswith("17"):
        raise SystemExit("Java 17 could not be verified")
    wrapper = (root.parent / ".mvn/wrapper/maven-wrapper.properties").read_text()
    maven_match = re.search(r"apache-maven-([0-9.]+)-bin\.zip", wrapper)
    pom = ET.parse(root / "pom.xml").getroot()
    ns = {"m": "http://maven.apache.org/POM/4.0.0"}
    liberty = pom.find(".//m:liberty.runtime.version", ns)
    if not maven_match or liberty is None or not liberty.text:
        raise SystemExit("Maven Wrapper or Liberty version could not be resolved")
    event_is_pr = os.environ["GITHUB_EVENT_NAME"] == "pull_request"
    pr_number = os.environ.get("CI_PR_NUMBER", "")
    if event_is_pr and (not pr_number.isdigit() or int(pr_number) <= 0):
        raise SystemExit("CI_PR_NUMBER must be a positive integer")
    base_url = (
        f"{os.environ['GITHUB_SERVER_URL']}/{os.environ['GITHUB_REPOSITORY']}"
    )
    artifacts = (
        ("performance-java", "performance-java",
         "bounded direct OpenJDK 17 performance evidence"),
        ("performance-jaz-bypassed", "performance-jaz-bypassed",
         "bounded bypassed jaz performance evidence"),
        ("performance-jaz-tuned", "performance-jaz-tuned",
         "bounded tuned jaz performance evidence"),
        ("performance-comparison", "performance-comparison",
         "paired diagnostic comparison of direct java and jaz"),
    )
    commands_template = None
    for relative, name, concern in artifacts:
        directory = artifact_root / relative
        commands_file = directory / "commands.txt"
        if not commands_file.is_file() or not commands_file.read_text().strip():
            raise SystemExit(f"performance command transcript is missing: {name}")
        commands = [line for line in commands_file.read_text().splitlines() if line]
        files = []
        for file in sorted(directory.rglob("*")):
            if file.is_file() and file.name != "artifact-metadata.json":
                content = file.read_bytes()
                files.append({
                    "path": file.relative_to(directory).as_posix(),
                    "bytes": len(content),
                    "sha256": hashlib.sha256(content).hexdigest(),
                })
        if not files:
            raise SystemExit(f"performance artifact inventory is empty: {name}")
        metadata = {
            "schema": 1,
            "name": name,
            "concern": concern,
            "repository": os.environ["GITHUB_REPOSITORY"],
            "ref": os.environ["GITHUB_REF"],
            "sha": os.environ["GITHUB_SHA"],
            "workflow": os.environ["GITHUB_WORKFLOW"],
            "run": os.environ["GITHUB_RUN_ID"],
            "attempt": os.environ["GITHUB_RUN_ATTEMPT"],
            "url": f"{base_url}/actions/runs/{os.environ['GITHUB_RUN_ID']}",
            "job": os.environ["GITHUB_JOB"],
            "event": os.environ["GITHUB_EVENT_NAME"],
            "pr": pr_number if event_is_pr else "not-applicable",
            "runner": {
                "os": os.environ["RUNNER_OS"],
                "architecture": os.environ["RUNNER_ARCH"],
            },
            "tools": {
                "java": java_match.group(1),
                "maven": maven_match.group(1),
                "openLibertyRuntime": liberty.text,
                "jaz": "1.0.4 (amd64)" if name != "performance-java" else "not-used",
            },
            "startedAt": os.environ["PERFORMANCE_STARTED_AT"],
            "endedAt": datetime.now(timezone.utc).isoformat(),
            "commands": commands,
            "files": files,
        }
        (directory / "artifact-metadata.json").write_text(
            json.dumps(metadata, indent=2) + "\n"
        )
    print("performance artifact metadata and checksummed inventories written")
else:
    raise SystemExit(
        "usage: collect-process-metadata.sh "
        "{host|jfr-profile|find-server-pid|sample-server|ancestry|summarize}"
    )
PY
    ;;
  *)
    echo "usage: collect-process-metadata.sh {host|jfr-profile|find-server-pid|verify-jvm-option|sample-server|ancestry|summarize}" >&2
    exit 2
    ;;
esac
