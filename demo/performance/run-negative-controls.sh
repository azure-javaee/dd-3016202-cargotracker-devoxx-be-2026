#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
scratch="$(mktemp -d "${RUNNER_TEMP:-/tmp}/cargo-tracker-performance-controls.XXXXXX")"
helper="$root/performance/collect-process-metadata.sh"
fixture_server_dir="$scratch/liberty/usr/servers/defaultServer"
fixture_launcher_pids=()
fixture_java_pids=()
last_fixture_pid=""
fixture_sampler_pid=""
fixture_sampler_stop=""
cleanup() {
  local pid
  local -a cleanup_java_pids
  if [[ -n "$fixture_sampler_stop" ]]; then
    touch "$fixture_sampler_stop"
  fi
  if [[ -n "$fixture_sampler_pid" ]]; then
    wait "$fixture_sampler_pid" 2>/dev/null || true
  fi
  if [[ -d "$fixture_server_dir" ]]; then
    mapfile -t cleanup_java_pids < <("$helper" list-server-pids "$fixture_server_dir")
    for pid in "${cleanup_java_pids[@]}"; do
      kill "$pid" 2>/dev/null || true
    done
  fi
  for pid in "${fixture_java_pids[@]}"; do
    kill "$pid" 2>/dev/null || true
  done
  for pid in "${fixture_launcher_pids[@]}"; do
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
  done
  rm -rf "$scratch"
}
trap cleanup EXIT

if [[ -z "${JAVA_HOME:-}" || ! -f "$JAVA_HOME/release" ]]; then
  echo "Java 17 JAVA_HOME is required for performance negative controls" >&2
  exit 1
fi

expect_rejection() {
  local name="$1"
  local expected="$2"
  shift 2
  local output="$scratch/$name"
  mkdir -p "$output/artifacts"
  if env \
    -u JAVA_TOOL_OPTIONS -u _JAVA_OPTIONS -u JDK_JAVA_OPTIONS \
    -u JAVA_OPTS -u JVM_ARGS -u MAVEN_OPTS \
    -u JAZ_IGNORE_USER_TUNING -u JAZ_BYPASS -u JAZ_DRY_RUN \
    -u JAZ_EXIT_WITHOUT_FLUSH \
    "JAVA_HOME=$JAVA_HOME" \
    "RUNNER_TEMP=$scratch" \
    "PERFORMANCE_ARTIFACT_ROOT=$output/artifacts" \
    "$@" \
    "$root/performance/run-workload.sh" > "$output/transcript.txt" 2>&1; then
    echo "performance harness accepted prohibited input: $name" >&2
    exit 1
  fi
  if ! grep -Fq "$expected" "$output/transcript.txt"; then
    echo "performance harness rejected $name for an unexpected reason" >&2
    cat "$output/transcript.txt" >&2
    exit 1
  fi
  if find "$output/artifacts" -name jaz-download.log -print -quit | grep -q .; then
    echo "performance harness started installation before rejecting $name" >&2
    exit 1
  fi
  printf 'expected rejection passed: %s\n' "$name"
}

expect_rejection heap-tuning \
  'user-provided JVM tuning is not allowed (JAVA_TOOL_OPTIONS)' \
  JAVA_TOOL_OPTIONS=-Xmx256m
expect_rejection ignore-user-tuning \
  'JAZ_IGNORE_USER_TUNING must not be set for the comparison' \
  JAZ_IGNORE_USER_TUNING=1
expect_rejection external-bypass \
  'JAZ launcher variables must be controlled by the harness' \
  JAZ_BYPASS=1
expect_rejection external-dry-run \
  'JAZ launcher variables must be controlled by the harness' \
  JAZ_DRY_RUN=1
expect_rejection external-exit-without-flush \
  'JAZ launcher variables must be controlled by the harness' \
  JAZ_EXIT_WITHOUT_FLUSH=1

mkdir -p "$fixture_server_dir" "$scratch/liberty/bin/tools" "$scratch/classes"
cat > "$scratch/PerformanceProcessFixture.java" <<'JAVA'
public class PerformanceProcessFixture {
  public static void main(String[] args) throws InterruptedException {
    Thread.sleep(60000);
  }
}
JAVA
"$JAVA_HOME/bin/javac" -d "$scratch/classes" "$scratch/PerformanceProcessFixture.java"
"$JAVA_HOME/bin/jar" --create --file "$scratch/liberty/bin/tools/ws-server.jar" \
  --main-class PerformanceProcessFixture -C "$scratch/classes" .
fixture_jar="$scratch/liberty/bin/tools/ws-server.jar"
gc_option="-Xlog:gc*,safepoint:file=$scratch/gc-%p.log:time,uptime,level,tags"

"$JAVA_HOME/bin/java" "$gc_option" -cp "$fixture_jar" PerformanceProcessFixture \
  > "$scratch/gc-option.log" 2>&1 &
fixture_gc_pid=$!
fixture_java_pids=("$fixture_gc_pid")
sleep 0.5
"$JAVA_HOME/bin/jcmd" "$fixture_gc_pid" VM.command_line \
  > "$scratch/gc-command-line.txt"
"$helper" verify-jvm-option "$scratch/gc-command-line.txt" "$gc_option"
if "$helper" verify-jvm-option "$scratch/gc-command-line.txt" \
  '-Xlog:gc*,safepoint:file=missing-%p.log:time,uptime,level,tags' \
  > "$scratch/gc-missing.out" 2> "$scratch/gc-missing.err"; then
  echo "GC option verification accepted a missing effective JVM option" >&2
  exit 1
fi
grep -Fq 'effective JVM command line omitted required option' "$scratch/gc-missing.err"
kill "$fixture_gc_pid" 2>/dev/null || true
wait "$fixture_gc_pid" 2>/dev/null || true
fixture_java_pids=()
printf 'expected effective GC logging option verified and missing option rejected\n'

start_fixture() {
  local mode="$1"
  local expected_count attempt
  local pid existing_pid found
  local -a existing_fixture_pids discovered_fixture_pids
  mapfile -t existing_fixture_pids < <("$helper" list-server-pids "$fixture_server_dir")
  expected_count=$((${#existing_fixture_pids[@]} + 1))
  fixture_java_pids=("${existing_fixture_pids[@]}")
  case "$mode" in
    direct)
      "$JAVA_HOME/bin/java" -jar "$fixture_jar" defaultServer \
        > "$scratch/$mode.log" 2>&1 &
      ;;
    bypass)
      PERF_JAZ_MODE=bypass launch_jaz_fixture "$mode" &
      ;;
    tuned)
      PERF_JAZ_MODE=tuned launch_jaz_fixture "$mode" &
      ;;
    *)
      echo "unsupported fixture mode: $mode" >&2
      return 2
      ;;
  esac
  fixture_launcher_pids+=("$!")
  for ((attempt = 0; attempt < 50; attempt++)); do
    mapfile -t discovered_fixture_pids < <("$helper" list-server-pids "$fixture_server_dir")
    if [[ "${#discovered_fixture_pids[@]}" -eq "$expected_count" ]]; then
      fixture_java_pids=("${discovered_fixture_pids[@]}")
      last_fixture_pid=""
      for pid in "${discovered_fixture_pids[@]}"; do
        found=false
        for existing_pid in "${existing_fixture_pids[@]}"; do
          if [[ "$pid" == "$existing_pid" ]]; then
            found=true
            break
          fi
        done
        if [[ "$found" == false ]]; then
          last_fixture_pid="$pid"
          break
        fi
      done
      return 0
    fi
    sleep 0.1
  done
  echo "failed to start one $mode-shaped Liberty JVM fixture" >&2
  return 1
}

launch_jaz_fixture() {
  local mode="$1"
  # Both jaz modes intentionally share the same jaz-to-Java ancestry.
  if [[ "${PERF_JAZ_MODE:-}" != "$mode" ]]; then
    echo "jaz fixture mode does not match its environment" >&2
    return 1
  fi
  python3 -c 'import ctypes, subprocess, sys; ctypes.CDLL(None).prctl(15, ctypes.c_char_p(b"jaz"), 0, 0, 0); raise SystemExit(subprocess.call(sys.argv[1:]))' \
    "$JAVA_HOME/bin/java" -jar "$fixture_jar" defaultServer \
    > "$scratch/$mode.log" 2>&1
}

stop_fixture() {
  local pid
  for pid in "${fixture_java_pids[@]}"; do
    kill "$pid" 2>/dev/null || true
  done
  for pid in "${fixture_launcher_pids[@]}"; do
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
  done
  fixture_launcher_pids=()
  fixture_java_pids=()
}

for mode in direct bypass tuned; do
  start_fixture "$mode"
  fixture_pid="$("$helper" find-server-pid "$fixture_server_dir")"
  if [[ "$fixture_pid" != "$last_fixture_pid" ]]; then
    echo "$mode-shaped discovery returned the wrong Java PID" >&2
    exit 1
  fi
  "$helper" ancestry "$fixture_pid" "$scratch/$mode-ancestry.tsv"
  if [[ "$mode" == direct ]]; then
    if awk -F '\t' '$3 == "jaz" { found=1 } END { exit !found }' \
      "$scratch/$mode-ancestry.tsv"; then
      echo "direct fixture unexpectedly has a jaz ancestor" >&2
      exit 1
    fi
  elif ! awk -F '\t' '$3 == "jaz" { found=1 } END { exit !found }' \
    "$scratch/$mode-ancestry.tsv"; then
    echo "$mode fixture is missing its jaz-shaped ancestor" >&2
    exit 1
  fi
  printf 'expected single Liberty JVM discovered: %s\n' "$mode"
  stop_fixture
done

# These app args deliberately contain Liberty identifiers without its -jar launch form.
"$JAVA_HOME/bin/java" -cp "$fixture_jar" PerformanceProcessFixture \
  "$fixture_jar" defaultServer > "$scratch/non-server-java.log" 2>&1 &
fixture_non_server_pid=$!
fixture_launcher_pids+=("$fixture_non_server_pid")
sleep 0.5
mapfile -t false_positive_pids < <("$helper" list-server-pids "$fixture_server_dir")
if (( ${#false_positive_pids[@]} > 0 )); then
  echo "non-server Java helper was misidentified as the Liberty JVM" >&2
  exit 1
fi
kill "$fixture_non_server_pid" 2>/dev/null || true
wait "$fixture_non_server_pid" 2>/dev/null || true
fixture_launcher_pids=()
printf 'expected non-server Java helper ignored\n'

start_fixture direct
start_fixture bypass
if [[ "${#fixture_java_pids[@]}" -ne 2 ]]; then
  echo "duplicate JVM fixture did not produce exactly two server-shaped processes" >&2
  exit 1
fi
sampler_output="$scratch/transition-samples.tsv"
sampler_stop="$scratch/transition.stop"
sampler_pid_file="$scratch/transition.pid"
"$helper" sample-server "$fixture_server_dir" "$sampler_output" \
  "$sampler_stop" 0.02 "$sampler_pid_file" \
  > "$scratch/transition.out" 2> "$scratch/transition.err" &
fixture_sampler_pid=$!
fixture_sampler_stop="$sampler_stop"
sleep 0.2
if ! kill -0 "$fixture_sampler_pid" 2>/dev/null; then
  echo "sampler failed before post-readiness PID selection" >&2
  cat "$scratch/transition.err" >&2
  exit 1
fi
kill "$last_fixture_pid" 2>/dev/null || true
for ((attempt = 0; attempt < 50; attempt++)); do
  mapfile -t transition_pids < <("$helper" list-server-pids "$fixture_server_dir")
  [[ "${#transition_pids[@]}" -eq 1 ]] && break
  sleep 0.1
done
if [[ "${#transition_pids[@]}" -ne 1 ]]; then
  echo "startup fixture did not transition to one Liberty JVM" >&2
  exit 1
fi
selected_fixture_pid="$("$helper" find-server-pid "$fixture_server_dir")"
printf '%s\n' "$selected_fixture_pid" > "$sampler_pid_file"
for ((attempt = 0; attempt < 50; attempt++)); do
  [[ "$(wc -l < "$sampler_output")" -gt 1 ]] && break
  sleep 0.1
done
if [[ "$(wc -l < "$sampler_output")" -le 1 ]] \
  || [[ "$(awk -F '\t' 'NR == 2 { print $2 }' "$sampler_output")" != "$selected_fixture_pid" ]]; then
  echo "sampler did not transition to the strictly selected Liberty PID" >&2
  exit 1
fi
touch "$sampler_stop"
wait "$fixture_sampler_pid"
fixture_sampler_pid=""
fixture_sampler_stop=""
changed_pid_file="$scratch/changed-pid.txt"
printf '1\n' > "$changed_pid_file"
"$helper" sample-server "$fixture_server_dir" "$scratch/changed-pid-samples.tsv" \
  "$scratch/changed-pid.stop" 0.02 "$changed_pid_file" \
  > "$scratch/changed-pid.out" 2> "$scratch/changed-pid.err" &
fixture_sampler_pid=$!
fixture_sampler_stop="$scratch/changed-pid.stop"
if wait "$fixture_sampler_pid"; then
  echo "sampler accepted a different post-readiness Liberty PID" >&2
  exit 1
fi
fixture_sampler_pid=""
fixture_sampler_stop=""
grep -Fq 'Liberty JVM PID changed unexpectedly' "$scratch/changed-pid.err"
start_fixture bypass
sampler_output="$scratch/duplicate-samples.tsv"
sampler_stop="$scratch/duplicate.stop"
"$helper" sample-server "$fixture_server_dir" "$sampler_output" \
  "$sampler_stop" 0.02 "$sampler_pid_file" \
  > "$scratch/duplicate.out" 2> "$scratch/duplicate.err" &
fixture_sampler_pid=$!
fixture_sampler_stop="$sampler_stop"
if wait "$fixture_sampler_pid"; then
  echo "sampler accepted multiple Liberty JVMs after PID selection" >&2
  exit 1
fi
fixture_sampler_pid=""
fixture_sampler_stop=""
grep -Fq 'expected one Liberty JVM' "$scratch/duplicate.err"
if grep -Fq 'Broken pipe' "$scratch/duplicate.err"; then
  echo "sampler emitted a broken-pipe error during duplicate discovery" >&2
  exit 1
fi
printf 'expected pre-readiness candidates deferred and post-selection duplicates rejected\n'
stop_fixture
