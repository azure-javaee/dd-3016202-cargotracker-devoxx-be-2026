#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"
out="$root/ci-artifacts/compatibility-contract"
mkdir -p "$out"
report="$out/safety-net-negative-controls.txt"
: > "$report"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

expect_failure() {
  local name="$1"; shift
  local log="$tmp/$name.log"
  if "$@" >"$log" 2>&1; then
    echo "$name: UNEXPECTED PASS" | tee -a "$report"
    return 1
  fi
  echo "$name: expected failure" | tee -a "$report"
  sed -n '1,12p' "$log" >> "$report"
}

route_test=src/test/java/org/eclipse/cargotracker/domain/model/cargo/RouteSpecificationTest.java
cp "$route_test" "$tmp/RouteSpecificationTest.java"
sed -i '0,/assertTrue(routeSpecification.isSatisfiedBy(itinerary))/s//assertFalse(routeSpecification.isSatisfiedBy(itinerary))/' "$route_test"
expect_failure domain-invariant-regression ./mvnw '-P!openliberty' -Dtest=RouteSpecificationTest test
cp "$tmp/RouteSpecificationTest.java" "$route_test"

service_test=src/test/java/org/eclipse/cargotracker/application/BookingServiceTest.java
cp "$service_test" "$tmp/BookingServiceTest.java"
sed -i '0,/assertEquals(RoutingStatus.ROUTED/s//assertEquals(RoutingStatus.MISROUTED/' "$service_test"
expect_failure application-service-regression ./mvnw -Popenliberty -Dtest=BookingServiceTest test
cp "$tmp/BookingServiceTest.java" "$service_test"

web_source="$(find src/main -path '*interfaces/booking/web*' -type f -name '*.java' | head -1)"
cp "$web_source" "$tmp/web.java"
printf '\nimport org.eclipse.cargotracker.domain.model.cargo.Cargo;\n' >> "$web_source"
expect_failure package-layer-violation ./mvnw '-P!openliberty' -Dtest=LayeringTest test
cp "$tmp/web.java" "$web_source"

expect_failure liberty-startup-failure ./target/liberty/wlp/bin/server start no-such-server
expect_failure http-non-200-or-missing-content curl --fail --silent --show-error --max-time 5 http://127.0.0.1:1/missing
expect_failure readiness-timeout curl --fail --silent --show-error --connect-timeout 1 --max-time 2 \
  http://127.0.0.1:1/cargo-tracker/rest/cargo

if SMOKE_TEST_FORCE_FAILURE=1 ./scripts/ci/run-openliberty-acceptance.sh >"$tmp/forced-acceptance.log" 2>&1; then
  echo "forced-acceptance-cleanup: UNEXPECTED PASS" | tee -a "$report"
  exit 1
fi
if pgrep -af 'wlp/bin/server run defaultServer' >"$tmp/processes"; then
  echo "forced-acceptance-cleanup: Liberty still running" | tee -a "$report"
  cat "$tmp/processes" >> "$report"
  exit 1
fi
echo "forced-acceptance-cleanup: expected failure and Liberty stopped" | tee -a "$report"
sed -n '1,12p' "$tmp/forced-acceptance.log" >> "$report"
