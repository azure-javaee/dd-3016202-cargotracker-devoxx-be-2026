#!/usr/bin/env bash

set -euo pipefail

SPIKE_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKTREE="$(cd "${SPIKE_DIRECTORY}/../.." && pwd)"
BASELINE_SPIKE_DIRECTORY="${SPIKE_DIRECTORY}/../spike_1_15_capture_repeatable_performance_envelope"
BASELINE_CONTRACT="${BASELINE_SPIKE_DIRECTORY}/reports/workload-contract.txt"
BASELINE_JFR_CONFIGURATION="${BASELINE_SPIKE_DIRECTORY}/reports/profile-without-environment.jfc"
SCRATCH_ROOT="${SPIKE_DIRECTORY}/scratch"
SCRATCH_WORKTREE="${SCRATCH_ROOT}/worktree"
DEMO_DIRECTORY="${SCRATCH_WORKTREE}/demo"
REPORT_DIRECTORY="${SPIKE_DIRECTORY}/reports"
LOG_DIRECTORY="${SPIKE_DIRECTORY}/logs"
SAFE_JFR_CONFIGURATION="${REPORT_DIRECTORY}/profile-without-environment.jfc"
JAZ_VERSION="${JAZ_VERSION:-1.0.4}"
JAZ_PACKAGE_SHA256="${JAZ_PACKAGE_SHA256:-3d479f11ff2a037790505746a44568e1408f2f79aac62300ea4c651c4969a710}"
JAZ_PACKAGE_URL="${JAZ_PACKAGE_URL:-https://packages.microsoft.com/ubuntu/24.04/prod/pool/main/j/jaz/jaz_${JAZ_VERSION}_amd64.deb}"
JAZ_PACKAGE="${SCRATCH_ROOT}/jaz_${JAZ_VERSION}_amd64.deb"
JAZ_INSTALL_ROOT="${SCRATCH_ROOT}/jaz-install"
JAZ_BINARY="${JAZ_INSTALL_ROOT}/usr/bin/jaz"
JAZ_JAVA_HOME="${SCRATCH_ROOT}/jaz-java-home"
JAZ_WRAPPER="${JAZ_JAVA_HOME}/bin/java"
REAL_JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/msopenjdk-17-amd64}"
SERVER_MAY_BE_RUNNING=false
CURRENT_RUN_DIRECTORY=""
CURRENT_SERVER_PID=""
CURRENT_LAUNCHER_PID=""

export JAVA_HOME="${REAL_JAVA_HOME}"
export ANT_HOME="${ANT_HOME:-/usr/share/ant}"
export M2_HOME="${M2_HOME:-/usr/share/maven}"
export PATH="${M2_HOME}/bin:${ANT_HOME}/bin:${JAVA_HOME}/bin:${PATH}"

contract_value() {
  local key="$1"

  awk -F '=' -v key="${key}" '
    $1 == key {
      sub(/^[^=]*=/, "")
      print
      found=1
      exit
    }
    END {
      if (!found) {
        exit 1
      }
    }
  ' "${BASELINE_CONTRACT}"
}

if [[ ! -s "${BASELINE_CONTRACT}" || ! -s "${BASELINE_JFR_CONFIGURATION}" ]]; then
  printf 'Spike 1.15 contract or safe JFR configuration is missing.\n' >&2
  exit 1
fi

BASELINE_READINESS_ENDPOINT="$(contract_value readiness_endpoint)"
BASE_URL="${BASELINE_READINESS_ENDPOINT%/rest/cargo}"
READINESS_CONTENT="$(contract_value readiness_content)"
WARMUP_REQUESTS="$(contract_value warmup_requests)"
MEASURED_REQUESTS="$(contract_value measured_requests)"
REQUEST_PACING_SECONDS="$(contract_value request_pacing_seconds)"
JFR_DURATION_SECONDS="$(contract_value jfr_duration_seconds)"
CONTRACT_REPETITIONS="$(contract_value repetitions)"
RUN_COUNT="${RUN_COUNT:-${CONTRACT_REPETITIONS}}"
MAX_STARTUP_MS="$(contract_value maximum_startup_ms)"
MAX_TOTAL_MS="$(contract_value maximum_total_ms)"
MAX_RSS_KB="$(contract_value maximum_peak_rss_kb)"

mkdir -p "${REPORT_DIRECTORY}" "${LOG_DIRECTORY}" "${SCRATCH_ROOT}"

timestamp_ms() {
  date +%s%3N
}

install_jaz() {
  local entry
  local tool

  mkdir -p "${JAZ_INSTALL_ROOT}"

  curl \
    --fail \
    --location \
    --silent \
    --show-error \
    "${JAZ_PACKAGE_URL}" \
    --output "${JAZ_PACKAGE}"
  printf '%s  %s\n' "${JAZ_PACKAGE_SHA256}" "${JAZ_PACKAGE}" |
    sha256sum --check \
      > "${REPORT_DIRECTORY}/jaz-package-check.txt"
  dpkg-deb -x "${JAZ_PACKAGE}" "${JAZ_INSTALL_ROOT}"
  dpkg-deb -I "${JAZ_PACKAGE}" \
    > "${REPORT_DIRECTORY}/jaz-package-metadata.txt"
  JAZ_PRINT_VERSION=1 "${JAZ_BINARY}" \
    > "${REPORT_DIRECTORY}/jaz-version.txt" 2>&1

  rm -rf "${JAZ_JAVA_HOME}"
  mkdir -p "$(dirname "${JAZ_WRAPPER}")"
  for entry in "${REAL_JAVA_HOME}"/*; do
    if [[ "$(basename "${entry}")" != bin ]]; then
      ln -s "${entry}" "${JAZ_JAVA_HOME}/$(basename "${entry}")"
    fi
  done
  for tool in "${REAL_JAVA_HOME}"/bin/*; do
    if [[ "$(basename "${tool}")" != java ]]; then
      ln -s "${tool}" "${JAZ_JAVA_HOME}/bin/$(basename "${tool}")"
    fi
  done

  cat > "${JAZ_WRAPPER}" <<EOF
#!/usr/bin/env bash

set -euo pipefail

jaz_binary="${JAZ_BINARY}"
mode="\${JAZ_WRAPPER_MODE:?}"
invocations="\${JAZ_WRAPPER_INVOCATIONS:?}"
dry_run_output="\${JAZ_WRAPPER_DRY_RUN_OUTPUT:-}"

{
  printf '%s\t%s\t%s\t' "\$(date +%s%3N)" "\$\$" "\${PPID}"
  printf '%q ' "\$@"
  printf '\n'
} >> "\${invocations}"

arguments=" \$* "
if [[ "\${mode}" == tuned &&
      "\${arguments}" == *"ws-server.jar"* &&
      "\${arguments}" != *" --status"* &&
      "\${arguments}" != *" --stop"* &&
      "\${arguments}" != *" --version"* &&
      -n "\${dry_run_output}" ]] &&
  mkdir "\${dry_run_output}.lock" 2>/dev/null; then
  set +e
  JAZ_DRY_RUN=1 "\${jaz_binary}" "\$@" > "\${dry_run_output}" 2>&1
  dry_run_status="\$?"
  set -e
  printf '%s\n' "\${dry_run_status}" > "\${dry_run_output}.status"
  if [[ "\${dry_run_status}" -ne 1 ]]; then
    printf 'Expected jaz dry run to exit 1, got %s\n' \
      "\${dry_run_status}" >&2
    exit 1
  fi
fi

exec "\${jaz_binary}" "\$@"
EOF
  chmod +x "${JAZ_WRAPPER}"
  cp "${JAZ_WRAPPER}" "${REPORT_DIRECTORY}/jaz-java-wrapper.sh"
}

run_jaz_dry_probe() {
  local name="$1"
  shift
  local output="${REPORT_DIRECTORY}/${name}.txt"
  local status

  set +e
  JAZ_DRY_RUN=1 \
    JAZ_EXIT_WITHOUT_FLUSH=1 \
    "${JAZ_BINARY}" "$@" > "${output}" 2>&1
  status="$?"
  set -e
  printf '%s\n' "${status}" > "${output}.status"
  if [[ "${status}" -ne 1 ]]; then
    printf 'Expected jaz dry-run probe %s to exit 1, got %s\n' \
      "${name}" "${status}" >&2
    return 1
  fi
}

verify_jaz_preflight() {
  local tuned="${REPORT_DIRECTORY}/jaz-dry-run-tuned.txt"
  local xlog="${REPORT_DIRECTORY}/jaz-dry-run-xlog.txt"
  local bypass="${REPORT_DIRECTORY}/jaz-dry-run-bypass.txt"
  local suppressed="${REPORT_DIRECTORY}/jaz-dry-run-user-tuning.txt"

  run_jaz_dry_probe jaz-dry-run-tuned -version
  run_jaz_dry_probe jaz-dry-run-xlog \
    -Xlog:gc:file=/tmp/jaz-spike-gc.log -version

  set +e
  JAZ_BYPASS=1 \
    JAZ_DRY_RUN=1 \
    JAZ_EXIT_WITHOUT_FLUSH=1 \
    "${JAZ_BINARY}" -version > "${bypass}" 2>&1
  bypass_status="$?"
  set -e
  printf '%s\n' "${bypass_status}" > "${bypass}.status"
  if [[ "${bypass_status}" -ne 1 ]]; then
    printf 'Expected bypassed jaz dry run to exit 1, got %s\n' \
      "${bypass_status}" >&2
    return 1
  fi

  run_jaz_dry_probe jaz-dry-run-user-tuning -Xmx256m -version

  grep --fixed-strings --quiet -- '-XX:NativeMemoryTracking=summary' "${tuned}"
  grep --fixed-strings --quiet -- '-XX:G1PeriodicGCInterval=10000' "${tuned}"
  grep --fixed-strings --quiet -- '-Xlog:gc:file=/tmp/jaz-spike-gc.log' "${xlog}"
  grep --fixed-strings --quiet -- '-XX:NativeMemoryTracking=summary' "${xlog}"
  grep --fixed-strings --quiet -- '-XX:NativeMemoryTracking=summary' "${bypass}"
  if grep --fixed-strings --quiet -- '-XX:G1PeriodicGCInterval=10000' \
    "${bypass}"; then
    printf 'JAZ_BYPASS unexpectedly retained jaz GC tuning\n' >&2
    return 1
  fi
  grep --fixed-strings --quiet -- '-Xmx256m' "${suppressed}"
  grep --fixed-strings --quiet -- \
    '-XX:NativeMemoryTracking=summary' "${suppressed}"
  if grep --fixed-strings --quiet -- '-XX:G1PeriodicGCInterval=10000' \
    "${suppressed}"; then
    printf 'User tuning did not suppress normal jaz tuning\n' >&2
    return 1
  fi

  cat > "${REPORT_DIRECTORY}/jaz-preflight-summary.txt" <<EOF
jaz_version=${JAZ_VERSION}
tuned_dry_run=PASS
xlog_does_not_suppress_tuning=PASS
bypass_removes_heap_gc_tuning=PASS
user_tuning_suppresses_tuning=PASS
EOF
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
  local pid
  local arguments
  local executable
  local expected_java

  expected_java="$(readlink -f "${REAL_JAVA_HOME}/bin/java")"

  while read -r pid arguments; do
    if [[ "${arguments}" != *"${runtime}"* ||
      "${arguments}" != *"ws-server.jar"* ||
      "${arguments}" == *"--pid="* ||
      "${arguments}" == *"--status"* ||
      "${arguments}" == *"--stop"* ]]; then
      continue
    fi
    executable="$(readlink -f "/proc/${pid}/exe" 2>/dev/null || true)"
    if [[ "${executable}" == "${expected_java}" ]]; then
      printf '%s\n' "${pid}"
      return 0
    fi
  done < <(ps -eo pid=,args=)

  return 1
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

configure_server_mode() {
  local mode="$1"
  local run_directory="$2"
  local server_env="${DEMO_DIRECTORY}/target/liberty/wlp/usr/servers/defaultServer/server.env"
  local temporary="${server_env}.tmp"
  local gc_log="${run_directory}/gc-%p.log"

  if [[ -f "${server_env}" ]]; then
    grep -Ev \
      '^(JAVA_HOME|JVM_ARGS|JAZ_BYPASS|JAZ_EXIT_WITHOUT_FLUSH|JAZ_WRAPPER_MODE|JAZ_WRAPPER_INVOCATIONS|JAZ_WRAPPER_DRY_RUN_OUTPUT)=' \
      "${server_env}" > "${temporary}" || true
  else
    : > "${temporary}"
  fi

  case "${mode}" in
    direct)
      printf 'JAVA_HOME=%s\n' "${REAL_JAVA_HOME}" >> "${temporary}"
      ;;
    bypass)
      printf 'JAVA_HOME=%s\n' "${JAZ_JAVA_HOME}" >> "${temporary}"
      printf 'JAZ_BYPASS=1\n' >> "${temporary}"
      ;;
    tuned)
      printf 'JAVA_HOME=%s\n' "${JAZ_JAVA_HOME}" >> "${temporary}"
      ;;
    *)
      printf 'Unknown launch mode: %s\n' "${mode}" >&2
      return 1
      ;;
  esac

  if [[ "${mode}" != direct ]]; then
    : > "${run_directory}/jaz-invocations.tsv"
    printf 'JAZ_EXIT_WITHOUT_FLUSH=1\n' >> "${temporary}"
    printf 'JAZ_WRAPPER_MODE=%s\n' "${mode}" >> "${temporary}"
    printf 'JAZ_WRAPPER_INVOCATIONS=%s\n' \
      "${run_directory}/jaz-invocations.tsv" >> "${temporary}"
    printf 'JAZ_WRAPPER_DRY_RUN_OUTPUT=%s\n' \
      "${run_directory}/jaz-dry-run.txt" >> "${temporary}"
  fi

  printf 'JVM_ARGS=-Xlog:gc*,safepoint:file=%s:time,uptime,level,tags\n' \
    "${gc_log}" >> "${temporary}"
  mv "${temporary}" "${server_env}"
  cp "${server_env}" "${run_directory}/server.env"
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

find_jaz_ancestor() {
  local pid="$1"
  local current="${pid}"
  local parent
  local executable

  for _ in 1 2 3 4 5 6; do
    parent="$(
      awk '/^PPid:/ { print $2 }' "/proc/${current}/status" 2>/dev/null || true
    )"
    if [[ -z "${parent}" || "${parent}" == 0 || "${parent}" == 1 ]]; then
      return 1
    fi
    executable="$(readlink -f "/proc/${parent}/exe" 2>/dev/null || true)"
    if [[ "${executable}" == "$(readlink -f "${JAZ_BINARY}")" ]]; then
      printf '%s\n' "${parent}"
      return 0
    fi
    current="${parent}"
  done
  return 1
}

capture_process_tree() {
  local server_pid="$1"
  local launcher_pid="$2"
  local output="$3"

  {
    printf 'server_pid=%s\n' "${server_pid}"
    printf 'launcher_pid=%s\n' "${launcher_pid:-none}"
    printf 'processes_begin\n'
    ps -eo pid=,ppid=,stat=,comm=,args= |
      awk \
        -v server_pid="${server_pid}" \
        -v launcher_pid="${launcher_pid:-0}" \
        -v scratch="${SCRATCH_ROOT}" \
        -v jaz="${JAZ_BINARY}" '
          $1 == server_pid ||
          $1 == launcher_pid ||
          index($0, scratch) ||
          index($0, jaz)
        '
    printf 'processes_end\n'
  } > "${output}"
}

verify_process_cleanup() {
  local server_pid="$1"
  local launcher_pid="$2"
  local deadline="$((SECONDS + 15))"

  while ((SECONDS < deadline)); do
    if ! kill -0 "${server_pid}" 2>/dev/null &&
      { [[ -z "${launcher_pid}" ]] || ! kill -0 "${launcher_pid}" 2>/dev/null; }; then
      return 0
    fi
    sleep 0.2
  done

  printf 'Server or jaz launcher remained after Liberty stop\n' >&2
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
      grep --fixed-strings --quiet "${READINESS_CONTENT}" "${body}"; then
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
  if ! grep --fixed-strings --quiet "${READINESS_CONTENT}" "${output_body}"; then
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

flag_value() {
  local flags_file="$1"
  local flag_name="$2"

  awk -v flag_name="${flag_name}" '
    $2 == flag_name {
      for (field=1; field<=NF; field++) {
        if ($field == "=") {
          print $(field + 1)
          exit
        }
      }
    }
  ' "${flags_file}"
}

verify_mode_flags() {
  local mode="$1"
  local flags_file="$2"
  local native_memory_tracking
  local periodic_gc

  native_memory_tracking="$(flag_value "${flags_file}" NativeMemoryTracking)"
  periodic_gc="$(flag_value "${flags_file}" G1PeriodicGCInterval)"

  case "${mode}" in
    direct)
      [[ "${native_memory_tracking}" == off ]]
      [[ "${periodic_gc}" == 0 ]]
      ;;
    bypass)
      [[ "${native_memory_tracking}" == summary ]]
      [[ "${periodic_gc}" == 0 ]]
      [[ "$(flag_value "${flags_file}" MinHeapFreeRatio)" == 40 ]]
      [[ "$(flag_value "${flags_file}" MaxHeapFreeRatio)" == 70 ]]
      ;;
    tuned)
      [[ "${native_memory_tracking}" == summary ]]
      [[ "${periodic_gc}" == 10000 ]]
      [[ "$(flag_value "${flags_file}" MinHeapFreeRatio)" == 10 ]]
      [[ "$(flag_value "${flags_file}" MaxHeapFreeRatio)" == 50 ]]
      [[ "$(flag_value "${flags_file}" G1UseTimeBasedHeapSizing)" == true ]]
      ;;
  esac
}

mode_order_for_cycle() {
  case "$((($1 - 1) % 6))" in
    0) printf '%s\n' 'direct bypass tuned' ;;
    1) printf '%s\n' 'bypass tuned direct' ;;
    2) printf '%s\n' 'tuned direct bypass' ;;
    3) printf '%s\n' 'direct tuned bypass' ;;
    4) printf '%s\n' 'bypass direct tuned' ;;
    5) printf '%s\n' 'tuned bypass direct' ;;
  esac
}

analyze_run() {
  local cycle="$1"
  local position="$2"
  local mode="$3"
  local run_name="$4"
  local run_directory="$5"
  local startup_ms="$6"
  local total_ms="$7"
  local process_samples="${run_directory}/process-samples.tsv"
  local request_samples="${run_directory}/requests.tsv"
  local jfr="${run_directory}/recording.jfr"
  local server_pid="$8"
  local gc_log="${run_directory}/gc-${server_pid}.log"
  local heap_before="${run_directory}/heap-before.txt"
  local heap_after="${run_directory}/heap-after.txt"
  local flags_before="${run_directory}/jvm-flags-before.txt"

  python3 - \
    "${cycle}" \
    "${position}" \
    "${mode}" \
    "${run_name}" \
    "${startup_ms}" \
    "${total_ms}" \
    "${process_samples}" \
    "${request_samples}" \
    "${jfr}" \
    "${gc_log}" \
    "${heap_before}" \
    "${heap_after}" \
    "${flags_before}" \
    "${REPORT_DIRECTORY}/run-summary.tsv" \
    "${REPORT_DIRECTORY}/selected-jvm-flags.tsv" <<'PY'
import csv
import os
import re
import statistics
import sys

(
    cycle,
    position,
    mode,
    run_name,
    startup_ms,
    total_ms,
    process_path,
    request_path,
    jfr_path,
    gc_path,
    heap_before_path,
    heap_after_path,
    flags_before_path,
    summary_path,
    selected_flags_path,
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
    cycle,
    position,
    mode,
    run_name,
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

selected_names = [
    "InitialHeapSize",
    "MaxHeapSize",
    "MinHeapFreeRatio",
    "MaxHeapFreeRatio",
    "G1PeriodicGCInterval",
    "G1UseTimeBasedHeapSizing",
    "NativeMemoryTracking",
    "UseG1GC",
]
selected = {}
with open(flags_before_path, encoding="utf-8") as handle:
    for line in handle:
        for name in selected_names:
            match = re.search(rf"\b{name}\s+=\s+(\S+)", line)
            if match:
                selected[name] = match.group(1)

with open(selected_flags_path, "a", newline="", encoding="utf-8") as handle:
    csv.writer(handle, delimiter="\t", lineterminator="\n").writerow(
        [cycle, position, mode, run_name]
        + [selected.get(name, "MISSING") for name in selected_names]
    )
PY
}

summarize_all_runs() {
  python3 - \
    "${REPORT_DIRECTORY}/run-summary.tsv" \
    "${REPORT_DIRECTORY}/mode-statistics.tsv" \
    "${REPORT_DIRECTORY}/paired-comparison.tsv" \
    "${REPORT_DIRECTORY}/paired-delta-statistics.tsv" \
    "${REPORT_DIRECTORY}/results.json" \
    "${REPORT_DIRECTORY}" \
    "${REPORT_DIRECTORY}/request-distribution.tsv" <<'PY'
import csv
import glob
import json
import math
import statistics
import sys

(
    summary_path,
    statistics_path,
    paired_path,
    paired_statistics_path,
    json_path,
    report_directory,
    request_output,
) = sys.argv[1:]

with open(summary_path, newline="", encoding="utf-8") as handle:
    rows = list(csv.DictReader(handle, delimiter="\t"))

metric_names = [
    "startup_ms",
    "request_median_ms",
    "peak_rss_kb",
    "cpu_seconds",
    "heap_before_kb",
    "heap_after_kb",
    "gc_pause_count",
    "gc_pause_total_ms",
    "total_ms",
]
modes = ["direct", "bypass", "tuned"]

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

mode_summary = {}
for mode in modes:
    mode_rows = [row for row in rows if row["mode"] == mode]
    mode_summary[mode] = {
        metric: stats([float(row[metric]) for row in mode_rows])
        for metric in metric_names
    }

requests_by_mode = {mode: [] for mode in modes}
mode_by_run = {row["run_name"]: row["mode"] for row in rows}
for path in sorted(glob.glob(f"{report_directory}/cycle-*/requests.tsv")):
    run_name = path.split("/")[-2]
    mode = mode_by_run[run_name]
    with open(path, newline="", encoding="utf-8") as handle:
        requests_by_mode[mode].extend(
            float(row["time_seconds"]) * 1000
            for row in csv.DictReader(handle, delimiter="\t")
        )

def percentile(values, percentage):
    ordered = sorted(values)
    index = max(0, math.ceil(len(ordered) * percentage / 100) - 1)
    return ordered[index]

request_summary = {}
for mode, request_values in requests_by_mode.items():
    request_summary[mode] = {
        "count": len(request_values),
        "minimum_ms": min(request_values),
        "median_ms": statistics.median(request_values),
        "p90_ms": percentile(request_values, 90),
        "p95_ms": percentile(request_values, 95),
        "p99_ms": percentile(request_values, 99),
        "maximum_ms": max(request_values),
        "coefficient_of_variation_percent": (
            statistics.pstdev(request_values)
            / statistics.fmean(request_values)
            * 100
        ),
    }

with open(statistics_path, "w", newline="", encoding="utf-8") as handle:
    writer = csv.writer(handle, delimiter="\t", lineterminator="\n")
    writer.writerow(
        ["mode", "metric", "minimum", "median", "maximum", "range", "cv_percent"]
    )
    for mode in modes:
        for name, values in mode_summary[mode].items():
            writer.writerow(
                [
                    mode,
                    name,
                    f"{values['minimum']:.3f}",
                    f"{values['median']:.3f}",
                    f"{values['maximum']:.3f}",
                    f"{values['range']:.3f}",
                    f"{values['coefficient_of_variation_percent']:.3f}",
                ]
            )

paired_rows = []
rows_by_cycle = {}
for row in rows:
    rows_by_cycle.setdefault(row["cycle"], {})[row["mode"]] = row
for cycle in sorted(rows_by_cycle, key=int):
    cycle_rows = rows_by_cycle[cycle]
    if set(cycle_rows) != set(modes):
        raise RuntimeError(f"Cycle {cycle} does not contain all three modes")
    for metric in metric_names:
        direct = float(cycle_rows["direct"][metric])
        bypass = float(cycle_rows["bypass"][metric])
        tuned = float(cycle_rows["tuned"][metric])
        paired_rows.append(
            {
                "cycle": cycle,
                "metric": metric,
                "direct": direct,
                "bypass": bypass,
                "tuned": tuned,
                "bypass_minus_direct": bypass - direct,
                "tuned_minus_direct": tuned - direct,
                "tuned_minus_bypass": tuned - bypass,
            }
        )

with open(paired_path, "w", newline="", encoding="utf-8") as handle:
    fieldnames = [
        "cycle",
        "metric",
        "direct",
        "bypass",
        "tuned",
        "bypass_minus_direct",
        "tuned_minus_direct",
        "tuned_minus_bypass",
    ]
    writer = csv.DictWriter(
        handle, fieldnames=fieldnames, delimiter="\t", lineterminator="\n"
    )
    writer.writeheader()
    for row in paired_rows:
        writer.writerow(
            {
                name: f"{value:.3f}" if isinstance(value, float) else value
                for name, value in row.items()
            }
        )

comparison_definitions = {
    "bypass_minus_direct": ("bypass", "direct"),
    "tuned_minus_direct": ("tuned", "direct"),
    "tuned_minus_bypass": ("tuned", "bypass"),
}
paired_delta_statistics = []
for metric in metric_names:
    metric_rows = [row for row in paired_rows if row["metric"] == metric]
    for comparison, (left, right) in comparison_definitions.items():
        deltas = [row[comparison] for row in metric_rows]
        percentages = [
            (row[left] - row[right]) / row[right] * 100
            for row in metric_rows
            if row[right] != 0
        ]
        paired_delta_statistics.append(
            {
                "comparison": comparison,
                "metric": metric,
                "minimum_delta": min(deltas),
                "median_delta": statistics.median(deltas),
                "maximum_delta": max(deltas),
                "negative_cycles": sum(value < 0 for value in deltas),
                "zero_cycles": sum(value == 0 for value in deltas),
                "positive_cycles": sum(value > 0 for value in deltas),
                "median_percent": statistics.median(percentages),
            }
        )

with open(
    paired_statistics_path, "w", newline="", encoding="utf-8"
) as handle:
    fieldnames = [
        "comparison",
        "metric",
        "minimum_delta",
        "median_delta",
        "maximum_delta",
        "negative_cycles",
        "zero_cycles",
        "positive_cycles",
        "median_percent",
    ]
    writer = csv.DictWriter(
        handle, fieldnames=fieldnames, delimiter="\t", lineterminator="\n"
    )
    writer.writeheader()
    for row in paired_delta_statistics:
        writer.writerow(
            {
                name: f"{value:.3f}" if isinstance(value, float) else value
                for name, value in row.items()
            }
        )

with open(json_path, "w", encoding="utf-8") as handle:
    json.dump(
        {
            "cycle_count": len(rows_by_cycle),
            "launch_count": len(rows),
            "runs": rows,
            "mode_statistics": mode_summary,
            "paired_comparisons": paired_rows,
            "paired_delta_statistics": paired_delta_statistics,
            "request_distribution": request_summary,
        },
        handle,
        indent=2,
    )
    handle.write("\n")

with open(request_output, "w", newline="", encoding="utf-8") as handle:
    writer = csv.writer(handle, delimiter="\t", lineterminator="\n")
    writer.writerow(
        ["mode", "count", "minimum_ms", "median_ms", "p90_ms", "p95_ms", "p99_ms", "maximum_ms", "cv_percent"]
    )
    for mode in modes:
        values = request_summary[mode]
        writer.writerow(
            [
                mode,
                values["count"],
                f"{values['minimum_ms']:.3f}",
                f"{values['median_ms']:.3f}",
                f"{values['p90_ms']:.3f}",
                f"{values['p95_ms']:.3f}",
                f"{values['p99_ms']:.3f}",
                f"{values['maximum_ms']:.3f}",
                f"{values['coefficient_of_variation_percent']:.3f}",
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

install_jaz
verify_jaz_preflight

cp "${BASELINE_CONTRACT}" \
  "${REPORT_DIRECTORY}/section-1.15-workload-contract.txt"
cp "${BASELINE_JFR_CONFIGURATION}" "${SAFE_JFR_CONFIGURATION}"
(
  cd "${SPIKE_DIRECTORY}"
  sha256sum \
    ../spike_1_15_capture_repeatable_performance_envelope/reports/workload-contract.txt \
    ../spike_1_15_capture_repeatable_performance_envelope/reports/profile-without-environment.jfc
) > "${REPORT_DIRECTORY}/section-1.15-inputs.sha256"

cat > "${REPORT_DIRECTORY}/experiment-contract.txt" <<EOF
baseline_contract=../spike_1_15_capture_repeatable_performance_envelope/reports/workload-contract.txt
baseline_jfr_configuration=../spike_1_15_capture_repeatable_performance_envelope/reports/profile-without-environment.jfc
launch_modes=direct,bypass,tuned
cycle_count=${RUN_COUNT}
launches_per_cycle=3
alternating_order=true
jaz_version=${JAZ_VERSION}
jaz_package_url=${JAZ_PACKAGE_URL}
jaz_package_sha256=${JAZ_PACKAGE_SHA256}
jaz_exit_without_flush=true
containerized=false
synthetic_cgroup_limits=false
EOF

printf 'cycle\tposition\tmode\trun_name\tstartup_ms\trequest_count\trequest_min_ms\trequest_median_ms\trequest_max_ms\trequest_cv_percent\tpeak_rss_kb\tcpu_seconds\theap_before_kb\theap_after_kb\tgc_pause_count\tgc_pause_total_ms\ttotal_ms\tjfr_bytes\tgc_log_bytes\tresult\n' \
  > "${REPORT_DIRECTORY}/run-summary.tsv"
printf 'cycle\tposition\tmode\trun_name\tInitialHeapSize\tMaxHeapSize\tMinHeapFreeRatio\tMaxHeapFreeRatio\tG1PeriodicGCInterval\tG1UseTimeBasedHeapSizing\tNativeMemoryTracking\tUseG1GC\n' \
  > "${REPORT_DIRECTORY}/selected-jvm-flags.tsv"
printf 'cycle\tposition\tmode\trun_name\n' \
  > "${REPORT_DIRECTORY}/run-order.tsv"

run_maven package -DskipTests clean package
run_maven deploy liberty:deploy

cat > "${REPORT_DIRECTORY}/jfr-configuration.txt" <<EOF
source=../spike_1_15_capture_repeatable_performance_envelope/reports/profile-without-environment.jfc
copied_to=reports/profile-without-environment.jfc
EOF

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

for cycle in $(seq 1 "${RUN_COUNT}"); do
  position=0
  for mode in $(mode_order_for_cycle "${cycle}"); do
    position="$((position + 1))"
    run_name="$(printf 'cycle-%02d-%02d-%s' "${cycle}" "${position}" "${mode}")"
    run_directory="${REPORT_DIRECTORY}/${run_name}"
    CURRENT_RUN_DIRECTORY="${run_directory}"
    mkdir -p "${run_directory}"
    printf '%s\t%s\t%s\t%s\n' \
      "${cycle}" "${position}" "${mode}" "${run_name}" \
      >> "${REPORT_DIRECTORY}/run-order.tsv"

    restore_pristine_server
    configure_server_mode "${mode}" "${run_directory}"
    cat > "${run_directory}/launch-mode.txt" <<EOF
cycle=${cycle}
position=${position}
mode=${mode}
EOF
    cp "${REPORT_DIRECTORY}/war.sha256" \
      "${run_directory}/war.sha256"
    cp "${REPORT_DIRECTORY}/liberty-runtime-manifest.sha256" \
      "${run_directory}/liberty-runtime-manifest.sha256"

    repetition_start_ms="$(timestamp_ms)"
    start_maven_background "${run_name}-start" \
      -Dapplications=cargo-tracker \
      -DserverStartTimeout=90 \
      liberty:start

    server_pid="$(wait_for_server_pid)"
    CURRENT_SERVER_PID="${server_pid}"
    printf '%s\n' "${server_pid}" > "${run_directory}/server.pid"
    SERVER_MAY_BE_RUNNING=true

    launcher_pid=""
    if [[ "${mode}" == direct ]]; then
      if launcher_pid="$(find_jaz_ancestor "${server_pid}")"; then
        printf 'Direct mode unexpectedly used jaz process %s\n' \
          "${launcher_pid}" >&2
        exit 1
      fi
      launcher_pid=""
    else
      launcher_pid="$(find_jaz_ancestor "${server_pid}")"
      if [[ -z "${launcher_pid}" ]]; then
        printf '%s mode did not retain a jaz launcher ancestor\n' \
          "${mode}" >&2
        exit 1
      fi
      printf '%s\n' "${launcher_pid}" > "${run_directory}/launcher.pid"
    fi
    CURRENT_LAUNCHER_PID="${launcher_pid}"
    capture_process_tree \
      "${server_pid}" \
      "${launcher_pid}" \
      "${run_directory}/process-tree-before.txt"

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
    printf '%s\n' "${start_status}" > "${run_directory}/start-exit-status.txt"
    if [[ "${start_status}" -ne 0 ]]; then
      printf 'Liberty start failed for %s\n' "${run_name}" >&2
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

    if [[ "${mode}" == tuned ]]; then
      test -s "${run_directory}/jaz-dry-run.txt"
      test "$(cat "${run_directory}/jaz-dry-run.txt.status")" = 1
      grep --fixed-strings --quiet -- \
        '-XX:NativeMemoryTracking=summary' \
        "${run_directory}/jaz-dry-run.txt"
      grep --fixed-strings --quiet -- 'ws-server.jar' \
        "${run_directory}/jaz-dry-run.txt"
    elif [[ "${mode}" == bypass ]]; then
      test -s "${run_directory}/jaz-invocations.tsv"
    fi

    capture_jvm_diagnostics "${server_pid}" "${run_directory}" before
    if ! verify_mode_flags \
      "${mode}" "${run_directory}/jvm-flags-before.txt"; then
      printf 'Effective JVM flags did not match %s mode\n' "${mode}" >&2
      exit 1
    fi

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
      elapsed_ms="$(( $(timestamp_ms) - repetition_start_ms ))"
      if ((elapsed_ms > MAX_TOTAL_MS)); then
        printf '%s exceeded the %s ms repetition bound before JFR finalized; elapsed=%s ms\n' \
          "${run_name}" "${MAX_TOTAL_MS}" "${elapsed_ms}" >&2
      else
        printf 'JFR recording was not created for %s\n' "${run_name}" >&2
      fi
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
    verify_process_cleanup "${server_pid}" "${launcher_pid}"
    capture_process_tree \
      "${server_pid}" \
      "${launcher_pid}" \
      "${run_directory}/process-tree-after.txt"

    repetition_end_ms="$(timestamp_ms)"
    total_ms="$((repetition_end_ms - repetition_start_ms))"
    printf '%s\n' "${total_ms}" > "${run_directory}/total-ms.txt"
    if ((total_ms > MAX_TOTAL_MS)); then
      printf 'Repetition took %s ms, exceeding the %s ms bound\n' \
        "${total_ms}" "${MAX_TOTAL_MS}" >&2
      exit 1
    fi

    peak_rss_kb="$(
      awk -F '\t' \
        'NR > 1 && $2 > maximum { maximum=$2 } END { print maximum+0 }' \
        "${run_directory}/process-samples.tsv"
    )"
    if ((peak_rss_kb > MAX_RSS_KB)); then
      printf 'Peak RSS was %s KiB, exceeding the %s KiB bound\n' \
        "${peak_rss_kb}" "${MAX_RSS_KB}" >&2
      exit 1
    fi

    if [[ ! -s "${run_directory}/gc-${server_pid}.log" ]]; then
      printf 'GC log was not created for %s\n' "${run_name}" >&2
      exit 1
    fi

    analyze_run \
      "${cycle}" \
      "${position}" \
      "${mode}" \
      "${run_name}" \
      "${run_directory}" \
      "${startup_ms}" \
      "${total_ms}" \
      "${server_pid}"
    CURRENT_RUN_DIRECTORY=""
    CURRENT_SERVER_PID=""
    CURRENT_LAUNCHER_PID=""
  done
done

summarize_all_runs

rm -rf "${SCRATCH_ROOT}"
trap - EXIT

printf 'Java-versus-jaz spike passed. Evidence: %s\n' \
  "${REPORT_DIRECTORY}"
