# Investigate the Devoxx Cargo Tracker Experiment Failure

Use this prompt if the currently running Devoxx Cargo Tracker Shepherd
experiment fails.

The campaign was still in progress when this prompt was written on
October 2, 2026. Do not assume that a suspicious line in a streaming log is
the terminal outcome. First establish whether the run really failed, where it
failed, and whether the application work itself succeeded before the
controller or logging pipeline failed.

## Objective

Investigate the existing campaign in place. Determine the exact failure mode,
collect durable evidence, and recommend the least disruptive recovery.

Pay particular attention to **fixture plan contradictions**: combinations of
task requirements, repository CI invariants, completion gates, and issue scope
that make a task impossible to complete.

Do not mutate the disposable repository, restart the driver, rerun a Shepherd
stage, close issues, merge pull requests, or repair the fixture until the
failure is understood and I explicitly authorize intervention.

## Running experiment identity

Disposable repository:

```text
edburns/dd-3072539-tricked-out-cargotracker-run-01
```

Top-level driver log:

```text
/home/edburns/workareas/20261002-0339-job-logs.txt
```

Primary checkout:

```text
/home/edburns/workareas/dd-3072539-tricked-out-cargotracker-run-01-shepherd-target
```

Control worktree:

```text
/home/edburns/workareas/dd-3072539-tricked-out-cargotracker-run-01-shepherd-control
```

Campaign metadata directory:

```text
1-arrival-deadline-control-remove-before-merge
```

Campaign ID:

```text
0511bd1e-2e8d-4684-8614-e79b2edbedcc
```

Campaign run artifact directory:

```text
/home/edburns/workareas/dd-3072539-tricked-out-cargotracker-run-01-shepherd-control/1-arrival-deadline-control-remove-before-merge/shepherd-tasks-0511bd1e-2e8d-4684-8614-e79b2edbedcc-20261002-0344
```

Campaign branch:

```text
edburns/dd-3016202-cargotracker-devoxx-be-2026-add-feature-control
```

Immutable shared baseline branch:

```text
experiment/shepherd-shared-baseline
```

Ordered task issues:

```text
2,3,4,5,6
```

At the time this prompt was written:

- Stage 20 had completed.
- The fixture had verified all five generated issue bodies.
- Stage 25 had started serial processing of issues 2 through 6.

## Installed fixture identity

Installed fixture:

```text
/home/edburns/.copilot/plugins/shepherd-task/test/cargotracker-add-change-arrival-deadline-feature-devoxx-2026-edition
```

Shepherd source repository:

```text
/home/edburns/workareas/awesome-copilot-03
```

Installed Shepherd source commit:

```text
4eef4fdedef5efec4256f5a9e2ff1b9c59e50d05
```

Authoritative Cargo Tracker source repository:

```text
/home/edburns/workareas/dd-3016202-cargotracker-devoxx-be-2026-02
```

Immutable corrected baseline commit:

```text
44b52082d4175af4c5fa92a107e87004f67fa418
```

## First establish whether it really failed

Correlate all of the following before declaring a terminal failure:

1. The current process tree for `run-campaign.sh`,
   `shepherd-task-25-given-list.sh`, Stage 30, Stage 40, Copilot, Maven, and
   GitHub CLI children.
2. The top-level log's final lines, modification time, and driver exit status
   if available.
3. The campaign run directory's per-phase Markdown, JSONL, job logs,
   post-mortem, and final response markers.
4. GitHub issue, pull request, branch, commit, review, and Actions state.
5. Local and remote campaign-branch heads.

A string such as:

```text
SHEPHERD FAILED: no completed correction
```

inside an `assistant.tool_call_delta`, shell fallback source, or other
streaming JSON fragment is not by itself a Shepherd result. Determine the
semantic outcome from the completed Copilot response and from independently
verified GitHub state.

Conversely, do not assume that application work failed merely because the
controller exited nonzero. A prior Shepherd campaign completed substantive
Stage 40 work but failed afterward in its JSONL redaction/export pipeline.

## Classify the failure

Distinguish among at least these categories:

1. **Implementation defect**
   - Production behavior, tests, compilation, or runtime acceptance genuinely
     failed.
2. **Fixture plan contradiction**
   - The task requires behavior or evidence that repository gates forbid,
     while the task scope forbids or omits the gate change needed to make it
     possible.
3. **Stale or incorrect fixture research**
   - The plan assumes a runtime, test environment, compiler level, API, or
     repository behavior that the prepared baseline does not have.
4. **Shepherd lifecycle/controller defect**
   - The implementation and GitHub lifecycle succeeded, but orchestration,
     semantic verification, redaction, export, or state reconciliation failed.
5. **Transient infrastructure failure**
   - GitHub, Actions, networking, Copilot, or the local machine interrupted an
     otherwise satisfiable task.
6. **Operationally difficult but satisfiable gate**
   - The task is possible, but its browser, runtime, timing, or evidence
     requirements were not successfully executed.

Do not label a failure as an implementation defect until fixture and baseline
contracts have been compared.

## Fixture plan contradiction test

Treat a task as contradictory when the evidence establishes an unsatisfiable
set similar to:

```text
The issue requires A.
Repository CI rejects A.
The issue forbids or does not authorize changing the CI rule that rejects A.
The completion gate still requires proof of A.
```

For any suspected contradiction, quote and correlate:

- the exact generated issue requirement;
- its completion gates;
- its allowed and forbidden file scope;
- the relevant ignorance-reduction-plan text;
- the actual baseline source or CI assertion;
- the failing workflow step and log;
- any corrective-agent attempts and why none could satisfy every constraint.

Explicitly distinguish:

- mandatory requirements from optional guidance;
- conditional gates from unconditional completion gates;
- exact-cardinality assertions from extensible minimum or named-invariant
  assertions;
- a plan error from an agent choosing a poor implementation.

## Previous confirmed contradiction

The first disposable campaign failed on its first task because:

```text
required BookingServiceTest methods = 5
Main Build required exactly 4
workflow/configuration changes were forbidden
```

Open Liberty integration tests passed 5/5, all local package tests passed, and
the feature implementation was substantively correct. Main Build alone failed
because `.github/workflows/main.yml` contained:

```bash
test "$count" -eq 4
```

That baseline defect was repaired before this campaign. The corrected gate:

- requires the `BookingServiceTest` report;
- permits at least four tests;
- requires zero failures, errors, and skips;
- preserves the four historical named methods;
- permits the feature's fifth `testChangeDeadline` method.

Do not rediscover or reapply that old fix unless evidence shows the disposable
repository was prepared from the wrong baseline.

Previous failed campaign evidence is preserved in:

```text
/home/edburns/workareas/dd-3072166-tricked-out-cargotracker-run-01-shepherd-control/1-arrival-deadline-control-remove-before-merge/shepherd-tasks-4583b192-2c95-45de-a888-34bed4d26fdf-20261001-2346
```

Its post-mortem is:

```text
/home/edburns/workareas/dd-3072166-tricked-out-cargotracker-run-01-shepherd-control/1-arrival-deadline-control-remove-before-merge/shepherd-tasks-4583b192-2c95-45de-a888-34bed4d26fdf-20261001-2346/20261002-0021-post-mortem.md
```

## Anticipated contradiction risks in this campaign

### 1. Static test inventory versus new focused tests

Inspect:

```text
demo/scripts/ci/write-test-inventory.sh
```

The prepared baseline hardcodes exactly:

```text
8 active test classes
3 dormant test classes
```

It compares that inventory with every discovered `*Test.java`. A newly added
test class fails Main Build unless the inventory script is also changed.

#### Facade task, issue #3 / plan item 4.2

The generated issue optionally allows a new:

```text
DefaultBookingServiceFacadeTest.java
```

If the agent creates that class, the static inventory can fail. Because the
test and its corresponding completion gates are conditional, omitting the
optional test may be a valid resolution. Treat this as a conditional trap
unless the final issue wording or Shepherd enforcement makes it mandatory.

#### Backing-model task, issue #4 / plan item 4.3

The generated issue says:

```text
Add a container-free JUnit test where practical.
```

Its completion gate also says, without the same qualification, that focused
tests must discriminate successful parsing and delegation from malformed and
null inputs.

A likely new class:

```text
ChangeArrivalDeadlineDateTest.java
```

would fail the hardcoded inventory. The issue's declared implementation files
do not include `write-test-inventory.sh`.

If this task fails, determine whether the effective contract was:

```text
focused test required
new test class rejected by CI
CI inventory change outside issue scope
no existing in-scope test class suitable for the focused test
```

If all four are true, document this as another fixture plan contradiction,
not merely an agent failure.

Also examine whether a container-free success-path test was genuinely
practical without a mocking dependency, because the backing model closes a
PrimeFaces dynamic dialog after successful delegation.

### 2. Stale Java version statement

The installed plan contains stale wording approximately equivalent to:

```text
Preserve the Java 7 source/target level used by this historical codebase.
```

The actual repository contract is Java 17:

```xml
<maven.compiler.release>17</maven.compiler.release>
```

Compatibility CI also enforces Java 17. The generated issue bodies were
observed using Java 17 wording rather than repeating the Java 7 instruction,
so this was not yet considered a proven blocking contradiction.

If an agent changes compiler configuration, rejects Java 17 APIs because of
the stale statement, or otherwise acts on Java 7 assumptions, identify the
stale plan statement as the source.

### 3. Browser and live-runtime acceptance

Issues #5 and #6 require dynamic PrimeFaces dialog/dashboard behavior and
runtime validation under Open Liberty. Existing Destination dialog code shows
that the proposed PrimeFaces APIs and design pattern are available.

These gates may still be operationally difficult to automate. Distinguish:

- a genuinely impossible contract;
- lack of browser tooling;
- an Open Liberty startup/readiness failure;
- JSF state or dialog interaction difficulty;
- failure to retain evidence;
- a real application defect.

Do not call operational difficulty a fixture contradiction without proving
that the task requirements cannot be satisfied in the provided environment.

## Important campaign files

Installed resolved plan:

```text
/home/edburns/workareas/dd-3072539-tricked-out-cargotracker-run-01-shepherd-control/1-arrival-deadline-control-remove-before-merge/add-change-arrival-deadline-feature-ignorance-reduction-plan.md
```

Generated issue bodies:

```text
/home/edburns/workareas/dd-3072539-tricked-out-cargotracker-run-01-shepherd-control/1-arrival-deadline-control-remove-before-merge/prompts/
```

Campaign state:

```text
/home/edburns/workareas/dd-3072539-tricked-out-cargotracker-run-01-shepherd-control/1-arrival-deadline-control-remove-before-merge/shepherd-campaign.json
```

Experiment metadata:

```text
/home/edburns/workareas/dd-3072539-tricked-out-cargotracker-run-01-shepherd-control/1-arrival-deadline-control-remove-before-merge/shepherd-test-experiment.json
```

Authoritative baseline workflow:

```text
/home/edburns/workareas/dd-3016202-cargotracker-devoxx-be-2026-02/.github/workflows/main.yml
```

Authoritative baseline evidence:

```text
/home/edburns/workareas/dd-3016202-cargotracker-devoxx-be-2026-02/1-trick-out-01-remove-before-merge/evidence-matrix.md
```

## Investigation rules

- Use `gh` for GitHub state.
- Preserve the failed repository and all local run artifacts.
- Do not launch another `run-campaign.sh` against this repository.
- Do not assume the top-level log contains detailed per-issue output.
- Inspect the exact phase transcript and JSONL associated with the failed
  issue.
- Do not treat a corrective cloud-agent commit as proof of success; verify its
  exact SHA and hosted checks.
- Do not treat a red CI check as proof of bad application code; inspect the
  failing assertion.
- Do not weaken repository safety gates merely to make the campaign pass.
- Do not change unrelated authoritative source or fixture code.
- If proposing a repair, identify whether it belongs in:
  - the authoritative Cargo Tracker baseline;
  - the Shepherd fixture plan;
  - Stage 20 issue generation;
  - Shepherd orchestration;
  - or the disposable campaign implementation.

## Requested response

Report:

1. **Actual current/terminal state**
   - active or exited processes;
   - active issue and stage;
   - pull request and commit state;
   - exact failing workflow run, job, and step.
2. **Substantive implementation state**
   - what passed;
   - what failed;
   - whether the feature work itself is correct.
3. **Root cause classification**
   - implementation defect, fixture contradiction, stale research,
     lifecycle/controller defect, transient infrastructure, or operational
     difficulty.
4. **Contract proof**
   - quote the relevant issue, plan, CI, and scope clauses;
   - show whether the constraints were satisfiable.
5. **Recovery options**
   - preserve-first immediate action;
   - least disruptive continuation, if possible;
   - authoritative baseline or fixture repair needed before a fresh run;
   - whether any already completed issue or pull request must not be rerun.
6. **Recommendation**
   - state plainly whether to resume, retry one issue, repair Shepherd, repair
     the fixture/baseline and start fresh, or preserve the run as a failed
     experiment.

Do not perform the recovery until I approve it.
