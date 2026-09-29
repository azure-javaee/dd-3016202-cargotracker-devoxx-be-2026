# Understanding of the Goal

The goal is to prepare a complete, credible 50-minute Devoxx presentation in
three full workdays after Monday, September 28, 2026. The presentation argues
that Java's mature, ordinary, and sometimes boring ecosystem features make it
especially well suited to agentic software development.

The talk's thesis is not that Java agents are inherently smarter. It is that
Java projects can surround agents with strong constraints and feedback:

1. Type system
2. Testing ecosystem
3. Backwards compatibility culture
4. Deep static analysis
5. Build system maturity and dependency management
6. Code formatting and style enforcement
7. Virtual threads and structured concurrency
8. Observability stack
9. JVM performance tuning
10. Breadth of deployment options

These mechanisms can amplify agent strengths, such as speed, breadth, and
willingness to perform repetitive work, while limiting agent weaknesses such as
nondeterminism, hallucinated APIs, dependency sprawl, inconsistent error
handling, unreviewable changes, and code that works initially but is difficult
to maintain.

## Role of the Demo

The Cargo Tracker demo is the main source of evidence for the talk. The demo
should not merely show a completed feature. It should show what happens when
agents try to implement a real, layered Java feature inside a repository whose
development process has been deliberately strengthened with Java ecosystem
guardrails.

The experiment begins from a feature-absent Cargo Tracker baseline in the
lineage of commit `e7b651f`, chosen because it is a known-good Java 17 starting
point. Before asking agents to add the feature, the experiment branch will be
"tricked out": its CI/CD, tests, analysis, build rules, repository instructions,
observability, and other appropriate controls will be improved enough to make
the ten claims in the abstract testable where practical.

The fully instrumented but still feature-absent state will be tagged. That tag
will identify the exact starting point of the agentic implementation campaign
and make the demonstration reproducible.

## Shepherd Task's Role

Shepherd Task is the experiment's orchestration system and a means to an end.
It is not the primary subject of the talk.

The Shepherd Task lifecycle stages initialize campaign state, turn a resolved
plan into ordered issues, dispatch those issues, supervise Copilot Coding Agent
work, enforce CI and review gates, merge successful changes serially, and
produce persistent run evidence and a post-mortem.

Those lifecycle stages must be kept distinct from the Cargo Tracker
implementation activity performed by the agents. The implementation campaign
adds the Change Arrival Deadline feature through five ordered engineering
increments:

1. Add the application-layer operation that changes a cargo's arrival deadline
   through the existing domain model.
2. Expose that operation through the booking facade without leaking domain
   types into the web layer.
3. Implement the JSF backing model that loads, validates, and submits the
   editable deadline.
4. Implement the PrimeFaces dynamic dialog used to edit the deadline.
5. Integrate the operation into the Administration dashboard and verify the
   complete behavior on the running Open Liberty application.

The fixture at
`awesome-copilot-03/plugins/shepherd-task/test/cargotracker-add-change-arrival-deadline-feature/run-campaign.sh`
provides a known end-to-end way to exercise Shepherd Task against this resolved
five-issue implementation plan. It is the outer experimental harness. The five
Cargo Tracker issues are the inner implementation sequence whose behavior and
outcomes matter to the talk.

## Intended Experiment

The high-level preparation and execution sequence is:

1. Establish the intended feature-absent Cargo Tracker starting point on the
   experiment branch.
2. Add enough repository and CI/CD instrumentation to make relevant Java
   safeguards visible during agentic development.
3. Verify that the instrumented baseline is usable and tag it.
4. Run the Change Arrival Deadline Shepherd Task campaign.
5. Preserve and inspect the campaign's issues, pull requests, commits, CI
   results, tests, review findings, corrections, logs, telemetry, and
   post-mortem.
6. Determine which of the ten boring reasons materially affected the agents'
   work.
7. Use the strongest observations as the concrete evidence in the
   presentation.

The experiment does not need to prove that all ten reasons influence this one
feature. Some may have direct and visible effects, some may provide passive
safety, and some may not be exercised meaningfully. The desired result is
honest evidence about which Java safeguards helped, what failure modes they
addressed, and where the abstract's hypothesis is or is not supported.

## Continuous Green CI Invariant

Every incremental change made on
`edburns/dd-3016202-cargotracker-devoxx-be-2026-experiment` must preserve a
green CI state. Tricking out the demo is not a sequence in which several broken
intermediate states are accumulated and repaired at the end. Each step must be
small enough to validate, and its required GitHub Actions checks must succeed
before work proceeds to the next step.

Two successful `Main Build` runs provide known-green reference points:

- [Run 36182474700](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/actions/runs/36182474700),
  for commit `c8e8ca7944ac7b25e169cdd2b07714b7326542c0`
- [Run 36183229399](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/actions/runs/36183229399),
  for commit `c4ae1b9020214e64547f72d9da5f116c1983897a`

Both runs completed the existing jobs successfully:

1. `formatting`, which uses Microsoft Build of OpenJDK 17 and runs
   `./mvnw spotless:check` in `demo`
2. `build`, which uses Microsoft Build of OpenJDK 17 and runs
   `./mvnw clean package --file pom.xml` in `demo`

These runs are behavioral baselines for the current workflow, not proof that
future experiment-branch commits are green. The current `push` trigger in
`.github/workflows/main.yml` names only
`edburns/dd-3016202-cargotracker-devoxx-be-2026-01`. Before relying on automatic
push validation during demo iteration, the workflow or operating procedure
must ensure that every experiment-branch increment receives an authoritative
GitHub Actions run. Until the trigger is updated, this requires a pull-request
run or an explicit `workflow_dispatch` run for the experiment commit.

As the workflow is expanded, each new guardrail must be introduced without
discarding or bypassing previously green checks. A failed required check stops
the current preparation step: diagnose it, correct it, and restore green status
before adding another change. The instrumented pre-campaign tag may be created
only from a commit whose complete required workflow set is green.

## Evidence to Seek

Useful evidence includes situations in which:

- the compiler or type system rejects an invalid agent decision;
- tests catch a behavioral or architectural regression;
- backwards compatibility requirements prevent an inappropriate migration;
- static analysis identifies a defect or maintainability problem;
- Maven dependency or build controls prevent dependency sprawl or an invalid
  build;
- formatting and style checks keep independently generated changes consistent;
- concurrency facilities make a correct implementation easier to express or
  verify;
- observability makes an agent-created runtime problem diagnosable;
- JVM behavior or performance evidence changes an implementation decision; or
- the same verified application can be built and exercised through realistic
  deployment machinery such as Open Liberty and GitHub Actions.

Negative and mixed results are also useful. A safeguard that the agents bypass,
misunderstand, or fail to benefit from may reveal what additional repository
engineering is required to make Java development genuinely agent-safe.

## Worktree Boundaries

Non-demo preparation belongs on branch
`edburns/dd-3016202-cargotracker-devoxx-be-2026-01` in worktree
`/home/edburns/workareas/dd-3016202-cargotracker-devoxx-be-2026-00`. This
includes text notes and preparation artifacts. Slide construction is outside
the scope of Copilot assistance.

Demo implementation and experimentation belong on branch
`edburns/dd-3016202-cargotracker-devoxx-be-2026-experiment` in worktree
`/home/edburns/workareas/dd-3016202-cargotracker-devoxx-be-2026-02`.

Branch `edburns/dd-3016202-cargotracker-devoxx-be-2026-control` is the untouched
control branch and must not be modified during talk preparation.

## Definition of Success

The preparation succeeds when there is a reliable, rehearsable demonstration
that begins from a tagged and instrumented feature-absent state, runs the
five-part agentic implementation campaign, and produces enough understandable
evidence to support a practical 50-minute argument about Java and agentic
development.

The final message should remain grounded: Java's established ecosystem does not
eliminate agent mistakes, but it supplies unusually mature ways to constrain,
detect, explain, and correct them. Moving agentic development forward may
depend on returning to these proven engineering disciplines.
