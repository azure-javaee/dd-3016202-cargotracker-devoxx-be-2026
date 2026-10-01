#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"
versions_file="$root/observability/versions.properties"
agent_version="$(sed -n 's/^otel\.javaagent\.version=//p' "$versions_file")"
agent_sha256="$(sed -n 's/^otel\.javaagent\.sha256=//p' "$versions_file")"
collector_image="$(sed -n 's/^otel\.collector\.image=//p' "$versions_file")"
if [[ -z "$agent_version" || -z "$agent_sha256" || -z "$collector_image" ]]; then
  echo "incompatible instrumentation: observability version pins are incomplete" >&2
  exit 1
fi
collector_health_url="http://127.0.0.1:13133/"
request_id="cargo-tracker-ci-observability"
trace_id_success="11111111111111111111111111111111"
trace_id_invalid="22222222222222222222222222222222"
otel_out="${OBSERVABILITY_OUTPUT_DIR:-$root/ci-artifacts/otel-telemetry}"
liberty_out="${OBSERVABILITY_LIBERTY_OUTPUT_DIR:-$root/ci-artifacts/liberty-logs}"
agent="$root/target/observability/opentelemetry-javaagent.jar"
server_dir="$root/target/liberty/wlp/usr/servers/defaultServer"
collector_name="cargo-tracker-otel-${GITHUB_RUN_ID:-local}-$$"
collector_started=false
acceptance_started=false
server_config_saved=false
server_env_existed=false
jvm_options_existed=false
tmp=""

record_command() {
  printf '%s\n' "$*" >> "$otel_out/commands.txt"
}

record_argv() {
  printf '%q' "$1" >> "$otel_out/commands.txt"
  shift
  printf ' %q' "$@" >> "$otel_out/commands.txt"
  printf '\n' >> "$otel_out/commands.txt"
}

stage_server_options() {
  if [[ -f "$server_dir/server.env" ]]; then
    cp -p "$server_dir/server.env" "$tmp/server.env"
    server_env_existed=true
  fi
  if [[ -f "$server_dir/jvm.options" ]]; then
    cp -p "$server_dir/jvm.options" "$tmp/jvm.options"
    jvm_options_existed=true
  fi
  server_config_saved=true
  cat > "$tmp/instrumented-server.env" <<EOF
JAVA_TOOL_OPTIONS=-javaagent:$agent
OTEL_SERVICE_NAME=cargo-tracker
OTEL_RESOURCE_ATTRIBUTES=service.namespace=cargo-tracker-ci,deployment.environment=ci
OTEL_EXPORTER_OTLP_ENDPOINT=http://127.0.0.1:4318
OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf
OTEL_TRACES_EXPORTER=otlp
OTEL_METRICS_EXPORTER=otlp
OTEL_LOGS_EXPORTER=none
OTEL_TRACES_SAMPLER=always_on
OTEL_METRIC_EXPORT_INTERVAL=1000
OTEL_INSTRUMENTATION_HTTP_SERVER_CAPTURE_REQUEST_HEADERS=x-ci-request-id
EOF
}

restore_server_options() {
  [[ "$server_config_saved" == true ]] || return 0
  if [[ "$server_env_existed" == true ]]; then
    cp -p "$tmp/server.env" "$server_dir/server.env"
  else
    rm -f "$server_dir/server.env"
  fi
  if [[ "$jvm_options_existed" == true ]]; then
    cp -p "$tmp/jvm.options" "$server_dir/jvm.options"
  else
    rm -f "$server_dir/jvm.options"
  fi
}

wait_for_collector() {
  local health_url="${1:-$collector_health_url}"
  local timeout_seconds="${2:-60}"
  local deadline now remaining request_timeout
  deadline=$(($(date +%s) + timeout_seconds))
  while true; do
    now=$(date +%s)
    ((now < deadline)) || break
    remaining=$((deadline - now))
    request_timeout=2
    ((remaining < request_timeout)) && request_timeout=$remaining
    if curl --fail --silent --show-error --max-time "$request_timeout" \
      "$health_url" >/dev/null 2>&1; then
      printf 'collector health check passed: %s\n' "$health_url"
      return 0
    fi
    now=$(date +%s)
    ((now < deadline)) && sleep 1
  done
  echo "collector unavailable: health check did not pass at $health_url within ${timeout_seconds}s" >&2
  return 1
}

if [[ "${1:-}" == "--probe-collector" ]]; then
  wait_for_collector "${2:?health URL required}" "${3:-2}"
  exit $?
fi

tmp="$(mktemp -d)"
if [[ -z "${OBSERVABILITY_OUTPUT_DIR:-}" ]]; then
  rm -rf "$otel_out"
fi
if [[ -z "${OBSERVABILITY_LIBERTY_OUTPUT_DIR:-}" ]]; then
  rm -rf "$liberty_out"
fi
mkdir -p "$otel_out" "$liberty_out"
: > "$otel_out/commands.txt"
printf '%s\n' "Observability lifecycle has not started." > "$otel_out/status.txt"
printf 'OpenTelemetry Java agent %s\nCollector image %s\n' \
  "$agent_version" "$collector_image" > "$otel_out/instrumentation-versions.txt"
printf '%s\n' "$collector_name" > "$otel_out/collector-name.txt"
cp "$root/observability/otel-collector-config.yaml" "$otel_out/"
cp "$versions_file" "$otel_out/"

cleanup() {
  local status=$?
  trap - EXIT
  if [[ "$collector_started" == true ]]; then
    docker logs "$collector_name" > "$otel_out/collector.log" 2>&1 || true
    record_command "docker stop --time 10 $collector_name"
    docker stop --time 10 "$collector_name" >/dev/null 2>&1 || true
    record_command "docker rm $collector_name"
    docker rm "$collector_name" >/dev/null 2>&1 || true
  fi
  restore_server_options || true
  if [[ ! -s "$liberty_out/messages.log" && ! -s "$liberty_out/console.log" \
    && ! -s "$liberty_out/observability-access.log" ]]; then
    if [[ "$acceptance_started" == true ]]; then
      printf '%s\n' "Liberty diagnostics were unavailable from the failed acceptance lifecycle." \
        > "$liberty_out/observability-diagnostic.txt"
    else
      printf '%s\n' "Liberty was not started because observability initialization did not complete." \
        > "$liberty_out/observability-diagnostic.txt"
    fi
  fi
  if [[ "$status" -ne 0 ]]; then
    printf 'observability lifecycle failed with exit status %s\n' "$status" \
      > "$otel_out/failure-diagnostics.txt"
    if [[ -s "$otel_out/collector.log" ]]; then
      printf '%s\n' "Collector output is in collector.log." >> "$otel_out/failure-diagnostics.txt"
    fi
  fi
  record_command "./scripts/ci/redact-artifacts.sh ci-artifacts/otel-telemetry ci-artifacts/liberty-logs"
  "$root/scripts/ci/redact-artifacts.sh" "$otel_out" "$liberty_out" \
    > "$otel_out/redaction-check.txt" 2>&1 || status=$?
  rm -rf "$tmp"
  return "$status"
}
trap cleanup EXIT

mkdir -p "$(dirname "$agent")"
agent_url="https://repo.maven.apache.org/maven2/io/opentelemetry/javaagent/opentelemetry-javaagent/$agent_version/opentelemetry-javaagent-$agent_version.jar"
record_command "curl --fail --location --retry 3 --connect-timeout 10 --max-time 180 $agent_url"
if ! curl --fail --location --retry 3 --connect-timeout 10 --max-time 180 \
  "$agent_url" -o "$agent" > "$otel_out/agent-download.log" 2>&1; then
  cat "$otel_out/agent-download.log" >&2
  echo "incompatible instrumentation: pinned OpenTelemetry Java agent download failed" >&2
  exit 1
fi
record_command "sha256sum --check pinned OpenTelemetry Java agent SHA-256"
if ! printf '%s  %s\n' "$agent_sha256" "$agent" | \
  sha256sum --check > "$otel_out/agent-checksum.log" 2>&1; then
  cat "$otel_out/agent-checksum.log" >&2
  echo "incompatible instrumentation: pinned OpenTelemetry Java agent checksum mismatch" >&2
  exit 1
fi
record_command "java -javaagent:$agent -version"
if ! java -javaagent:"$agent" -version > "$otel_out/instrumentation-check.log" 2>&1; then
  echo "incompatible instrumentation: pinned agent could not attach to the configured Java runtime" >&2
  cat "$otel_out/instrumentation-check.log" >&2
  exit 1
fi

record_command "docker pull $collector_image"
if ! timeout 180 docker pull "$collector_image" > "$otel_out/collector-pull.log" 2>&1; then
  cat "$otel_out/collector-pull.log" >&2
  echo "collector unavailable: pinned Collector image could not be pulled" >&2
  exit 1
fi
record_command "docker image inspect $collector_image"
if ! docker image inspect "$collector_image" > "$otel_out/collector-image.json" 2>&1; then
  cat "$otel_out/collector-image.json" >&2
  echo "collector unavailable: pinned Collector image is not available locally" >&2
  exit 1
fi
chmod 0777 "$otel_out"
collector_command=(docker run --detach \
  --name "$collector_name" \
  --publish 127.0.0.1:4318:4318 \
  --publish 127.0.0.1:13133:13133 \
  --volume "$root/observability/otel-collector-config.yaml:/etc/otelcol-contrib/config.yaml:ro" \
  --volume "$otel_out:/otel-output:rw" \
  "$collector_image" \
  --config=/etc/otelcol-contrib/config.yaml)
record_argv "${collector_command[@]}"
collector_started=true
"${collector_command[@]}" \
  > "$otel_out/collector-container-id.txt" 2> "$otel_out/collector-launch.log"
if ! wait_for_collector > "$otel_out/collector-health.log" 2>&1; then
  cat "$otel_out/collector-health.log" >&2
  exit 1
fi
record_command "bounded Collector health check $collector_health_url (maximum 60 seconds)"
if [[ "${OBSERVABILITY_FORCE_FAILURE_AFTER_COLLECTOR:-0}" == "1" ]]; then
  echo "forced diagnostic failure after Collector health check" >&2
  exit 97
fi

stage_server_options
printf '%s\n' "Collector healthy; starting the existing Open Liberty acceptance lifecycle." \
  > "$otel_out/status.txt"
acceptance_command=(env \
  "OBSERVABILITY_REQUEST_ID=$request_id" \
  "OBSERVABILITY_SERVER_ENV=$tmp/instrumented-server.env" \
  "OBSERVABILITY_TRACE_ID_SUCCESS=$trace_id_success" \
  "OBSERVABILITY_TRACE_ID_INVALID=$trace_id_invalid" \
  "OBSERVABILITY_TRANSCRIPT=$otel_out/request-transcript.jsonl" \
  "LIBERTY_LOG_OUTPUT_DIR=$liberty_out" \
  ./scripts/ci/run-openliberty-acceptance.sh)
record_argv "${acceptance_command[@]}"
acceptance_started=true
if ! "${acceptance_command[@]}"; then
  if grep -Eiq 'java\.lang\.instrument|agent.*(failed|error)|error opening zip' \
    "$root/ci-artifacts/compatibility-contract/liberty-start.log" 2>/dev/null; then
    echo "incompatible instrumentation: Open Liberty rejected the pinned Java agent" >&2
  fi
  exit 1
fi

sleep 3
docker logs "$collector_name" > "$otel_out/collector.log" 2>&1 || true
printf '%s\n' "Acceptance lifecycle completed; telemetry export captured." \
  > "$otel_out/status.txt"
record_command "python3 scripts/ci/verify-observability.py ci-artifacts/otel-telemetry ci-artifacts/otel-telemetry/request-transcript.jsonl ci-artifacts/liberty-logs/observability-access.log"
python3 scripts/ci/verify-observability.py \
  "$otel_out" "$otel_out/request-transcript.jsonl" \
  "$liberty_out/observability-access.log"
