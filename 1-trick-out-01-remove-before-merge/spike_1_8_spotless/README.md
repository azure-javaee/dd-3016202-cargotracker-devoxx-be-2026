# Spike 1.8: Spotless baseline and ratchet semantics

Date: 2026-09-29

Plan question:
`1-trick-out-01-remove-before-merge/trick-out-01-ignorance-reduction-plan.md`,
section 1.8.

## Decision

Keep:

```xml
<ratchetFrom>1fd1c340fa56c6c77a601d2fbba20294afa46dd9</ratchetFrom>
```

through all trick-out implementation issues.

Do not:

- remove `ratchetFrom`;
- format the whole legacy tree;
- advance the ratchet to the current branch tip;
- advance it merely because a newer commit or temporary baseline exists.

After the complete feature-absent trick-out baseline is green and tagged,
advance `ratchetFrom` once to that tag's immutable commit SHA. Before creating
the tag, the old ratchet must remain active and `spotless:check` must pass so
that no malformed Java change is grandfathered.

Keep the `formatting` job first in CI.

## What the spike established

### Current and proposed baselines are equivalent today

No tracked Java files differ between the historical ratchet commit and current
HEAD:

```text
historical ratchet: 1fd1c340fa56c6c77a601d2fbba20294afa46dd9
current HEAD:       cf19be6029aad88ce792e544cc4dd8135867723f
changed Java files: 0
```

Both clean cases passed `spotless:check` and `spotless:apply` without changing
a Java file.

Moving the ratchet to current HEAD would therefore provide no present benefit.
There is also no completed trick-out baseline tag yet.

### Whole-tree formatting is excessive

Removing `ratchetFrom` caused `spotless:check` to fail. `spotless:apply` then
changed:

| Measurement | Result |
|---|---:|
| Tracked Java files | 106 |
| Java files rewritten | 95 |
| Added lines | 5,245 |
| Deleted lines | 5,184 |
| Total changed lines | 10,429 |

This is the large, low-value legacy rewrite anticipated by the plan. It would
obscure later agent-authored changes and should not be part of the campaign.

### The ratchet covers later Java work

The failure fixture:

- modified the tracked legacy `Cargo.java`;
- added and staged a malformed `BadFormatting.java`.

With either the historical ratchet or a ratchet at current HEAD:

- `spotless:check` failed;
- both files were named;
- the output prescribed `mvn spotless:apply`;
- `spotless:apply` fixed both files.

This proves that the existing ratchet covers both a later modification to a
legacy Java file and a later added Java file.

Spotless formats the complete contents of a touched file, not only the changed
lines. Touching the legacy `Cargo.java` produced a 172-line addition and
186-line deletion after formatting. This localized churn is preferable to
rewriting 95 files at once, but implementation issues should avoid mixing
unrelated edits into a Java file that Spotless must normalize.

### Advancing the ratchet can hide malformed committed Java

The spike committed the same malformed `Cargo.java` and
`BadFormatting.java`, then moved `ratchetFrom` to that synthetic commit.

Observed result:

| Command | Result |
|---|---|
| `spotless:check` | Pass |
| `spotless:apply` | Pass |
| Java files changed by apply | 0 |

The malformed files became part of the baseline and were ignored. This
directly confirms the plan's concern that moving the ratchet too early can
silently grandfather files that should have remained in scope.

## Policy semantics to document

The ratchet is a changed-file policy:

1. Java files changed relative to `ratchetFrom` are checked.
2. Added Java files must be visible to Git; the spike staged its added fixture
   before checking.
3. Legacy Java files with no Git change relative to the baseline are not
   checked.
4. Once a Java file is in scope, Google Java Format evaluates and may rewrite
   the entire file.
5. Content already committed at a newly selected baseline is outside the
   ratchet, even if malformed.

CI must retain full Git history for the ratchet commit to be resolvable. The
current workflow's `actions/checkout` configuration uses `fetch-depth: 0`,
which satisfies this requirement.

## Baseline-advance procedure

Advance the ratchet only when creating the completed feature-absent baseline:

1. Keep the historical ratchet active through every trick-out issue.
2. Run `spotless:check` as the first required CI job on the candidate baseline
   commit.
3. Require every other campaign gate to pass.
4. Create the final immutable baseline tag on that green commit.
5. In the next POM-only commit, set `ratchetFrom` to the tagged commit's full
   SHA.
6. Rerun `spotless:check` with full Git history.
7. Do not move the ratchet again during feature implementation.

Using the full commit SHA avoids ambiguity if a tag is moved accidentally,
while the tag records the human-meaningful baseline.

## Reproduction

Run from the repository root:

```bash
1-trick-out-01-remove-before-merge/spike_1_8_spotless/run-spike.sh
```

The harness:

- creates disposable shared clones with complete Git history;
- tests the historical ratchet;
- simulates a ratchet at current HEAD;
- tests whole-tree formatting;
- tests modified and added malformed Java under both ratchets;
- proves the grandfathering behavior with a synthetic committed baseline;
- preserves Maven logs, changed-file inventories, and `run-summary.tsv`;
- removes all disposable clones when finished.

It never applies formatting to the campaign worktree.

## Proposed text for the plan's Resolution field

Keep `ratchetFrom` pinned to
`1fd1c340fa56c6c77a601d2fbba20294afa46dd9` throughout the trick-out
implementation issues and keep `formatting` as the first required CI job.
Do not adopt whole-tree formatting: removing the ratchet rewrote 95 of 106
Java files with 5,245 added and 5,184 deleted lines. The historical ratchet
and a simulated ratchet at current HEAD behaved identically because no tracked
Java file currently differs between those commits; both detected and repaired
a modified legacy file and a newly added staged Java file. Advancing the
ratchet early has no benefit and can hide defects: when malformed Java was
committed and the ratchet was moved to that commit, both `spotless:check` and
`spotless:apply` passed without touching either file. Advance the ratchet only
after the complete feature-absent trick-out baseline passes all gates and is
tagged. Keep the old ratchet active while validating the tagged commit, then
set `ratchetFrom` in a following POM-only commit to that tag's immutable full
commit SHA and rerun formatting with full Git history.
