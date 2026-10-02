# Fix evidence-only Shepherd Task remediation with deterministic scripts

Implement the focused remediation fix described below, but ONLY after the recovery campaign has completed successfully and its evidence has been published. This prompt is prepared on October 2, 2026; it does not assert that recovery has finished.

## First: enforce the evidence-preservation prerequisite

Use `gh` for GitHub access. Inspect current state rather than trusting historical observations in this prompt.

Recovery repository: `edburns/dd-3072707-tricket-out-cargotracker-run-03`.
Campaign ID: `a63d175f-0ce7-4430-850d-c134a707f88c`.
Campaign branch: `edburns/dd-3016202-cargotracker-devoxx-be-2026-add-feature-control`.
Local control worktree:
`/home/edburns/workareas/dd-3072707-tricket-out-cargotracker-run-03-shepherd-control`.
Metadata directory: `1-arrival-deadline-control-remove-before-merge`.

Before modifying any harness code, skills, issues, installation, or campaign state, verify:

1. Child issues 2, 3, 4, 5, and 6 are closed and their authoritative linked PRs are merged into the campaign branch in serial order. Parent issue 1 may remain open.
2. The original run, `shepherd-tasks-a63d175f-0ce7-4430-850d-c134a707f88c-20261002-1414`, remains recorded as failed. Its manifest reports exit code 1 and completion at `2026-10-02T19:32:25Z`. Do not rewrite that outcome.
3. The resumed Stage 25 attempt for issue 6 has succeeded, its Stage 50 post-mortem exists, the existing final campaign verifier has passed, and final feature acceptance evidence is preserved. The known recovery directory is `shepherd-tasks-a63d175f-0ce7-4430-850d-c134a707f88c-20261002-2058`; locate any later attempts explicitly rather than silently choosing one.
4. The original and recovery manifests, transcripts, post-mortems, CI identifiers/results, manual validation evidence, and intervention chronology are durably published. Verify actual remote artifacts/commits, not merely local files or tracking refs. Original evidence was published at commit `f586a46fdbe252b57b2cf473361256cc8e225361`; that commit alone is NOT proof that recovery evidence was published.
5. No campaign or post-mortem process is still using the installation that would be affected.

The recovery was launched with the unchanged installed Stage 25 script, passing only issue `6`. A successful recovery manifest therefore legitimately contains `taskIssues: [6]`; combine it with the preserved original attempt for campaign-wide accounting. Do not demand a fabricated successful five-task manifest or an uninterrupted autonomous success.

If any prerequisite is false, unknown, or inaccessible, STOP and report the exact missing evidence. Do not finish the campaign, launch another paid session, approve workflows, modify acceptance criteria, dismiss reviews, install a plugin, or fix the harness to bypass this prerequisite.

## What failed, in plain language

The agent was asked to supply missing test/browser evidence on a PR, not necessarily change application code. It completed its work cycle without a new commit. Shepherd treated "no new commit" as "remediation never completed" and timed out instead of evaluating whether the requested evidence had been supplied.

There was also a publication problem: the cloud agent claimed to have updated the PR description, but the live description did not contain the promised detailed evidence. These are separate problems. Allowing unchanged-HEAD completion must NOT convert an unverified publication claim into acceptance.

### Concrete incident

- Task: `edburns/dd-3072707-tricket-out-cargotracker-run-03#6`.
- PR: `edburns/dd-3072707-tricket-out-cargotracker-run-03#11`.
- Original validation HEAD: `0f9cebb0aed65a80c215270ee73fa2d584a9e0ef`.
- Requested-changes review: `5395715707`, submitted at `2026-10-02T19:05:50Z`.
- Remediation `copilot_work_started`: `2026-10-02T19:06:35Z`.
- Remediation `copilot_work_finished`: `2026-10-02T19:13:40Z`.
- Remote remediation workflow: `37051867014`, job `110986971229`.
- Agent comment claiming evidence publication: `5959630120`.
- The agent completed within the ten-minute window, but HEAD remained unchanged.
- The final local Stage 30 transcript reported `SHEPHERD FAILED` with a no-remediation-push diagnostic.

The Actions log showed prompt dispatch at approximately 19:06:46 UTC, validation-related commands, browser tooling, and a successful `report_progress` call. The log did not expose enough tool arguments/results to establish why the claimed PR-body update was absent. Do not invent an API failure or independently certify the agent's reported browser results from tool-success summaries.

This was NOT the earlier 700-second MCP discovery delay, and it was NOT solely the changed-HEAD/incomplete-cycle defect. Increasing a timeout cannot fix an intentionally unchanged HEAD.

### Manual recovery already undertaken

The maintainer independently built and exercised the PR revision, published evidence in the PR description, and dismissed the specific missing-evidence review with an explanatory message. Main Build `37051113910` and Shepherd task Cargo Tracker `37051113953`, attempt 2, both passed on the original validation HEAD. The PR remained draft for normal resumed validation.

Browser evidence comments include `5960567014`, `5960583559`, `5961226502`, and `5961248159`. The latter records updated date `01/12/2027` surviving refresh and dialog reopening.

An earlier manual test accidentally ran the pre-feature `shepherd-target` baseline at `89e107c3ed6dd3655c2ffdf638b57d6c47099dab`. Its missing edit control was expected. Do not confuse that run with PR validation.

Use published campaign evidence as the durable source. Supplemental observer artifacts may be available locally under:
`/home/edburns/.copilot/session-state/877c7d0a-201d-4fbc-8a48-e5f9a1d33089/files/`.
Relevant filenames include `task5-failure-diagnosis.json`, `task5-remediation-agent.log`, `task5-pr11-failure-evidence.json`, `manual-ci-reruns-20261002-2022.json`, and `manual-recovery-handoff-20261002-2055.json`.

## Implementation repository and scope

This prompt is stored in a Cargo Tracker preparation repository for convenience. The fix belongs in `edburns/awesome-copilot`, normally checked out at:
`/home/edburns/workareas/awesome-copilot-03`.

Read its current contributor instructions, working-tree status, branch, and source before editing. The investigated source and installed revision was `3dd3749db96fba7514c229c200591e24a22a8bd5`, with version label 1.0.4. Do not reset to that revision or overwrite later work.

Read the current bodies and relevant discussion of:

- `edburns/awesome-copilot#1`: extract deterministic lifecycle gates from skill prose.
- `edburns/awesome-copilot#15`: changed-HEAD/incomplete-cycle timeout defect.
- `edburns/awesome-copilot#3`: separate bounded progress-aware remediation policy.
- `edburns/awesome-copilot#16`: DEFERRED redaction performance/visibility work.

Implement a narrow slice consistent with #1, not its entire campaign. Do not automatically launch the planning or paid campaign workflows described in those issue bodies.

Issue #15 currently requires failure for a finished cycle without a new HEAD. That is the old policy and conflicts with this fix. Explicitly explain the changed policy and the affected tests; do not silently implement contradictory criteria. Keep unrelated deadline extensions, progress leases, grace periods, and whole-stage automatic retries from #3 out of scope.

Do NOT implement #16. Do not optimize redaction, change application code, rewrite campaign evidence, or reinstall the plugin as part of this task.

## Required design

### Execute the lifecycle gate as maintained code

Move the focused remediation lifecycle state machine behind committed executable helpers, using repository-compatible Bash/PowerShell interfaces and existing dependencies. Inspect prior art first and reuse existing helpers where suitable.

The skill must invoke the shipped helper, not translate a Markdown polling example into another ad hoc loop. Do not leave competing authoritative implementations in prose and scripts. Keep skill content limited to invocation, result interpretation, and reasoning-heavy requirement assessment.

Trace and wire every relevant Stage 30 remediation entry, including pre-ready review remediation. Ensure source-checkout, installed-plugin, and composed/published-plugin layouts include and locate the helpers. Avoid relying on this preparation directory or observer session artifacts at runtime.

### Separate lifecycle completion from acceptance

Inputs must explicitly identify repository, issue, authoritative PR, expected base, original HEAD, remediation-request boundary, and bounded wait policy. Do not depend on stale ambient shell variables.

Capture an attempt boundary before the triggering mutation so a fast new work cycle cannot be missed. Correlate start/finish observations with that attempt, handle pagination and same-second events, and reject stale or unrelated events. Use monotonic elapsed time for bounded polling and UTC timestamps for diagnostics.

Required behavior:

| Observation | Outcome |
|---|---|
| No fresh cycle starts | Follow the existing bounded re-engagement/reassignment policy, then fail accurately if exhausted |
| HEAD changes but current cycle is unfinished | Continue waiting within the existing bound; fail distinctly at expiry |
| Fresh cycle finishes and HEAD changes | Return completed-cycle state; invalidate old revision evidence and revalidate the new HEAD |
| Fresh cycle finishes and HEAD is unchanged | Return completed-cycle state with unchanged HEAD; reevaluate the requested evidence/deliverable |
| Only an old finish exists | Do not accept completion |
| API/query/parse failure or PR linkage/base/state invariant violation | Explicit fail-closed result, not a missing-event default or success |
| Explicit failed agent cycle | A distinct failure result consistent with existing policy; never silently classify it as successful completion |

A completed-cycle result is NOT `SHEPHERD COMPLETE` and is NOT permission to mark ready or merge.

Return a versioned machine-readable result with outcome category, attempt identity/boundary, original/current HEAD, relevant event identities/timestamps, elapsed time/budget, and reassignment information. Align exit semantics with repository conventions and distinguish completed-cycle, timeout, invalid-state, and API failure.

Preserve existing configured timeouts, cadence, retry caps, and full validation requirements. Do not reset an absolute deadline indefinitely through nested loops or repeated requests. If timeout values have changed independently, preserve those current values rather than reverting them to this incident's numbers.

### Verify the correction after completion

After either changed-HEAD or unchanged-HEAD completion, return to the normal issue-evidence and validation gates. Code corrections still require an effective implementation; evidence corrections still require actual published evidence.

For evidence publication:

- Re-fetch the authoritative PR description/comment/artifact actually required by the issue or remediation request.
- Read back a write before reporting it succeeded.
- Associate results with the exact tested HEAD and preserve command results and human-versus-agent provenance.
- Do not substitute a "done" comment for missing required detail.
- If the agent claims to have updated a description and it is unchanged, report the contradiction.
- If the correction is missing or inadequate, report ineffective remediation and use the existing bounded retry/failure policy. Do not loop indefinitely on finished but ineffective cycles.
- Do not require an empty commit, unrelated file change, or arbitrary evidence file merely to make HEAD change.

Keep assessment of browser behavior, substantive code correctness, and adequacy of evidence in the skill. Do not pretend a deterministic text-presence check can prove those judgments.

All existing final gates remain: authoritative issue linkage, correct base, open draft PR, nonempty effective PR diff, stable exact HEAD, issue acceptance, required commands, relevant substantive CI, review state, and immutable lesson mode. Do not auto-dismiss reviews or weaken criteria to achieve a passing campaign.

## Validation

Use deterministic offline tests with mocked `gh` and a simulated/no-op clock. Execute the actual runtime helpers, not a duplicate predicate or an example extracted solely for tests.

Cover at least:

1. Fresh finished cycle without a commit returns to validation.
2. Valid evidence-only update can satisfy the evidence gate without a dummy commit.
3. Claimed-but-unpublished evidence cannot pass.
4. Finished cycle with unchanged, inadequate implementation cannot pass acceptance.
5. New HEAD without a finish fails at the deadline, covering #15.
6. Missing/stale timestamps, old-cycle finishes, later starts, same-second events, and multiple timeline pages.
7. A completed new cycle with changed HEAD invalidates earlier evidence.
8. No re-engagement, reassignment, and per-attempt state reset.
9. Explicit agent failure, API failure, malformed responses, and authoritative PR/base/state drift.
10. Monotonic deadlines and bounded retry behavior; no real timeout-length sleeps.
11. Bash/PowerShell output and failure-category parity for supported environments.
12. Source and installed/published-layout invocation, including Step 8's reuse of the helper.
13. Outer Stage 30/25 semantic failure propagation remains fail-closed.

Extend existing plugin/skill and session-outcome contracts where appropriate. Update directly related documentation and use repository build tooling for generated content. Do not install dependencies unless needed by a manifest change or a missing-dependency failure.

Do not launch paid cloud-agent experiments, alter an active installation, push branches, create PRs, or change existing GitHub issue bodies without separate user authorization. If live cross-platform evidence required by #1 remains outstanding, report it as outstanding rather than claiming full campaign acceptance from offline tests.

## Deliverable

Implement and validate the focused fix locally after the prerequisite passes. Report:

- The exact behavioral change and why it prevents the observed unchanged-HEAD false timeout without treating missing evidence as success.
- Files changed and shipped invocation path.
- Exact test commands and results, plus unrun platform/live gates.
- The explicit policy conflict with #15 and suggested issue wording changes.
- Confirmation that application/campaign evidence, installed plugin, timeout policy, and deferred redaction work were not changed.

Do not claim the remote PR-publication problem itself is fixed unless there is direct evidence for that separate conclusion.
