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
cleanup() {
  if pgrep -f '[w]lp/bin/server run defaultServer' >/dev/null 2>&1; then
    ./mvnw liberty:stop >/dev/null 2>&1 || true
  fi
  cp "$tmp/RouteSpecificationTest.java" "$route_test"
  cp "$tmp/BookingServiceTest.java" "$service_test"
  cp "$tmp/web.java" "$web_source"
  rm -rf "$tmp"
}
trap cleanup EXIT

expect_failure() {
  local name="$1"; shift
  local log="$tmp/$name.log"
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

sed -i '0,/assertTrue(routeSpecification.isSatisfiedBy(itinerary))/s//assertFalse(routeSpecification.isSatisfiedBy(itinerary))/' "$route_test"
expect_failure domain-invariant-regression timeout 120s ./mvnw '-P!openliberty' -Dtest=RouteSpecificationTest test
cp "$tmp/RouteSpecificationTest.java" "$route_test"

sed -i '0,/assertEquals(RoutingStatus.ROUTED/s//assertEquals(RoutingStatus.MISROUTED/' "$service_test"
expect_failure application-service-regression timeout 120s ./mvnw -Popenliberty -Dtest=BookingServiceTest test
cp "$tmp/BookingServiceTest.java" "$service_test"

printf '\nimport org.eclipse.cargotracker.domain.model.cargo.Cargo;\n' >> "$web_source"
expect_failure package-layer-violation timeout 120s ./mvnw '-P!openliberty' -Dtest=LayeringTest test

expect_failure liberty-startup-failure ./target/liberty/wlp/bin/server start no-such-server
expect_failure http-non-200-or-missing-content curl --fail --silent --show-error --max-time 5 http://127.0.0.1:1/missing
expect_failure readiness-timeout curl --fail --silent --show-error --connect-timeout 1 --max-time 2 \
  http://127.0.0.1:1/cargo-tracker/rest/cargo

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
