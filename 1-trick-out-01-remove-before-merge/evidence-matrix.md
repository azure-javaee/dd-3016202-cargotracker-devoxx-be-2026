# Campaign Evidence Matrix

Campaign: `1-trick-out-01-remove-before-merge`

This document records what the campaign actually demonstrates about the ten
boring reasons from the talk abstract. It begins with hypotheses and
`Not exercised` classifications. Implementation issues must replace those
initial values only when durable campaign evidence exists.

The ignorance-reduction plan and generated implementation issues define the
mandatory update timing and completion gates. In particular, the current
issue's evidence must be recorded and merged before the next serial issue
begins.

## Field definitions

| Field | Meaning |
|---|---|
| Reason | The ordered reason from the abstract |
| Agentic failure mode | The weakness it is meant to constrain |
| Repository mechanism | Compiler, Maven, test, analyzer, workflow, telemetry, or deployment control |
| Implementation task | The trick-out issue and PR that introduce, exercise, or verify it |
| Observed campaign event | A concrete success, failure, correction, or non-event |
| Artifact | CI run, log, PR, review, trace, JFR, screenshot, or post-mortem |
| Confidence | `Strong`, `Moderate`, `Weak`, `Unsupported`, or `Not exercised` |
| Slide implication | `Main slide`, `Brief mention`, `Appendix`, `Cut`, or `TBD` |

## Update rules

1. Preserve the reason numbering and ordering.
2. Treat the failure modes and mechanisms below as initial hypotheses, not
   evidence.
3. Update every applicable summary row after implementation, validation, and
   review-feedback resolution for an issue.
4. Identify implementation work with exact issue and PR numbers.
5. Link or name durable artifacts precisely: commit SHA, GitHub Actions run and
   job, check name, repository-relative artifact path, log, trace, profile,
   screenshot, or post-mortem section.
6. Distinguish a mechanism being installed from being executed, detecting a
   problem, preventing a problem, or materially improving the work.
7. Record silent or negative results. If the work did not exercise a reason,
   leave or set its confidence to `Not exercised` and explain the non-event.
8. Do not invent evidence or upgrade confidence because a tool merely passed.
9. Do not delete earlier evidence. Update the summary and append a dated
   issue-specific entry to the evidence log.
10. Put reusable implementation guidance in `campaign-lessons.md`, not here.

## Summary matrix

| Reason | Agentic failure mode | Repository mechanism | Implementation task | Observed campaign event | Artifact | Confidence | Slide implication |
|---|---|---|---|---|---|---|---|
| 1. Type system | Hallucinated APIs, incompatible values, invalid generics, and domain or layer leakage | Java compiler and Maven compiler configuration | Issue #4 / PR #12 | Local Java 17 compilation and the compatibility checker passed; the release negative control rejected a temporary release-21 POM. Hosted formatting and build jobs passed on the validated implementation HEAD. | Validated implementation HEAD `a3bee8d24ec54e6b3587ccf0cec443969d0609bd`; successful Main Build [run #36801557821](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/actions/runs/36801557821), `formatting` job/check [110176804872](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/actions/runs/36801557821/job/110176804872), `build` job/check [110176909417](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/actions/runs/36801557821/job/110176909417), and compatibility-contract artifact [11135847970](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/actions/runs/36801557821/artifacts/11135847970), digest `sha256:1de927b096f1ceaef7c1a3aae9c9f1bb2cafcbcc9ee53b5b3ae4ef1324f2018f` | Strong hosted implementation evidence | Brief mention |
| 2. Testing ecosystem | Behavior that compiles but is incomplete, incorrect, or regressive | JUnit, Arquillian, Open Liberty integration tests, architecture tests, and acceptance checks | Issue #2 / PR #9 | Hosted `build` passed on implementation commit; locally, 28/28 tests passed (including four managed Open Liberty tests), and production WAR returned HTTP 200 JSON containing `ABC123` before Liberty stopped successfully | Commit `bc6c3e387ccf5b3cab5e14b5ab4d91d512ef426b`; successful Main Build [run #36754101720](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/actions/runs/36754101720), `build` job/check [110022310098](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/actions/runs/36754101720/job/110022310098); local `demo/target/cargo-tracker.war`, 8,232,335 bytes, SHA-256 `93b8fc97ab3b8afcd44b1a062cbada335af79f5a764865a2e1fe2ed47e0c5419` | Strong for hosted build and local test/runtime evidence; production HTTP lifecycle was local, not hosted | Brief mention |
| 3. Backwards compatibility culture | Accidental migration away from Java 17, Java EE 7, `javax.*`, existing contracts, or established runtime behavior | Compiler release, dependency and API constraints, compatibility tests, and repository instructions | Issue #4 / PR #12 | The focused contract passed for Java 17, Java EE 7 provided API, WAR identity, Liberty feature/deployment, and production `javax.*` source; all seven isolated negative controls rejected their intended boundary. The packaged WAR reached `/cargo-tracker/rest/cargo` with seeded `ABC123` over Open Liberty and stopped cleanly. Hosted formatting and build jobs passed on the validated implementation HEAD and uploaded the compatibility report and runtime evidence. | Validated implementation HEAD `a3bee8d24ec54e6b3587ccf0cec443969d0609bd`; successful Main Build [run #36801557821](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/actions/runs/36801557821), `formatting` job/check [110176804872](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/actions/runs/36801557821/job/110176804872), `build` job/check [110176909417](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/actions/runs/36801557821/job/110176909417), and compatibility-contract artifact [11135847970](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/actions/runs/36801557821/artifacts/11135847970), digest `sha256:1de927b096f1ceaef7c1a3aae9c9f1bb2cafcbcc9ee53b5b3ae4ef1324f2018f` | Strong hosted implementation evidence plus runtime proof | Main slide |
| 4. Deep static analysis | Defects, architectural violations, maintainability problems, or security findings not rejected by compilation | Static analyzers, architecture rules, and security-oriented source analysis selected by the resolved plan | Unassigned | Not yet exercised | None yet | Not exercised | TBD |
| 5. Build system maturity and dependency management | Dependency sprawl, version drift, non-reproducible builds, plugin drift, or unapproved repositories | Maven dependency management, Enforcer rules, convergence checks, plugin controls, and dependency/security analysis | Issue #3 / PR #10; Issue #4 / PR #12 | Issue #3 established the authoritative dependency gate. Issue #4 added direct Jakarta/framework/runtime dependency rejection, validated true project-level negative fixtures, and added schema/hash-checked compatibility artifact metadata. | Issue #3 PR Main Build [run 36792676155](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/actions/runs/36792676155) and exact-SHA push [run 36793581535](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/actions/runs/36793581535); Issue #4 validated implementation HEAD `a3bee8d24ec54e6b3587ccf0cec443969d0609bd`, successful Main Build [run #36801557821](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/actions/runs/36801557821), `build` job/check [110176909417](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/actions/runs/36801557821/job/110176909417), compatibility-contract artifact [11135847970](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/actions/runs/36801557821/artifacts/11135847970) | Strong hosted dependency and compatibility enforcement evidence | Brief mention |
| 6. Code formatting and style enforcement | Noisy diffs and inconsistent independently generated code | Spotless and any additional narrowly justified style checks | Issue #3 / PR #10 | The `formatting` job was first and passed for both the final implementation synthetic merge and the exact primary merge SHA; the historical Spotless ratchet remained unchanged. | PR Main Build `formatting` job/check [110148953240](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/actions/runs/36792676155/job/110148953240); exact-SHA push Main Build `formatting` job/check [110151794413](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/actions/runs/36793581535/job/110151794413), `.github/workflows/main.yml`, `demo/pom.xml` | Strong PR and exact-SHA merged experiment-branch evidence | Brief mention |
| 7. Virtual threads and structured concurrency | Ad hoc concurrency, unmanaged task lifetimes, and unnecessary platform-thread complexity | A bounded Java 21-or-later spike isolated from the Java 17 Cargo Tracker baseline | Unassigned | Not yet exercised; the primary application baseline is Java 17 | None yet | Not exercised | TBD |
| 8. Observability stack | Opaque runtime failures and insufficient evidence for diagnosis | Structured logs, metrics, traces, correlation, OpenTelemetry artifacts, and optional Azure Monitor/Application Insights integration | Unassigned | Not yet exercised | None yet | Not exercised | TBD |
| 9. JVM performance tuning | Poor heap sizing, garbage-collector choices, startup behavior, or resource utilization under container limits | Repeatable workload, constrained runtime, JFR, GC evidence, and `java` versus `jaz` comparison | Unassigned | Not yet exercised | None yet | Not exercised | TBD |
| 10. Breadth of deployment options | Environment-coupled code or packaging that cannot move between realistic runtime targets | Repeatable deployment of the same Cargo Tracker artifact or container to Azure execution models | Unassigned | Not yet exercised | None yet | Not exercised | TBD |

## Issue-specific evidence log

Append one subsection for every implementation issue, even when it produces no
meaningful evidence. Keep entries in serial issue order.

### Issue #2: Establish the Open Liberty-only baseline

- **PR:** #9
- **Implementation commit:** `bc6c3e387ccf5b3cab5e14b5ab4d91d512ef426b` (pre-merge; do not treat as a future merge commit)
- **Completed:** 2026-09-30 UTC
- **Reasons expected to be exercised:** 2, 3, 5, 6
- **Reasons actually exercised:** 2, 3, 5, 6
- **Implementation result:** Removed Payara/Cargo/GlassFish runtime paths and guidance; retained Open Liberty as the sole active-by-default profile to preserve the resolved Maven validation tiers. Preserved Java 17, Java EE 7, `javax.*`, WAR packaging, and `cargo-tracker.war`.
- **Observed events:**
  - Spotless passed; the clean package passed all 28 tests (including four managed Open Liberty tests).
  - The production-WAR lifecycle deployed the WAR, started Liberty with the 90-second bound, observed server/application readiness, and received HTTP 200 `application/json` containing seeded `ABC123`; the EXIT cleanup invoked `liberty:stop` successfully.
  - The canonical profile-excluded compile and 24-test unit tiers passed; the explicit Liberty integration tier passed four tests; canonical package produced the WAR without a Liberty runtime directory.
  - A temporary unsupported-server fixture was found by the same search that returned no unsupported-server guidance in the demo.
  - Main Build push run [#36754101720](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/actions/runs/36754101720), attempt 2, passed for implementation commit `bc6c3e387ccf5b3cab5e14b5ab4d91d512ef426b`: `formatting` job/check [110022167006](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/actions/runs/36754101720/job/110022167006) and `build` job/check [110022310098](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/actions/runs/36754101720/job/110022310098) both succeeded. The run has no artifacts.
  - The evidence-matrix update commit `bb9a8f033ac14935a235cd0710aed95efd1014d0` also passed Main Build push run [#36754242738](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/actions/runs/36754242738), attempt 2: `formatting` job/check [110022156492](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/actions/runs/36754242738/job/110022156492) and `build` job/check [110022342235](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/actions/runs/36754242738/job/110022342235) both succeeded. This run has no artifacts.
- **Durable artifacts:**
  - Local deployable WAR identity: `demo/target/cargo-tracker.war`, 8,232,335 bytes, SHA-256 `93b8fc97ab3b8afcd44b1a062cbada335af79f5a764865a2e1fe2ed47e0c5419`. This was produced and deployed locally; it is not represented as a hosted workflow artifact.
  - Supporting configuration/source: `demo/pom.xml`, `demo/src/main/liberty/config/server.xml`, `demo/src/test/resources/arquillian.xml`, and `demo/src/main/java/org/eclipse/cargotracker/interfaces/booking/socket/RealtimeCargoTrackingService.java`.
  - Hosted CI evidence: implementation push run #29 / ID `36754101720` on commit `bc6c3e387ccf5b3cab5e14b5ab4d91d512ef426b`, with successful `formatting` job/check ID `110022167006` and `build` job/check ID `110022310098`; current evidence update push run #31 / ID `36754242738` on commit `bb9a8f033ac14935a235cd0710aed95efd1014d0`, with successful `formatting` job/check ID `110022156492` and `build` job/check ID `110022342235`. Both runs have no artifacts.
- **Evidence assessment:** Strong for hosted formatting/build and local unit/integration/runtime lifecycle. The hosted workflow verifies formatting and Maven build; the production HTTP readiness assertion and guaranteed Liberty shutdown were verified locally, not by hosted acceptance CI.
- **Candidate reusable lessons:** Keep the `openliberty` profile excludable while canonical fast tiers use `-P!openliberty`; flattening the plugin into the main build would change those commands.

### Issue #3: Make CI authoritative and establish the Maven/dependency foundation

- **PR:** #10
- **Implementation commit:** `c98096d70caad040bd8c3613a630c7c064cc13e2`
- **Merged commit:** `ff40701729cbfac46e2bcb6cd17fcd14a5dfeff0`
- **Completed:** 2026-09-30 UTC
- **Reasons expected to be exercised:** 5, 6
- **Reasons actually exercised:** 5, 6
- **Implementation result:** Established serial formatting-first CI, Maven Enforcer governance, reproducible dependency inventories, advisory delta gating, negative controls, and immutable build/dependency artifacts.
- **Observed events:**
  - Successful Main Build PR run [36792676155](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/actions/runs/36792676155), attempt 1, validated synthetic merge SHA `37099baee55ca89517a83a3a555b436ffe1f4387` for implementation HEAD `c98096d70caad040bd8c3613a630c7c064cc13e2`.
  - PR `formatting` job/check [110148953240](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/actions/runs/36792676155/job/110148953240) and `build` job/check [110149060803](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/actions/runs/36792676155/job/110149060803) passed in serial order.
  - PR #10 merged as primary merge SHA `ff40701729cbfac46e2bcb6cd17fcd14a5dfeff0`.
  - Successful Main Build push run [36793581535](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/actions/runs/36793581535), attempt 1, validated that exact SHA on `edburns/dd-3016202-cargotracker-devoxx-be-2026-experiment`.
  - `formatting` job/check [110151794413](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/actions/runs/36793581535/job/110151794413) and `build` job/check [110151881020](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/actions/runs/36793581535/job/110151881020) passed in serial order.
  - Required negative controls rejected Java range, Maven range, unversioned plugin, duplicate dependency, banned dependency, unauthorized repository, dependency convergence, malformed formatting, corrupted WAR checksum, and known-vulnerable Log4j advisory fixtures.
  - Current and baseline inventories each contained 108 resolved coordinates; the full-coordinate delta was empty and no matching new HIGH/CRITICAL advisories were returned.
- **Durable artifacts:**
  - PR `build-contract` artifact ID `11133305135`, [URL](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/actions/runs/36792676155/artifacts/11133305135), digest `sha256:d3219a3cdb329839b8aadc1229132c4402b4b24917be45d4db8c8f0e4b53aec1`.
  - PR `dependency-reports` artifact ID `11132736102`, [URL](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/actions/runs/36792676155/artifacts/11132736102), digest `sha256:70ef51f9e344ea1c1d7e77dd7f2ae07bb0a06bdfb4e01ca2fcb00388f70ee690`.
  - `build-contract` artifact ID `11132333582`, [URL](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/actions/runs/36793581535/artifacts/11132333582), digest `sha256:62a97f70663473867dc7f4646b79e0632da775ddfe82dfa1a01df8682070fc72`; supporting files `enforcer-negative-controls.txt`, `war-inventory.txt`, `war.sha256`, and `artifact-metadata.json`.
  - `dependency-reports` artifact ID `11132333587`, [URL](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/actions/runs/36793581535/artifacts/11132333587), digest `sha256:7b1f547c05280d8c5b270b38e00c95192112514bab64de41d780fe1e8bd8e7aa`; supporting files `effective-pom.xml`, `dependency-tree.txt`, `resolved-plugins.txt`, `vulnerability-report.json`, `vulnerability-report.txt`, and `artifact-metadata.json`.
- **Evidence assessment:** Strong for both the final PR synthetic-merge validation and the authoritative exact-SHA experiment-branch push run with immutable artifacts.
- **Candidate reusable lessons:** Keep formatting first, retain the historical Spotless ratchet, and record synthetic-merge SHA separately from implementation HEAD.

### Issue #4: Enforce the Java 17 and Java EE 7 compatibility contract

- **PR:** #12
- **Implementation commit:** `a3bee8d24ec54e6b3587ccf0cec443969d0609bd` (validated implementation HEAD)
- **Completed:** 2026-10-01 UTC
- **Reasons expected to be exercised:** 1, 3, 5
- **Reasons actually exercised:** 1, 3, 5
- **Implementation result:** Added focused POM, Liberty, and production-source assertions; isolated negative fixtures; repository agent instructions; and a single deployed Open Liberty acceptance lifecycle with bounded evidence.
- **Observed events:**
  - Local compatibility validation passed for compiler release 17, `javax:javaee-api:7.0` in provided scope, WAR packaging/final name, `javaee-7.0`, WAR location, and `/cargo-tracker`.
  - Negative fixtures rejected a Jakarta import, Jakarta dependency, release 21, JAR packaging, renamed WAR, Spring dependency, and removed `javaee-7.0`, each naming the violated boundary.
  - The packaged WAR deployed and returned seeded `ABC123` from `/cargo-tracker/rest/cargo`; the acceptance script captured deploy/start/readiness/stop evidence and stopped Liberty cleanly.
  - Hosted Main Build run [#36801557821](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/actions/runs/36801557821) passed on validated implementation HEAD `a3bee8d24ec54e6b3587ccf0cec443969d0609bd`; `formatting` job/check [110176804872](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/actions/runs/36801557821/job/110176804872) and `build` job/check [110176909417](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/actions/runs/36801557821/job/110176909417) both succeeded.
  - Direct Jakarta and Spring dependencies were rejected from the project-level dependency list, and compatibility metadata passed required-field, file-size, and SHA-256 verification.
- **Durable artifacts:**
  - `demo/scripts/ci/verify-compatibility-contract.sh`
  - `demo/scripts/ci/run-openliberty-acceptance.sh`
  - `demo/ci-artifacts/compatibility-contract/compatibility-report.txt`, `negative-controls.txt`, `liberty-deploy.log`, `liberty-start.log`, `liberty-stop.log`, `readiness.json` from local validation
  - `demo/ci-artifacts/compatibility-contract/liberty-messages-excerpt.txt` and compatibility-specific `artifact-metadata.json`
  - `.github/workflows/main.yml` compatibility-contract upload with 90-day retention
- **Hosted artifact:** `compatibility-contract` artifact [11135847970](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/actions/runs/36801557821/artifacts/11135847970), digest `sha256:1de927b096f1ceaef7c1a3aae9c9f1bb2cafcbcc9ee53b5b3ae4ef1324f2018f`.
- **Evidence assessment:** Strong for the validated implementation HEAD hosted contract, negative controls, artifact evidence, and deployed runtime lifecycle.
- **Candidate reusable lessons:** Keep repository assertions narrow and let the packaged WAR, rather than a managed test-only deployment, define the Open Liberty acceptance boundary.

Use this template:

```markdown
### Issue #<number>: <title>

- **PR:** #<number>
- **Merged commit:** `<full SHA>`
- **Completed:** `<UTC timestamp>`
- **Reasons expected to be exercised:** <reason numbers>
- **Reasons actually exercised:** <reason numbers or `None`>
- **Implementation result:** <concise factual summary>
- **Observed events:**
  - <what happened, including failures, corrections, and meaningful non-events>
- **Durable artifacts:**
  - <exact run URL, job/check name, repository-relative path, log, trace,
    profile, screenshot, review thread, or post-mortem section>
- **Evidence assessment:** <why the resulting confidence is Strong, Moderate,
  Weak, Unsupported, or Not exercised>
- **Candidate reusable lessons:** <candidate guidance, or `None`; validated
  reusable guidance belongs in campaign-lessons.md>
```

No implementation issue is complete until its subsection has been appended
and the corresponding summary rows have been updated.

## Appendix I: Human observations

- While filling out the ignorance reduction plan, I was frequently guided toward narrowing the possible paths the agents could go. See "1.6 — Executable Java 17 and Java EE 7 compatibility contract". Without narrowing it down, the agents might want to upgrade the system forward: javax → jakarta for example. By explicitly disallowing that, we close down that possible wandering path.
