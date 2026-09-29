# Spike 1.1: Authoritative experiment-branch CI path

Date: 2026-09-29

Plan question:
`1-trick-out-01-remove-before-merge/trick-out-01-ignorance-reduction-plan.md`,
section 1.1.

Repository:
`edburns/dd-3016202-cargotracker-devoxx-be-2026`

Experiment branch:
`edburns/dd-3016202-cargotracker-devoxx-be-2026-experiment`

## Question

Which GitHub Actions event and branch rules will prove that each commit merged
into the experiment branch passed the complete required workflow set?

## Result

Select **option D**:

1. Add the experiment branch to the `push.branches` list in
   `.github/workflows/main.yml`.
2. Retain `pull_request` validation.
3. Add a branch ruleset or branch protection for the experiment branch that
   requires the stable checks `formatting` and `build` before merge.
4. Treat the PR checks as the pre-merge gate.
5. Treat the experiment-branch push run as the authoritative validation of the
   exact merged campaign-base SHA.
6. Do not dispatch the next serial issue until the post-merge push run for that
   SHA is green and the preceding evidence-matrix update is visible on the
   campaign base branch.

The two event paths are **complementary**, not merely redundant:

- A `pull_request` run validates GitHub's synthetic PR merge ref. With the
  current workflow, `actions/checkout@v7` has no explicit `ref`, so it checks
  out the PR merge branch rather than only the contributor branch.
- A `push` run validates the actual commit now present at the tip of the
  experiment branch after the PR is merged.

The current repository has neither part of this enforcement:

- PR checks run, but no ruleset or branch protection requires them.
- Pushes to the experiment branch do not trigger `Main Build`.
- Manual dispatch works, but it depends on a human remembering to run and
  verify it.

## Observed repository state

### Repository and branch

| Field | Observed value |
|---|---|
| Repository visibility | Public |
| Default branch | `edburns/dd-3016202-cargotracker-devoxx-be-2026-01` |
| Experiment tip | `3016bc265e6301edb591b2c352363ccf75b18b63` |
| Experiment branch protected | `false` |
| Active repository rulesets | None |
| Active rules applying to experiment branch | None |
| Experiment branch required status checks | Off; no contexts or checks |

The REST branch-protection endpoint returned HTTP 404 with
`Branch not protected`.

### Current workflow triggers

The experiment branch's remote `.github/workflows/main.yml` is byte-for-byte
identical to the local file. Both produced SHA-256:

```text
232e4b6009937016c98de6e1e490e093e242e0601b011056323b8939dd0c1e40
```

Its trigger is:

```yaml
on:
  push:
    paths-ignore:
      - "docs/**"
    branches:
      - edburns/dd-3016202-cargotracker-devoxx-be-2026-01
  pull_request:
    types:
      - opened
      - synchronize
      - reopened
  workflow_dispatch:
```

Consequences:

- Pushes to `...-01` run automatically.
- Pull requests targeting any branch run automatically.
- The experiment branch can be tested manually.
- Pushes and merges to the experiment branch do not run automatically.

### Required-check candidates

Known green run `36182474700` used manual dispatch and had these successful
jobs:

```text
formatting
build
```

Known green run `36183229399` used the `push` event on the `...-01` branch and
had the same successful jobs:

```text
formatting
build
```

These are the current stable check names to require. The workflow name
`Main Build` is not the required-check context; the individual job/check names
are.

### Experiment-branch Actions history before the spike

Before this spike dispatched a run:

- the Actions API returned zero workflow runs for the experiment branch;
- the experiment tip had zero check runs;
- the experiment tip had zero commit statuses.

The combined commit-status endpoint reported `pending` only because no status
contexts existed; it did not represent a running check.

## Manual fallback verification

The spike dispatched the existing `Main Build` workflow against the exact
experiment tip without modifying the workflow:

| Field | Value |
|---|---|
| Run | `36619468411` |
| Event | `workflow_dispatch` |
| Branch | `edburns/dd-3016202-cargotracker-devoxx-be-2026-experiment` |
| Head SHA | `3016bc265e6301edb591b2c352363ccf75b18b63` |
| Conclusion | `success` |
| `formatting` | `success`, job `109580872932` |
| `build` | `success`, job `109581022025` |

Run URL:

https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/actions/runs/36619468411

This proves that `workflow_dispatch` is a usable emergency/manual fallback and
that `formatting` and `build` execute successfully on the experiment branch.
It does **not** make CI authoritative because nothing automatically dispatches
the run after each merged increment.

The run also reported GitHub's advance notice that `ubuntu-latest` will begin
migrating to Ubuntu 26 on October 19, 2026. That is not a blocker for this
spike, but future runtime/performance issues should pin or record the runner
image when reproducibility matters.

## Ruleset and required-check conclusion

GitHub currently has no ruleset or branch protection to edit. A new rule must
be created for the experiment branch.

The rule can name `formatting` and `build` because:

1. both names are emitted as successful GitHub Actions jobs;
2. both were reconfirmed on the experiment branch by run `36619468411`; and
3. GitHub rulesets and branch protection support required status-check names.

Recommended initial rule:

| Setting | Value |
|---|---|
| Target | `edburns/dd-3016202-cargotracker-devoxx-be-2026-experiment` |
| Require pull request | Yes |
| Required checks | `formatting`, `build` |
| Require branch up to date before merge | Yes, if it does not conflict with Shepherd Task's serial merge procedure |
| Bypass | No routine human or automation bypass; add one only if Shepherd Task proves unable to merge through the normal PR path |
| Force pushes | Block |
| Branch deletion | Block |

As later implementation issues add required jobs, update the rule only after
the new job has:

1. run successfully on the experiment branch;
2. acquired a stable, unique check name; and
3. demonstrated an actionable failure mode.

## Why PR and push runs are complementary

GitHub documents that a workflow triggered by `pull_request` uses:

```text
GITHUB_REF = refs/pull/<number>/merge
GITHUB_SHA = the merge commit on that PR merge branch
```

Because this workflow does not override `actions/checkout`'s `ref`, the PR run
tests the synthetic merged result. That is the correct pre-merge behavior and
should be required by branch rules.

After the PR merges, the campaign invariant concerns the real experiment-branch
tip. A squash, rebase, merge queue, changed base, or merge commit can make that
tip a different SHA from the PR run's synthetic merge SHA. The `push` run
therefore supplies the durable proof for the exact merged campaign-base SHA.

The serial campaign protocol should be:

1. PR `formatting` and `build` checks pass.
2. The PR includes its required evidence-matrix update.
3. Branch rules permit the merge.
4. Merge the PR.
5. Automatic experiment-branch `push` run starts.
6. Verify that run's `headSha` equals the new experiment-branch tip.
7. Verify every required job is successful.
8. Verify the evidence-matrix update exists on the branch.
9. Only then begin or dispatch the next serial issue.

## Minimum acceptable fallback

If branch rules cannot be configured immediately, implement option A now:

```yaml
on:
  push:
    branches:
      - edburns/dd-3016202-cargotracker-devoxx-be-2026-01
      - edburns/dd-3016202-cargotracker-devoxx-be-2026-experiment
```

Then make the exact-SHA post-merge push run an explicit Shepherd Task gate.
This is weaker than option D because it detects a bad merge only after the
commit reaches the campaign branch, but it removes the current manual-dispatch
gap.

## Commands used

```bash
gh repo view edburns/dd-3016202-cargotracker-devoxx-be-2026 \
  --json nameWithOwner,defaultBranchRef,visibility,url

gh api --paginate \
  repos/edburns/dd-3016202-cargotracker-devoxx-be-2026/rulesets

gh api \
  'repos/edburns/dd-3016202-cargotracker-devoxx-be-2026/rules/branches/edburns%2Fdd-3016202-cargotracker-devoxx-be-2026-experiment'

gh api \
  'repos/edburns/dd-3016202-cargotracker-devoxx-be-2026/branches/edburns%2Fdd-3016202-cargotracker-devoxx-be-2026-experiment/protection'

gh run list \
  --repo edburns/dd-3016202-cargotracker-devoxx-be-2026 \
  --workflow 'Main Build' \
  --branch edburns/dd-3016202-cargotracker-devoxx-be-2026-experiment

gh workflow run 'Main Build' \
  --repo edburns/dd-3016202-cargotracker-devoxx-be-2026 \
  --ref edburns/dd-3016202-cargotracker-devoxx-be-2026-experiment

gh run view 36619468411 \
  --repo edburns/dd-3016202-cargotracker-devoxx-be-2026
```

## Official behavior references

- GitHub Actions `pull_request` event and merge-ref behavior:
  https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#pull_request
- GitHub ruleset creation and required status checks:
  https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/creating-rulesets-for-a-repository
- GitHub protected branches and required status checks:
  https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches

## Proposed text for the plan's Resolution field

Select option D. Add
`edburns/dd-3016202-cargotracker-devoxx-be-2026-experiment` to the workflow's
`push.branches`, retain `pull_request`, and create an experiment-branch ruleset
requiring the stable `formatting` and `build` checks before merge. PR runs are
the pre-merge gate and validate GitHub's synthetic merge ref; the automatic
post-merge push run is the authoritative proof for the exact campaign-base
SHA. The next serial issue may not begin until that push run is green and the
preceding evidence-matrix update is visible on the experiment branch. Manual
dispatch remains an emergency fallback, not the normal invariant.
