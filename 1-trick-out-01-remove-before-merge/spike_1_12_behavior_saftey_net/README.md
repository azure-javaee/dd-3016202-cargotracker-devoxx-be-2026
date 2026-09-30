# Spike 1.12: Behavioral safety-net readiness

Date: 2026-09-29

## Verdict

The repository is **at the starting line for domain and application-service
behavioral tests**, but it is **not yet at the starting line for the complete
Section 1.12 safety net**.

The existing JUnit 5 and Arquillian foundation is working:

- `mvn test` executes 28 tests successfully.
- 24 tests exercise domain behavior.
- 4 Arquillian tests exercise `BookingService` with Open Liberty, JPA, and the
  application service implementation.
- A temporary mutation of the missed-deadline assertion produced a concise,
  targeted failure, and the restored test passed.

However, the normal Maven test lifecycle has no executable coverage for the
booking facade/DTO boundary, JSF backing state, the deployed application HTTP
surface, the Administration page, or architecture boundaries. This spike now
contains a runnable production-WAR HTTP acceptance prototype, but it is not
yet part of Maven or CI. Three source files whose names imply tests are not
discovered as tests.

The campaign therefore does **not** need to invent a test stack. It does need a
small enabling slice that turns the already working stack into a full-application
behavioral safety net.

## Existing executable test inventory

| Layer | Executed tests | Current value | Important gap |
|---|---:|---|---|
| Cargo domain | 9 | Delivery and routing status, handling progress, misdirection | No focused route-change/deadline-change contract |
| Itinerary domain | 3 | Expected events and constructor guards | `testNextExpectedEvent` is empty but passes |
| Route specification | 4 | Origin, destination, and deadline satisfaction | Good direct starting point for deadline behavior |
| Handling domain | 8 | Handling-event construction and history | Some tests are explicitly described as trivial |
| `BookingService` Arquillian | 4 | Book, request routes, assign route, change destination | Ordered/static-state coupling; no facade or HTTP boundary |
| Full application HTTP/UI | 0 in Maven; spike harness available | Production-WAR root, Administration, detail, and REST checks | Not integrated into Maven or CI |
| Architecture | 0 | None | No architecture-test dependency or tests |
| Browser | 0 | None | No browser automation dependency or harness |

The six discovered test classes are:

1. `BookingServiceTest`
2. `CargoTest`
3. `ItineraryTest`
4. `RouteSpecificationTest`
5. `HandlingEventTest`
6. `HandlingHistoryTest`

Maven compiles 11 test source files, but these three test-looking classes are
not discovered because they have no JUnit 5 `@Test` methods:

- `CargoLifecycleScenarioTest`
- `HandlingEventServiceTest`
- `ExternalRoutingServiceTest`

The remaining two compiled test sources are Arquillian deployment helpers.

## What `mvn test` actually proves

The default Open Liberty profile is active during `mvn test`.
`BookingServiceTest` starts Open Liberty and deploys a ShrinkWrap-generated
`cargo-tracker-test.war`. That is useful application-service integration
coverage, but it is not a deployment test of the production
`cargo-tracker.war`.

The test run logs this warning before the Arquillian deployment:

```text
CWWKZ0014W: The application cargo-tracker could not be started as it could not
be found at location cargo-tracker.war.
```

The generated test WAR then starts successfully and all four
`BookingServiceTest` methods pass. Consequently, a green `mvn test` or current
CI package job does not prove that the real root page, Administration page,
REST endpoint, JSF wiring, or production WAR startup works.

## Existing contracts relevant to Change Arrival Deadline

Useful contracts already exist:

- `RouteSpecificationTest.testIsNotSatisfiedByMissedDeadline` proves that an
  itinerary arriving after the deadline does not satisfy the specification.
- `BookingServiceTest.testRegisterNew` proves a newly booked cargo retains its
  requested arrival deadline.
- `BookingServiceTest.testAssignRoute` proves the assigned route arrives before
  that deadline.
- `BookingServiceTest.testChangeDestination` proves changing destination
  preserves the deadline and makes the existing itinerary misrouted.
- `BookingServiceTest` proves cargo lookup through `CargoRepository` after
  application-service operations.

These are a credible base for deadline-change tests. They do not protect:

- a future `BookingService.changeArrivalDeadline` operation;
- facade and DTO propagation of a changed deadline;
- JSF backing-state behavior;
- rendered Administration behavior;
- production application startup and seeded-data usability.

## Deterministic deployed-application path

The full application was packaged and started with Open Liberty. These paths
all returned HTTP 200:

| Path | Deterministic evidence |
|---|---|
| `/cargo-tracker/` | Rendered `Cargo Tracker` |
| `/cargo-tracker/admin/dashboard.xhtml` | Rendered `Cargo Dashboard` and `ABC123` |
| `/cargo-tracker/admin/show.xhtml?trackingId=ABC123` | Rendered seeded cargo `ABC123` |
| `/cargo-tracker/rest/cargo` | JSON contained `ABC123`, `DEF789`, `JKL567`, and `MNO456` |

The best no-browser safety-net path is:

```text
GET /cargo-tracker/rest/cargo
```

It is stable, machine-readable, requires no session choreography, and proves
that the production WAR, JPA, startup seeding, repository, and JAX-RS boundary
are usable.

For an Administration-specific assertion, use:

```text
GET /cargo-tracker/admin/dashboard.xhtml
```

and assert HTTP 200 plus `Cargo Dashboard` and `ABC123`. A stronger cargo-detail
check is:

```text
GET /cargo-tracker/admin/show.xhtml?trackingId=ABC123
```

The four tracking IDs are deterministic. Their date values are not fixed:
`SampleDataGenerator` calculates deadlines and itinerary dates relative to
`LocalDate.now()`. Tests should assert identities, statuses, locations, and
date relationships rather than literal dates.

## Automated HTTP acceptance prototype

Run:

```bash
./1-trick-out-01-remove-before-merge/spike_1_12_behavior_saftey_net/run-http-acceptance.sh
```

The script:

1. packages the production `cargo-tracker.war`;
2. prepares and deploys it with the Open Liberty Maven plugin;
3. starts Open Liberty and waits for the `cargo-tracker` application;
4. asserts the root page, Administration dashboard, seeded cargo detail, and
   cargo REST contracts;
5. writes response bodies, headers, a TSV summary, and Maven logs into the
   spike directory; and
6. stops Open Liberty on both success and failure.

It deliberately uses `liberty:start` and `liberty:stop` rather than placing a
Maven process in the background. The harness requires only the repository's
Maven wrapper, Java 17, `curl`, and standard POSIX command-line tools.

## Browser-test decision

Do **not** add browser automation as part of the initial safety net.

Server-rendered JSF pages and the JSON endpoint provide enough value to prove
startup, seeded cargo lookup, Administration rendering, and the deployed
application boundary. Adding Playwright, Selenium, or another browser stack
would introduce runtime installation, synchronization, and CI maintenance
without protecting a behavior that cannot first be covered more cheaply.

A small browser test becomes justified only when the later feature needs to
prove PrimeFaces dialog/Ajax behavior that cannot be expressed through:

1. domain tests;
2. `BookingService`/facade tests; and
3. direct HTTP rendering checks.

## Architecture-test readiness

There is no architecture-testing dependency or architecture test.
Furthermore, a strict version of the proposed rules fails against the current
code:

- tracking web classes directly import domain model and repository types;
- `BookingBackingBean` is physically located in the domain package while
  importing the booking facade, DTOs, JSF, PrimeFaces, and application utility
  code.

Architecture checks must therefore either:

- establish an explicit baseline/allowlist for known violations and prevent
  new ones; or
- first move `BookingBackingBean` and resolve the intentional tracking-web
  exception.

Adding a blanket “interfaces never depend on domain” or “domain never depends
on interfaces/application” rule immediately would fail before the deadline
feature begins.

## Failure-signal experiment

The assertion in
`RouteSpecificationTest.testIsNotSatisfiedByMissedDeadline` was temporarily
changed from `assertFalse` to `assertTrue`.

The targeted command failed in 7.6 seconds with:

```text
RouteSpecificationTest.testIsNotSatisfiedByMissedDeadline:85
expected: <true> but was: <false>
```

The source was restored, the same targeted test passed, and `git diff` showed
no remaining change to the test file.

This demonstrates that the domain test layer gives the concise failure signal
requested by Section 1.12.

## Work required before the complete safety net

The minimum enabling work is:

1. Promote the spike's `run-http-acceptance.sh` production-WAR lifecycle into
   the repository's supported test/CI entry points.
2. Add direct tests for `DefaultBookingServiceFacade` and the relevant DTO
   assembly so arrival-deadline behavior is protected across the interface
   boundary without requiring a browser.
3. Add an architecture-test facility with a documented baseline for current
   violations, then prohibit new domain-to-interface/application dependencies
   and new web-to-domain leakage outside the accepted legacy tracking path.
4. Decide explicitly whether to revive or delete the three undiscovered legacy
   test classes; they currently create false confidence from their names.
5. Replace the empty `ItineraryTest.testNextExpectedEvent` placeholder with a
   real assertion or remove it from the test count.

After those steps, the later Change Arrival Deadline campaign can add behavior
tests at each crossed boundary without first building new infrastructure.

## Evidence

- `resolution.md` — decision and required safety-net scope
- `logs/20260929-1821-spike-1-12-test-logs.txt` — successful 28-test baseline
- `logs/20260929-1826-spike-1-12-mutation-logs.txt` — expected mutation failure
- `logs/20260929-1827-spike-1-12-restored-test-logs.txt` — restored test passes
- `logs/20260929-1827-spike-1-12-package-logs.txt` — production WAR package
- `logs/20260929-1828-spike-1-12-http-logs.txt` — production Open Liberty startup
- `reports/http-probe.txt` — deployed endpoint results
- `run-http-acceptance.sh` — automated production-WAR HTTP acceptance prototype
- `reports/http-acceptance-20260929-183256/` — successful automated run evidence
