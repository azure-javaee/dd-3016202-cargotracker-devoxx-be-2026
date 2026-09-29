## Implementation Ordering for the Trick-Out Campaign

The ignorance-reduction plan should validate this ordering rather than blindly
copy it. Each implementation issue must be independently useful and must end
with green CI.

### 1. Make experiment-branch CI authoritative

- Ensure pushes or PRs for
  `edburns/dd-3016202-cargotracker-devoxx-be-2026-experiment` receive the
  required workflow.
- Preserve the existing Microsoft Build of OpenJDK 17 formatting and build
  jobs.
- Establish exact green baseline commands and artifacts.
- Ensure failure in any required job blocks progression.

This is the prerequisite for all later trick-out issues.

### 2. Strengthen build, dependency, and compatibility governance

- Introduce Maven and dependency rules incrementally.
- Preserve Java 17, Java EE 7, `javax.*`, WAR packaging, Open Liberty, and
  existing behavior.
- Prevent accidental migration to Jakarta namespaces, Spring, a different UI
  stack, or an unrelated runtime.
- Add each rule with a green baseline or a narrowly documented suppression.

This covers the foundation for reasons 5 and 3.

### 3. Preserve and expand fast deterministic source gates

- Preserve Spotless as the first fast gate.
- Make compiler/type failures prominent and attributable.
- Add static analysis one tool or rule family at a time.
- Separate new-code enforcement from unavoidable legacy debt where necessary.
- Include security-oriented source and dependency checks in the relevant
  build/static-analysis surfaces rather than creating a disconnected
  "security" bucket.

This covers reasons 6, 1, and 4.

### 4. Build the behavioral safety net

- Add or strengthen focused domain and application-service tests.
- Add architecture tests where they protect the layered design.
- Add Open Liberty integration and HTTP acceptance checks.
- Add the smallest practical browser/UI validation for the eventual deadline
  feature.
- Ensure tests produce useful failure evidence for agents and reviewers.

This covers reason 2 and is the most important guardrail before the feature
campaign begins.

### 5. Add runtime observability

- Produce useful structured application/runtime logs.
- Capture metrics and traces with stable correlation.
- Preserve telemetry artifacts from CI runs.
- Make agent-created runtime failures diagnosable without requiring manual
  guesswork.
- Add Azure Monitor/Application Insights only where it strengthens the
  evidence without making local and CI validation depend on Azure.

This covers reason 8.

### 6. Add measured JVM performance evidence

- Establish a repeatable workload and resource limits.
- Capture startup, memory, GC, and JFR evidence.
- Evaluate `java` versus `jaz` in a constrained Linux/container environment.
- Avoid brittle performance gates; use broad regression checks and preserved
  diagnostic artifacts unless repeatability supports stricter thresholds.

This covers reason 9 and depends on the observability and workload work.

### 7. Isolate the Java 21 concurrency capability spike

- Do not migrate the primary Cargo Tracker baseline away from Java 17 merely
  to demonstrate reason 7.
- Evaluate a separate Java 21-or-later test, module, branch, or documented
  experiment for virtual threads and structured concurrency.
- Accept "not applicable to this Java 17 campaign" as an honest outcome if no
  credible, bounded experiment fits the schedule.

This covers reason 7 without breaking the backwards-compatibility story.
