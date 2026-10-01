#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"
out="$root/ci-artifacts/compatibility-contract"
mkdir -p "$out"
report="$out/safety-net-negative-controls.txt"
log_excerpt_lines="${LOG_EXCERPT_LINES:-40}"
: > "$report"
tmp="$(mktemp -d)"
command -v timeout >/dev/null || {
  echo "timeout command not found" >&2
  exit 1
}
route_test=src/test/java/org/eclipse/cargotracker/domain/model/cargo/RouteSpecificationTest.java
service_test=src/test/java/org/eclipse/cargotracker/application/BookingServiceTest.java
web_source="$(find src/main -path '*interfaces/booking/web*' -type f -name '*.java' | head -1)"
test -n "$web_source"
cp "$route_test" "$tmp/RouteSpecificationTest.java"
cp "$service_test" "$tmp/BookingServiceTest.java"
cp "$web_source" "$tmp/web.java"
test -s "$tmp/RouteSpecificationTest.java"
test -s "$tmp/BookingServiceTest.java"
test -s "$tmp/web.java"
http_server_pid=
readiness_server_pid=
cleanup() {
  local status=$?
  [[ -z "$http_server_pid" ]] || kill "$http_server_pid" 2>/dev/null || true
  [[ -z "$readiness_server_pid" ]] || kill "$readiness_server_pid" 2>/dev/null || true
  if pgrep -f '[w]lp/bin/server run defaultServer' >/dev/null 2>&1; then
    ./mvnw liberty:stop >/dev/null 2>&1 || true
  fi
  cp "$tmp/RouteSpecificationTest.java" "$route_test"
  cp "$tmp/BookingServiceTest.java" "$service_test"
  cp "$tmp/web.java" "$web_source"
  rm -rf "$tmp"
  return "$status"
}
trap cleanup EXIT

control_log_path() {
  printf '%s/%s.log' "$tmp" "$1"
}
expect_failure() {
  local name="$1"; shift
  local log
  log="$(control_log_path "$name")"
  set +e
  "$@" >"$log" 2>&1
  local status=$?
  set -e
  if [[ "$status" -eq 0 ]]; then
    echo "$name: UNEXPECTED PASS" | tee -a "$report"
    return 1
  fi
  if [[ "$status" -eq 124 ]]; then
    echo "$name: bounded timeout (control did not complete)" | tee -a "$report"
    return 1
  fi
  echo "$name: expected failure" | tee -a "$report"
  sed -n "1,${log_excerpt_lines}p" "$log" >> "$report"
}
expect_failure_with_diagnostic() {
  local name="$1" pattern="$2"; shift 2
  expect_failure "$name" "$@"
  local log
  log="$(control_log_path "$name")"
  if [[ ! -s "$log" ]] || ! grep -Eiq "$pattern" "$log"; then
    echo "$name: expected diagnostic /$pattern/ not found" | tee -a "$report"
    exit 1
  fi
}

sed -i '0,/assertTrue(routeSpecification.isSatisfiedBy(itinerary))/s//assertFalse(routeSpecification.isSatisfiedBy(itinerary))/' "$route_test"
expect_failure domain-invariant-regression timeout 120s ./mvnw '-P!openliberty' -Dtest=RouteSpecificationTest test
cp "$tmp/RouteSpecificationTest.java" "$route_test"

sed -i '0,/assertEquals(RoutingStatus.ROUTED/s//assertEquals(RoutingStatus.MISROUTED/' "$service_test"
expect_failure application-service-regression timeout 120s ./mvnw -Popenliberty -Dtest=BookingServiceTest test
cp "$tmp/BookingServiceTest.java" "$service_test"

sed -i '/^package /a import org.eclipse.cargotracker.domain.model.cargo.Cargo;' "$web_source"
expect_failure_with_diagnostic package-layer-violation 'LayeringTest|domain\.' \
  timeout 120s ./mvnw '-P!openliberty' -Dtest=LayeringTest test

expect_failure liberty-startup-failure ./target/liberty/wlp/bin/server start no-such-server
python3 -m http.server 18080 --bind 127.0.0.1 --directory "$tmp" >"$tmp/http-server.log" 2>&1 &
http_server_pid=$!
for _ in $(seq 1 20); do
  curl --silent --max-time 1 http://127.0.0.1:18080/ >/dev/null 2>&1 && break
  sleep 0.1
done
if ! curl --silent --max-time 1 http://127.0.0.1:18080/ >/dev/null 2>&1; then
  echo "http-non-200-or-missing-content: HTTP fixture failed to start" | tee -a "$report"
  exit 1
fi
expect_failure_with_diagnostic http-non-200-or-missing-content '404|curl: \(22\)' \
  curl --fail --silent --show-error --max-time 5 http://127.0.0.1:18080/missing
python3 -c '
import socket
import time
s = socket.socket()
s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
s.bind(("127.0.0.1", 18081))
s.listen(5)
time.sleep(3600)
' >"$tmp/readiness-server.log" 2>&1 &
readiness_server_pid=$!
probe_status=7
for _ in $(seq 1 20); do
  set +e
  curl --silent --connect-timeout 0.2 --max-time 0.2 \
    http://127.0.0.1:18081/ >/dev/null 2>&1
  probe_status=$?
  set -e
  [[ "$probe_status" -eq 28 ]] && break
  if [[ "$probe_status" -ne 7 ]]; then
    echo "readiness-timeout: fixture probe returned curl status $probe_status" | tee -a "$report"
    exit 1
  fi
  sleep 0.1
done
if [[ "$probe_status" -ne 28 ]]; then
  echo "readiness-timeout: stalling fixture did not produce a timeout" | tee -a "$report"
  exit 1
fi
expect_failure_with_diagnostic readiness-timeout 'timed out|Operation timed out|\(28\)' \
  curl --fail --silent --show-error --connect-timeout 1 --max-time 2 \
  http://127.0.0.1:18081/cargo-tracker/rest/cargo

if SMOKE_TEST_FORCE_FAILURE=1 ./scripts/ci/run-openliberty-acceptance.sh >"$tmp/forced-acceptance.log" 2>&1; then
  echo "forced-acceptance-cleanup: UNEXPECTED PASS" | tee -a "$report"
  exit 1
fi
if pgrep -f '[w]lp/bin/server run defaultServer' >"$tmp/processes" 2>/dev/null; then
  echo "forced-acceptance-cleanup: Liberty still running" | tee -a "$report"
  cat "$tmp/processes" >> "$report"
  exit 1
fi
echo "forced-acceptance-cleanup: expected failure and Liberty stopped" | tee -a "$report"
sed -n "1,${log_excerpt_lines}p" "$tmp/forced-acceptance.log" >> "$report"
exit 0
