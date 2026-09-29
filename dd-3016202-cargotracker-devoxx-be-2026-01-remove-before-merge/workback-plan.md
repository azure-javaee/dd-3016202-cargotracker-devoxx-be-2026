# Workback Plan: First Complete Presentation Draft

## Objective

By Friday afternoon, October 2, 2026, produce a reasonable first draft of the
entire 50-minute presentation:

- a complete slide deck draft;
- a coherent beginning-to-end talk narrative;
- a working and reproducible Cargo Tracker demo path;
- concrete evidence connecting agentic-development failure modes to the ten
  boring Java reasons;
- a timed rehearsal with identified cuts, gaps, and follow-up work.

This is a first complete draft, not the final conference-ready presentation.
Completeness, a defensible thesis, and a reliable demonstration are more
important this week than polishing every slide or proving every reason equally.

The four available workdays are:

1. Tuesday, September 29, 2026
2. Wednesday, September 30, 2026
3. Thursday, October 1, 2026
4. Friday, October 2, 2026

## Non-Negotiable Invariants

1. Non-demo preparation belongs on
   `edburns/dd-3016202-cargotracker-devoxx-be-2026-01` in worktree
   `/home/edburns/workareas/dd-3016202-cargotracker-devoxx-be-2026-00`.
2. Demo preparation belongs on
   `edburns/dd-3016202-cargotracker-devoxx-be-2026-experiment` in worktree
   `/home/edburns/workareas/dd-3016202-cargotracker-devoxx-be-2026-02`.
3. Do not modify
   `edburns/dd-3016202-cargotracker-devoxx-be-2026-control`.
4. Every incremental experiment-branch change must leave required GitHub
   Actions CI green before the next change proceeds.
5. Do not tag the tricked-out pre-feature baseline until its complete required
   workflow set is green.
6. Shepherd Task lifecycle stages and Cargo Tracker implementation stages must
   remain distinct in notes, slides, and explanations.
7. Shepherd Task is the repeatable orchestration mechanism, not the primary
   subject of the talk.
8. Use Azure for any cloud deployment.
9. The presentation must report negative or inconclusive evidence honestly.
   It is not necessary for all ten reasons to produce equally strong results.

## Active Work Threads

The Azure DevOps tracker state as of Tuesday, September 29, 2026 is:

| Work item | Tracker title | Type | State | Risk | Parent |
|---|---|---|---|---|---|
| [`dd-3069276-build-workback-plan`](https://devdiv.visualstudio.com/DevDiv/_workitems/edit/3069276) | Build workback plan | Task | In Progress | High | [`dd-3068359-10-boring-reasons-ideation`](https://devdiv.visualstudio.com/DevDiv/_workitems/edit/3068359) |
| [`dd-3070726-first-agentic-run`](https://devdiv.visualstudio.com/DevDiv/_workitems/edit/3070726) | 10 boring reasons: first agentic run | User Story | In Progress | High | [`dd-3016202-2026-devoxx-belgium`](https://devdiv.visualstudio.com/DevDiv/_workitems/edit/3016202) |
| [`dd-3070749-slides-first-draft`](https://devdiv.visualstudio.com/DevDiv/_workitems/edit/3070749) | Slides first draft | User Story | In Progress | High | [`dd-3016202-2026-devoxx-belgium`](https://devdiv.visualstudio.com/DevDiv/_workitems/edit/3016202) |

All three active items are assigned to Ed Burns. The workback-plan task is a
child of the ideation story, while the two execution threads are direct
children of the Devoxx experience. This plan coordinates them operationally
even though their tracker parents differ.

### `dd-3069276-build-workback-plan`

Owns this plan and its daily adjustment. The plan should be updated when a
critical-path assumption changes, but planning must not displace execution.

### `dd-3070726-first-agentic-run`

Uses Shepherd Task v1.0.4 to trick out the Cargo Tracker experiment branch.
The campaign metadata directory is:

```text
1-trick-out-01-remove-before-merge
```

Stage 00 has already initialized the campaign manifest and lessons file. The
next action is to invoke
`shepherd-task-10-create-ignorance-reduction-plan`, then resolve every
implementation-gating question before creating implementation issues.

The intended implementation concerns are:

- **Foundation:** build/dependency management and backwards compatibility
  (reasons 5 and 3)
- **Fast deterministic gates:** formatting/style, type-system enforcement, and
  deep static analysis (reasons 6, 1, and 4)
- **Behavioral verification:** tests at appropriate layers (reason 2)
- **Runtime evidence:** observability and JVM performance tuning
  (reasons 8 and 9)
- **Compatibility-breaking capability spike:** virtual threads and structured
  concurrency without destabilizing the Java 17 baseline (reason 7)

### `dd-3070749-slides-first-draft`

Owns the slide deck. Slide construction does not occur in this Copilot session,
but it must run in parallel with demo preparation. The slide author must not
wait for all demo evidence before drafting the complete narrative. Unknown
evidence should be represented by explicit placeholders and replaced as
campaign results arrive.

## Additional Required Workstreams

These activities are required for a complete presentation even if they do not
yet have separate work items.

### Evidence matrix and talk narrative

Maintain a single matrix with one row per boring reason and these columns:

| Field | Meaning |
|---|---|
| Reason | The ordered reason from the abstract |
| Agentic failure mode | The weakness it is meant to constrain |
| Repository mechanism | Compiler, Maven, test, analyzer, workflow, telemetry, or deployment control |
| Implementation task | The trick-out issue that introduces or verifies it |
| Observed campaign event | A concrete success, failure, correction, or non-event |
| Artifact | CI run, log, PR, review, trace, JFR, screenshot, or post-mortem |
| Confidence | Strong, moderate, weak, unsupported, or not exercised |
| Slide implication | Main slide, brief mention, appendix, or cut |

This matrix is the bridge between the engineering work and the slide deck.

### Azure deployment for reason 10

Reason 10, breadth of deployment options, requires an actual Azure deployment
to provide credible evidence. The minimum acceptable first-draft result is one
repeatable Azure deployment of the same Cargo Tracker artifact or container
used by the demo. A second Azure execution model is desirable but is a stretch
goal for this week.

Prefer the least disruptive target that can run the existing Open Liberty
application without forcing an unrelated application rewrite. Record the
deployment commands, runtime configuration, successful health check, and
cleanup procedure. Do not allow this workstream to destabilize the main
experiment branch or block completion of the first full slide draft.

### Feature campaign and evidence collection

After the tricked-out baseline is green and tagged, run the resolved Change
Arrival Deadline campaign against that baseline. Preserve:

- campaign metadata and ignorance-reduction plan;
- ordered child issues;
- implementation PRs and review history;
- all required GitHub Actions runs;
- Copilot CLI session artifacts;
- OpenTelemetry output;
- test, analyzer, and build artifacts;
- runtime logs, profiles, and performance evidence;
- the Shepherd Task post-mortem.

This feature campaign is where the talk's hypothesis is tested. The trick-out
campaign creates the guardrails; the feature campaign reveals whether agents
use, trigger, or benefit from them.

### Demo hardening and rehearsal

Prepare both:

1. a live demonstration path; and
2. a fallback path using captured terminal output, screenshots, workflow runs,
   logs, traces, profiles, and PR evidence.

The presentation must remain deliverable if GitHub, Azure, networking, or a
long-running agentic operation is unavailable during the talk.

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

## Day-by-Day Workback

## Tuesday, September 29: Plan, Start the Campaign, Draft the Whole Story

### Primary outcome

End Tuesday with the trick-out campaign fully specified and started, plus a
complete slide-deck skeleton covering the entire talk.

### `dd-3069276-build-workback-plan`

- Complete and commit this workback plan.
- Establish the evidence matrix.
- Define the Friday acceptance criteria and the Wednesday/Thursday cut lines.
- Identify any required new tracking items for Azure deployment, feature
  campaign execution, evidence synthesis, and rehearsal.

### `dd-3070726-first-agentic-run`

1. Source the Shepherd Task environment:

   ```bash
   source dd-3058828-cargotracker-remove-before-merge/setenv.sh
   ```

2. Verify Shepherd Task v1.0.4 and the campaign manifest.
3. Invoke `shepherd-task-10-create-ignorance-reduction-plan`.
4. Create the plan inside `1-trick-out-01-remove-before-merge`.
5. Resolve every implementation-gating ignorance-reduction question using:
   - the abstract;
   - `20260928-sol-understanding-of-goal.md`;
   - the actual Cargo Tracker Maven, test, Open Liberty, and workflow state;
   - the continuous-green CI invariant;
   - Microsoft Learn guidance for Microsoft Build of OpenJDK, `jaz`, and
     Application Insights.
6. Convert the implementation into ordered, independently green issues.
7. Run Stage 15 and Stage 20 as soon as the plan is resolved.
8. Start Stage 25 on Tuesday if the ordered issues are ready.

### `dd-3070749-slides-first-draft`

Create a complete slide skeleton with placeholders, not polished slides:

1. personal credibility and historical perspective;
2. current agentic-development hype and failure modes;
3. thesis: boring Java mechanisms keep agents honest;
4. Cargo Tracker and the experiment design;
5. Shepherd Task as orchestration, clearly separated from feature
   implementation;
6. one section for each of the ten reasons;
7. practical agent-safe Java checklist;
8. conclusion: to move forward, go back.

### Tuesday exit gate

- The ignorance-reduction plan exists and all implementation-gating questions
  are resolved.
- Ordered implementation issues exist or Stage 20 is actively producing them.
- The slide deck has a beginning, middle, end, and a placeholder for all ten
  reasons.
- The evidence matrix exists.
- No experiment-branch step has proceeded past a red CI result.

## Wednesday, September 30: Execute the Trick-Out Campaign and Build Evidence

### Primary outcome

End Wednesday with the highest-value repository guardrails implemented and
green, while replacing slide placeholders with real engineering evidence.

### `dd-3070726-first-agentic-run`

- Run the ordered issues serially with Shepherd Task.
- Do not allow a later issue to hide or bypass a failed earlier gate.
- After each merged task:
  - confirm required CI is green;
  - record the exact run and commit;
  - update the evidence matrix;
  - note useful agent mistakes, review findings, and corrections;
  - preserve artifacts that can appear in slides or the fallback demo.
- Prioritize completion in this order:
  1. authoritative experiment CI;
  2. build/dependency and compatibility foundation;
  3. testing safety net;
  4. formatting/type/static-analysis gates;
  5. observability;
  6. performance evidence;
  7. concurrency spike.

The first four items are the minimum viable trick-out baseline. Runtime
evidence is next. The concurrency spike is the first explicit cut candidate.

### `dd-3070749-slides-first-draft`

- Turn the skeleton into a complete rough deck.
- Give each reason:
  - the agentic failure mode;
  - the Java safeguard;
  - the intended demo or evidence;
  - a placeholder for the observed result.
- Draft the experiment diagram and five-step Change Arrival Deadline feature
  diagram.
- Avoid explaining every Shepherd Task stage in the main narrative. Put
  orchestration detail in backup slides unless it directly explains evidence.

### Wednesday decision gate

At midday and end of day, classify every trick-out issue:

- complete and green;
- active and likely to complete;
- reducible to a smaller useful increment;
- defer to appendix/future work.

If the minimum viable baseline is not on track by Wednesday evening, cut the
concurrency spike first, reduce performance work to artifact capture rather
than enforcement, and prefer one useful analyzer over a broad analyzer suite.

### Wednesday exit gate

- Foundation and behavioral-verification work is complete or demonstrably on
  the final issue.
- The slide deck is complete in rough form.
- At least several reasons have concrete CI, PR, test, or review evidence.
- Thursday still has enough time for the feature campaign.

## Thursday, October 1: Freeze the Baseline and Run the Feature Experiment

### Primary outcome

End Thursday with a tagged, green tricked-out baseline and the Change Arrival
Deadline campaign completed or far enough along to provide strong evidence.

### Freeze the tricked-out baseline

- Complete the minimum viable trick-out issues.
- Run the full required workflow set.
- Confirm the experiment branch is clean, pushed, and green.
- Create and push an annotated tag identifying the pre-feature tricked-out
  baseline.
- Record the tag, commit, workflow runs, and included guardrails.
- Generate or recover the trick-out campaign post-mortem.

### Run the Change Arrival Deadline campaign

- Start from the tagged tricked-out baseline.
- Use the already resolved five-issue feature plan:
  1. application-layer deadline operation;
  2. booking-facade operation;
  3. JSF backing model;
  4. PrimeFaces dialog;
  5. Administration dashboard integration and acceptance.
- Run issues serially.
- For each issue, capture:
  - the agent's implementation choices;
  - compiler, build, formatting, analyzer, and test feedback;
  - code-review findings and fixes;
  - runtime or telemetry evidence;
  - whether an intended safeguard was silent, triggered, bypassed, or helpful.

### Azure deployment

- Produce at least one repeatable Azure deployment or complete the deployment
  path far enough to identify the remaining blocker precisely.
- Capture evidence suitable for reason 10 even if a second target is deferred.
- Keep Azure work from blocking the feature campaign or breaking the
  experiment branch.

### Slides and notes

- Replace placeholders with observed campaign evidence.
- Mark every reason as strong, moderate, weak, unsupported, or not exercised.
- Move weak or purely conceptual material to appendix slides.
- Draft the final practical checklist from the controls that actually helped.

### Thursday exit gate

- The green tricked-out baseline is tagged.
- The feature campaign has produced usable evidence and preserved artifacts.
- The deck contains actual results rather than only proposed demonstrations.
- The live demo path and fallback evidence path are documented.
- Remaining Friday work is synthesis, rehearsal, and correction, not invention
  of major new infrastructure.

## Friday, October 2: Synthesize, Rehearse, and Produce the First Full Draft

### Primary outcome

By Friday afternoon, have a complete, deliverable first draft of the
presentation and a prioritized list of post-draft improvements.

### Morning: evidence synthesis and demo hardening

- Finish or stop any remaining long-running campaign work by a fixed morning
  cut time.
- Generate/review Shepherd Task post-mortems.
- Finalize the evidence matrix.
- Verify the live demo from the documented starting point.
- Verify the fallback demo artifacts independently.
- Confirm all referenced GitHub Actions runs, PRs, logs, traces, profiles, and
  tags are durable and easy to locate.
- Validate the Azure deployment evidence or explicitly frame it as incomplete.

### Midday: complete the slide and note draft

- Replace remaining placeholders.
- Ensure all ten reasons appear, but allocate time according to evidence
  strength rather than giving each equal weight.
- Add transitions that preserve the central narrative:
  agent strength -> agent weakness -> Java guardrail -> observed evidence.
- Include a practical checklist the audience can apply.
- Keep Shepherd Task mechanics subordinate to the Java argument.

### Afternoon: timed rehearsal

Run at least one uninterrupted rehearsal. Target 43-45 minutes of planned
content so the live delivery has room for pauses, transitions, and demo
variance within the 50-minute slot.

Record:

- actual duration;
- sections that drag or repeat;
- slides without a clear claim;
- demos with excessive setup or risk;
- terminology that conflates orchestration and implementation;
- claims unsupported by evidence;
- transitions that require speaker notes.

Make one focused revision pass after rehearsal. Do not begin a new major
engineering workstream Friday afternoon.

### Friday completion criteria

The first draft is complete when:

- the deck can be presented from beginning to end;
- the talk fits the time budget with reasonable buffer;
- the thesis is understandable without explaining Shepherd Task internals;
- the Cargo Tracker experiment is reproducible from a tagged green baseline;
- the feature implementation has usable campaign evidence;
- each boring reason has an honest evidence classification;
- reason 10 has Azure deployment evidence or a clearly disclosed gap;
- a live demo and a fallback path both exist;
- remaining work is captured as prioritized refinement rather than missing
  structure.

## Suggested 50-Minute Narrative Budget

This is a starting constraint for the slide thread, not a requirement to give
every reason equal time.

| Section | Target |
|---|---:|
| Opening, credibility, and agentic failure modes | 5 minutes |
| Thesis and experiment design | 5 minutes |
| Foundation and deterministic guardrails | 10 minutes |
| Testing and behavioral verification | 7 minutes |
| Runtime observability and JVM evidence | 7 minutes |
| Concurrency and deployment breadth | 5 minutes |
| Cargo Tracker campaign results and synthesis | 6 minutes |
| Practical checklist and conclusion | 5 minutes |

## Cut Order if Time or Campaign Execution Slips

Cut scope in this order while preserving the talk's thesis:

1. A production-quality virtual-thread/structured-concurrency implementation;
   retain a bounded spike or explain the Java 17 compatibility constraint.
2. A second Azure deployment target; retain one real Azure deployment.
3. Strict JVM performance regression gates; retain measurements and artifacts.
4. Multiple overlapping static analyzers; retain one useful deep analyzer plus
   existing formatting/compiler gates.
5. Broad UI automation; retain focused acceptance evidence for the deadline
   flow.

Do not cut:

- authoritative green CI on the experiment branch;
- the build/compatibility foundation;
- meaningful behavioral tests;
- the tagged pre-feature baseline;
- evidence collection from the feature campaign;
- the complete slide narrative;
- the Friday timed rehearsal.

## Known Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Shepherd Task issues take longer than expected | Start Stage 25 Tuesday; use explicit Wednesday cut lines; reduce issue scope without bypassing green CI |
| Legacy code produces overwhelming analyzer debt | Ratchet against new changes, baseline known findings, introduce one analyzer at a time |
| Performance results are noisy in hosted CI | Preserve JFR/GC/startup artifacts; use broad comparisons rather than brittle thresholds |
| Java 17 blocks virtual-thread demonstration | Use an isolated Java 21 spike or report the compatibility boundary honestly |
| Azure deployment becomes a migration project | Use the existing WAR/container with the least disruptive Azure target; limit this week to one credible deployment |
| Live agentic campaign is too slow for a talk | Present preserved issues, PRs, CI, reviews, telemetry, and post-mortem; do not run the full campaign live |
| Network, GitHub, or Azure is unavailable during delivery | Maintain a complete fallback path using durable captured artifacts |
| Slide work waits for engineering completion | Draft the entire deck Tuesday and replace evidence placeholders continuously |
| The talk becomes a Shepherd Task presentation | Keep lifecycle mechanics in backup slides and organize the main story around Java guardrails and observed agent behavior |

## Immediate Next Actions

1. Commit this workback plan on the non-demo preparation branch.
2. In worktree `...-02`, source the Shepherd Task environment and verify
   version 1.0.4.
3. Invoke `shepherd-task-10-create-ignorance-reduction-plan` for
   `1-trick-out-01-remove-before-merge`.
4. Resolve the plan completely and create ordered implementation issues.
5. Start the trick-out Stage 25 run as early Tuesday as possible.
6. Begin the complete slide skeleton in parallel under
   `dd-3070749-slides-first-draft`.
