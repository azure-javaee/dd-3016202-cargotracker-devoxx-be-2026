# Spike 1.13: Open Liberty lifecycle and acceptance-test boundary

## Result

Accept the existing recommendation: retain Arquillian for focused in-container
tests and add one bounded black-box acceptance job that deploys the production
WAR, starts Open Liberty once, verifies positive application readiness over
HTTP, captures evidence, and always stops the server.

The reliable clean CI lifecycle for Liberty Maven Plugin 3.12.1 and Open
Liberty 26.0.0.8 is:

```bash
./mvnw -DskipTests clean package
./mvnw liberty:deploy
./mvnw \
  -Dapplications=cargo-tracker \
  -DserverStartTimeout=90 \
  liberty:start

curl --fail \
  http://127.0.0.1:8080/cargo-tracker/rest/cargo

./mvnw liberty:stop
```

`liberty:deploy` is required. A clean `package` creates the Liberty runtime and
the WAR, but it does not place the application into the server. Starting
immediately after `clean package` reached Liberty's server-ready marker, then
timed out waiting for the `cargo-tracker` application marker and failed.

## Environment

- Experiment baseline: `cf19be6029aad88ce792e544cc4dd8135867723f`
- Microsoft OpenJDK: 17.0.18
- Maven Wrapper: 3.9.9
- Liberty Maven Plugin: 3.12.1
- Open Liberty runtime: 26.0.0.8
- Application context root: `/cargo-tracker`

All runtime experiments used full scratch clones. The campaign worktree's
application source was not modified.

## Verified lifecycle behavior

### `liberty:run`

The documented developer command works:

```bash
./mvnw clean package liberty:run
```

The application became HTTP-ready after 62 seconds. The command remains
attached to the server and therefore is inconvenient for a CI script that must
run separate HTTP commands. A separate `liberty:stop` invocation stopped the
server and allowed the attached Maven process to exit successfully.

Because ordinary `clean package` executes the existing tests, this command also
starts a Liberty test deployment before the final application run. The
acceptance job should use `-DskipTests` because unit and Arquillian tests belong
to earlier validation tiers and the acceptance boundary should start the
packaged application only once.

### `clean package` is not deployment

This sequence fails:

```bash
./mvnw -DskipTests clean package
./mvnw \
  -Dapplications=cargo-tracker \
  -DserverStartTimeout=45 \
  liberty:start
```

Liberty emitted `CWWKF0011I`, including the text
`is ready to run a smarter planet`, but the Maven goal timed out waiting for:

```text
CWWKZ0001I.*cargo-tracker
```

The plugin then stopped the server and returned a failed Maven build. The
failure is preserved in
`logs/20260929-1838-clean-package-liberty-start-job-logs.txt`.

### Explicit deployment and bounded start

After:

```bash
./mvnw liberty:deploy
```

the start goal succeeded and waited for both:

1. `CWWKF0011I`: the Liberty server is ready to run a smarter planet.
2. `CWWKZ0001I`: application `cargo-tracker` started.

Supplying `-Dapplications=cargo-tracker` is important because it makes
`liberty:start` verify the application marker instead of declaring success
when only the server kernel is ready.

### `liberty:status`

`liberty:status` is useful for diagnostics but not as an exit-code gate:

- while running, it printed `Server defaultServer is running` and exited zero;
- after stopping, it printed `Server defaultServer is not running` and also
  exited zero.

CI would have to parse the text. The positive application marker plus the HTTP
probe is a stronger readiness contract.

## HTTP readiness endpoint

Use:

```text
GET http://127.0.0.1:8080/cargo-tracker/rest/cargo
```

Require:

- HTTP 200;
- `Content-Type: application/json`; and
- at least the deterministic seeded cargo identifier
  `"trackingId":"ABC123"`.

This is stronger than checking `/cargo-tracker/` alone. It proves that the
deployed WAR, JAX-RS configuration, CDI/EJB wiring, persistence initialization,
sample data, and JSON provider are functioning. The final harness also checks:

- `/cargo-tracker/` for `Cargo Tracker`;
- `/cargo-tracker/admin/dashboard.xhtml` for `Cargo Dashboard` and `ABC123`;
- `/cargo-tracker/rest/cargo` for all four deterministic seeded tracking IDs.

The successful response evidence is in
`reports/acceptance-20260929-183934/`.

## Repeatable harness

Run:

```bash
./1-trick-out-01-remove-before-merge/spike_1_13_acceptance_tests/run-spike.sh
```

The harness:

1. refuses to run if Cargo Tracker is already responding on port 8080;
2. creates a clean package with tests skipped;
3. explicitly deploys the application;
4. starts Liberty with a 90-second server timeout and application-marker wait;
5. confirms the exact Liberty and application log markers;
6. retries the seeded REST readiness check for at most 60 seconds;
7. captures headers, bodies, Maven output, `messages.log`, and `console.log`;
8. runs the root, dashboard, and REST acceptance checks; and
9. invokes `liberty:stop` from an `EXIT` trap on success or failure.

`DEMO_DIRECTORY` and `BASE_URL` can be overridden for an isolated clone or a
non-default endpoint.

## Workflow recommendation

Add one required acceptance job after package and integration validation. Give
the overall job an explicit timeout in addition to the script's bounded
startup and HTTP timeouts. Upload the following with `if: always()`:

- the harness-generated report directory;
- Maven package, deploy, start, and stop logs;
- Liberty `messages.log`;
- Liberty `console.log`; and
- HTTP headers and response bodies.

Do not use `liberty:run` for this workflow job and do not launch a new Liberty
instance per HTTP assertion.

## Paste-ready Section 1.13 resolution

Accept the recommendation. Keep Arquillian for focused in-container tests and
add one bounded black-box acceptance job around the production WAR and
`server.xml`.

The verified clean lifecycle with Liberty Maven Plugin 3.12.1 and Open Liberty
26.0.0.8 is:

```bash
./mvnw -DskipTests clean package
./mvnw liberty:deploy
./mvnw -Dapplications=cargo-tracker -DserverStartTimeout=90 liberty:start
# bounded HTTP acceptance checks
./mvnw liberty:stop
```

An explicit `liberty:deploy` is required. `clean package` creates the runtime
and WAR but does not deploy the application. Starting directly after package
reached `CWWKF0011I`—`is ready to run a smarter planet`—but timed out waiting
for `CWWKZ0001I.*cargo-tracker` and failed. After `liberty:deploy`,
`liberty:start` successfully waited for both the server-ready and
application-started markers.

Use `GET /cargo-tracker/rest/cargo` as the positive HTTP readiness endpoint.
Require HTTP 200, `Content-Type: application/json`, and deterministic seeded
content such as `"trackingId":"ABC123"`. This proves substantially more of the
application than the root page alone. The acceptance harness may additionally
assert the root page and Administration dashboard.

Do not use `liberty:status` as an exit-code gate: plugin version 3.12.1 returned
zero both when the server was running and when it printed that the server was
not running. Do not use foreground `liberty:run` in CI; it works for local
development but complicates HTTP orchestration and, without skipped tests,
causes an additional Liberty test lifecycle.

The workflow must use explicit timeouts, invoke `liberty:stop` from an
unconditional cleanup trap, print or upload Liberty logs on failure, and
retain HTTP headers and bodies. The repeatable harness, successful evidence,
negative package-without-deploy experiment, and lifecycle logs are in
`1-trick-out-01-remove-before-merge/spike_1_13_acceptance_tests/`.
