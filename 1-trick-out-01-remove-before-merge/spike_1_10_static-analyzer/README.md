# Spike 1.10: Static analyzer and legacy-debt strategy

Date: 2026-09-29

Plan question:
`1-trick-out-01-remove-before-merge/trick-out-01-ignorance-reduction-plan.md`,
section 1.10.

## Decision

Select **SpotBugs** as the single initial general static analyzer.

Use:

- `com.github.spotbugs:spotbugs-maven-plugin:4.10.4.1`;
- SpotBugs `4.10.4`;
- `effort=Max`;
- `threshold=Low`;
- production classes only;
- correctness, security, and multithreaded-correctness findings.

Exclude the `MALICIOUS_CODE`, `BAD_PRACTICE`, `STYLE`, `I18N`, and
`PERFORMANCE` categories from the initial gate. This is a deliberate initial
rule-scope choice, not an assertion that those categories never matter.

Fix the seven selected baseline findings, then bind `spotbugs:check` to
`verify` as a zero-finding gate. Do not suppress or baseline the seven
findings: all seven represent real defects.

Do not add PMD as a required analyzer in this campaign. Preserve its report as
research evidence and reconsider individual PMD rules later, separately from
the initial general-analyzer gate.

## Comparison

Both tools were run against the same 95 production Java files and the default
Open Liberty build.

| Tool | Focused baseline | Compile-and-analyze runtime | Fixture result | Decision |
|---|---:|---:|---|---|
| SpotBugs | 7 findings | 25 seconds | Added one priority-1 `NP_ALWAYS_NULL` finding | Select |
| PMD | 24 findings | 22 seconds | Added one `CloseResource` finding | Do not select initially |

The runtimes are operationally equivalent. Both include Maven compilation and
Open Liberty assembly work, so the difference is not a useful selection
criterion.

SpotBugs produced the smaller and more defect-oriented baseline. PMD produced
useful findings, but its baseline requires more framework and legacy-policy
triage before it could be a low-noise required gate.

The current official plugin documentation identifies SpotBugs Maven Plugin
`4.10.4.1` with SpotBugs `4.10.4`; Maven PMD Plugin `3.28.0` uses PMD `7.17.0`
in this run.

Official version sources:

- <https://spotbugs.github.io/spotbugs-maven-plugin/>
- <https://maven.apache.org/plugins/maven-pmd-plugin/examples/upgrading-PMD-at-runtime.html>

## SpotBugs baseline

### Five concurrency defects

SpotBugs reported
`STCAL_INVOKE_ON_STATIC_DATE_FORMAT_INSTANCE` in:

1. `CargoRoute`;
2. `Leg`;
3. `ItineraryCandidateDtoAssembler`;
4. `CargoTrackingViewAdapter.getEta()`;
5. `CargoTrackingViewAdapter.HandlingEventViewAdapter.getTime()`.

Each class shares a static `SimpleDateFormat`. `SimpleDateFormat` is mutable
and not thread-safe, while these DTO, assembler, and web paths can execute
concurrently. These are real runtime defects, not Java EE or Open Liberty
false positives.

Fix them with a thread-safe formatter or a per-use formatter while preserving
the existing textual date contract. Do not use this task to migrate domain
APIs from `Date` to `java.time`.

### Permanently null booking result

`BookingBackingBean.newTrackingId` is initialized to null and never assigned.
`register()` assigns the booking result to a local `trackingId` variable that
is never subsequently used, while `getNewTrackingId()` exposes the field.

This is a real UI-state defect. Assign the booking result to the field or
remove the field/getter only after verifying the intended JSF behavior.

### Unwritten route DTO field

`CargoRoute.nextLocation` has a getter but is never assigned by its
constructor or any method. The getter therefore always returns null.

This is a real DTO defect relevant to later booking and administration work.
Populate it from the intended source or remove the unused contract after
checking all view references.

## SpotBugs noise assessment

Before focusing the rules, the report contained 60 representation-exposure
findings in `MALICIOUS_CODE`, primarily `EI_EXPOSE_REP` and
`EI_EXPOSE_REP2`. Enforcing those would require broad defensive-copy changes
to legacy entity and DTO APIs and would turn the campaign into an
encapsulation modernization effort.

The other omitted categories contained constructor/finalizer warnings,
container-injected serialization fields, serial-version advice, locale
advice, dead-store/style findings, and performance suggestions. Those can be
evaluated in later focused work but are not suitable for the first required
deep-analysis gate.

The selected categories produced seven findings, all classified as real
defects, and no Open Liberty or Jakarta EE false positives.

## PMD baseline

The curated PMD rules produced:

| Rule | Count | Assessment |
|---|---:|---|
| `UseLocaleWithCaseConversions` | 9 | Useful compatibility debt |
| `SimpleDateFormatNeedsLocale` | 8 | Useful compatibility debt |
| `AvoidCatchingNPE` | 2 | Real defect candidates |
| `UnusedNullCheckInEquals` | 1 | Real defect candidate |
| `NonSerializableClass` | 1 | Requires JSF/container review |
| `ConstructorCallsOverridableMethod` | 1 | Requires JPA/domain review |
| `CloseResource` | 1 | False positive on container-managed WebSocket `Session` |
| `AssignmentInOperand` | 1 | Intentional checkpoint pattern |

PMD initially produced 165 findings when the entire Error Prone category was
enabled. Of those, 106 were `ReplaceJavaUtilDate`, which is migration advice
rather than evidence of a current defect. Restricting PMD to selected rules
reduced the baseline to 24, but it still mixed defects, modernization advice,
framework review, and a container false positive.

PMD may be useful later as individually selected source rules. It should not
be the campaign's first required general analyzer.

## Failure control

The temporary fixture contained:

- an unconditional null dereference;
- an unclosed input stream.

Observed deltas:

- SpotBugs increased from 7 to 8 findings and reported the fixture as
  priority 1, rank 5, `NP_ALWAYS_NULL`;
- PMD increased from 24 to 25 findings and reported `CloseResource`.

The harness asserts that each fixture report names
`AnalyzerFailureFixture`. The temporary fixture and analyzer POM changes were
confined to disposable clones.

## Reporting and gate behavior

Check in the focused SpotBugs exclusion filter with comments explaining each
omitted category. Generate and upload:

- SpotBugs XML;
- a concise TSV or SARIF conversion with priority, rank, category, type,
  class, source line, and message;
- Maven log and elapsed time.

After fixing the seven baseline findings:

1. run SpotBugs after compilation;
2. run `spotbugs:check` during `verify`;
3. fail on every selected finding;
4. require a narrow class-and-bug-pattern exclusion with rationale if a later
   false positive is demonstrated;
5. do not suppress by package, category, or broad wildcard merely to keep CI
   green.

Style remains owned by Spotless. Architecture remains owned by tests such as
ArchUnit. Dependency vulnerabilities remain owned by the dependency-security
task.

## Reproduction

Run from the repository root:

```bash
1-trick-out-01-remove-before-merge/spike_1_10_static-analyzer/run-spike.sh
```

The harness:

- creates disposable shared clones;
- injects SpotBugs and PMD independently;
- runs baseline and failure-fixture analysis;
- records end-to-end runtime;
- preserves XML reports, normalized TSV findings, and Maven logs;
- asserts that both tools detect the fixture;
- removes the disposable clones.

It does not modify the application worktree.

## Additional information

SpotBugs produced 7 high-signal findings, all real defects: five shared `SimpleDateFormat` concurrency hazards, `BookingBackingBean.newTrackingId` remaining permanently null, and `CargoRoute.nextLocation` never being written. PMD produced 24 findings mixing useful locale advice, defect candidates, framework-sensitive warnings, an intentional pattern, and a false `CloseResource` warning for a container-managed WebSocket session. Their compile-and-analyze runtimes were comparable: 25 seconds for SpotBugs and 22 seconds for PMD. As of September 29, 2026, the official versions are SpotBugs Maven Plugin `4.10.4.1` with SpotBugs `4.10.4`, and Maven PMD Plugin `3.28.0` with PMD `7.17.0`. 

Select SpotBugs Maven Plugin `4.10.4.1` as the single initial general static analyzer, configured with `effort=Max`, `threshold=Low`, and focused on correctness, security, and multithreaded-correctness findings for production classes. Exclude the `MALICIOUS_CODE`, `BAD_PRACTICE`, `STYLE`, `I18N`, and `PERFORMANCE` categories from the initial gate with a checked-in rationale; the broad report otherwise contains representation-exposure, framework, style, locale, and modernization noise. The focused SpotBugs baseline has seven findings and all are real defects: five shared static `SimpleDateFormat` concurrency hazards, `BookingBackingBean.newTrackingId` remaining permanently null while a booking result is assigned to an unused local variable, and `CargoRoute.nextLocation` never being written. Fix those seven findings rather than suppressing them, then bind `spotbugs:check` to `verify` as a zero-finding required gate and upload the XML plus a normalized CI-friendly report. Do not select PMD as the initial required analyzer: even a curated correctness/security ruleset produced 24 findings mixing useful locale advice, three clear defect candidates, framework-sensitive serialization and constructor warnings, an intentional assignment pattern, and a false `CloseResource` warning for a container-managed WebSocket `Session`. SpotBugs and PMD had comparable compile-and-analyze runtimes of 25 and 22 seconds. The failure fixture was detected by both tools; SpotBugs reported the injected null dereference as priority 1 `NP_ALWAYS_NULL`. Keep formatting in Spotless, architecture rules in tests, and dependency vulnerability analysis in the dependency-governance work.
