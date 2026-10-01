#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
helper="$root/performance/collect-process-metadata.sh"

if [[ "${1:-}" == "--one" ]]; then
  shift
  mode="${1:?mode required}"
  cycle="${2:?cycle required}"
  position="${3:?position required}"
  run_name="${4:?run name required}"
  output="${5:?run output directory required}"
  pristine_server="${6:?pristine server directory required}"
  server_dir="${7:?Liberty server directory required}"
  liberty_root="$(dirname "$(dirname "$(dirname "$server_dir")")")"
  mkdir -p "$output"
  start_ns="$(date +%s%N)"
  started_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  startup_ms=""
  server_started=false
  cleanup_status=0
  sampler_pid=""
  start_maven_pid=""
  sampler_stop="$output/sampler.stop"
  selected_server_pid_file="$output/server.pid"
  server_pid=""
  scratch="$(mktemp -d)"

  record_command() {
    printf '%s\n' "$*" >> "$output/commands.txt"
  }

  run_maven() {
    local stage="$1"
    shift
    local log_dir="$output/maven/$stage"
    local log_file status_code timeout_seconds=90 kill_after=10 remaining_ms
    if [[ "$stage" == stop ]]; then
      remaining_ms="$((120000 - (($(date +%s%N) - start_ns) / 1000000) - 12000))"
      if (( remaining_ms < 1000 )); then
        remaining_ms=1000
      fi
      timeout_seconds="$((remaining_ms / 1000))"
      kill_after=2
    fi
    mkdir -p "$log_dir"
    log_file="$log_dir/$(date -u +%Y%m%d-%H%M)-job-logs.txt"
    record_command "timeout --signal=TERM --kill-after=$kill_after $timeout_seconds $* (tee: ${log_file#"$output"/})"
    if timeout --signal=TERM --kill-after="$kill_after" "$timeout_seconds" "$@" 2>&1 \
      | sed 's/ABC123/<SEEDED-CARGO-REDACTED>/g' | tee "$log_file"; then
      status_code=0
    else
      status_code=$?
    fi
    if [[ -s "$log_file" ]]; then
      cat "$log_file" > "$output/maven/$stage.last-log.txt"
    else
      printf 'Maven log was empty: %s\n' "$log_file" >&2
      return 1
    fi
    if [[ "$status_code" -eq 0 ]] && ! grep -q 'BUILD SUCCESS' "$log_file"; then
      echo "Maven command did not report BUILD SUCCESS: $log_file" >&2
      return 1
    fi
    return "$status_code"
  }

  run_jcmd() {
    timeout --signal=TERM --kill-after=2 10 "$JAVA_HOME/bin/jcmd" "$@"
  }

  has_user_tuning() {
    local value="$1"
    [[ "$value" =~ (^|[[:space:]])(-X(ms|mx|mn|ss|oss)|-XX:([^[:space:]]*(Heap|GC|ActiveProcessorCount|CICompilerCount|G1|RAM|Threads|Ratio|Metaspace|Survivor|NewSize|ContainerSupport|UseSerialGC|UseParallelGC|UseZGC|UseShenandoah|StartFlightRecording))) ]]
  }

  validate_no_user_tuning() {
    local name value file
    for name in JAVA_TOOL_OPTIONS _JAVA_OPTIONS JDK_JAVA_OPTIONS JAVA_OPTS JVM_ARGS MAVEN_OPTS; do
      value="${!name:-}"
      if [[ -n "$value" ]] && has_user_tuning "$value"; then
        echo "user-provided JVM tuning is not allowed ($name)" >&2
        return 1
      fi
    done
    if [[ -n "${JAZ_IGNORE_USER_TUNING:-}" ]]; then
      echo "JAZ_IGNORE_USER_TUNING must not be set for the comparison" >&2
      return 1
    fi
    for file in "$pristine_server/server.env" "$pristine_server/jvm.options"; do
      if [[ -f "$file" ]] && has_user_tuning "$(cat "$file")"; then
        echo "user-provided JVM tuning is not allowed in the pristine Liberty configuration" >&2
        return 1
      fi
    done
    if [[ -f "$pristine_server/server.env" ]] \
      && grep -Eq '^(JAZ_|PERF_)' \
        "$pristine_server/server.env"; then
      echo "jaz launcher variables must be controlled by the performance harness" >&2
      return 1
    fi
  }

  write_server_environment() {
    local server_env="$server_dir/server.env"
    if [[ -f "$pristine_server/server.env" ]]; then
      awk '!/^(JAVA_HOME|JAZ_|PERF_)/' \
        "$pristine_server/server.env" > "$server_env"
    else
      : > "$server_env"
    fi
    if [[ "$mode" == direct ]]; then
      printf 'JAVA_HOME=%s\n' "$JAVA_HOME" >> "$server_env"
      return
    fi
    {
      printf 'JAVA_HOME=%s\n' "$PERF_MIRROR_JAVA_HOME"
      printf 'PERF_REAL_JAVA_HOME=%s\n' "$JAVA_HOME"
      printf 'PERF_JAZ_BIN=%s\n' "$PERF_JAZ_BIN"
      printf 'PERF_JAZ_MODE=%s\n' "$mode"
      printf 'PERF_JAZ_DRY_RUN_OUTPUT=%s/jaz-dry-run.txt\n' "$output"
      printf 'PERF_JAZ_INVOCATIONS=%s/jaz-invocations.txt\n' "$output"
      printf 'JAZ_EXIT_WITHOUT_FLUSH=1\n'
      if [[ "$mode" == bypass ]]; then
        printf 'JAZ_BYPASS=1\n'
      fi
    } >> "$server_env"
  }

  # shellcheck disable=SC2317
  copy_liberty_logs() {
    local source="$server_dir/logs"
    mkdir -p "$output/liberty"
    for name in messages.log console.log; do
      if [[ -f "$source/$name" ]]; then
        tail -n 200 "$source/$name" | sed 's/ABC123/<SEEDED-CARGO-REDACTED>/g' \
          > "$output/liberty/$name"
      fi
    done
    if [[ -d "$source/ffdc" ]]; then
      local index=0 file
      while IFS= read -r -d '' file; do
        index=$((index + 1))
        tail -n 120 "$file" | sed 's/ABC123/<SEEDED-CARGO-REDACTED>/g' \
          > "$output/liberty/ffdc-$index-$(basename "$file")"
      done < <(find "$source/ffdc" -maxdepth 1 -type f -print0 | sort -z)
    fi
  }

  # shellcheck disable=SC2317
  cleanup() {
    local original_status=$?
    set +e
    if [[ -n "$start_maven_pid" ]]; then
      wait "$start_maven_pid" || true
      start_maven_pid=""
    fi
    if [[ -n "$sampler_pid" ]]; then
      touch "$sampler_stop"
      wait "$sampler_pid"
      sample_status=$?
      if [[ "$sample_status" -ne 0 && "$original_status" -eq 0 ]]; then
        echo "process sampling did not produce valid samples" >&2
        original_status=1
      fi
    fi
    if [[ "$server_started" == true ]]; then
      run_maven stop ./mvnw -Popenliberty liberty:stop
      cleanup_status=$?
      if [[ "$cleanup_status" -ne 0 ]]; then
        echo "liberty:stop failed for $run_name" >&2
        [[ "$original_status" -ne 0 ]] || original_status=1
      fi
    fi
    for _ in $(seq 1 20); do
      remaining_server_pids="$("$helper" list-server-pids "$server_dir")"
      remaining_jaz_pids=""
      if [[ "$mode" != direct ]]; then
        remaining_jaz_pids="$(ps -eo pid=,comm= | awk '$2 == "jaz" { print $1 }')"
      fi
      if [[ -z "$remaining_server_pids" && -z "$remaining_jaz_pids" ]]; then
        break
      fi
      sleep 0.25
    done
    copy_liberty_logs
    if grep -Eiq 'OutOfMemoryError|Java heap space|GC overhead limit exceeded' \
      "$output"/maven/*/*.txt "$output"/liberty/* 2>/dev/null; then
      echo "the Liberty process reported an out-of-memory failure" >&2
      original_status=1
    fi
    remaining_server_pids="$("$helper" list-server-pids "$server_dir")"
    if [[ -n "$remaining_server_pids" ]]; then
      printf 'Liberty JVM survived cleanup: %s\n' "$remaining_server_pids" >&2
      original_status=1
    else
      rm -rf "$server_dir"
      cp -a "$pristine_server" "$server_dir"
      restored_hash="$(tar --sort=name --mtime='UTC 1970-01-01' --owner=0 --group=0 \
        --numeric-owner -C "$server_dir" -cf - . | sha256sum | awk '{ print $1 }')"
      if [[ "$restored_hash" != "$PERF_SERVER_TEMPLATE_SHA256" ]]; then
        echo "Liberty server cleanup did not restore the pristine template" >&2
        original_status=1
      fi
    fi
    if [[ "$mode" != direct ]]; then
      remaining_jaz_pids="$(ps -eo pid=,comm= | awk '$2 == "jaz" { print $1 }')"
      if [[ -n "$remaining_jaz_pids" ]]; then
        printf 'jaz launcher survived cleanup: %s\n' "$remaining_jaz_pids" >&2
        original_status=1
      fi
    fi
    local ended_ns total_ms run_status
    ended_ns="$(date +%s%N)"
    total_ms="$(((ended_ns - start_ns) / 1000000))"
    if [[ "$original_status" -eq 0 ]]; then
      run_status=PASS
    else
      run_status=FAIL
    fi
    python3 - "$output/run-state.json" "$mode" "$cycle" "$position" "$run_name" \
      "$startup_ms" "$total_ms" "$run_status" "$original_status" "$cleanup_status" \
      "$started_at" <<'PY'
import json
import pathlib
import sys
from datetime import datetime, timezone

path, mode, cycle, position, name, startup, total, status, exit_code, cleanup, started = sys.argv[1:]
state = {
    "mode": mode,
    "cycle": int(cycle),
    "position": int(position),
    "runName": name,
    "startedAt": started,
    "startupMs": int(startup) if startup.isdigit() else None,
    "totalMs": int(total),
    "status": status,
    "exitStatus": int(exit_code),
    "cleanupStatus": int(cleanup),
}
pathlib.Path(path).write_text(json.dumps(state, indent=2) + "\n")
PY
    "$helper" summarize summarize-run "$output" || original_status=1
    rm -rf "$scratch"
    exit "$original_status"
  }
  trap cleanup EXIT
  trap 'exit 124' HUP INT TERM

  case "$mode" in
    direct)
      ;;
    bypass|tuned)
      [[ -x "${PERF_JAZ_BIN:-}" && -x "${PERF_MIRROR_JAVA_HOME:-}/bin/java" ]] || {
        echo "pinned jaz launcher or mirrored JDK is unavailable" >&2
        exit 1
      }
      ;;
    *)
      echo "unsupported performance mode: $mode" >&2
      exit 2
      ;;
  esac

  validate_no_user_tuning
  rm -rf "$server_dir"
  mkdir -p "$(dirname "$server_dir")"
  cp -a "$pristine_server" "$server_dir"
  restored_hash="$(tar --sort=name --mtime='UTC 1970-01-01' --owner=0 --group=0 \
    --numeric-owner -C "$server_dir" -cf - . | sha256sum | awk '{ print $1 }')"
  if [[ "$restored_hash" != "$PERF_SERVER_TEMPLATE_SHA256" ]]; then
    echo "Liberty server was not restored from the pristine template" >&2
    exit 1
  fi
  write_server_environment
  gc_log="$output/gc-%p.log"
  gc_option="-Xlog:gc*,safepoint:file=$gc_log:time,uptime,level,tags"
  printf 'mode\t%s\ncycle\t%s\nposition\t%s\nrun\t%s\n' \
    "$mode" "$cycle" "$position" "$run_name" > "$output/run-identity.txt"
  cat "$PERF_ARTIFACT_IDENTITY" >> "$output/run-identity.txt"
  {
    printf 'mode\t%s\n' "$mode"
    printf 'java_home\t%s\n' "$([[ "$mode" == direct ]] && echo real-jdk || echo mirrored-jdk-bin-java-shim)"
    printf 'jaz_bypass\t%s\n' "$([[ "$mode" == bypass ]] && echo 1 || echo 0)"
    printf 'jaz_exit_without_flush\t%s\n' "$([[ "$mode" == direct ]] && echo not-applicable || echo 1)"
  } > "$output/launch-mode.txt"
  printf 'commands are recorded in commands.txt; response bodies are validated in memory only\n' \
    > "$output/status.txt"
  : > "$output/commands.txt"
  printf 'request\tstatus\tduration_ms\n' > "$output/warmup.tsv"
  printf 'request\tstatus\tduration_ms\n' > "$output/requests.tsv"
  record_command "restore pristine defaultServer and apply mode-specific server.env plus diagnostic-only GC logging"
  "$helper" sample-server "$server_dir" "$output/process-samples.tsv" \
    "$sampler_stop" 0.2 "$selected_server_pid_file" &
  sampler_pid=$!
  server_started=true
  launch_start_ns="$(date +%s%N)"
  launch_start_seconds="$(date +%s)"
  run_maven start ./mvnw -Popenliberty \
    "-Dliberty.jvm.performanceGc=$gc_option" \
    -Dapplications=cargo-tracker -DserverStartTimeout=90 liberty:start &
  start_maven_pid=$!

  deadline="$((launch_start_seconds + 90))"
  server_pid=""
  while (( $(date +%s) < deadline )); do
    mapfile -t startup_pids < <("$helper" list-server-pids "$server_dir")
    if (( ${#startup_pids[@]} == 1 )); then
      server_pid="${startup_pids[0]}"
      printf '%s\n' "$server_pid" > "$selected_server_pid_file.tmp"
      mv "$selected_server_pid_file.tmp" "$selected_server_pid_file"
      break
    fi
    if ! kill -0 "$start_maven_pid" 2>/dev/null; then
      break
    fi
    sleep 0.1
  done
  if [[ -z "$server_pid" ]]; then
    echo "unique Liberty server JVM did not appear during startup" >&2
    exit 1
  fi
  if ! wait "$start_maven_pid"; then
    start_maven_pid=""
    echo "Liberty Maven startup failed" >&2
    exit 1
  fi
  start_maven_pid=""

  ready=false
  response_body="$scratch/readiness.json"
  while (( $(date +%s) < deadline )); do
    remaining_seconds="$((deadline - $(date +%s)))"
    request_timeout=10
    if (( remaining_seconds < request_timeout )); then
      request_timeout=$remaining_seconds
    fi
    response="$(
      curl --silent --show-error --connect-timeout 5 --max-time "$request_timeout" \
        --output "$response_body" --write-out $'%{http_code}\t%{time_total}\t%{content_type}' \
        http://127.0.0.1:8080/cargo-tracker/rest/cargo 2>/dev/null
    )" || response=""
    IFS=$'\t' read -r http_status elapsed content_type <<< "$response"
    if [[ "$http_status" == 200 && "$content_type" == application/json* ]] \
      && grep -q 'ABC123' "$response_body"; then
      ready=true
      break
    fi
    sleep 1
  done
  if [[ "$ready" != true ]]; then
    echo "performance readiness failed: expected HTTP 200, JSON, and seeded-cargo validation within 90 seconds" >&2
    exit 1
  fi
  startup_end_ns="$(date +%s%N)"
  startup_ms="$(((startup_end_ns - launch_start_ns) / 1000000))"
  if (( startup_ms > 90000 )); then
    echo "startup exceeded 90 seconds: ${startup_ms}ms" >&2
    exit 1
  fi
  printf 'status\t%s\ncontent_type\t%s\nrequest_ms\t%s\n' \
    "$http_status" "$content_type" "$(awk -v seconds="$elapsed" 'BEGIN { printf "%.3f", seconds * 1000 }')" \
    > "$output/readiness.txt"
  rm -f "$response_body"
  record_command "GET /cargo-tracker/rest/cargo readiness; validate HTTP 200, JSON, and seeded-cargo presence without retaining the body"

  if [[ "$("$helper" find-server-pid "$server_dir")" != "$server_pid" ]]; then
    echo "Liberty server JVM changed between startup and readiness" >&2
    exit 1
  fi
  if ! run_jcmd "$server_pid" VM.command_line \
    > "$output/jvm-command-line.txt" 2>&1; then
    echo "jcmd VM.command_line failed" >&2
    exit 1
  fi
  if ! "$helper" verify-jvm-option "$output/jvm-command-line.txt" "$gc_option"; then
    echo "Liberty JVM did not start with the required diagnostic GC logging option" >&2
    exit 1
  fi
  if ! run_jcmd "$server_pid" VM.flags -all \
    > "$output/jvm-flags.txt" 2>&1; then
    echo "jcmd VM.flags -all failed" >&2
    exit 1
  fi
  "$helper" ancestry "$server_pid" "$output/process-ancestry.tsv"
  if [[ "$mode" == direct ]]; then
    if awk -F '\t' '$3 == "jaz" { found=1 } END { exit !found }' \
      "$output/process-ancestry.tsv"; then
      echo "direct Java mode unexpectedly has a jaz ancestor" >&2
      exit 1
    fi
  elif ! awk -F '\t' '$3 == "jaz" { found=1 } END { exit !found }' \
    "$output/process-ancestry.tsv"; then
    echo "$mode mode has no jaz launcher in the Liberty process ancestry" >&2
    exit 1
  fi
  printf 'command-line\t%s\njvm-flags\t%s\nprocess-ancestry\t%s\n' \
    "jvm-command-line.txt" "jvm-flags.txt" "process-ancestry.tsv" \
    > "$output/effective-jvm-evidence.txt"
  record_command "timeout --signal=TERM --kill-after=2 10 jcmd $server_pid VM.command_line"
  record_command "timeout --signal=TERM --kill-after=2 10 jcmd $server_pid VM.flags -all"

  selected_flag() {
    local flag="$1"
    awk -v flag="$flag" '$1 == flag || $2 == flag { sub(/^.*=[[:space:]]*/, "", $0); sub(/[[:space:]].*$/, "", $0); print; exit }' \
      "$output/jvm-flags.txt"
  }
  {
    printf 'flag\tvalue\n'
    for flag in InitialHeapSize MaxHeapSize MinHeapFreeRatio MaxHeapFreeRatio \
      G1PeriodicGCInterval G1UseTimeBasedHeapSizing NativeMemoryTracking UseG1GC; do
      value="$(selected_flag "$flag")"
      [[ -n "$value" ]] || value=MISSING
      printf '%s\t%s\n' "$flag" "$value"
    done
  } > "$output/selected-jvm-flags.tsv"

  if [[ "$mode" == tuned ]]; then
    dry_run="$output/jaz-dry-run.txt"
    for _ in $(seq 1 30); do
      [[ -s "$dry_run" ]] && break
      sleep 0.2
    done
    if [[ ! -s "$dry_run" ]] \
      || ! grep -q '^jaz would run:' "$dry_run" \
      || ! grep -q -- '-XX:MinHeapFreeRatio=10' "$dry_run" \
      || ! grep -q -- '-XX:MaxHeapFreeRatio=50' "$dry_run" \
      || ! grep -q -- '-XX:G1PeriodicGCInterval=10000' "$dry_run" \
      || ! grep -q -- '-XX:+G1UseTimeBasedHeapSizing' "$dry_run" \
      || ! grep -Eq -- '(-Xmx[0-9]+[kKmMgGtT]?|-XX:MaxHeapSize=)' "$dry_run" \
      || ! grep -q -- '-XX:+UseG1GC' "$dry_run" \
      || ! grep -Fq "$JAVA_HOME/bin/java" "$dry_run"; then
      echo "tuned jaz dry-run omitted resolved heap/G1 settings" >&2
      exit 1
    fi
  fi

  validate_flag() {
    local flag="$1" expected="$2" actual
    actual="$(awk -F '\t' -v name="$flag" '$1 == name { print $2 }' "$output/selected-jvm-flags.tsv")"
    if [[ "$actual" != "$expected" ]]; then
      printf '%s mode selected unexpected %s=%s (expected %s)\n' \
        "$mode" "$flag" "$actual" "$expected" >&2
      return 1
    fi
  }
  if [[ "$mode" == tuned ]]; then
    validate_flag MinHeapFreeRatio 10
    validate_flag MaxHeapFreeRatio 50
    validate_flag G1PeriodicGCInterval 10000
    validate_flag G1UseTimeBasedHeapSizing true
    validate_flag NativeMemoryTracking summary
    validate_flag UseG1GC true
    tuned_heap="$(awk -F '\t' '$1 == "MaxHeapSize" { print $2 }' "$output/selected-jvm-flags.tsv")"
    if [[ ! "$tuned_heap" =~ ^[0-9]+$ ]] || (( tuned_heap <= 0 )); then
      echo "tuned jaz did not select a parseable maximum heap" >&2
      exit 1
    fi
    if ! grep -q -- '-XX:ErrorFile=' "$output/jvm-command-line.txt"; then
      echo "tuned jaz did not retain its error-file diagnostics" >&2
      exit 1
    fi
  elif [[ "$mode" == bypass ]]; then
    validate_flag NativeMemoryTracking summary
    if ! grep -q -- '-XX:ErrorFile=' "$output/jvm-command-line.txt"; then
      echo "bypassed jaz did not retain launcher diagnostics" >&2
      exit 1
    fi
  else
    validate_flag NativeMemoryTracking off
    if grep -q -- '-XX:ErrorFile=' "$output/jvm-command-line.txt"; then
      echo "direct Java mode unexpectedly includes jaz error-file diagnostics" >&2
      exit 1
    fi
  fi

  curl_request() {
    local kind="$1" request_number="$2"
    local body="$scratch/response-$kind-$request_number.json" result status_code elapsed
    result="$(
      curl --silent --show-error --connect-timeout 5 --max-time 10 \
        --output "$body" --write-out $'%{http_code}\t%{time_total}' \
        http://127.0.0.1:8080/cargo-tracker/rest/cargo
    )" || {
      rm -f "$body"
      echo "$kind request $request_number timed out or failed" >&2
      return 1
    }
    IFS=$'\t' read -r status_code elapsed <<< "$result"
    if [[ "$status_code" != 200 ]] || ! grep -q 'ABC123' "$body"; then
      rm -f "$body"
      echo "$kind request $request_number failed HTTP/seed validation" >&2
      return 1
    fi
    rm -f "$body"
    duration_ms="$(awk -v seconds="$elapsed" 'BEGIN { printf "%.3f", seconds * 1000 }')"
    printf '%s\t%s\t%s\n' "$request_number" "$status_code" "$duration_ms"
  }

  for request in $(seq 1 5); do
    result="$(curl_request warmup "$request")"
    printf '%s\n' "$result" >> "$output/warmup.tsv"
  done
  record_command "five sequential HTTP 200 seeded-cargo warm-up requests"
  if ! run_jcmd "$server_pid" GC.heap_info > "$output/heap-before.txt"; then
    echo "jcmd GC.heap_info before workload failed" >&2
    exit 1
  fi
  record_command "timeout --signal=TERM --kill-after=2 10 jcmd $server_pid GC.heap_info before measured workload"
  jfr_profile="$PERF_JFR_PROFILE"
  if ! run_jcmd "$server_pid" JFR.start \
    name=performance settings="$jfr_profile" duration=10s \
    filename="$output/recording.jfr" dumponexit=true \
    > "$output/jfr-start.txt" 2>&1; then
    echo "dynamic 10-second JFR start failed" >&2
    exit 1
  fi
  grep -q 'Started recording' "$output/jfr-start.txt"
  record_command "timeout --signal=TERM --kill-after=2 10 jcmd $server_pid JFR.start with redacted profile, dynamic 10-second duration, and no startup recording flags"
  for request in $(seq 1 30); do
    result="$(curl_request measured "$request")"
    printf '%s\n' "$result" >> "$output/requests.tsv"
    sleep 0.2
  done
  if ! run_jcmd "$server_pid" GC.heap_info > "$output/heap-after.txt"; then
    echo "jcmd GC.heap_info after workload failed" >&2
    exit 1
  fi
  record_command "30 sequential HTTP 200 seeded-cargo requests paced 200 milliseconds apart"
  record_command "timeout --signal=TERM --kill-after=2 10 jcmd $server_pid GC.heap_info"
  if ! kill -0 "$server_pid" 2>/dev/null; then
    echo "Liberty JVM exited before the workload completed" >&2
    exit 1
  fi

  for _ in $(seq 1 30); do
    [[ -s "$output/recording.jfr" ]] && break
    sleep 0.5
  done
  if [[ ! -s "$output/recording.jfr" ]]; then
    echo "bounded JFR recording did not finish within 15 seconds after workload" >&2
    exit 1
  fi
  if ! "$JAVA_HOME/bin/jfr" summary "$output/recording.jfr" \
    > "$output/jfr-summary.txt" 2>&1; then
    echo "JFR recording was not parseable" >&2
    exit 1
  fi
  grep -q '^ Event Type' "$output/jfr-summary.txt"
  if ! "$helper" verify-jfr-redaction "$output/recording.jfr" \
    "$output/jfr-redaction-counts.tsv"; then
    echo "JFR recording contains sensitive event types" >&2
    exit 1
  fi
  gc_log="$output/gc-$server_pid.log"
  if [[ ! -s "$gc_log" ]] || ! grep -Eq '\[info\]\[gc' "$gc_log"; then
    echo "server-PID-specific GC log is missing or unparseable" >&2
    exit 1
  fi
  record_command "$JAVA_HOME/bin/jfr summary $output/recording.jfr"
  record_command "verify zero sensitive JFR events in $output/recording.jfr"
  exit 0
fi

if [[ "${1:-}" != "" ]]; then
  echo "usage: run-workload.sh (or internal --one mode ...)" >&2
  exit 2
fi

cd "$root"
artifact_root="${PERFORMANCE_ARTIFACT_ROOT:-$root/ci-artifacts}"
export PERFORMANCE_ARTIFACT_ROOT="$artifact_root"
comparison="$artifact_root/performance-comparison"
direct_artifact="$artifact_root/performance-java"
bypass_artifact="$artifact_root/performance-jaz-bypassed"
tuned_artifact="$artifact_root/performance-jaz-tuned"
for directory in "$comparison" "$direct_artifact" "$bypass_artifact" "$tuned_artifact"; do
  rm -rf "$directory"
  mkdir -p "$directory"
  printf '%s\n' "performance evidence collection initialized" > "$directory/commands.txt"
done
comparison_started="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
export PERFORMANCE_STARTED_AT="$comparison_started"
if [[ -n "${GITHUB_ENV:-}" ]]; then
  printf 'PERFORMANCE_STARTED_AT=%s\n' "$comparison_started" >> "$GITHUB_ENV"
fi
workspace="${RUNNER_TEMP:-/tmp}/cargo-tracker-performance-$$"
mkdir -p "$workspace"
cleanup_workspace() {
  local code=$?
  rm -rf "$workspace"
  exit "$code"
}
trap cleanup_workspace EXIT
comparison_command() {
  printf '%s\n' "$*" >> "$comparison/commands.txt"
}

if [[ -z "${JAVA_HOME:-}" || ! -x "$JAVA_HOME/bin/java" || ! -x "$JAVA_HOME/bin/jcmd" ]]; then
  echo "Java 17 JAVA_HOME with java and jcmd is required" >&2
  exit 1
fi
release_text="$(cat "$JAVA_HOME/release")"
if ! grep -q '^JAVA_VERSION="17' <<< "$release_text"; then
  echo "the performance workload requires the configured Java 17 JDK" >&2
  exit 1
fi
if [[ "$(uname -m)" != x86_64 ]]; then
  echo "pinned jaz evidence requires an amd64 runner" >&2
  exit 1
fi
for name in JAVA_TOOL_OPTIONS _JAVA_OPTIONS JDK_JAVA_OPTIONS JAVA_OPTS JVM_ARGS MAVEN_OPTS; do
  value="${!name:-}"
  if [[ "$value" =~ (^|[[:space:]])(-X(ms|mx|mn|ss|oss)|-XX:([^[:space:]]*(Heap|GC|ActiveProcessorCount|CICompilerCount|G1|RAM|Threads|Ratio|Metaspace|Survivor|NewSize|ContainerSupport|UseSerialGC|UseParallelGC|UseZGC|UseShenandoah|StartFlightRecording))) ]]; then
    echo "user-provided JVM tuning is not allowed ($name)" >&2
    exit 1
  fi
done
if [[ -n "${JAZ_IGNORE_USER_TUNING:-}" ]]; then
  echo "JAZ_IGNORE_USER_TUNING must not be set for the comparison" >&2
  exit 1
fi
if [[ -n "${JAZ_BYPASS:-}" || -n "${JAZ_DRY_RUN:-}" \
  || -n "${JAZ_EXIT_WITHOUT_FLUSH:-}" ]]; then
  echo "JAZ launcher variables must be controlled by the harness" >&2
  exit 1
fi

war="$root/target/cargo-tracker.war"
liberty_root="$root/target/liberty/wlp"
server_dir="$liberty_root/usr/servers/defaultServer"
if [[ ! -s "$war" || ! -d "$liberty_root" || ! -d "$server_dir" ]]; then
  echo "canonical WAR and Open Liberty runtime must already be built before performance capture" >&2
  exit 1
fi
server_config="$root/src/main/liberty/config/server.xml"
if ! grep -q 'javaee-7.0' "$server_config" || ! grep -q 'cargo-tracker.war' "$server_config"; then
  echo "performance runtime does not match the Open Liberty application contract" >&2
  exit 1
fi

jaz_url="https://packages.microsoft.com/ubuntu/24.04/prod/pool/main/j/jaz/jaz_1.0.4_amd64.deb"
jaz_sha256="3d479f11ff2a037790505746a44568e1408f2f79aac62300ea4c651c4969a710"
jaz_package="$workspace/jaz_1.0.4_amd64.deb"
jaz_extract="$workspace/jaz-package"
comparison_command "curl --fail --location --retry 3 --connect-timeout 10 --max-time 180 $jaz_url"
if ! timeout 180 curl --fail --location --retry 3 --connect-timeout 10 --max-time 180 \
  "$jaz_url" -o "$jaz_package" > "$comparison/jaz-download.log" 2>&1; then
  cat "$comparison/jaz-download.log" >&2
  echo "pinned jaz download failed" >&2
  exit 1
fi
if ! printf '%s  %s\n' "$jaz_sha256" "$jaz_package" | \
  sha256sum --check > "$comparison/jaz-checksum.txt" 2>&1; then
  cat "$comparison/jaz-checksum.txt" >&2
  echo "pinned jaz checksum verification failed" >&2
  exit 1
fi
if [[ "$(dpkg-deb -f "$jaz_package" Version)" != 1.0.4 \
  || "$(dpkg-deb -f "$jaz_package" Architecture)" != amd64 ]]; then
  echo "jaz package version or architecture mismatch" >&2
  exit 1
fi
mkdir -p "$jaz_extract"
dpkg-deb -x "$jaz_package" "$jaz_extract"
jaz_bin="$jaz_extract/usr/bin/jaz"
if [[ ! -x "$jaz_bin" ]]; then
  echo "pinned jaz package did not contain usr/bin/jaz" >&2
  exit 1
fi
printf 'version\t1.0.4\narchitecture\tamd64\nurl\t%s\nsha256\t%s\n' \
  "$jaz_url" "$jaz_sha256" > "$comparison/jaz-installation.txt"
comparison_command "dpkg-deb -x verified jaz_1.0.4_amd64.deb into disposable scratch space (no package database changes)"

mirror_java_home="$workspace/mirrored-jdk"
mkdir -p "$mirror_java_home"
cp -a "$JAVA_HOME"/. "$mirror_java_home"/
rm -f "$mirror_java_home/bin/java"
cat > "$mirror_java_home/bin/java" <<'JAZ_WRAPPER'
#!/usr/bin/env bash
set -euo pipefail
: "${PERF_REAL_JAVA_HOME:?real JDK home missing}"
: "${PERF_JAZ_BIN:?jaz binary missing}"
: "${PERF_JAZ_MODE:?jaz mode missing}"
: "${PERF_JAZ_INVOCATIONS:?jaz invocation transcript missing}"
export JAVA_HOME="$PERF_REAL_JAVA_HOME"
printf '%q' "$0" >> "$PERF_JAZ_INVOCATIONS"
printf ' %q' "$@" >> "$PERF_JAZ_INVOCATIONS"
printf '\n' >> "$PERF_JAZ_INVOCATIONS"
if [[ "$PERF_JAZ_MODE" == tuned ]]; then
  : "${PERF_JAZ_DRY_RUN_OUTPUT:?jaz dry-run output missing}"
  JAZ_DRY_RUN=1 JAZ_EXIT_WITHOUT_FLUSH=1 "$PERF_JAZ_BIN" "$@" \
    >> "$PERF_JAZ_DRY_RUN_OUTPUT" 2>&1 || dry_run_status=$?
  if [[ -n "${dry_run_status:-}" ]] \
    && ! grep -q '^jaz would run:' "$PERF_JAZ_DRY_RUN_OUTPUT"; then
    exit 1
  fi
fi
if [[ "$PERF_JAZ_MODE" == bypass ]]; then
  export JAZ_BYPASS=1
else
  unset JAZ_BYPASS || true
fi
export JAZ_EXIT_WITHOUT_FLUSH=1
exec "$PERF_JAZ_BIN" "$@"
JAZ_WRAPPER
chmod 0755 "$mirror_java_home/bin/java"
if [[ "$(sha256sum "$mirror_java_home/release" | awk '{ print $1 }')" != \
  "$(sha256sum "$JAVA_HOME/release" | awk '{ print $1 }')" ]]; then
  echo "mirrored JDK metadata differs from the real JDK" >&2
  exit 1
fi

deploy_log="$comparison/maven/deploy/$(date -u +%Y%m%d-%H%M)-job-logs.txt"
mkdir -p "$(dirname "$deploy_log")"
comparison_command "./mvnw -Popenliberty liberty:deploy (tee: ${deploy_log#"$comparison"/})"
residual_server_pids="$("$helper" list-server-pids "$server_dir")"
if [[ -n "$residual_server_pids" ]]; then
  echo "a prior Liberty process is still running before performance deployment" >&2
  exit 1
fi
rm -rf "$server_dir/logs" "$server_dir/workarea"
if ! timeout --signal=TERM --kill-after=10 180 ./mvnw -Popenliberty liberty:deploy \
  2>&1 | sed 's/ABC123/<SEEDED-CARGO-REDACTED>/g' | tee "$deploy_log"; then
  cat "$deploy_log" >&2
  exit 1
fi
if ! grep -q 'BUILD SUCCESS' "$deploy_log"; then
  echo "Liberty deployment did not report BUILD SUCCESS" >&2
  exit 1
fi
cat "$deploy_log" > "$comparison/maven/deploy.last-log.txt"
if [[ ! -d "$server_dir" ]]; then
  echo "Liberty deploy did not create defaultServer" >&2
  exit 1
fi
rm -rf "$server_dir/logs" "$server_dir/workarea"
pristine_server="$workspace/pristine-defaultServer"
cp -a "$server_dir" "$pristine_server"
server_template_sha256="$(tar --sort=name --mtime='UTC 1970-01-01' --owner=0 --group=0 \
  --numeric-owner -C "$pristine_server" -cf - . | sha256sum | awk '{ print $1 }')"
war_sha256="$(sha256sum "$war" | awk '{ print $1 }')"
runtime_sha256="$(
  cd "$liberty_root"
  find . -type f ! -path './usr/servers/*' -print0 |
    sort -z | xargs -0 sha256sum | sha256sum | awk '{ print $1 }'
)"
workload_sha256="$(
  sha256sum "$root/performance/run-workload.sh" \
    "$root/performance/run-liberty-java.sh" \
    "$root/performance/run-liberty-jaz.sh" \
    "$root/performance/collect-process-metadata.sh" \
    "$server_config" | sha256sum | awk '{ print $1 }'
)"
"$helper" host "$comparison"
"$helper" jfr-profile \
  "$JAVA_HOME/lib/jfr/profile.jfc" "$comparison/profile-without-environment.jfc"
jfr_sha256="$(sha256sum "$comparison/profile-without-environment.jfc" | awk '{ print $1 }')"
host_sha256="$(sha256sum "$comparison/runner-environment.txt" | awk '{ print $1 }')"
cat > "$comparison/artifact-identity.txt" <<EOF
war_sha256=$war_sha256
open_liberty_runtime_sha256=$runtime_sha256
pristine_default_server_sha256=$server_template_sha256
workload_and_configuration_sha256=$workload_sha256
redacted_jfr_profile_sha256=$jfr_sha256
runner_environment_sha256=$host_sha256
EOF
write_current_artifact_identity() {
  local output_file="$1"
  local current_war current_runtime current_server current_workload current_jfr
  current_war="$(sha256sum "$war" | awk '{ print $1 }')"
  current_runtime="$(
    cd "$liberty_root"
    find . -type f ! -path './usr/servers/*' -print0 |
      sort -z | xargs -0 sha256sum | sha256sum | awk '{ print $1 }'
  )"
  current_server="$(tar --sort=name --mtime='UTC 1970-01-01' \
    --owner=0 --group=0 --numeric-owner -C "$pristine_server" -cf - . |
    sha256sum | awk '{ print $1 }')"
  current_workload="$(
    sha256sum "$root/performance/run-workload.sh" \
      "$root/performance/run-liberty-java.sh" \
      "$root/performance/run-liberty-jaz.sh" \
      "$root/performance/collect-process-metadata.sh" \
      "$server_config" | sha256sum | awk '{ print $1 }'
  )"
  current_jfr="$(
    sha256sum "$comparison/profile-without-environment.jfc" | awk '{ print $1 }'
  )"
  cat > "$output_file" <<EOF
war_sha256=$current_war
open_liberty_runtime_sha256=$current_runtime
pristine_default_server_sha256=$current_server
workload_and_configuration_sha256=$current_workload
redacted_jfr_profile_sha256=$current_jfr
runner_environment_sha256=$host_sha256
EOF
}
printf 'WAR SHA-256\t%s\nLiberty runtime SHA-256\t%s\n' \
  "$war_sha256" "$runtime_sha256" > "$comparison/artifact-checksums.txt"
printf 'cycle\tposition\tmode\trun_name\n' > "$comparison/run-order.tsv"
cat > "$comparison/request-contract.txt" <<'EOF'
Open Liberty /cargo-tracker/rest/cargo; sequential requests only.
Readiness: HTTP 200, application/json, and seeded-content validation.
Warm-up: 5 requests. Measured: 30 requests. Pacing: 200 ms.
Request timeout: 10 s. Startup bound: 90 s. Repetition bound: 120 s.
JFR: dynamically started, redacted profile, 10 s. Containerization: none.
Response bodies are validated transiently and are not retained in artifacts.
EOF
cat > "$comparison/observability-context.txt" <<'EOF'
Task 2.6 OpenTelemetry acceptance and diagnostic artifacts ran earlier in this
same GitHub Actions job and on this hosted runner. For application/runtime
anomalies, consult the task 2.6 ci-artifacts/otel-telemetry and
ci-artifacts/liberty-logs outputs beside these performance artifacts. They are
context from the same host, not measurements from the individual performance
processes. Ordinary performance variation is diagnostic only.
EOF
comparison_command "record runner OS, kernel, CPU, memory, cgroup view, JFR profile hash, WAR hash, Liberty runtime hash, and pristine server hash"
overall_status=0
while IFS=$'\t' read -r cycle position mode run_name; do
  [[ "$cycle" == cycle ]] && continue
  printf '%s\t%s\t%s\t%s\n' "$cycle" "$position" "$mode" "$run_name" \
    >> "$comparison/run-order.tsv"
  case "$mode" in
    direct)
      artifact="$direct_artifact"
      wrapper="$root/performance/run-liberty-java.sh"
      ;;
    bypass)
      artifact="$bypass_artifact"
      wrapper="$root/performance/run-liberty-jaz.sh"
      ;;
    tuned)
      artifact="$tuned_artifact"
      wrapper="$root/performance/run-liberty-jaz.sh"
      ;;
  esac
  run_output="$artifact/$run_name"
  mkdir -p "$run_output"
  export PERF_JAZ_BIN="$jaz_bin"
  export PERF_MIRROR_JAVA_HOME="$mirror_java_home"
  export PERF_JFR_PROFILE="$comparison/profile-without-environment.jfc"
  export PERF_SERVER_TEMPLATE_SHA256="$server_template_sha256"
  export PERF_ARTIFACT_IDENTITY="$comparison/artifact-identity.txt"
  if [[ "$mode" == direct ]]; then
    args=("$cycle" "$position" "$run_name" "$run_output" "$pristine_server" "$server_dir")
  else
    args=("$mode" "$cycle" "$position" "$run_name" "$run_output" "$pristine_server" "$server_dir")
  fi
  {
    printf 'timeout --signal=TERM --kill-after=15 105 '
    printf '%q' "$wrapper"
    printf ' %q' "${args[@]}"
    printf '\n'
  } >> "$comparison/commands.txt"
  {
    printf 'mode\t%s\ncycle\t%s\nposition\t%s\nrun\t%s\n' \
      "$mode" "$cycle" "$position" "$run_name"
    write_current_artifact_identity "$run_output/input-identity.txt"
    if ! diff -u "$comparison/artifact-identity.txt" \
      "$run_output/input-identity.txt"; then
      echo "performance inputs changed before launch: $run_name" >&2
      exit 1
    fi
    cat "$run_output/input-identity.txt"
  } > "$run_output/run-identity.txt"
  printf '%s\n' "performance launch attempt recorded" > "$run_output/status.txt"
  printf '%s\n' "run wrapper command is recorded in comparison/commands.txt" \
    > "$run_output/commands.txt"
  if timeout --signal=TERM --kill-after=15 105 "$wrapper" "${args[@]}"; then
    wrapper_status=0
  else
    wrapper_status=$?
    overall_status=1
    printf 'FAIL: wrapper exit status %s; 105-second watchdog reserves cleanup time\n' \
      "$wrapper_status" > "$run_output/status.txt"
  fi
  mapfile -t post_run_server_pids < <("$helper" list-server-pids "$server_dir")
  if (( ${#post_run_server_pids[@]} > 0 )); then
    printf 'Liberty JVMs remained after wrapper exit: %s\n' \
      "${post_run_server_pids[*]}" >> "$run_output/status.txt"
    for pid in "${post_run_server_pids[@]}"; do
      kill "$pid" 2>/dev/null || true
    done
    sleep 1
    mapfile -t post_run_server_pids < <("$helper" list-server-pids "$server_dir")
    for pid in "${post_run_server_pids[@]}"; do
      kill -KILL "$pid" 2>/dev/null || true
    done
    overall_status=1
  fi
  cat "$run_output/commands.txt" >> "$artifact/commands.txt"
  cat "$run_output/commands.txt" >> "$comparison/commands.txt"
  if [[ -f "$run_output/run-identity.txt" ]] && \
    ! diff -u "$comparison/artifact-identity.txt" \
      <(sed -n '/^war_sha256=/,$p' "$run_output/run-identity.txt"); then
    echo "launch artifact identity mismatch: $run_name" >&2
    overall_status=1
  fi
done <<'ORDERS'
1	1	direct	cycle-01-01-direct
1	2	bypass	cycle-01-02-bypass
1	3	tuned	cycle-01-03-tuned
2	1	bypass	cycle-02-01-bypass
2	2	tuned	cycle-02-02-tuned
2	3	direct	cycle-02-03-direct
3	1	tuned	cycle-03-01-tuned
3	2	direct	cycle-03-02-direct
3	3	bypass	cycle-03-03-bypass
4	1	direct	cycle-04-01-direct
4	2	tuned	cycle-04-02-tuned
4	3	bypass	cycle-04-03-bypass
5	1	bypass	cycle-05-01-bypass
5	2	direct	cycle-05-02-direct
5	3	tuned	cycle-05-03-tuned
ORDERS

"$helper" summarize summarize-all \
  || overall_status=1
if [[ "$overall_status" -ne 0 ]]; then
  printf '%s\n' "One or more performance repetitions failed; see per-run status and diagnostics." \
    > "$comparison/failure-summary.txt"
  exit "$overall_status"
fi
printf '%s\n' "all 15 launch-mode repetitions passed their functional, diagnostic, resource, and cleanup gates" \
  > "$comparison/status.txt"
