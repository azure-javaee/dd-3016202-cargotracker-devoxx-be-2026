#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"
out="$root/ci-artifacts/compatibility-contract"
liberty_out="${LIBERTY_LOG_OUTPUT_DIR:-$root/ci-artifacts/liberty-logs}"
job_log="$root/target/$(date -u +%Y%m%d-%H%M)-job-logs.txt"
mkdir -p "$out"
mkdir -p "$root/target"
server_stopped=false
collect_logs() {
  local server_dir=target/liberty/wlp/usr/servers/defaultServer
  mkdir -p "$liberty_out"
  for name in messages.log console.log; do
    if [[ -f "$server_dir/logs/$name" ]]; then
      tail -n 200 "$server_dir/logs/$name" > "$liberty_out/$name"
    fi
  done
  if [[ -n "${OBSERVABILITY_REQUEST_ID:-}" && -f "$server_dir/logs/http_access.log" ]]; then
    grep -F "$OBSERVABILITY_REQUEST_ID" "$server_dir/logs/http_access.log" \
      > "$liberty_out/observability-access.log" || true
  fi
  if [[ -d "$server_dir/logs/ffdc" ]]; then
    local ffdc_index=0
    while IFS= read -r -d '' file; do
      ffdc_index=$((ffdc_index + 1))
      tail -n 200 "$file" > "$liberty_out/ffdc-${ffdc_index}-$(basename "$file")"
    done < <(find "$server_dir/logs/ffdc" -maxdepth 1 -type f -print0 | sort -z)
  fi
  if [[ -f "$liberty_out/messages.log" ]]; then
    if [[ -s "$liberty_out/messages.log" ]]; then
      tail -n 80 "$liberty_out/messages.log" > "$out/liberty-messages-excerpt.txt"
    else
      printf '%s\n' "Liberty messages.log was empty." > "$out/liberty-messages-excerpt.txt"
    fi
  else
    printf '%s\n' "No Liberty messages.log was produced." > "$out/liberty-messages-excerpt.txt"
  fi
}
stop_server() {
  if [[ "$server_stopped" == false ]]; then
    local server_env=target/liberty/wlp/usr/servers/defaultServer/server.env
    if [[ -n "${OBSERVABILITY_REQUEST_ID:-}" && -f "$server_env" ]]; then
      local server_env_without_agent
      server_env_without_agent="$(mktemp)"
      grep -v '^JAVA_TOOL_OPTIONS=' "$server_env" > "$server_env_without_agent"
      cp "$server_env_without_agent" "$server_env"
      rm -f "$server_env_without_agent"
    fi
    ./mvnw liberty:stop 2>&1 | tee "$out/liberty-stop.log" | tee -a "$job_log"
    server_stopped=true
  fi
}
cleanup() {
  local status=$?
  if [[ "$status" -ne 0 ]]; then
    collect_logs || true
    if [[ -s "$out/liberty-messages-excerpt.txt" ]]; then
      cat "$out/liberty-messages-excerpt.txt" >&2
    fi
  fi
  if [[ "$server_stopped" == false ]]; then
    stop_server || true
  fi
  if [[ -s "$job_log" ]]; then
    tail -n 80 "$job_log" >&2
  fi
  return "$status"
}
trap cleanup EXIT

./mvnw liberty:deploy 2>&1 | tee "$out/liberty-deploy.log" | tee -a "$job_log"
if [[ -n "${OBSERVABILITY_SERVER_ENV:-}" ]]; then
  if [[ ! -s "$OBSERVABILITY_SERVER_ENV" ]]; then
    echo "incompatible instrumentation: staged Liberty agent environment is missing" >&2
    exit 1
  fi
  server_config_dir=target/liberty/wlp/usr/servers/defaultServer
  cp "$OBSERVABILITY_SERVER_ENV" "$server_config_dir/server.env"
fi
./mvnw -Dapplications=cargo-tracker -DserverStartTimeout=90 liberty:start \
  2>&1 | tee "$out/liberty-start.log" | tee -a "$job_log"

ready=false
for _ in $(seq 1 60); do
  if curl --fail --silent --show-error \
    --connect-timeout 5 --max-time 10 \
    -H 'Accept: application/json' \
    http://localhost:8080/cargo-tracker/rest/cargo > "$out/readiness.json"; then
    if grep -q '"trackingId":"ABC123"' "$out/readiness.json"; then
      ready=true
      break
    fi
  fi
  sleep 2
done
if [[ "$ready" != true ]]; then
  echo "Open Liberty readiness boundary was not reached" >&2
  exit 1
fi
if [[ "${SMOKE_TEST_FORCE_FAILURE:-0}" == "1" ]]; then
  echo "forced acceptance failure after readiness" >&2
  exit 97
fi
curl --fail --silent --show-error --dump-header "$out/readiness.headers" \
  --connect-timeout 5 --max-time 10 \
  -H 'Accept: application/json' \
  http://localhost:8080/cargo-tracker/rest/cargo > "$out/readiness.json"
grep -qi '^content-type: application/json' "$out/readiness.headers"
curl --fail --silent --show-error --connect-timeout 5 --max-time 10 \
  http://localhost:8080/cargo-tracker/ > "$out/root.html"
grep -q '<title>Cargo Tracker</title>' "$out/root.html"
curl --fail --silent --show-error --connect-timeout 5 --max-time 10 \
  "http://localhost:8080/cargo-tracker/admin/dashboard.xhtml" > "$out/admin-dashboard.html"
grep -qi 'dashboard' "$out/admin-dashboard.html"
curl --fail --silent --show-error --connect-timeout 5 --max-time 10 \
  "http://localhost:8080/cargo-tracker/admin/show.xhtml?trackingId=ABC123" > "$out/admin-show.html"
grep -q 'ABC123' "$out/admin-show.html"
if [[ -n "${OBSERVABILITY_REQUEST_ID:-}" ]]; then
  record_observability_request() {
    local kind="$1" path="$2" trace_id="$3" parent_span_id="$4" expected_status="$5"
    local status timestamp
    status="$(curl --silent --show-error --output /dev/null --write-out '%{http_code}' \
      --connect-timeout 5 --max-time 10 \
      -H "X-CI-Request-ID: $OBSERVABILITY_REQUEST_ID" \
      -H "traceparent: 00-${trace_id}-${parent_span_id}-01" \
      "http://localhost:8080${path}")"
    if [[ "$status" != "$expected_status" ]]; then
      echo "$kind request returned HTTP $status; expected $expected_status" >&2
      exit 1
    fi
    timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf '{"timestamp":"%s","kind":"%s","request_id":"%s","method":"GET","path":"%s","status":%s,"trace_id":"%s","parent_span_id":"%s"}\n' \
      "$timestamp" "$kind" "$OBSERVABILITY_REQUEST_ID" "$path" "$status" \
      "$trace_id" "$parent_span_id" >> "$OBSERVABILITY_TRANSCRIPT"
  }
  record_observability_request success /cargo-tracker/rest/cargo \
    "$OBSERVABILITY_TRACE_ID_SUCCESS" aaaaaaaaaaaaaaaa 200
  record_observability_request invalid /cargo-tracker/rest/does-not-exist \
    "$OBSERVABILITY_TRACE_ID_INVALID" bbbbbbbbbbbbbbbb 404
fi
collect_logs
stop_server
