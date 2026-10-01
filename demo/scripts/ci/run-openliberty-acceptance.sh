#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"
out="$root/ci-artifacts/compatibility-contract"
liberty_out="$root/ci-artifacts/liberty-logs"
mkdir -p "$out"
server_stopped=false
collect_logs() {
  local server_dir=target/liberty/wlp/usr/servers/defaultServer
  mkdir -p "$liberty_out"
  for name in messages.log console.log; do
    if [[ -f "$server_dir/logs/$name" ]]; then
      tail -n 200 "$server_dir/logs/$name" > "$liberty_out/$name"
    fi
  done
  if [[ -d "$server_dir/logs/ffdc" ]]; then
    local ffdc_index=0
    find "$server_dir/logs/ffdc" -maxdepth 1 -type f -print0 |
      sort -z | while IFS= read -r -d '' file; do
        ffdc_index=$((ffdc_index + 1))
        tail -n 200 "$file" > "$liberty_out/ffdc-${ffdc_index}-$(basename "$file")"
      done
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
    ./mvnw liberty:stop 2>&1 | tee "$out/liberty-stop.log"
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
  return "$status"
}
trap cleanup EXIT

./mvnw liberty:deploy 2>&1 | tee "$out/liberty-deploy.log"
./mvnw -Dapplications=cargo-tracker -DserverStartTimeout=90 liberty:start \
  2>&1 | tee "$out/liberty-start.log"

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
curl --fail --silent --show-error http://localhost:8080/cargo-tracker/ > "$out/root.html"
grep -q '<title>Cargo Tracker</title>' "$out/root.html"
curl --fail --silent --show-error \
  "http://localhost:8080/cargo-tracker/admin/dashboard.xhtml" > "$out/admin-dashboard.html"
grep -qi 'dashboard' "$out/admin-dashboard.html"
curl --fail --silent --show-error \
  "http://localhost:8080/cargo-tracker/admin/show.xhtml?trackingId=ABC123" > "$out/admin-show.html"
grep -q 'ABC123' "$out/admin-show.html"
collect_logs
stop_server
