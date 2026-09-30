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
| 1. Type system | Hallucinated APIs, incompatible values, invalid generics, and domain or layer leakage | Java compiler and Maven compiler configuration | Unassigned | Not yet exercised | None yet | Not exercised | TBD |
| 2. Testing ecosystem | Behavior that compiles but is incomplete, incorrect, or regressive | JUnit, Arquillian, Open Liberty integration tests, architecture tests, and acceptance checks | Issue #2 / PR #9 | Hosted `build` passed on implementation commit; locally, 28/28 tests passed (including four managed Open Liberty tests), and production WAR returned HTTP 200 JSON containing `ABC123` before Liberty stopped successfully | Commit `bc6c3e387ccf5b3cab5e14b5ab4d91d512ef426b`; successful Main Build [run #36754101720](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/actions/runs/36754101720), `build` job/check [110022310098](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/actions/runs/36754101720/job/110022310098); local `demo/target/cargo-tracker.war`, 8,232,335 bytes, SHA-256 `93b8fc97ab3b8afcd44b1a062cbada335af79f5a764865a2e1fe2ed47e0c5419` | Strong for hosted build and local test/runtime evidence; production HTTP lifecycle was local, not hosted | Brief mention |
| 3. Backwards compatibility culture | Accidental migration away from Java 17, Java EE 7, `javax.*`, existing contracts, or established runtime behavior | Compiler release, dependency and API constraints, compatibility tests, and repository instructions | Issue #2 / PR #9 | Hosted Maven build passed on the implementation commit; local Java 17 compilation and Java EE 7/Open Liberty production WAR lifecycle passed without Jakarta/API or application behavior changes | Commit `bc6c3e387ccf5b3cab5e14b5ab4d91d512ef426b`; successful Main Build [run #36754101720](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/actions/runs/36754101720), `build` job/check [110022310098](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/actions/runs/36754101720/job/110022310098); `demo/pom.xml`, `demo/src/main/liberty/config/server.xml`, local `demo/target/cargo-tracker.war` SHA-256 `93b8fc97ab3b8afcd44b1a062cbada335af79f5a764865a2e1fe2ed47e0c5419` | Strong for hosted build and local compatibility/runtime verification; HTTP acceptance was local, not hosted | Brief mention |
| 4. Deep static analysis | Defects, architectural violations, maintainability problems, or security findings not rejected by compilation | Static analyzers, architecture rules, and security-oriented source analysis selected by the resolved plan | Unassigned | Not yet exercised | None yet | Not exercised | TBD |
| 5. Build system maturity and dependency management | Dependency sprawl, version drift, non-reproducible builds, plugin drift, or unapproved repositories | Maven dependency management, Enforcer rules, convergence checks, plugin controls, and dependency/security analysis | Issue #3 / PR #10 | Hosted PR synthetic-merge validation passed; current and baseline inventories each contained 108 resolved coordinates, with zero new coordinates and zero matching new HIGH/CRITICAL advisories. All required negative controls rejected their invalid fixtures. | Main Build [run 36789919690](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/actions/runs/36789919690), `build` job/check [110140266582](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/actions/runs/36789919690/job/110140266582), `dependency-reports` artifact [11132085424](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/actions/runs/36789919690/artifacts/11132085424), `demo/scripts/ci/run-dependency-security-gate.sh`, `vulnerability-report.json` | Strong for the verified PR synthetic-merge evidence; this is not merged experiment-branch evidence | Brief mention |
| 6. Code formatting and style enforcement | Noisy diffs and inconsistent independently generated code | Spotless and any additional narrowly justified style checks | Issue #3 / PR #10 | The `formatting` job was first and passed on the verified PR synthetic-merge run; the historical Spotless ratchet remained unchanged. | Main Build `formatting` job/check [110140148289](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/actions/runs/36789919690/job/110140148289), `.github/workflows/main.yml`, `demo/pom.xml` | Strong for this PR synthetic-merge evidence; merged experiment-branch evidence is intentionally not claimed | Brief mention |
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
- **Implementation commit:** `fd9156f4d43ea2e26eaefa55778299dc6b4bc190`
- **Completed:** 2026-09-30 UTC
- **Reasons expected to be exercised:** 5, 6
- **Reasons actually exercised:** 5, 6
- **Implementation result:** Established serial formatting-first CI, Maven Enforcer governance, reproducible dependency inventories, advisory delta gating, negative controls, and immutable build/dependency artifacts.
- **Observed events:**
  - Successful Main Build run [36789919690](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/actions/runs/36789919690), attempt 1, validated the PR synthetic merge SHA `24612be574b3e735ee379a9f15417d2c68984b19` for implementation HEAD `fd9156f4d43ea2e26eaefa55778299dc6b4bc190`.
  - `formatting` job/check [110140148289](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/actions/runs/36789919690/job/110140148289) and `build` job/check [110140266582](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/actions/runs/36789919690/job/110140266582) passed in serial order.
  - Required negative controls rejected Java range, Maven range, unversioned plugin, duplicate dependency, banned dependency, unauthorized repository, dependency convergence, malformed formatting, corrupted WAR checksum, and known-vulnerable Log4j advisory fixtures.
  - Current and baseline inventories each contained 108 resolved coordinates; the full-coordinate delta was empty and no matching new HIGH/CRITICAL advisories were returned.
- **Durable artifacts:**
  - `build-contract` artifact ID `11132090396`, [URL](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/actions/runs/36789919690/artifacts/11132090396), digest `sha256:0cf0e52054175c3012f0aa4bfe7cd097f5f7b752331c11d81bb35418ea38f830`; supporting files `enforcer-negative-controls.txt`, `war-inventory.txt`, `war.sha256`, and `artifact-metadata.json`.
  - `dependency-reports` artifact ID `11132085424`, [URL](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/actions/runs/36789919690/artifacts/11132085424), digest `sha256:9ff5975b814481a9d7ae23e0486ad90b3aa76c9272170241ef1c613df9cf8ec7`; supporting files `effective-pom.xml`, `dependency-tree.txt`, `resolved-plugins.txt`, `vulnerability-report.json`, `vulnerability-report.txt`, and `artifact-metadata.json`.
- **Evidence assessment:** Strong for this verified PR synthetic-merge run and its immutable artifacts. It does not claim a merged experiment-branch push run; that evidence belongs to the later stage.
- **Candidate reusable lessons:** Keep formatting first, retain the historical Spotless ratchet, and record synthetic-merge SHA separately from implementation HEAD.

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
