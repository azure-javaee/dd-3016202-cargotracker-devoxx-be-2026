# Spike 1.12 resolution

The existing JUnit 5 and Arquillian scheme is a suitable foundation, but the
normal Maven lifecycle does not yet exercise the production WAR. Preserve the
existing domain and `BookingService` tests and establish the following minimum
safety net before the Change Arrival Deadline campaign begins:

1. retain focused domain contracts proving route-specification origin,
   destination, and arrival-deadline invariants;
2. retain the Arquillian `BookingService` contracts for booking, route
   selection, route assignment, cargo lookup, and destination changes that
   preserve the existing deadline;
3. add direct facade/DTO and JSF backing-state tests for the existing deadline
   value before adding deadline-change behavior;
4. promote `run-http-acceptance.sh` into a supported production-WAR acceptance
   entry point that packages and deploys the application, waits for Open
   Liberty, verifies `/cargo-tracker/rest/cargo`,
   `/cargo-tracker/admin/dashboard.xhtml`, and
   `/cargo-tracker/admin/show.xhtml?trackingId=ABC123`, and always stops the
   server; and
5. introduce architecture checks with an explicit baseline for current
   violations rather than enabling blanket rules that fail immediately.

Use seeded cargo `ABC123` as the deterministic browser-free acceptance record.
The REST endpoint must return all four stable tracking IDs, while the
Administration dashboard and detail page must render `ABC123`. Do not assert
literal seeded dates because `SampleDataGenerator` derives them from the
current date.

Do not add browser automation before the talk deadline. Direct HTTP checks
already cover production deployment, startup seeding, persistence, JAX-RS,
JSF rendering, cargo lookup, and Administration availability. Reconsider a
browser test only if the later feature introduces PrimeFaces dialog or Ajax
behavior that cannot be protected at the domain, application, facade, backing
bean, or HTTP-rendering layers.

The failure experiment is resolved: temporarily reversing
`RouteSpecificationTest.testIsNotSatisfiedByMissedDeadline` produced a concise,
targeted assertion failure, and the restored test passed. The existing domain
test layer is therefore appropriate for invariant failures.

