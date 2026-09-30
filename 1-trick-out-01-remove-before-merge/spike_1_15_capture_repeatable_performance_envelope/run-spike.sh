#!/usr/bin/env bash

set -euo pipefail

SPIKE_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKTREE="$(cd "${SPIKE_DIRECTORY}/../.." && pwd)"
SCRATCH_ROOT="${SPIKE_DIRECTORY}/scratch"
SCRATCH_WORKTREE="${SCRATCH_ROOT}/worktree"
DEMO_DIRECTORY="${SCRATCH_WORKTREE}/demo"
REPORT_DIRECTORY="${SPIKE_DIRECTORY}/reports"
LOG_DIRECTORY="${SPIKE_DIRECTORY}/logs"
SAFE_JFR_CONFIGURATION="${REPORT_DIRECTORY}/profile-without-environment.jfc"
RUN_COUNT="${RUN_COUNT:-5}"
WARMUP_REQUESTS="${WARMUP_REQUESTS:-5}"
MEASURED_REQUESTS="${MEASURED_REQUESTS:-30}"
REQUEST_PACING_SECONDS="${REQUEST_PACING_SECONDS:-0.2}"
JFR_DURATION_SECONDS="${JFR_DURATION_SECONDS:-10}"
MAX_STARTUP_MS="${MAX_STARTUP_MS:-90000}"
MAX_TOTAL_MS="${MAX_TOTAL_MS:-120000}"
MAX_RSS_KB="${MAX_RSS_KB:-2097152}"
BASE_URL="${BASE_URL:-http://127.0.0.1:8080/cargo-tracker}"
SERVER_MAY_BE_RUNNING=false
CURRENT_RUN_DIRECTORY=""

export JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/msopenjdk-17-amd64}"
export ANT_HOME="${ANT_HOME:-/usr/share/ant}"
export M2_HOME="${M2_HOME:-/usr/share/maven}"
export PATH="${M2_HOME}/bin:${ANT_HOME}/bin:${JAVA_HOME}/bin:${PATH}"

mkdir -p "${REPORT_DIRECTORY}" "${LOG_DIRECTORY}" "${SCRATCH_ROOT}"

timestamp_ms() {
  date +%s%3N
}

run_maven() {
  local phase="$1"
  shift
  local phase_directory="${LOG_DIRECTORY}/${phase}"
  local log
  local status

  mkdir -p "${phase_directory}"
  log="${phase_directory}/$(date +%Y%m%d-%H%M)-job-logs.txt"

  set +e
  (
    cd "${DEMO_DIRECTORY}"
    ./mvnw --batch-mode --no-transfer-progress "$@"
  ) 2>&1 | tee "${log}"
  status="${PIPESTATUS[0]}"
  set -e

  printf '%s\n' "${log}" > "${phase_directory}/log-path.txt"
  return "${status}"
}

start_maven_background() {
  local phase="$1"
  shift
  local phase_directory="${LOG_DIRECTORY}/${phase}"
  local log

  mkdir -p "${phase_directory}"
  log="${phase_directory}/$(date +%Y%m%d-%H%M)-job-logs.txt"
  printf '%s\n' "${log}" > "${phase_directory}/log-path.txt"

  (
    cd "${DEMO_DIRECTORY}"
    ./mvnw --batch-mode --no-transfer-progress "$@"
  ) 2>&1 | tee "${log}" &
  MAVEN_BACKGROUND_PID="$!"
}

find_server_pid() {
  local runtime="${DEMO_DIRECTORY}/target/liberty/wlp"

  ps -eo pid=,args= |
    awk -v runtime="${runtime}" '
      index($0, runtime) && /ws-server\.jar/ {
        print $1
        exit
      }
    '
}

sample_process() {
  local pid="$1"
  local output="$2"
  local stop_file="$3"
  local rss
  local stat
  local utime
  local stime

  printf 'timestamp_ms\trss_kb\tcpu_ticks\n' > "${output}"
  while [[ ! -e "${stop_file}" && -r "/proc/${pid}/stat" ]]; do
    rss="$(
      awk '/^VmRSS:/ { print $2; found=1 } END { if (!found) print 0 }' \
        "/proc/${pid}/status" 2>/dev/null || printf '0'
    )"
    stat="$(cat "/proc/${pid}/stat" 2>/dev/null || true)"
    if [[ -z "${stat}" ]]; then
      break
    fi
    utime="$(awk '{ print $14 }' <<< "${stat}")"
    stime="$(awk '{ print $15 }' <<< "${stat}")"
    printf '%s\t%s\t%s\n' \
      "$(timestamp_ms)" \
      "${rss}" \
      "$((utime + stime))" \
      >> "${output}"
    sleep 0.2
  done
}

capture_runner_metadata() {
  local cgroup_file
  local output="${REPORT_DIRECTORY}/environment.txt"

  {
    printf 'commit=%s\n' "$(git -C "${WORKTREE}" rev-parse HEAD)"
    printf 'captured_at=%s\n' "$(date --iso-8601=seconds)"
    printf 'java_home=%s\n' "${JAVA_HOME}"
    printf 'java_version_begin\n'
    java -version 2>&1
    printf 'java_version_end\n'
    printf 'maven_version_begin\n'
    (
      cd "${DEMO_DIRECTORY}"
      ./mvnw --version
    )
    printf 'maven_version_end\n'
    printf 'uname=%s\n' "$(uname -a)"
    printf 'cpu_count=%s\n' "$(nproc)"
    printf 'clock_ticks=%s\n' "$(getconf CLK_TCK)"
    printf 'lscpu_begin\n'
    lscpu
    printf 'lscpu_end\n'
    printf 'memory_begin\n'
    free -b
    printf 'memory_end\n'
    printf 'cgroup_membership_begin\n'
    cat /proc/self/cgroup
    printf 'cgroup_membership_end\n'
    for cgroup_file in \
      /sys/fs/cgroup/cpu.max \
      /sys/fs/cgroup/cpu.weight \
      /sys/fs/cgroup/memory.max \
      /sys/fs/cgroup/memory.high \
      /sys/fs/cgroup/memory.current; do
      if [[ -r "${cgroup_file}" ]]; then
        printf '%s=%s\n' "${cgroup_file}" "$(cat "${cgroup_file}")"
      fi
    done
  } > "${output}"
}

restore_pristine_server() {
  local server_directory="${DEMO_DIRECTORY}/target/liberty/wlp/usr/servers/defaultServer"
  local pid_file="${DEMO_DIRECTORY}/target/liberty/wlp/usr/servers/.pid/defaultServer.pid"
  local template="${SCRATCH_ROOT}/defaultServer-template"

  rm -rf "${server_directory}"
  cp -a "${template}" "${server_directory}"
  rm -f "${pid_file}"
}

configure_gc_log() {
  local run_directory="$1"
  local server_env="${DEMO_DIRECTORY}/target/liberty/wlp/usr/servers/defaultServer/server.env"
  local temporary="${server_env}.tmp"
  local gc_log="${run_directory}/gc-%p.log"

  if [[ -f "${server_env}" ]]; then
    grep -v '^JVM_ARGS=' "${server_env}" > "${temporary}" || true
  else
    : > "${temporary}"
  fi
  printf 'JVM_ARGS=-Xlog:gc*,safepoint:file=%s:time,uptime,level,tags\n' \
    "${gc_log}" >> "${temporary}"
  mv "${temporary}" "${server_env}"
}

wait_for_server_pid() {
  local deadline="$((SECONDS + 90))"
  local pid=""

  while ((SECONDS < deadline)); do
    pid="$(find_server_pid || true)"
    if [[ -n "${pid}" ]]; then
      printf '%s\n' "${pid}"
      return 0
    fi
    if ! kill -0 "${MAVEN_BACKGROUND_PID}" 2>/dev/null; then
      break
    fi
    sleep 0.1
  done
  return 1
}

wait_for_readiness() {
  local run_directory="$1"
  local deadline="$((SECONDS + 60))"
  local status
  local body="${run_directory}/readiness.body"
  local headers="${run_directory}/readiness.headers"

  while ((SECONDS < deadline)); do
    status="$(
      curl \
        --silent \
        --show-error \
        --max-time 3 \
        --dump-header "${headers}" \
        --output "${body}" \
        --write-out '%{http_code}' \
        "${BASE_URL}/rest/cargo" 2>/dev/null || true
    )"
    if [[ "${status}" == "200" ]] &&
      grep --fixed-strings --quiet '"trackingId":"ABC123"' "${body}"; then
      return 0
    fi
    sleep 0.2
  done
  return 1
}

request_once() {
  local output_body="$1"
  local output_line
  local status

  output_line="$(
    curl \
      --silent \
      --show-error \
      --max-time 10 \
      --output "${output_body}" \
      --write-out '%{http_code}\t%{time_total}\t%{size_download}' \
      "${BASE_URL}/rest/cargo"
  )"
  status="${output_line%%$'\t'*}"
  if [[ "${status}" != "200" ]]; then
    printf 'Measured request returned HTTP %s\n' "${status}" >&2
    return 1
  fi
  if ! grep --fixed-strings --quiet '"trackingId":"ABC123"' "${output_body}"; then
    printf 'Measured response did not contain seeded cargo ABC123\n' >&2
    return 1
  fi
  printf '%s\n' "${output_line}"
}

capture_jvm_diagnostics() {
  local pid="$1"
  local run_directory="$2"
  local phase="$3"

  jcmd "${pid}" VM.command_line > "${run_directory}/jvm-command-line-${phase}.txt"
  jcmd "${pid}" VM.flags -all > "${run_directory}/jvm-flags-${phase}.txt"
  jcmd "${pid}" GC.heap_info > "${run_directory}/heap-${phase}.txt"
}

analyze_run() {
  local run_number="$1"
  local run_directory="$2"
  local startup_ms="$3"
  local total_ms="$4"
  local process_samples="${run_directory}/process-samples.tsv"
  local request_samples="${run_directory}/requests.tsv"
  local jfr="${run_directory}/recording.jfr"
  local server_pid="$5"
  local gc_log="${run_directory}/gc-${server_pid}.log"
  local heap_before="${run_directory}/heap-before.txt"
  local heap_after="${run_directory}/heap-after.txt"

  python3 - \
    "${run_number}" \
    "${startup_ms}" \
    "${total_ms}" \
    "${process_samples}" \
    "${request_samples}" \
    "${jfr}" \
    "${gc_log}" \
    "${heap_before}" \
    "${heap_after}" \
    "${REPORT_DIRECTORY}/run-summary.tsv" <<'PY'
import csv
import os
import re
import statistics
import sys

(
    run_number,
    startup_ms,
    total_ms,
    process_path,
    request_path,
    jfr_path,
    gc_path,
    heap_before_path,
    heap_after_path,
    summary_path,
) = sys.argv[1:]

with open(process_path, newline="", encoding="utf-8") as handle:
    process_rows = list(csv.DictReader(handle, delimiter="\t"))

with open(request_path, newline="", encoding="utf-8") as handle:
    request_rows = list(csv.DictReader(handle, delimiter="\t"))

rss_values = [int(row["rss_kb"]) for row in process_rows]
cpu_ticks = [int(row["cpu_ticks"]) for row in process_rows]
request_ms = [float(row["time_seconds"]) * 1000 for row in request_rows]

def heap_used_kb(path):
    with open(path, encoding="utf-8") as handle:
        match = re.search(r"garbage-first heap\s+total \d+K, used (\d+)K", handle.read())
    if not match:
        raise RuntimeError(f"Unable to parse heap usage from {path}")
    return int(match.group(1))

gc_pause_ms = []
with open(gc_path, encoding="utf-8") as handle:
    for line in handle:
        match = re.search(
            r"\[gc\s*\].*GC\(\d+\) Pause .* ([0-9.]+)ms$", line.rstrip()
        )
        if match:
            gc_pause_ms.append(float(match.group(1)))

def coefficient_of_variation(values):
    mean = statistics.fmean(values)
    return 0.0 if mean == 0 else statistics.pstdev(values) / mean * 100

clock_ticks = os.sysconf(os.sysconf_names["SC_CLK_TCK"])
cpu_seconds = 0.0
if len(cpu_ticks) >= 2:
    cpu_seconds = (cpu_ticks[-1] - cpu_ticks[0]) / clock_ticks

row = [
    run_number,
    startup_ms,
    len(request_ms),
    f"{min(request_ms):.3f}",
    f"{statistics.median(request_ms):.3f}",
    f"{max(request_ms):.3f}",
    f"{coefficient_of_variation(request_ms):.3f}",
    max(rss_values),
    f"{cpu_seconds:.3f}",
    heap_used_kb(heap_before_path),
    heap_used_kb(heap_after_path),
    len(gc_pause_ms),
    f"{sum(gc_pause_ms):.3f}",
    total_ms,
    os.path.getsize(jfr_path),
    os.path.getsize(gc_path),
    "PASS",
]

with open(summary_path, "a", newline="", encoding="utf-8") as handle:
    csv.writer(handle, delimiter="\t", lineterminator="\n").writerow(row)
PY
}

summarize_all_runs() {
  python3 - \
    "${REPORT_DIRECTORY}/run-summary.tsv" \
    "${REPORT_DIRECTORY}/statistics.tsv" \
    "${REPORT_DIRECTORY}/results.json" \
    "${REPORT_DIRECTORY}" \
    "${REPORT_DIRECTORY}/request-distribution.tsv" <<'PY'
import csv
import glob
import json
import math
import statistics
import sys

summary_path, statistics_path, json_path, report_directory, request_output = sys.argv[1:]

with open(summary_path, newline="", encoding="utf-8") as handle:
    rows = list(csv.DictReader(handle, delimiter="\t"))

metrics = {
    "startup_ms": [float(row["startup_ms"]) for row in rows],
    "request_median_ms": [float(row["request_median_ms"]) for row in rows],
    "peak_rss_kb": [float(row["peak_rss_kb"]) for row in rows],
    "cpu_seconds": [float(row["cpu_seconds"]) for row in rows],
    "heap_before_kb": [float(row["heap_before_kb"]) for row in rows],
    "heap_after_kb": [float(row["heap_after_kb"]) for row in rows],
    "gc_pause_count": [float(row["gc_pause_count"]) for row in rows],
    "gc_pause_total_ms": [float(row["gc_pause_total_ms"]) for row in rows],
    "total_ms": [float(row["total_ms"]) for row in rows],
}

def stats(values):
    mean = statistics.fmean(values)
    return {
        "minimum": min(values),
        "median": statistics.median(values),
        "maximum": max(values),
        "range": max(values) - min(values),
        "coefficient_of_variation_percent": (
            0.0 if mean == 0 else statistics.pstdev(values) / mean * 100
        ),
    }

summary = {name: stats(values) for name, values in metrics.items()}

request_values = []
for path in sorted(glob.glob(f"{report_directory}/run-[0-9][0-9]/requests.tsv")):
    with open(path, newline="", encoding="utf-8") as handle:
        request_values.extend(
            float(row["time_seconds"]) * 1000
            for row in csv.DictReader(handle, delimiter="\t")
        )

def percentile(values, percentage):
    ordered = sorted(values)
    index = max(0, math.ceil(len(ordered) * percentage / 100) - 1)
    return ordered[index]

request_summary = {
    "count": len(request_values),
    "minimum_ms": min(request_values),
    "median_ms": statistics.median(request_values),
    "p90_ms": percentile(request_values, 90),
    "p95_ms": percentile(request_values, 95),
    "p99_ms": percentile(request_values, 99),
    "maximum_ms": max(request_values),
    "coefficient_of_variation_percent": (
        statistics.pstdev(request_values) / statistics.fmean(request_values) * 100
    ),
}

with open(statistics_path, "w", newline="", encoding="utf-8") as handle:
    writer = csv.writer(handle, delimiter="\t", lineterminator="\n")
    writer.writerow(
        ["metric", "minimum", "median", "maximum", "range", "cv_percent"]
    )
    for name, values in summary.items():
        writer.writerow(
            [
                name,
                f"{values['minimum']:.3f}",
                f"{values['median']:.3f}",
                f"{values['maximum']:.3f}",
                f"{values['range']:.3f}",
                f"{values['coefficient_of_variation_percent']:.3f}",
            ]
        )

with open(json_path, "w", encoding="utf-8") as handle:
    json.dump(
        {
            "run_count": len(rows),
            "runs": rows,
            "statistics": summary,
            "request_distribution": request_summary,
        },
        handle,
        indent=2,
    )
    handle.write("\n")

with open(request_output, "w", newline="", encoding="utf-8") as handle:
    writer = csv.writer(handle, delimiter="\t", lineterminator="\n")
    writer.writerow(
        ["count", "minimum_ms", "median_ms", "p90_ms", "p95_ms", "p99_ms", "maximum_ms", "cv_percent"]
    )
    writer.writerow(
        [
            request_summary["count"],
            f"{request_summary['minimum_ms']:.3f}",
            f"{request_summary['median_ms']:.3f}",
            f"{request_summary['p90_ms']:.3f}",
            f"{request_summary['p95_ms']:.3f}",
            f"{request_summary['p99_ms']:.3f}",
            f"{request_summary['maximum_ms']:.3f}",
            f"{request_summary['coefficient_of_variation_percent']:.3f}",
        ]
    )
PY
}

preserve_liberty_logs() {
  local run_directory="$1"
  local liberty_logs="${DEMO_DIRECTORY}/target/liberty/wlp/usr/servers/defaultServer/logs"

  if [[ -f "${liberty_logs}/messages.log" ]]; then
    cp "${liberty_logs}/messages.log" "${run_directory}/liberty-messages.log"
  fi
  if [[ -f "${liberty_logs}/console.log" ]]; then
    cp "${liberty_logs}/console.log" "${run_directory}/liberty-console.log"
  fi
}

stop_current_server() {
  local phase="$1"

  if [[ "${SERVER_MAY_BE_RUNNING}" == true ]]; then
    set +e
    run_maven "${phase}" liberty:stop
    local status="$?"
    set -e
    SERVER_MAY_BE_RUNNING=false
    return "${status}"
  fi
}

cleanup() {
  local status="$?"

  trap - EXIT
  if [[ -n "${CURRENT_RUN_DIRECTORY}" ]]; then
    preserve_liberty_logs "${CURRENT_RUN_DIRECTORY}"
  fi
  stop_current_server cleanup-stop || true
  rm -rf "${SCRATCH_ROOT}"
  exit "${status}"
}
trap cleanup EXIT

if curl --silent --max-time 2 "${BASE_URL}/" >/dev/null; then
  printf 'Refusing to run because %s is already responding.\n' "${BASE_URL}" >&2
  exit 1
fi

rm -rf "${SCRATCH_ROOT}" "${REPORT_DIRECTORY}" "${LOG_DIRECTORY}"
mkdir -p "${SCRATCH_ROOT}" "${REPORT_DIRECTORY}" "${LOG_DIRECTORY}"

git clone --quiet --shared "${WORKTREE}" "${SCRATCH_WORKTREE}"
git -C "${SCRATCH_WORKTREE}" checkout --quiet "$(git -C "${WORKTREE}" rev-parse HEAD)"

capture_runner_metadata

cat > "${REPORT_DIRECTORY}/workload-contract.txt" <<EOF
war=demo/target/cargo-tracker.war
liberty_server=defaultServer
readiness_endpoint=${BASE_URL}/rest/cargo
readiness_content="trackingId":"ABC123"
warmup_requests=${WARMUP_REQUESTS}
measured_requests=${MEASURED_REQUESTS}
request_concurrency=1
request_pacing_seconds=${REQUEST_PACING_SECONDS}
jfr_duration_seconds=${JFR_DURATION_SECONDS}
repetitions=${RUN_COUNT}
containerized=false
jfr_configuration=profile-without-environment.jfc
maximum_startup_ms=${MAX_STARTUP_MS}
maximum_total_ms=${MAX_TOTAL_MS}
maximum_peak_rss_kb=${MAX_RSS_KB}
EOF

printf 'run\tstartup_ms\trequest_count\trequest_min_ms\trequest_median_ms\trequest_max_ms\trequest_cv_percent\tpeak_rss_kb\tcpu_seconds\theap_before_kb\theap_after_kb\tgc_pause_count\tgc_pause_total_ms\ttotal_ms\tjfr_bytes\tgc_log_bytes\tresult\n' \
  > "${REPORT_DIRECTORY}/run-summary.tsv"

run_maven package -DskipTests clean package
run_maven deploy liberty:deploy

jfr configure \
  --input "${JAVA_HOME}/lib/jfr/profile.jfc" \
  --output "${SAFE_JFR_CONFIGURATION}" \
  jdk.JVMInformation#enabled=false \
  jdk.InitialSystemProperty#enabled=false \
  jdk.OSInformation#enabled=false \
  jdk.InitialEnvironmentVariable#enabled=false \
  jdk.SystemProcess#enabled=false \
  > "${REPORT_DIRECTORY}/jfr-configuration.txt"

WAR="${DEMO_DIRECTORY}/target/cargo-tracker.war"
SERVER="${DEMO_DIRECTORY}/target/liberty/wlp/usr/servers/defaultServer"
RUNTIME="${DEMO_DIRECTORY}/target/liberty/wlp"

(
  cd "${DEMO_DIRECTORY}"
  sha256sum target/cargo-tracker.war
) > "${REPORT_DIRECTORY}/war.sha256"
(
  cd "${DEMO_DIRECTORY}"
  sha256sum target/liberty/wlp/usr/servers/defaultServer/server.xml
) > "${REPORT_DIRECTORY}/server-xml.sha256"
(
  cd "${RUNTIME}"
  find . -type f -print0 |
    sort -z |
    xargs -0 sha256sum |
    sha256sum
) > "${REPORT_DIRECTORY}/liberty-runtime-manifest.sha256"
"${RUNTIME}/bin/productInfo" version \
  > "${REPORT_DIRECTORY}/liberty-version.txt" 2>&1

cp -a "${SERVER}" "${SCRATCH_ROOT}/defaultServer-template"

for run_number in $(seq 1 "${RUN_COUNT}"); do
  run_name="$(printf 'run-%02d' "${run_number}")"
  run_directory="${REPORT_DIRECTORY}/${run_name}"
  CURRENT_RUN_DIRECTORY="${run_directory}"
  mkdir -p "${run_directory}"

  restore_pristine_server
  configure_gc_log "${run_directory}"

  repetition_start_ms="$(timestamp_ms)"
  start_maven_background "${run_name}-start" \
    -Dapplications=cargo-tracker \
    -DserverStartTimeout=90 \
    liberty:start

  server_pid="$(wait_for_server_pid)"
  printf '%s\n' "${server_pid}" > "${run_directory}/server.pid"
  SERVER_MAY_BE_RUNNING=true

  sampler_stop="${run_directory}/sampler.stop"
  sample_process \
    "${server_pid}" \
    "${run_directory}/process-samples.tsv" \
    "${sampler_stop}" &
  sampler_pid="$!"

  set +e
  wait "${MAVEN_BACKGROUND_PID}"
  start_status="$?"
  set -e
  if [[ "${start_status}" -ne 0 ]]; then
    printf 'Liberty start failed for repetition %s\n' "${run_number}" >&2
    exit "${start_status}"
  fi

  wait_for_readiness "${run_directory}"
  ready_ms="$(timestamp_ms)"
  startup_ms="$((ready_ms - repetition_start_ms))"
  printf '%s\n' "${startup_ms}" > "${run_directory}/startup-ms.txt"
  if ((startup_ms > MAX_STARTUP_MS)); then
    printf 'Startup took %s ms, exceeding the %s ms bound\n' \
      "${startup_ms}" "${MAX_STARTUP_MS}" >&2
    exit 1
  fi

  capture_jvm_diagnostics "${server_pid}" "${run_directory}" before

  printf 'request\tstatus\ttime_seconds\tsize_bytes\n' \
    > "${run_directory}/warmup-requests.tsv"
  for request_number in $(seq 1 "${WARMUP_REQUESTS}"); do
    request_result="$(
      request_once "${run_directory}/warmup-response.body"
    )"
    printf '%s\t%s\n' "${request_number}" "${request_result}" \
      >> "${run_directory}/warmup-requests.tsv"
  done

  jcmd "${server_pid}" JFR.start \
    "name=spike-${run_name}" \
    "settings=${SAFE_JFR_CONFIGURATION}" \
    "duration=${JFR_DURATION_SECONDS}s" \
    "filename=${run_directory}/recording.jfr" \
    > "${run_directory}/jfr-start.txt"

  printf 'request\tstatus\ttime_seconds\tsize_bytes\n' \
    > "${run_directory}/requests.tsv"
  for request_number in $(seq 1 "${MEASURED_REQUESTS}"); do
    request_result="$(
      request_once "${run_directory}/measured-response.body"
    )"
    printf '%s\t%s\n' "${request_number}" "${request_result}" \
      >> "${run_directory}/requests.tsv"
    sleep "${REQUEST_PACING_SECONDS}"
  done

  jfr_deadline="$((SECONDS + JFR_DURATION_SECONDS + 20))"
  while [[ ! -s "${run_directory}/recording.jfr" ]] &&
    ((SECONDS < jfr_deadline)); do
    sleep 1
  done
  if [[ ! -s "${run_directory}/recording.jfr" ]]; then
    printf 'JFR recording was not created for repetition %s\n' \
      "${run_number}" >&2
    exit 1
  fi

  jfr summary "${run_directory}/recording.jfr" \
    > "${run_directory}/jfr-summary.txt"
  if awk '
      $1 == "jdk.JVMInformation" && $2 != 0 { found=1 }
      $1 == "jdk.InitialSystemProperty" && $2 != 0 { found=1 }
      $1 == "jdk.OSInformation" && $2 != 0 { found=1 }
      $1 == "jdk.InitialEnvironmentVariable" && $2 != 0 { found=1 }
      $1 == "jdk.SystemProcess" && $2 != 0 { found=1 }
      END { exit found ? 0 : 1 }
    ' "${run_directory}/jfr-summary.txt"; then
    printf 'JFR contains an event type excluded by the safe profile\n' >&2
    exit 1
  fi
  capture_jvm_diagnostics "${server_pid}" "${run_directory}" after

  touch "${sampler_stop}"
  wait "${sampler_pid}"

  preserve_liberty_logs "${run_directory}"
  stop_current_server "${run_name}-stop"

  repetition_end_ms="$(timestamp_ms)"
  total_ms="$((repetition_end_ms - repetition_start_ms))"
  printf '%s\n' "${total_ms}" > "${run_directory}/total-ms.txt"
  if ((total_ms > MAX_TOTAL_MS)); then
    printf 'Repetition took %s ms, exceeding the %s ms bound\n' \
      "${total_ms}" "${MAX_TOTAL_MS}" >&2
    exit 1
  fi

  peak_rss_kb="$(
    awk -F '\t' 'NR > 1 && $2 > maximum { maximum=$2 } END { print maximum+0 }' \
      "${run_directory}/process-samples.tsv"
  )"
  if ((peak_rss_kb > MAX_RSS_KB)); then
    printf 'Peak RSS was %s KiB, exceeding the %s KiB bound\n' \
      "${peak_rss_kb}" "${MAX_RSS_KB}" >&2
    exit 1
  fi

  if [[ ! -s "${run_directory}/gc-${server_pid}.log" ]]; then
    printf 'GC log was not created for repetition %s\n' "${run_number}" >&2
    exit 1
  fi

  analyze_run \
    "${run_number}" \
    "${run_directory}" \
    "${startup_ms}" \
    "${total_ms}" \
    "${server_pid}"
  CURRENT_RUN_DIRECTORY=""
done

summarize_all_runs

rm -rf "${SCRATCH_ROOT}"
trap - EXIT

printf 'Performance-envelope spike passed. Evidence: %s\n' \
  "${REPORT_DIRECTORY}"
