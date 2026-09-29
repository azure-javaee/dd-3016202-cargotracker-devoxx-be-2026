# Spike 1.3: Validation tier selection

Date: 2026-09-29

Plan question:
`1-trick-out-01-remove-before-merge/trick-out-01-ignorance-reduction-plan.md`,
section 1.3.

## Question

What exact commands define each validation tier—environment, formatting, build
contract, unit tests, Open Liberty integration tests, and deployable
packaging—and which tiers currently download, create, or start an Open Liberty
runtime?

## Answer

The current default Maven lifecycle does **not** provide distinct validation
tiers:

- `clean test` creates an Open Liberty installation, installs features, starts
  Liberty through Arquillian, and runs both 24 domain unit tests and four
  `BookingServiceTest` integration tests.
- `clean package` repeats that behavior before producing the WAR.
- `-Popenliberty verify` is not a separate verification tier. The profile is
  already active by default, no additional verification-phase plugin is
  configured, and the command reruns the same 28 tests and starts Liberty
  again.

The tiers can be separated with the commands below. These commands were run
successfully except for the documented Spotless linked-worktree failure.

## Selected validation tiers

### 1. Environment

```bash
./mvnw -version
```

Purpose:

- confirm Maven Wrapper version;
- confirm Microsoft Build of OpenJDK 17;
- record the OS and architecture.

Observed:

- Maven 3.9.9;
- Microsoft OpenJDK 17.0.18;
- approximately 0.3-0.6 seconds;
- no Maven local-repository growth;
- no `target/`;
- does not download, create, or start Liberty.

### 2. Formatting

```bash
./mvnw spotless:check
```

Purpose:

- check formatting before any compiler, test, or runtime work.

Observed:

- cold isolated repository growth: 12,592,985 bytes;
- cold duration: approximately 6 seconds;
- warm duration: approximately 3 seconds;
- does not create `target/liberty`;
- does not start Liberty;
- currently fails in this linked Git worktree with:

```text
Cannot find git repository in any parent directory
```

Spotless 2.43.0 uses the configured `ratchetFrom` Git baseline but does not
recognize this linked worktree's `.git` file. The same command is green in
GitHub Actions, where `actions/checkout` creates a conventional clone.

Therefore, this is the correct formatting-tier command, but it is **not yet a
valid local baseline command in the campaign worktree**. The implementation
must repair or replace the ratchet behavior without formatting the entire
legacy tree.

### 3. Build contract and compilation

Current provisional command:

```bash
./mvnw '-P!openliberty' -DskipTests clean compile
```

Purpose:

- compile all 95 production source files at Java release 17;
- execute future Maven Enforcer and compatibility rules when they are bound to
  `validate` or another phase at or before `compile`;
- avoid resolving or constructing the Open Liberty runtime.

Observed from an empty isolated Maven repository:

- success;
- 21 seconds cold and 13 seconds warm;
- cold repository growth: 22,322,735 bytes;
- zero tests;
- no `target/liberty`;
- no Liberty start.

The repository does not yet have a true build-contract check because Maven
Enforcer and the planned compatibility rules have not been added. Today this
command proves compilation only. It becomes the build-contract tier when those
rules are bound before or during `compile`.

### 4. Unit tests

Current exact command:

```bash
./mvnw '-P!openliberty' \
  -Dtest=CargoTest,ItineraryTest,RouteSpecificationTest,HandlingEventTest,HandlingHistoryTest \
  clean test
```

Purpose:

- run the five active domain-model test classes without the Arquillian
  container test.

Observed from an empty isolated Maven repository:

- success;
- 24 tests, zero failures, zero errors, zero skipped;
- 21 seconds cold and 14 seconds warm;
- additional cold repository growth after compilation:
  16,828,275 bytes;
- no `target/liberty`;
- no Liberty start.

The explicit class list is accurate today but brittle. The implementation
should replace it with a durable test boundary, such as a Maven unit-test
profile, JUnit tag, or naming convention that excludes container tests without
requiring a manually maintained class list.

The following test-shaped classes do not execute in this tier or in the
default test run:

- `CargoLifecycleScenarioTest`
- `ExternalRoutingServiceTest`

Their test methods lack active JUnit 5 annotations and their setup is absent or
commented out.

### 5. Open Liberty integration tests

```bash
./mvnw -Popenliberty -Dtest=BookingServiceTest clean test
```

Purpose:

- create the Open Liberty runtime;
- install the configured Java EE 7 features;
- start Liberty through Arquillian;
- deploy the Arquillian test WAR;
- run the four in-container application-service tests;
- stop Liberty.

Observed from an empty isolated Maven repository:

- success;
- four tests, zero failures, zero errors, zero skipped;
- 89 seconds cold and 79 seconds with a warm Maven repository;
- cold repository growth: 396,702,594 bytes;
- generated `target/liberty` of approximately 488 MB;
- executed `liberty:create`;
- executed `liberty:install-feature`;
- started `defaultServer`;
- stopped `defaultServer`;
- did not produce the final `cargo-tracker.war`.

This is the only selected tier that downloads the Open Liberty runtime on a
clean cache, creates an installation, or starts a Liberty server.

### 6. Deployable packaging

```bash
./mvnw -Popenliberty -Dskip=true -DskipTests clean package
```

Purpose:

- retain the `openliberty` profile's application dependency configuration,
  including compile-scoped Jackson libraries;
- skip the profile's bound `liberty:create` and
  `liberty:install-feature` goals;
- skip tests already covered by the unit and integration tiers;
- produce the canonical deployable `target/cargo-tracker.war`.

Observed from an empty isolated Maven repository:

- success;
- 34 seconds cold and 14 seconds warm;
- cold Maven repository size after completion: 66,605,044 bytes;
- the Open Liberty runtime ZIP was not downloaded;
- `target/liberty` was not created;
- Liberty was not started;
- produced an 8,233,001-byte WAR;
- included the Jackson JAX-RS provider and transitive Jackson libraries
  required by the active `openliberty` profile.

The Liberty Maven Plugin 3.12.1 exposes a `skip` parameter for both bound
goals. The log confirms:

```text
Skipping create goal.
Skipping install-feature goal.
```

Do not use this superficially similar command as the canonical package tier:

```bash
./mvnw '-P!openliberty' -DskipTests clean package
```

Although it avoids Liberty and produces a WAR, it changes
`jackson.scope` back to `provided`. The resulting WAR was only 6,560,866 bytes
and omitted the Jackson libraries included by the intended Open Liberty
profile. It is not byte- or dependency-equivalent to the current workflow's
artifact.

## Tier summary

| Tier | Exact command | Cold time | Warm time | Cold network/cache effect | Creates Liberty | Starts Liberty | Tests | Produces canonical WAR |
|---|---|---:|---:|---|---|---|---:|---|
| Environment | `./mvnw -version` | <1s | <1s | None | No | No | 0 | No |
| Formatting | `./mvnw spotless:check` | 6s | 3s | Downloads about 12.6 MB of formatting/plugin artifacts | No | No | 0 | No |
| Build contract/compile | `./mvnw '-P!openliberty' -DskipTests clean compile` | 21s | 13s | Downloads about 22.3 MB from an empty cache | No | No | 0 | No |
| Unit | `./mvnw '-P!openliberty' -Dtest=... clean test` | 21s | 14s | Adds about 16.8 MB after compile dependencies | No | No | 24 | No |
| Integration | `./mvnw -Popenliberty -Dtest=BookingServiceTest clean test` | 89s | 79s | Adds about 396.7 MB, including the Liberty runtime and test adapter | Yes, about 488 MB | Yes | 4 | No |
| Package | `./mvnw -Popenliberty -Dskip=true -DskipTests clean package` | 34s | 14s | Uses about 66.6 MB from a standalone empty cache; does not download the Liberty runtime | No | No | 0 | Yes |

Timing is descriptive, not a performance guarantee. Runs occurred on the same
WSL2 host using an isolated Maven local repository.

## Measurements of the original commands

The originally proposed commands produced these results:

| Command | Cold-sequence result | Warm result | Liberty behavior |
|---|---|---|---|
| `./mvnw -version` | Success, <1s | Success, <1s | None |
| `./mvnw spotless:check` | Failed, 6s | Failed, 3s | None; linked-worktree ratchet defect |
| `./mvnw clean test` | Success, 70s, 28 tests | Success, 40s, 28 tests | Creates, installs, starts, and stops Liberty |
| `./mvnw clean package` | Success, 50s, 28 tests | Success, 49s, 28 tests | Creates, installs, starts, and stops Liberty; packages WAR |
| `./mvnw -Popenliberty verify` | Success, 30s after package | Success, 34s | Reruns 28 tests and starts Liberty; adds no distinct verification |

The "cold-sequence" package and verify measurements benefited from artifacts
downloaded by earlier commands in the same sequence. The isolated candidate
measurements provide the clearer per-tier network boundary.

## Network and runtime conclusions

### Tiers that access the network on an empty Maven cache

- Formatting, to resolve Spotless and its dependencies.
- Build contract/compile, to resolve compiler and application dependencies.
- Unit tests, to resolve Surefire and test dependencies.
- Integration, to resolve the Arquillian Liberty adapter and the large Open
  Liberty runtime.
- Packaging, to resolve build, application, Liberty-plugin, and WAR-plugin
  dependencies.

The environment command does not populate the isolated Maven repository. The
Maven Wrapper distribution was already present in
`~/.m2/wrapper/dists/apache-maven-3.9.9`; this spike did not test a machine
without the wrapper distribution.

### Tiers that download the Open Liberty runtime

- Open Liberty integration only.

The package command resolves the Liberty Maven Plugin so its skipped bound
goals can be evaluated, but the empty-cache run confirmed that it does not
download `io.openliberty:openliberty-runtime`.

### Tiers that create a Liberty installation

- Open Liberty integration only.

### Tiers that start Liberty

- Open Liberty integration only.

## Recommended workflow shape

Run these required jobs or steps in order:

1. `environment`
2. `formatting`
3. `build-contract`
4. `unit`
5. `integration`
6. `package`

The first implementation issue should fix the Spotless linked-worktree failure
or document a supported local equivalent before calling formatting a canonical
local command.

The build-contract issue should add Maven Enforcer and compatibility rules at
or before `compile`, allowing the measured build-contract command to remain the
entry point.

The testing issue should formalize the unit/integration split so the workflow
does not depend on a hard-coded five-class unit-test list.

The package tier should run only after unit and integration are green. It
should preserve the active Open Liberty profile while skipping its setup goals
and tests:

```bash
./mvnw -Popenliberty -Dskip=true -DskipTests clean package
```

## Proposed text for the plan's Resolution field

Use six validation tiers. Environment is `./mvnw -version`. Formatting remains
`./mvnw spotless:check`, but its Git ratchet must be repaired for linked
worktrees before it is a valid local baseline. Build contract/compilation is
`./mvnw '-P!openliberty' -DskipTests clean compile`; bind Maven Enforcer and
compatibility rules at or before `compile`. Unit tests are the 24 active domain
tests with the Open Liberty profile disabled; replace the measured explicit
class list with a durable unit-test profile or naming/tagging rule. Integration
is `./mvnw -Popenliberty -Dtest=BookingServiceTest clean test`, which is the
only tier permitted to download, create, and start Open Liberty. Deployable
packaging is
`./mvnw -Popenliberty -Dskip=true -DskipTests clean package`; it preserves the
canonical 8,233,001-byte WAR dependency shape while skipping Liberty creation,
feature installation, and test execution. Remove `-Popenliberty verify` from
the tier model because it adds no distinct verification in the current POM.

## Artifact index

- `run-spike.sh`: original-command cold/warm measurement harness.
- `run-summary.tsv`: original-command measurements.
- `logs/`: original-command Maven logs.
- `inventories/`: original-command generated-content inventories.
- `attempt-1-worktree-formatting-failure/`: preserved first failed formatting
  attempt.
- `run-candidate-tiers.sh`: separated-tier measurement harness.
- `candidate-summary.tsv`: separated-tier warm-cache results.
- `candidate-cold-summary.tsv`: separated-tier empty-cache results.
- `candidate-logs/` and `candidate-cold-logs/`: Maven logs.
- `candidate-inventories/` and `candidate-cold-inventories/`: generated
  content, test, Liberty, and WAR inventories.
