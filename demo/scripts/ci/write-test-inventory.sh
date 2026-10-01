#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"
out="$root/ci-artifacts/test-reports-unit"
mkdir -p "$out"
# Keep this count synchronized with the inventory below; undispositioned test classes must fail CI.
test_count="$(find src/test/java -name '*Test.java' | wc -l)"
test "$test_count" -eq 11 || {
  echo "Expected 11 test classes listed below, found $test_count" >&2
  exit 1
}

{
  printf 'class\tclassification\treason\n'
  printf 'org.eclipse.cargotracker.application.BookingServiceTest\tactive\tArquillian managed Open Liberty\n'
  printf 'org.eclipse.cargotracker.application.HandlingEventServiceTest\tdormant\tNo JUnit 5 test methods\n'
  printf 'org.eclipse.cargotracker.domain.model.cargo.CargoTest\tactive\tJUnit 5\n'
  printf 'org.eclipse.cargotracker.domain.model.cargo.ItineraryTest\tactive\tJUnit 5; all methods assert behavior\n'
  printf 'org.eclipse.cargotracker.domain.model.cargo.RouteSpecificationTest\tactive\tJUnit 5\n'
  printf 'org.eclipse.cargotracker.domain.model.handling.HandlingEventTest\tactive\tJUnit 5\n'
  printf 'org.eclipse.cargotracker.domain.model.handling.HandlingHistoryTest\tactive\tJUnit 5\n'
  printf 'org.eclipse.cargotracker.infrastructure.routing.ExternalRoutingServiceTest\tdormant\tRequires obsolete remote routing fixture\n'
  printf 'org.eclipse.cargotracker.scenario.CargoLifecycleScenarioTest\tdormant\tRequires removed in-memory application fixtures\n'
  printf 'org.eclipse.cargotracker.architecture.LayeringTest\tactive\tJUnit 5 architecture baseline\n'
  printf 'org.eclipse.cargotracker.interfaces.booking.facade.BookingFacadeDtoTest\tactive\tJUnit 5 facade and DTO boundary\n'
} > "$out/test-inventory.tsv"

test "$(grep -c $'\tactive\t' "$out/test-inventory.tsv")" -eq 8
test "$(grep -c $'\tdormant\t' "$out/test-inventory.tsv")" -eq 3
printf 'active=8 dormant=3 repaired=0 removed=0\n' > "$out/test-inventory-summary.txt"
