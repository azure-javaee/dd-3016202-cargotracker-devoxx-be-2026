#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"
out="$root/ci-artifacts/compatibility-contract"
mkdir -p "$out"
server_stopped=false
collect_logs() {
  find target/liberty/wlp/usr/servers -name messages.log -type f -print -exec tail -n 80 {} \; \
    > "$out/liberty-messages-excerpt.txt"
  test -s "$out/liberty-messages-excerpt.txt"
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
