#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"
out="$root/ci-artifacts/compatibility-contract"
mkdir -p "$out"
server_stopped=false
stop_server() {
  if [[ "$server_stopped" == false ]]; then
    ./mvnw liberty:stop 2>&1 | tee "$out/liberty-stop.log" || true
    server_stopped=true
  fi
}
trap stop_server EXIT

./mvnw liberty:deploy 2>&1 | tee "$out/liberty-deploy.log"
./mvnw -Dapplications=cargo-tracker -DserverStartTimeout=90 liberty:start \
  2>&1 | tee "$out/liberty-start.log"

for attempt in $(seq 1 30); do
  if curl --fail --silent --show-error \
      -H 'Accept: application/json' \
      http://localhost:8080/cargo-tracker/rest/cargo > "$out/readiness.json"; then
    grep -q '"trackingId":"ABC123"' "$out/readiness.json"
    grep -qi 'application/json' "$out/readiness.headers" 2>/dev/null || true
    break
  fi
  if [[ "$attempt" == 30 ]]; then
    echo "Open Liberty readiness boundary was not reached" >&2
    exit 1
  fi
  sleep 2
done
curl --fail --silent --show-error --dump-header "$out/readiness.headers" \
  -H 'Accept: application/json' \
  http://localhost:8080/cargo-tracker/rest/cargo > "$out/readiness.json"
grep -qi '^content-type: application/json' "$out/readiness.headers"
find target/liberty/wlp/usr/servers -name messages.log -type f -print -exec tail -n 80 {} \; \
  > "$out/liberty-messages-excerpt.txt"
stop_server
