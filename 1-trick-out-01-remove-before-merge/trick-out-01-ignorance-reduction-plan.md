# Implementation plan: Trick out Cargo Tracker for agent-safe Java development (dd-3070726 / campaign #1)

Human DRI: Ed Burns<br>
Campaign: `1-trick-out-01-remove-before-merge`<br>
Campaign ID: `474aebe4-23f7-45cf-a841-e214bdcdd132`<br>
Repository: `edburns/dd-3016202-cargotracker-devoxx-be-2026`<br>
Campaign base branch: `edburns/dd-3016202-cargotracker-devoxx-be-2026-experiment`<br>
Campaign issue: https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/issues/1<br>
Azure DevOps work item: https://devdiv.visualstudio.com/DevDiv/_workitems/edit/3070726<br>
Campaign metadata: `1-trick-out-01-remove-before-merge/shepherd-campaign.json`<br>
Campaign evidence: `1-trick-out-01-remove-before-merge/evidence-matrix.md`<br>
Campaign lessons: `1-trick-out-01-remove-before-merge/campaign-lessons.md`<br>
Talk abstract: `dd-3032592-10-boring-reasons-abstract.md`<br>
Application root: `demo/`<br>
Primary workflow: `.github/workflows/main.yml`<br>

---

## Goal

Create a tagged, feature-absent Cargo Tracker baseline whose Java 17 build,
compatibility rules, deterministic source gates, behavioral tests,
observability, and JVM diagnostics give later coding agents fast and useful
feedback.

The baseline will be used by a separate Shepherd Task campaign that adds the
Change Arrival Deadline feature. This campaign does not prove the talk's
hypothesis merely by installing tools. It creates the guardrails and durable
artifact paths needed to observe whether those guardrails execute, detect
mistakes, prevent mistakes, or materially improve the later agents' work.

Every increment must preserve required green GitHub Actions CI before the next
serial issue begins. The campaign must prefer a small number of attributable,
reliable controls over a broad collection of noisy checks.

### Baseline technology contract

| Concern | Current contract |
|---|---|
| Java runtime and compiler | Microsoft Build of OpenJDK 17 in CI; `maven.compiler.release` 17 |
| Enterprise API | Java EE 7 through `javax:javaee-api:7.0`; no migration to `jakarta.*` |
| Packaging | Maven WAR named `cargo-tracker.war` |
| Runtime | Open Liberty 26.0.0.8 with `javaee-7.0` |
| Data | Embedded Derby for the demo and Open Liberty tests |
| UI | JSF and PrimeFaces 8 |
| Build entry point | Maven Wrapper from the repository; commands run in `demo/` |
| Existing fast gate | Spotless with Google Java Format and a historical ratchet |
| Existing tests | JUnit 5 domain tests plus Arquillian/Open Liberty integration tests; some scenario and routing tests appear dormant and require verification |
| Existing CI | `formatting` followed by `build` in `.github/workflows/main.yml` |

### Reasons exercised by this campaign

| Abstract reason | Planned treatment |
|---|---|
| 1. Type system | Make compilation and useful compiler diagnostics explicit and attributable |
| 2. Testing ecosystem | Strengthen domain, application, architecture, Open Liberty, and HTTP verification |
| 3. Backwards compatibility culture | Enforce Java 17, Java EE 7, `javax.*`, WAR, and Open Liberty boundaries |
| 4. Deep static analysis | Add one useful analyzer at a time with a controlled legacy baseline |
| 5. Build system maturity and dependency management | Add reproducibility, Maven, plugin, dependency, and repository rules |
| 6. Code formatting and style enforcement | Preserve and clarify the existing Spotless gate |
| 7. Virtual threads and structured concurrency | No code spike in this campaign; explain on slides because the demo remains on JDK 17 |
| 8. Observability stack | Capture diagnosable logs, metrics, and traces as durable CI artifacts |
| 9. JVM performance tuning | Capture repeatable startup, memory, GC, JFR, and `java` versus `jaz` evidence |
| 10. Breadth of deployment options | Outside this campaign; tracked separately by dd-3070761 |

### Success criteria

1. Pushes and pull requests for the experiment branch receive an authoritative
   workflow run.
2. Each generated implementation issue is independently useful and leaves all
   required checks green.
3. The Maven build rejects violations of the resolved Java, Java EE, packaging,
   dependency, plugin, and repository contract.
4. Formatting, compiler, static-analysis, unit, integration, runtime, and
   performance results are distinguishable by job, step, log, and artifact.
5. Expensive or noisy checks do not obscure earlier deterministic failures.
6. Runtime and performance jobs use bounded waits and cannot hang indefinitely.
7. Every issue updates and merges the campaign evidence matrix before the next
   issue begins.
8. Reason 7 remains a slide-only discussion; this plan introduces no Java 21
   source set, module, branch, or workflow.
9. Reason 10 remains in the separate Azure deployment risk-reduction thread and
   does not block this trick-out campaign.
10. The final tagged baseline is created only from a commit whose complete
    required workflow set is green.

---

## Completed phases

### Phase 0.1 ✅ — Establish campaign state

- Shepherd Task 1.0.4 initialized campaign
  `474aebe4-23f7-45cf-a841-e214bdcdd132`.
- The campaign base branch is
  `edburns/dd-3016202-cargotracker-devoxx-be-2026-experiment`.
- Lesson propagation is disabled; reusable lessons remain available in
  `campaign-lessons.md` but are not automatically injected into later issues.

### Phase 0.2 ✅ — Establish the evidence-capture structure

- `evidence-matrix.md` contains the ten canonical reasons in the abstract's
  original order.
- Every reason begins at `Not exercised`.
- The matrix defines durable artifact expectations and an append-only
  per-issue evidence log.

### Phase 0.3 ✅ — Establish the known green starting behavior

- Known green GitHub Actions runs `36182474700` and `36183229399` executed the
  existing `formatting` and `build` jobs.
- The existing workflow uses Microsoft Build of OpenJDK 17.
- The current push trigger does not name the experiment branch; pull-request
  and manual dispatch paths exist, but an authoritative per-increment path
  still must be resolved.

### Phase 0.4 ✅ — Bound concurrency and Azure scope

- The Cargo Tracker application remains on JDK 17.
- Reason 7 will be covered with slides rather than a Java 21 implementation
  spike.
- Azure deployment risk reduction is tracked separately by dd-3070761 and is
  not part of the ordered implementation below.

---

## Phase 1 — Ignorance reduction: questions to resolve before creating issues

Resolve these questions in order. Earlier answers constrain later tool
selection and workflow design. Each `Resolution:` field is intentionally empty
for human completion.

### 1.1 — Authoritative experiment-branch CI path

**Question:** Which GitHub Actions event and branch rules will prove that each
commit merged into
`edburns/dd-3016202-cargotracker-devoxx-be-2026-experiment` passed the complete
required workflow set?

The current workflow runs automatically for pushes to the non-demo
`...-01` branch, for pull requests, and for manual dispatch. That is not enough
to establish an automatic experiment-branch invariant unless the operating
procedure always creates a qualifying pull request and verifies its exact head
SHA.

| Option | Shape | Trade-off |
|---|---|---|
| A | Add the experiment branch to the existing `push.branches` list | Smallest change; validates every pushed increment but may duplicate PR runs |
| B | Make PR validation authoritative and require an exact-head workflow before merge | Strong merge gate; depends on repository branch-protection configuration outside the workflow file |
| C | Use only `workflow_dispatch` and record the selected SHA | Flexible but human-dependent and easiest to forget |
| D | Use A for continuous evidence and B for merge protection | Strongest coverage but produces more workflow activity |

**Spike needed:** Inspect repository rulesets and branch protection with `gh`;
confirm whether required checks can name the proposed jobs and whether a PR run
and push run would be redundant or complementary.

**Recommendation:** Use option D when repository rulesets permit it: add the
experiment branch to `push`, retain PR validation, and make stable job names
required. At minimum, use option A so every experiment-branch increment gets an
automatic run.

**Failure example:** Push a harmless branch-only change to an isolated test
branch with equivalent trigger configuration and verify the workflow starts
for the exact SHA. Do not manufacture a red commit on the campaign base branch.

**Resolution:**

### 1.2 — Required job topology and fail-fast order

**Question:** Should the workflow remain a strictly serial chain, or should
independent jobs fan out after a common build-contract job?

The desired diagnostic order is:

1. formatting;
2. build and dependency contract;
3. compatibility and compiler checks;
4. static analysis;
5. unit tests;
6. Open Liberty integration and HTTP acceptance;
7. observability;
8. performance evidence.

A fully serial workflow is easy to understand but can be slow. A fully parallel
workflow is faster but may spend time on expensive runtime jobs after a cheap
gate has already failed.

**Recommendation:** Keep formatting first. Make a build-contract job depend on
formatting. Fan out compiler/static analysis and unit tests after the contract
job. Make Open Liberty acceptance depend on unit tests, observability depend on
acceptance, and performance depend on the stable runtime workload. Preserve
stable job and check names for branch protection and slide evidence.

**Spike needed:** Measure the current formatting and package durations from
known green runs and estimate the critical path before fixing the topology.

**Resolution:**

### 1.3 — Canonical local and CI Maven commands

**Question:** What exact command set defines the green baseline for each cost
tier, given that the `openliberty` profile is active by default and binds
Liberty creation and feature installation to `compile`?

The current workflow runs:

```bash
./mvnw spotless:check
./mvnw clean package --file pom.xml
```

The active Open Liberty profile means even apparently simple Maven phases may
download and configure a Liberty runtime. The plan needs commands that are
honest about what they exercise and avoid repeating expensive setup
unnecessarily.

**Spike needed:** From a clean Maven cache and from a warm cache, record the
goals, duration, tests executed, generated runtime content, and network access
for:

```bash
./mvnw -version
./mvnw spotless:check
./mvnw clean test
./mvnw clean package
./mvnw -Popenliberty verify
```

Determine whether a lightweight profile or property is needed for pure source
checks without weakening the canonical package and integration paths.

**Recommendation:** Define named command tiers in repository documentation and
workflow steps: `format`, `contract`, `unit`, `integration`, and `package`.
Reuse the Maven local repository cache but never reuse generated `target/`
output as proof of a clean build.

**Resolution:**

### 1.4 — Maven and dependency-governance rules

**Question:** Which Maven Enforcer and dependency checks provide strong,
low-noise evidence without turning the legacy application into a dependency
modernization project?

Candidate rules include:

| Rule | Value | Principal risk |
|---|---|---|
| `requireJavaVersion` | Enforces Java 17 | Accidentally accepting a newer developer JDK without release discipline |
| `requireMavenVersion` | Makes wrapper/tool assumptions explicit | Choosing a minimum incompatible with the checked-in wrapper |
| `requirePluginVersions` | Prevents implicit plugin drift | May expose lifecycle plugins not explicitly versioned |
| `dependencyConvergence` | Finds conflicting dependency graphs | Arquillian and Liberty test graphs may contain legitimate conflicts |
| `requireUpperBoundDeps` | Detects older transitive selections | Often noisy on mature Java EE dependency graphs |
| `banDuplicatePomDependencyVersions` | Rejects ambiguous POM declarations | Low risk and deterministic |
| `bannedDependencies` | Prevents Jakarta/Spring/runtime migration | Patterns must avoid banning required test/runtime artifacts |
| `externalRules` or repository checks | Restricts unapproved repositories | Must account for Maven Central and any Liberty-specific artifact source |

**Spike needed:** Run candidate rules one at a time against the current POM.
Record all baseline findings and classify them as defects, acceptable legacy
debt, or tool false positives. Do not add broad exclusions before explaining
each finding.

**Recommendation:** Start with Java/Maven version, plugin version,
duplicate-declaration, and narrowly scoped banned-dependency rules. Add
convergence or upper-bound enforcement only if the baseline can be made green
with small, understandable dependency-management changes.

**Failure example:** In a temporary POM copy, add an unapproved dependency or
an unversioned plugin and verify the resolved rule fails with an actionable
message.

**Resolution:**

### 1.5 — Reproducibility and dependency-security evidence

**Question:** Which outputs should be preserved to demonstrate a controlled
dependency graph and supply-chain posture without requiring the campaign to
remediate every historical vulnerability?

Possible evidence:

- effective POM;
- dependency tree;
- dependency convergence report;
- resolved plugin list;
- packaged WAR checksum and contents;
- GitHub dependency review for pull requests;
- a vulnerability report with a documented baseline and severity policy.

The application intentionally retains old Java EE 7-era dependencies such as
PrimeFaces 8 and Joda-Time. A vulnerability scanner may report substantial
legacy debt. Failing immediately on every historical finding would violate the
incremental-green requirement and obscure whether later agents introduce new
risk.

**Spike needed:** Generate a dependency vulnerability report with the
candidate scanner. Determine runtime versus provided/test findings, data-feed
reliability, runtime duration, and whether the tool supports a checked-in
suppression file with expiry and rationale.

**Recommendation:** Preserve the dependency tree, effective POM, WAR checksum,
and vulnerability report as artifacts. Enforce no newly introduced
high-severity dependency findings or use GitHub dependency review on PR deltas;
do not make wholesale legacy remediation part of this campaign.

**Resolution:**

### 1.6 — Executable Java 17 and Java EE 7 compatibility contract

**Question:** How should the repository reject accidental migration away from
Java 17, Java EE 7, `javax.*`, WAR packaging, and Open Liberty's `javaee-7.0`
feature?

The contract currently exists in several independent places:

```xml
<maven.compiler.release>17</maven.compiler.release>
<javaee_api.version>7.0</javaee_api.version>
<groupId>javax</groupId>
<artifactId>javaee-api</artifactId>
<packaging>war</packaging>
```

and:

```xml
<feature>javaee-7.0</feature>
<webApplication location="cargo-tracker.war"
                contextRoot="/cargo-tracker" />
```

Possible enforcement mechanisms include Maven Enforcer banned dependencies,
source-package scans for `jakarta.*`, XML assertions over `pom.xml` and
`server.xml`, and runtime checks against the deployed application.

**Recommendation:** Use multiple narrow checks because no single tool covers
the contract: Maven Enforcer for dependencies and Java version, a small
JUnit-based repository contract test or script for POM/server configuration,
and the Open Liberty acceptance job for runtime proof. Ban production imports
from `jakarta.*` while allowing no exceptions unless a resolved question
documents one.

**Failure example:** In an isolated temporary fixture, substitute
`jakarta.platform:jakarta.jakartaee-api` or change `javaee-7.0`; verify the
contract check identifies the exact boundary that changed.

**Resolution:**

### 1.7 — Repository-level instructions for agents

**Question:** Which compatibility and validation rules must be written into
repository instructions so coding agents understand the contract before CI
rejects their work?

The repository currently has no discovered Copilot instruction file. Build
rules alone provide feedback after a change, but the experiment should also
test whether concise repository guidance prevents predictable mistakes.

The instructions must cover at least:

- Java 17 only;
- Java EE 7 and `javax.*`, not Jakarta EE;
- Maven Wrapper commands run from `demo/`;
- WAR and Open Liberty assumptions;
- required green CI before proceeding;
- no broad dependency upgrades;
- no replacement with Spring or another application server;
- required evidence-matrix update timing.

**Recommendation:** Add a short `.github/copilot-instructions.md` that states
invariants and canonical validation commands without duplicating the entire
plan. Treat instruction effectiveness as evidence only when a later agent
actually follows, misunderstands, or violates it.

**Resolution:**

### 1.8 — Spotless baseline and ratchet semantics

**Question:** Should the existing Spotless `ratchetFrom` remain pinned to
`1fd1c340fa56c6c77a601d2fbba20294afa46dd9`, move to the tagged trick-out
baseline, or be replaced by whole-tree formatting?

Keeping the historical ratchet minimizes churn but can make it hard to explain
which files are checked. Reformatting the whole legacy tree creates a large,
low-value diff and may obscure subsequent agent changes. Moving the ratchet too
early may silently grandfather files that should remain in scope.

**Spike needed:** Run `spotless:check` and `spotless:apply` in a disposable
worktree or temporary copy to enumerate exactly which files differ under the
current ratchet and under a proposed baseline. Do not apply whole-tree changes
to the campaign branch during the spike.

**Recommendation:** Preserve the current ratchet through the trick-out issues
unless it fails to cover later modified Java files. Document its semantics and
keep `formatting` as the first required job. Reconsider the ratchet only when
tagging the completed pre-feature baseline.

**Failure example:** Format a temporary Java fixture incorrectly and verify
`spotless:check` reports the file and remediation command.

**Resolution:**

### 1.9 — Compiler diagnostics and type-system evidence

**Question:** Which compiler warnings can be enabled and enforced without
creating a large legacy-cleanup issue or conflating external analyzer findings
with Java's type system?

Candidates include `-Xlint:all`, selected `-Xlint` categories, deprecation
reporting, parameter metadata, and `-Werror`. The project uses Java EE 7 APIs,
older libraries, reflection, and serialization patterns that may produce
warnings unrelated to agent-created errors.

**Spike needed:** Compile with `-Xlint:all` and record warning categories and
locations. Determine which categories can be corrected or enforced within one
small issue and which require a documented baseline.

**Recommendation:** Keep compilation as its own named step and enable the
largest actionable warning subset that is clean. Do not use Error Prone,
NullAway, or another compiler replacement unless a spike proves compatibility
with Java 17, Java EE 7, annotation processing, and the existing Maven build.

**Failure example:** Compile an isolated fixture that calls a nonexistent
method or crosses a typed API boundary and preserve the compiler diagnostic as
an example; do not intentionally break campaign CI.

**Resolution:**

### 1.10 — Static analyzer and legacy-debt strategy

**Question:** Which single initial analyzer best finds meaningful defects in
this Cargo Tracker codebase with acceptable runtime and baseline complexity?

| Candidate | Strength | Risk |
|---|---|---|
| SpotBugs | Bytecode-level bug patterns, familiar Maven integration | Java EE/container patterns may require exclusions; runs after compilation |
| PMD | Source-level correctness and maintainability rules | Default rulesets can produce broad style debt overlapping Spotless |
| Checkstyle | Precise source/style rules | Duplicates formatting and is weaker evidence for "deep" analysis |
| ArchUnit | Enforces package/layer architecture in tests | Best treated as behavioral architecture verification rather than the sole general analyzer |

**Spike needed:** Run SpotBugs and PMD separately with focused correctness and
security-oriented rules. Record finding count, severity, runtime, false
positives, report quality, and whether findings identify real defects relevant
to later feature work.

**Recommendation:** Prefer SpotBugs as the first general analyzer if its
baseline is tractable. Keep style rules in Spotless, architecture rules in
tests, and dependency vulnerability analysis in the build/dependency issue.
Check in every exclusion with a narrow match and rationale.

**Failure example:** Use an analyzer-provided test fixture or temporary class
containing a known null-dereference/resource bug and assert that the selected
rules detect it.

**Resolution:**

### 1.11 — Actual test inventory and dormant-test disposition

**Question:** Which existing tests execute in the canonical Maven build, and
what should happen to test-shaped classes whose methods lack JUnit 5
annotations or setup hooks?

The current tree contains:

- focused JUnit 5 domain tests;
- Arquillian/Open Liberty tests such as `BookingServiceTest`;
- `CargoLifecycleScenarioTest`, whose scenario method and setup method do not
  currently carry JUnit 5 annotations;
- `ExternalRoutingServiceTest`, whose test method also appears unannotated and
  whose setup is commented out.

It is unsafe to describe the project as having scenario or routing coverage
until execution reports prove those tests run.

**Spike needed:** Capture Surefire's discovered test count, executed test
classes, skipped tests, duration, and reports for the canonical unit and
Open Liberty commands. Verify whether Arquillian starts Open Liberty and
whether dormant tests can be repaired with small, valid fixtures.

**Recommendation:** Classify every existing test as active, intentionally
dormant, or repairable. Repair only tests that can express stable behavior
without reconstructing obsolete infrastructure. Remove no test-shaped code
without documenting why it cannot provide reliable coverage.

**Resolution:**

### 1.12 — Behavioral safety net for the later deadline feature

**Question:** What minimum behavioral contracts must exist before the
five-issue Change Arrival Deadline campaign begins?

The later feature crosses:

1. the cargo aggregate and route specification;
2. the `BookingService` application boundary;
3. the booking facade and DTO boundary;
4. JSF backing state;
5. the PrimeFaces Administration UI.

The trick-out campaign must not implement that feature, but it should ensure
the existing behavior around booking, routing, destination changes, cargo
lookup, and Administration startup is protected.

**Recommendation:** Add or strengthen:

- focused domain tests for route specification and itinerary invariants;
- application/Arquillian tests around `BookingService`;
- architecture checks that prevent domain types from leaking into the web
  layer and prevent domain code from depending on application/interfaces;
- an Open Liberty HTTP smoke test for `/cargo-tracker/`;
- a stable Administration-page or REST interaction that proves the deployed
  application is usable.

**Spike needed:** Identify a deterministic HTTP path and seeded cargo record
that can be exercised without browser automation. Determine whether a small
browser test adds enough value to justify its setup before the talk deadline.

**Failure example:** Mutate an assertion or temporary fixture so a cargo route
violates a known invariant; verify the intended test layer reports a concise
failure.

**Resolution:**

### 1.13 — Open Liberty lifecycle and acceptance-test boundary

**Question:** Should Open Liberty acceptance reuse Arquillian's managed server,
or should CI start the packaged application once and run black-box HTTP checks
against it?

Arquillian is appropriate for in-container integration tests, but black-box
acceptance should validate the same packaged WAR and `server.xml` used by the
demo. Starting Liberty separately for every test class would be slow and
fragile.

**Recommendation:** Keep Arquillian for focused in-container tests. Add one
bounded workflow job that packages the WAR, starts Open Liberty once, waits for
a positive readiness signal, runs HTTP checks, captures logs, and always stops
the server. Use explicit timeouts and print server logs on failure.

**Spike needed:** Verify the reliable Maven goals for start, status/readiness,
and stop with Liberty Maven Plugin 3.12.1 and runtime 26.0.0.8. Identify the
startup log marker and HTTP readiness endpoint.

**Resolution:**

### 1.14 — Runtime observability mechanism

**Question:** What is the smallest observability design that produces useful
logs, metrics, and traces in GitHub Actions without making CI depend on Azure?

Options include:

| Option | Shape | Trade-off |
|---|---|---|
| A | Existing `java.util.logging` plus Liberty logs | Lowest change; weak correlation and no traces |
| B | OpenTelemetry Java agent plus local collector | No application API migration; produces standard traces/metrics/log correlation |
| C | Add MicroProfile Telemetry/Metrics features | Strong Liberty integration but may conflict with the Java EE 7 feature contract or require source changes |
| D | Application Insights Java agent | Relevant to Azure but makes generic CI evidence depend on an Azure-oriented agent and possibly an external resource |

**Spike needed:** Attach the OpenTelemetry Java agent to the current Liberty
runtime, send OTLP to a collector in GitHub Actions or locally, exercise a
stable request, and verify trace and metric export. Confirm compatibility with
Java 17, Open Liberty 26.0.0.8, Java EE 7, and current logging.

**Recommendation:** Prefer option B for this campaign. Preserve Liberty logs
and use Azure Monitor/Application Insights only in the separate deployment
thread or as optional follow-on evidence.

**Resolution:**

### 1.15 — Telemetry correlation, redaction, and artifact format

**Question:** Which fields and artifact formats make a failed request
diagnosable while preventing cargo data, credentials, or environment secrets
from leaking into CI artifacts?

At minimum, evidence should correlate:

- workflow run and commit SHA;
- application startup;
- HTTP request path and status;
- trace/span identifier;
- relevant application or Liberty log lines;
- collector export;
- test or smoke-check result.

**Recommendation:** Use a fixed CI-only request identifier, do not log request
bodies or secrets, export collector output in a text or JSON format suitable
for artifact upload, and retain Liberty `messages.log`, `console.log`, and the
smoke-test transcript. Add an explicit artifact-redaction check before upload.

**Failure example:** Exercise a known invalid cargo or route request and verify
the failure can be followed from the smoke-test output to a trace and
application log without exposing a secret.

**Resolution:**

### 1.16 — Repeatable performance workload and resource envelope

**Question:** Which workload is stable enough to compare JVM startup and
runtime behavior in hosted CI, and what resource limits should constrain it?

Possible workloads:

- time from process start to the first successful `/cargo-tracker/` response;
- a fixed number of cargo-tracking or routing HTTP requests;
- an application-service test loop;
- a containerized Liberty run with explicit CPU and memory limits.

Hosted runners are noisy, so strict latency regression thresholds could create
false failures. The initial value is diagnostic evidence, not benchmark
competition.

**Spike needed:** Run the candidate workload at least three times under a
fixed container memory and CPU limit. Record variance for startup, peak RSS,
heap, GC, request duration, and total job duration.

**Recommendation:** Use a containerized Open Liberty workload with a generous
timeout and broad sanity bounds. Upload measurements on every run, but fail
only on crashes, out-of-memory errors, inability to become ready, or gross
regressions supported by repeatable evidence.

**Resolution:**

### 1.17 — `java` versus `jaz`, GC logs, and JFR capture

**Question:** How should CI compare direct JVM launch with Azure Command
Launcher for Java (`jaz`) while proving both runs execute the same Liberty
artifact under the same cgroup limits?

Required evidence candidates:

- effective JVM command/options;
- selected heap and GC settings;
- startup time;
- container memory limit and observed memory;
- GC log;
- bounded JFR recording;
- workload result;
- exit status.

**Spike needed:** Determine the supported `jaz` installation and invocation for
the Liberty launch command. Verify that `jaz` observes the intended cgroup CPU
and memory limits and that its chosen settings are visible without exposing
secrets.

**Recommendation:** Run direct `java` and `jaz` sequentially in equivalent
fresh containers. Use the same WAR, Liberty runtime, workload, limits, and
artifact naming. Treat differences as observations unless repeated runs
support a defensible threshold.

**Failure example:** Use an intentionally too-small memory limit only in an
isolated spike to verify the job preserves GC, JFR, container, and startup
diagnostics; do not retain an unstable limit in required CI.

**Resolution:**

### 1.18 — Artifact naming, retention, and merge evidence

**Question:** What stable naming and retention scheme will let the later
feature campaign and slide author locate evidence without reading arbitrary
workflow logs?

**Recommendation:** Upload artifacts using names that include the concern but
not a hard-coded run number:

```text
build-contract
dependency-reports
test-reports-unit
test-reports-liberty
liberty-logs
otel-telemetry
performance-java
performance-jaz
```

Each artifact should contain a small metadata file with commit SHA, branch,
workflow run ID, job name, Java version, Maven version, start/end timestamps,
and the command executed. Choose retention long enough to survive talk
preparation and rehearsal.

**Spike needed:** Confirm repository artifact-retention policy and expected
size, especially for Liberty runtimes, JFR files, and Maven reports. Upload
reports and diagnostics, not the entire Maven cache or Liberty installation.

**Resolution:**

---

## Phase 2 — Implementation

Create these as ordered serial issues. Every issue inherits the evidence-matrix
gate later in this document. Stage 20 may refine titles after all Phase 1
resolutions are filled, but it must preserve this dependency order.

### 2.1 — Make CI authoritative and establish the Maven/dependency foundation

**Reasons exercised:** 5. Build system maturity and dependency management;
6. Code formatting and style enforcement.

**What to build:**

- Make `.github/workflows/main.yml` authoritative for experiment-branch
  increments according to resolutions 1.1 and 1.2.
- Preserve the existing Microsoft Build of OpenJDK 17 `formatting` and `build`
  behavior.
- Give jobs and steps stable, descriptive names.
- Define and document canonical Maven command tiers.
- Add the resolved low-noise Maven Enforcer rules.
- Add the resolved dependency/security report without turning historical debt
  into an unrelated remediation project.
- Generate reproducibility evidence: effective POM, dependency tree, plugin
  information, WAR contents, and WAR checksum.
- Upload build and dependency reports with commit/run metadata.

**Files to modify:**

- `.github/workflows/main.yml`
- `demo/pom.xml`
- `.mvn/wrapper/maven-wrapper.properties` only if the resolved Maven minimum
  requires a wrapper change
- `demo/README.md` or the existing nearest developer documentation

**Files to create when selected by the resolutions:**

- `demo/config/dependency-check-suppressions.xml`
- `demo/scripts/ci/write-build-metadata.sh`
- `demo/scripts/ci/verify-build-contract.sh`

**Tests and validation:**

- Run Spotless before every more expensive job.
- Run every selected Enforcer rule against the current baseline.
- Verify a clean package from a fresh `target/`.
- Verify `cargo-tracker.war` exists and record its SHA-256 checksum.
- Verify dependency and effective-POM reports are generated and uploaded.
- Exercise each new rule against a temporary invalid POM fixture or copy and
  assert a clear nonzero result.
- Trigger the workflow for the exact experiment-branch commit and record its
  run URL and job names.

**Expected failure evidence:**

- Unapproved Java/Maven version;
- missing plugin version;
- banned or newly vulnerable dependency;
- dependency-convergence violation when that rule is selected;
- formatting failure;
- package or artifact-checksum failure.

**Required artifacts:**

- effective POM;
- dependency tree;
- dependency/security report;
- Enforcer output;
- WAR file list and checksum;
- workflow metadata file.

**Rollback considerations:**

- Introduce rules individually so a noisy rule can be reverted without
  removing authoritative branch validation.
- Do not remove the existing formatting or package commands.
- If vulnerability data feeds are unavailable, fail or degrade exactly as
  specified by the resolution; never emit a success-shaped empty report.
- Do not upgrade application dependencies merely to make a broad scanner
  report empty.

**Issue gate:**

- The exact issue commit receives the authoritative workflow.
- Existing formatting and package behavior remains green.
- Every selected build/dependency rule is green on the baseline and has a
  verified actionable failure mode.
- Required reports are downloadable from the run.
- The evidence-matrix update is merged and visible on the campaign base branch.

### 2.2 — Enforce the Java 17 and Java EE 7 compatibility contract

**Reasons exercised:** 3. Backwards compatibility culture; 1. Type system;
5. Build system maturity and dependency management.

**What to build:**

- Encode the resolved contract for Java 17, Java EE 7, `javax.*`, WAR
  packaging, Open Liberty, and `javaee-7.0`.
- Reject production `jakarta.*` imports and banned framework/runtime
  dependencies.
- Add concise repository instructions for coding agents.
- Verify the packaged application still deploys with the existing
  `server.xml`.
- Make compatibility failures name the violated boundary.

**Files to modify:**

- `demo/pom.xml`
- `demo/src/main/liberty/config/server.xml` only when needed to make the
  existing contract explicit without changing it
- `.github/workflows/main.yml`

**Files to create:**

- `.github/copilot-instructions.md`
- The resolved contract test or script, for example:
  `demo/src/test/java/org/eclipse/cargotracker/architecture/CompatibilityContractTest.java`
  or `demo/scripts/ci/verify-compatibility-contract.sh`

**Tests and validation:**

- Assert compiler release 17.
- Assert `javax:javaee-api:7.0` remains provided scope.
- Assert WAR packaging and final name.
- Assert `server.xml` includes `javaee-7.0`, the expected WAR, and the
  `/cargo-tracker` context root.
- Scan production source for forbidden `jakarta.*` imports.
- Verify the current application packages and starts on Open Liberty.
- Run temporary negative fixtures for a Jakarta API dependency, a forbidden
  import, a changed compiler release, and changed packaging.

**Expected failure evidence:**

- `jakarta.*` source import;
- Jakarta EE platform dependency;
- Java release other than 17;
- JAR packaging or renamed WAR;
- Spring or alternative application-server dependency;
- removal of `javaee-7.0`.

**Required artifacts:**

- compatibility-contract report;
- compiler version and release output;
- Open Liberty feature and deployment excerpt;
- package/startup log.

**Rollback considerations:**

- Keep source scans narrow enough not to flag documentation or generated
  reports.
- Do not ban dependencies needed only by tooling without understanding their
  scope.
- Never "fix" a violation by migrating the application to Jakarta EE.

**Issue gate:**

- All compatibility assertions pass on the current application.
- Every negative fixture fails for the intended reason.
- The application packages and starts on JDK 17/Open Liberty.
- CI is green and the evidence-matrix update is merged.

### 2.3 — Strengthen formatting, compiler, type, and static-analysis gates

**Reasons exercised:** 6. Code formatting and style enforcement; 1. Type
system; 4. Deep static analysis.

**What to build:**

- Preserve the resolved Spotless ratchet and first-job position.
- Enable the resolved actionable compiler diagnostics.
- Add the selected static analyzer and focused ruleset.
- Establish narrow, documented legacy suppressions only where necessary.
- Keep formatting, compilation, and analyzer reports separate so a later
  agent can identify which mechanism responded.
- Add controlled negative fixtures for formatting, compilation, and analyzer
  behavior without leaving red commits on the campaign branch.

**Files to modify:**

- `demo/pom.xml`
- `.github/workflows/main.yml`

**Files to create when selected:**

- `demo/config/spotbugs-exclude.xml`
- `demo/config/pmd-ruleset.xml`
- `demo/scripts/ci/verify-source-gates.sh`
- analyzer fixture sources under `demo/src/test/resources/analysis-fixtures/`

**Tests and validation:**

- Verify incorrectly formatted fixture code fails Spotless.
- Verify nonexistent method/incompatible type fixture fails compilation.
- Verify the analyzer detects at least one known fixture defect.
- Verify baseline application source passes all selected checks.
- Verify reports contain file, line, rule, and severity where supported.
- Measure runtime and confirm analyzer work does not repeat the full Open
  Liberty acceptance lifecycle.

**Expected failure evidence:**

- formatting drift;
- hallucinated API or incompatible type;
- selected null/resource/correctness analyzer defect;
- unauthorized suppression or malformed ruleset.

**Required artifacts:**

- compiler log;
- static-analysis XML/HTML report;
- source-gate metadata and duration;
- controlled negative-fixture transcript.

**Rollback considerations:**

- Add one warning category or analyzer rule family at a time.
- Revert a noisy rule rather than adding a blanket exclusion.
- Keep formatting concerns out of the deep analyzer.
- Do not enable `-Werror` until the selected warning set is proven clean.

**Issue gate:**

- Formatting, compiler, and analyzer jobs are independently attributable.
- Baseline source is green.
- Each mechanism has a verified controlled failure.
- Suppressions are narrow and documented.
- The evidence-matrix update is merged before behavioral-test work begins.

### 2.4 — Build the behavioral safety net

**Reasons exercised:** 2. Testing ecosystem; 3. Backwards compatibility
culture; 1. Type system where tests compile against typed boundaries.

**What to build:**

- Produce a trustworthy inventory of active, skipped, dormant, and repaired
  tests.
- Preserve the existing domain JUnit tests.
- Repair selected dormant scenario or routing tests only when they can become
  deterministic with small changes.
- Strengthen application-service and Arquillian/Open Liberty coverage.
- Add the resolved architecture rules for DDD layer boundaries.
- Add one bounded black-box Open Liberty smoke/acceptance job.
- Protect behavior needed before the later Change Arrival Deadline feature
  without implementing that feature.

**Files to modify as required:**

- `demo/pom.xml`
- `.github/workflows/main.yml`
- existing tests under `demo/src/test/java/org/eclipse/cargotracker/`

**Files to create when selected:**

- `demo/src/test/java/org/eclipse/cargotracker/architecture/LayeringTest.java`
- `demo/src/test/java/org/eclipse/cargotracker/scenario/` focused scenario
  fixtures
- `demo/scripts/ci/start-liberty-and-wait.sh`
- `demo/scripts/ci/smoke-test.sh`
- `demo/scripts/ci/stop-liberty.sh`

**Tests and validation:**

- Assert the expected Surefire test count and preserve XML reports.
- Run active unit tests independently from managed-container tests where
  practical.
- Verify application-service behavior through Arquillian/Open Liberty.
- Verify architecture rules over production packages.
- Start the packaged WAR, wait with a bounded timeout, and request
  `/cargo-tracker/`.
- Exercise at least one stable seeded-cargo, tracking, REST, or Administration
  path selected by the resolution.
- Ensure server shutdown runs even after a failed smoke test.

**Expected failure evidence:**

- domain invariant regression;
- application-service behavior regression;
- package-layer dependency violation;
- Open Liberty startup failure;
- HTTP non-200, missing application, or readiness timeout.

**Required artifacts:**

- Surefire and Arquillian reports;
- test inventory and count;
- architecture-test report;
- smoke-test transcript;
- Liberty `messages.log`, `console.log`, and FFDC files when present.

**Rollback considerations:**

- Do not make flaky or nondeterministic browser automation required.
- Do not claim dormant tests as coverage.
- If a legacy test cannot be repaired within scope, document it and retain or
  remove it only according to the resolution.
- Use bounded retries only for server readiness, not to hide test failures.

**Issue gate:**

- The active test inventory is explicit and reproducible.
- Unit, integration, architecture, and acceptance layers have distinct output.
- Open Liberty starts, serves the selected path, and stops reliably.
- Required CI is green and the evidence-matrix update is merged.

### 2.5 — Add CI observability and diagnostic artifacts

**Reasons exercised:** 8. Observability stack; 2. Testing ecosystem through
diagnosable runtime failures.

**What to build:**

- Add the resolved OpenTelemetry Java agent and local collector path, or the
  alternative selected in resolutions 1.14 and 1.15.
- Correlate a stable CI request with application/Liberty logs and exported
  telemetry.
- Exercise both a successful request and a controlled invalid request.
- Redact artifacts and upload only durable diagnostic outputs.
- Keep Azure Monitor/Application Insights optional and outside required CI.

**Files to modify:**

- `.github/workflows/main.yml`
- `demo/pom.xml` only if the selected mechanism needs build integration
- `demo/src/main/liberty/config/server.xml` or
  `demo/src/main/liberty/config/bootstrap.properties` only for resolved,
  portable configuration

**Files to create:**

- `demo/observability/otel-collector-config.yaml`
- `demo/scripts/ci/run-observability-check.sh`
- `demo/scripts/ci/redact-artifacts.sh`
- `demo/observability/README.md`

**Tests and validation:**

- Start the collector before Liberty and use bounded health checks.
- Start Liberty with the selected instrumentation.
- Send a successful request with a fixed CI correlation identifier.
- Send a deliberately invalid request.
- Verify exported telemetry contains the expected service name, operation,
  status, timestamps, and trace identifier.
- Verify logs and traces can be correlated.
- Search staged artifacts for configured secret patterns before upload.
- Stop both Liberty and the collector in an always-run cleanup step.

**Expected failure evidence:**

- collector unavailable;
- agent incompatible with Liberty;
- missing spans or metrics;
- failed correlation;
- accidental secret-like content in an artifact;
- invalid request with no diagnosable error signal.

**Required artifacts:**

- collector output;
- telemetry JSON/text;
- Liberty logs;
- successful and failed request transcripts;
- redaction-check result;
- instrumentation versions and command metadata.

**Rollback considerations:**

- Instrumentation must be removable through configuration without changing
  application behavior.
- Do not make CI depend on an Azure resource or secret.
- Do not upload raw environment dumps.
- If logs cannot be routed through OpenTelemetry reliably, retain Liberty logs
  as a separate correlated artifact rather than pretending log export worked.

**Issue gate:**

- A successful and failed request both produce correlated durable evidence.
- No Azure resource is required.
- Secret/redaction checks pass.
- Required CI is green and the evidence-matrix update is merged.

### 2.6 — Add bounded JVM performance and `jaz` evidence

**Reasons exercised:** 9. JVM performance tuning; 8. Observability stack.

**What to build:**

- Create the resolved repeatable workload and constrained container runtime.
- Run the same WAR and Liberty runtime directly and through `jaz`.
- Capture effective JVM settings, startup time, memory/CPU limits, GC logs,
  bounded JFR recordings, workload results, and exit status.
- Upload comparable artifacts without introducing brittle microbenchmark
  thresholds.
- Use observability from issue 2.5 to explain failures or anomalies.

**Files to modify:**

- `.github/workflows/main.yml`
- `demo/pom.xml` only for resolved packaging or launch support

**Files to create:**

- `demo/performance/run-workload.sh`
- `demo/performance/run-liberty-java.sh`
- `demo/performance/run-liberty-jaz.sh`
- `demo/performance/collect-process-metadata.sh`
- `demo/performance/README.md`

**Tests and validation:**

- Build the WAR once and use the same checksum for both launch paths.
- Run each path in a fresh container with identical CPU and memory limits.
- Use a bounded JFR duration and explicit GC logging.
- Wait for the same readiness condition.
- Execute the same request count and request data.
- Record at least the spike-determined number of repetitions.
- Verify JFR and GC artifacts are nonempty and parseable.
- Verify the `jaz` report reflects the configured cgroup limits.
- Fail on crash, out-of-memory, readiness failure, missing diagnostics, or
  workload failure; report timing differences without enforcing a narrow
  winner unless the resolution establishes a repeatable bound.

**Expected failure evidence:**

- JVM cannot become ready within the bound;
- out-of-memory or container kill;
- missing or empty JFR/GC output;
- `jaz` does not observe the intended cgroup limits;
- workload fails under one launch path.

**Required artifacts:**

- direct-Java metadata, GC log, JFR, and workload result;
- `jaz` metadata, selected settings, GC log, JFR, and workload result;
- WAR checksum;
- container resource configuration;
- comparison summary with variance and timestamps.

**Rollback considerations:**

- Keep performance evidence downstream of correctness and observability.
- Do not make hosted-runner timing noise a strict required threshold.
- Pin or verify `jaz` installation according to the resolution.
- Do not change application code merely to make one launch path look faster.

**Issue gate:**

- Both launch paths use the identical application artifact and resource
  envelope.
- Both complete the resolved workload or produce precise diagnostic failure.
- JFR, GC, and metadata artifacts are durable and comparable.
- The complete required workflow is green.
- The evidence-matrix update is merged before the tricked-out baseline is
  tagged.

---

## Cross-cutting campaign gate

Evidence matrix is a serial campaign gate

The campaign evidence matrix is:

`1-trick-out-01-remove-before-merge/evidence-matrix.md`

Every implementation issue must update this file. Evidence capture is part of the implementation work, not optional follow-up documentation.

Required workflow for every implementation issue

1. Before implementation, read the current evidence matrix from the campaign base branch. Identify which of the ten reasons the issue is intended to exercise. Do not overwrite evidence recorded by earlier issues.
2. Complete the issue’s implementation, local validation, required CI, and review-feedback resolution.
3. After the technical work and validation are complete, but before the issue is considered complete or its PR is merged, update the evidence matrix with what actually happened during this issue.
4. Commit the evidence-matrix update in the same task PR as the implementation. The PR must not merge without this update.
5. After merge, verify that the evidence-matrix update is present on the campaign base branch.
6. Do not assign, dispatch, or begin the next serial implementation issue until the preceding issue’s evidence-matrix update is merged and visible on the campaign base branch.

Required content

For every reason materially touched by the issue, update all applicable fields:

- Implementation task: Identify the issue and PR that introduced, exercised, or verified the mechanism.
- Observed campaign event: Describe a concrete event that actually occurred. Examples include a compiler rejection, failed test, analyzer finding, formatting failure, dependency rule violation, review correction, runtime diagnostic, trace, JFR recording, or performance observation.
- Artifact: Record durable evidence sufficient for another person to inspect the claim. Include exact issue numbers, PR numbers, commit SHAs, GitHub Actions run URLs, job names, check names, artifact paths, log paths, telemetry files, screenshots, traces, profiles, or post-mortem sections as applicable.
- Confidence: Classify the evidence as `Strong`, `Moderate`, `Weak`, `Unsupported`, or `Not exercised`.
- Slide implication: Classify the result as `Main slide`, `Brief mention`, `Appendix`, or `Cut`.

Preserve the abstract’s original reason numbering and ordering.

Evidence quality rules

- Record observations, not intentions.
- Do not claim that a safeguard helped merely because its tool was installed or its check passed.
- Distinguish between:
- a mechanism being present;
- a mechanism being executed;
- a mechanism detecting or preventing a problem; and
- a mechanism materially improving the agent’s work.
- If a mechanism ran but produced no meaningful event, state that explicitly.
- If the issue did not exercise an expected reason, record `Not exercised` rather than inventing evidence.
- If evidence is inconclusive, record `Weak` or `Unsupported` and explain why.
- Negative evidence is valid. Record cases where an agent bypassed, misunderstood, or received no benefit from a safeguard.
- Do not remove or rewrite earlier observations unless correcting a factual error. Add the new issue’s evidence so the campaign history remains understandable.
- Do not put reusable implementation guidance in the evidence matrix. Validated guidance for later issues belongs in `campaign-lessons.md`; the evidence matrix records what occurred and what supports the presentation.

Completion gate

An implementation issue is incomplete unless:

- its implementation and validation are complete;
- required CI is green;
- review feedback is resolved;
- its evidence-matrix update is committed in the task PR;
- the update contains durable references to the available evidence; and
- the merged campaign base branch contains that update.

The absence of meaningful evidence is not a reason to skip the update. Record the result as `Not exercised`, `Weak`, or `Unsupported`, with a concise explanation, before proceeding to the next issue.

---

## Reference material

- `dd-3032592-10-boring-reasons-abstract.md`
- `dd-3016202-cargotracker-devoxx-be-2026-01-remove-before-merge/20260928-sol-understanding-of-goal.md`
- `dd-3016202-cargotracker-devoxx-be-2026-01-remove-before-merge/suggested-implementation-order-from-workback-plan.md`
- `dd-3016202-cargotracker-devoxx-be-2026-01-remove-before-merge/workback-plan.md`
- `dd-3016202-cargotracker-devoxx-be-2026-01-remove-before-merge/20260925-prompts.md`
- `dd-3016202-cargotracker-devoxx-be-2026-01-remove-before-merge/20260928-prompts.md`
- `dd-3016202-cargotracker-devoxx-be-2026-01-remove-before-merge/20260929-prompts.md`
- `.github/workflows/main.yml`
- `demo/pom.xml`
- `demo/src/main/liberty/config/server.xml`
- `demo/src/test/java/org/eclipse/cargotracker/`
- `1-trick-out-01-remove-before-merge/shepherd-campaign.json`
- `1-trick-out-01-remove-before-merge/evidence-matrix.md`
- `1-trick-out-01-remove-before-merge/campaign-lessons.md`
