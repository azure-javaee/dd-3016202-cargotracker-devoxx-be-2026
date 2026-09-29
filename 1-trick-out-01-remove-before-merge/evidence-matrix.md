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
| 2. Testing ecosystem | Behavior that compiles but is incomplete, incorrect, or regressive | JUnit, Arquillian, Open Liberty integration tests, architecture tests, and acceptance checks | Unassigned | Not yet exercised | None yet | Not exercised | TBD |
| 3. Backwards compatibility culture | Accidental migration away from Java 17, Java EE 7, `javax.*`, existing contracts, or established runtime behavior | Compiler release, dependency and API constraints, compatibility tests, and repository instructions | Unassigned | Not yet exercised | None yet | Not exercised | TBD |
| 4. Deep static analysis | Defects, architectural violations, maintainability problems, or security findings not rejected by compilation | Static analyzers, architecture rules, and security-oriented source analysis selected by the resolved plan | Unassigned | Not yet exercised | None yet | Not exercised | TBD |
| 5. Build system maturity and dependency management | Dependency sprawl, version drift, non-reproducible builds, plugin drift, or unapproved repositories | Maven dependency management, Enforcer rules, convergence checks, plugin controls, and dependency/security analysis | Unassigned | Not yet exercised | None yet | Not exercised | TBD |
| 6. Code formatting and style enforcement | Noisy diffs and inconsistent independently generated code | Spotless and any additional narrowly justified style checks | Unassigned | Not yet exercised | None yet | Not exercised | TBD |
| 7. Virtual threads and structured concurrency | Ad hoc concurrency, unmanaged task lifetimes, and unnecessary platform-thread complexity | A bounded Java 21-or-later spike isolated from the Java 17 Cargo Tracker baseline | Unassigned | Not yet exercised; the primary application baseline is Java 17 | None yet | Not exercised | TBD |
| 8. Observability stack | Opaque runtime failures and insufficient evidence for diagnosis | Structured logs, metrics, traces, correlation, OpenTelemetry artifacts, and optional Azure Monitor/Application Insights integration | Unassigned | Not yet exercised | None yet | Not exercised | TBD |
| 9. JVM performance tuning | Poor heap sizing, garbage-collector choices, startup behavior, or resource utilization under container limits | Repeatable workload, constrained runtime, JFR, GC evidence, and `java` versus `jaz` comparison | Unassigned | Not yet exercised | None yet | Not exercised | TBD |
| 10. Breadth of deployment options | Environment-coupled code or packaging that cannot move between realistic runtime targets | Repeatable deployment of the same Cargo Tracker artifact or container to Azure execution models | Unassigned | Not yet exercised | None yet | Not exercised | TBD |

## Issue-specific evidence log

Append one subsection for every implementation issue, even when it produces no
meaningful evidence. Keep entries in serial issue order.

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
