# Devoxx Cargo Tracker Five-Issue Experiment Handoff

Captured: 2026-10-01 at approximately 23:44 UTC

Use this file as the starting context for a fresh Copilot CLI session whose
working directory is:

```text
/home/edburns/workareas/dd-3016202-cargotracker-devoxx-be-2026-02
```

The fresh session is expected to have these directories available:

```text
/home/edburns/workareas/dd-3016202-cargotracker-devoxx-be-2026-02
/home/edburns/.copilot/installed-plugins
/home/edburns/workareas/awesome-copilot-03
```

## Objective

Monitor, diagnose, and when explicitly requested recover the first complete
five-issue run of the Devoxx 2026 Cargo Tracker Change Arrival Deadline
fixture.

Do not start a second campaign against the same disposable repository while
the current command is running. The current run has already created its
baseline and campaign branches. Diagnose the existing run and preserve its
artifacts.

## Live invocation

The user launched:

```bash
runt "$fixture/run-campaign.sh" --repository-url "$repository_url"
```

Resolved invocation:

```bash
/home/edburns/.copilot/plugins/shepherd-task/test/cargotracker-add-change-arrival-deadline-feature-devoxx-2026-edition/run-campaign.sh \
  --repository-url https://github.com/edburns/dd-3072166-tricked-out-cargotracker-run-01
```

Top-level `runt` log:

```text
/home/edburns/workareas/dd-3016202-cargotracker-devoxx-be-2026-02/20261001-2341-job-logs.txt
```

At capture time the driver process was still running. Its process tree included:

```text
run-campaign.sh
  run-campaign.sh
    02-create-issues.sh
      20261001-2342-invoke-shepherd-task-20-create-issues-from-plan-skill.sh
```

The Stage 20 launcher was active. A transient `redact-secrets.sh` child was
also visible, so Stage 20 may have been finishing or exporting its session
when this snapshot was taken.

## Live campaign position

The top-level log showed successful completion or entry through:

1. Prerequisite validation.
2. Offline contracts.
3. Disposable-repository validation.
4. Primary checkout clone.
5. Immutable baseline publication.
6. Control worktree creation.
7. Campaign issue creation.
8. Stage 00 campaign initialization.
9. Deterministic Stage 10 plan substitution.
10. Stage 15 preparation.
11. Stage 20 issue creation, currently active at capture time.

Campaign issue:

```text
#1
```

Campaign shortname:

```text
arrival-deadline-control
```

Campaign metadata directory:

```text
1-arrival-deadline-control-remove-before-merge
```

The five task issue numbers were not yet known at capture time. Do not assume
their numbers. Query the repository after Stage 20 completes.

The log currently includes the planned Stage 25 invocation but had not yet
shown its actual invocation:

```text
shepherd-task-25-given-list.sh <TASK_ISSUE_LIST> \
  1-arrival-deadline-control-remove-before-merge
```

## Disposable experiment repository

Repository:

```text
edburns/dd-3072166-tricked-out-cargotracker-run-01
```

Repository URL:

```text
https://github.com/edburns/dd-3072166-tricked-out-cargotracker-run-01
```

State verified at capture time:

- It is standalone, not a fork.
- The authenticated user has `ADMIN` permission.
- Issues are enabled.
- Default branch is:

  ```text
  edburns/dd-3016202-cargotracker-devoxx-be-2026-experiment
  ```

- The fixture-created baseline branch now exists:

  ```text
  experiment/shepherd-shared-baseline
  ```

- The fixture-created campaign branch now exists:

  ```text
  edburns/dd-3016202-cargotracker-devoxx-be-2026-add-feature-control
  ```

The existence of these branches is expected because the current run created
them. It also means a clean restart of the same driver against this repository
will fail its fail-closed branch preflight. Prefer resuming or repairing the
current campaign rather than restarting it.

## Local experiment paths

Primary checkout:

```text
/home/edburns/workareas/dd-3072166-tricked-out-cargotracker-run-01-shepherd-target
```

Control worktree:

```text
/home/edburns/workareas/dd-3072166-tricked-out-cargotracker-run-01-shepherd-control
```

Expected campaign metadata path in the control worktree:

```text
/home/edburns/workareas/dd-3072166-tricked-out-cargotracker-run-01-shepherd-control/1-arrival-deadline-control-remove-before-merge
```

Stage 20 prompt/session directory observed at capture time:

```text
/home/edburns/workareas/dd-3072166-tricked-out-cargotracker-run-01-shepherd-control/1-arrival-deadline-control-remove-before-merge/prompts/shepherd-task-20-20261001-2342
```

## Fixture invariants

Installed fixture:

```text
/home/edburns/.copilot/plugins/shepherd-task/test/cargotracker-add-change-arrival-deadline-feature-devoxx-2026-edition
```

Source branch:

```text
edburns/dd-3016202-cargotracker-devoxx-be-2026-experiment
```

Exact immutable baseline SHA:

```text
eac2f312760dc7d5b47bea75989294559c024cdc
```

Shared baseline branch:

```text
experiment/shepherd-shared-baseline
```

Campaign branch:

```text
edburns/dd-3016202-cargotracker-devoxx-be-2026-add-feature-control
```

Historical non-tricked-out control branch:

```text
edburns/dd-3016202-cargotracker-devoxx-be-2026-control
```

The historical control branch must not be modified or deleted by this
experiment.

The Cargo Tracker Maven application is under:

```text
demo/
```

The generated substantive workflow runs:

```bash
cd demo && ./mvnw --batch-mode --no-transfer-progress clean package -Popenliberty
```

The embedded resolved plan contains five serial implementation issues and uses
`demo/`-relative source paths and Maven commands.

Lesson propagation is:

```text
off
```

## Installed Shepherd identity

Installed Shepherd version:

```text
1.0.4
```

Installed source commit:

```text
55d733cae927dddd8792bf61b6e73cbbe190e626
```

Installation timestamp:

```text
2026-10-01T22:53:23Z
```

Manifest:

```text
/home/edburns/.copilot/plugins/shepherd-task/install-manifest.json
```

The version number alone is not sufficient to identify this fixture because
the Devoxx fixture was added without a version bump. Verify the source commit
when installation identity matters.

The fixture source was created and pushed from:

```text
/home/edburns/workareas/awesome-copilot-03
```

Source branch:

```text
edburns/shepherd-task-v1.0.4-20260930
```

Fixture commit:

```text
55d733cae927dddd8792bf61b6e73cbbe190e626
```

That commit is pushed to `origin`.

Relevant earlier Shepherd repairs on the same source branch:

- `e52a7760fe676415d38188910e9b4faf53625aad`: repaired post-merge
  evidence-gate lifecycle and terminal-outcome parsing.
- `9f4e714da2d1f627855b353e07c8bc8c70ac45b4`: repaired malformed JSONL
  redaction and broken-pipe session termination.
- `55d733cae927dddd8792bf61b6e73cbbe190e626`: added the Devoxx fixture.

## Source repository transfer

The tricked-out source repository was transferred from the personal account
to:

```text
azure-javaee/dd-3016202-cargotracker-devoxx-be-2026
```

The current local Cargo Tracker repository remote is:

```text
origin  git@github.com:azure-javaee/dd-3016202-cargotracker-devoxx-be-2026.git
```

All worktrees belonging to this clone share that remote configuration.

Current local branch in the starting directory:

```text
edburns/dd-3016202-cargotracker-devoxx-be-2026-experiment
```

Current local HEAD:

```text
eac2f312760dc7d5b47bea75989294559c024cdc
```

The starting worktree was clean at capture time, apart from this handoff file
being added afterward.

## Canonical lifecycle for this run

The fixture describes the lifecycle as:

```text
Stage 00 -> Stage 10 -> research gate -> Stage 15 -> Stage 20 ->
Stage 25 -> Stage 30 -> Stage 40 -> Stage 50
```

For this deterministic fixture:

- Stage 10 and the human/Copilot research gate are not run live.
- The fixture installs an already-resolved ignorance-reduction plan.
- Stage 20 creates five ordered task issues.
- Stage 25 shepherds those issues serially.
- Each issue runs Stage 30 and then Stage 40.
- Stage 50 generates the final run post-mortem.
- The driver performs final campaign verification after Shepherd completes.

The phrase "five-stage experiment" may be used informally by the user, but do
not confuse feature implementation issues with Shepherd lifecycle stages.

## Initial fresh-session procedure

Start by reading this file and the live top-level log. Then determine whether
the original command is still running before changing anything.

Suggested read-only checks:

```bash
ps -eo pid,ppid,etimes,stat,args |
  grep -E '[r]un-campaign\.sh|[s]hepherd-task|[c]opilot --yolo'
```

```bash
tail -n 200 \
  /home/edburns/workareas/dd-3016202-cargotracker-devoxx-be-2026-02/20261001-2341-job-logs.txt
```

```bash
gh issue list \
  -R edburns/dd-3072166-tricked-out-cargotracker-run-01 \
  --state all \
  --limit 50
```

```bash
gh pr list \
  -R edburns/dd-3072166-tricked-out-cargotracker-run-01 \
  --state all \
  --limit 50
```

```bash
gh run list \
  -R edburns/dd-3072166-tricked-out-cargotracker-run-01 \
  --limit 30
```

Inspect the campaign directory for generated prompts, exported sessions,
JSONL, given-list run directories, and post-mortems:

```bash
find \
  /home/edburns/workareas/dd-3072166-tricked-out-cargotracker-run-01-shepherd-control/1-arrival-deadline-control-remove-before-merge \
  -maxdepth 3 -type f -print
```

## Debugging and recovery rules

1. While the original command is still running, prefer read-only observation.
   Do not launch another driver or Stage 25 process.
2. Do not kill a process merely because output is temporarily quiet. Inspect
   its child processes, exported session files, GitHub issue/PR state, and
   workflow runs.
3. If the top-level command fails, identify the exact failing lifecycle stage,
   issue number, PR number, exported session, and last semantic outcome before
   proposing recovery.
4. Shepherd success is semantic, not merely process exit. Look for
   `SHEPHERD COMPLETE` or `SHEPHERD FAILED` in exported session output and
   verify GitHub state.
5. Preserve all generated logs, session Markdown, JSONL, post-mortems, and
   campaign metadata.
6. Do not delete or recreate the fixture-created branches as an initial
   response to failure. They are durable recovery anchors.
7. For a failed Stage 30, inspect the linked draft PR, CI, unresolved review
   threads, and the Stage 30 exported session.
8. For a failed Stage 40, determine whether the PR is open, ready, merged, or
   in post-merge verification. A merged PR may be resumed through Stage 40
   post-merge verification rather than recreated.
9. If a PR merged into the non-default campaign branch, GitHub closing
   keywords will not close the task automatically. Stage 40 explicitly closes
   the task only after all post-merge gates pass.
10. Stage 40 may reopen an issue while post-merge verification is incomplete.
    An open issue with a merged PR can therefore be a valid resumable state.
11. If the driver reaches its final verifier, check all five closed issues,
    merged PR ordering, substantive Maven CI, campaign lessons placeholder,
    Stage 25 outcome, and Stage 50 post-mortem.
12. Do not modify Shepherd source or the fixture until evidence demonstrates a
    fixture/framework defect rather than an implementation-task failure.

## Validation already completed before the run

- Every copied Bash fixture contract passed.
- Bash installed-only validation passed.
- Bash and PowerShell installation-lineup contracts passed.
- Every PowerShell fixture file parsed successfully.
- Applicable PowerShell contracts passed.
- PowerShell contracts `05-stage20-artifact-contract.ps1` and
  `07-driver-encoding-contract.ps1` fail on this GNU/Linux machine because
  their mock `.cmd` files cannot be executed in that PowerShell pipeline.
  The same failures reproduce unchanged in the original fixture, so they are
  not Devoxx fixture regressions.
- The transformed embedded plan and PowerShell plan are identical.
- The plan SHA-256 is:

  ```text
  55325888ac5c6fc22951b251ae4ae534c4a02c33d3d8c23c26b4125e7c616d08
  ```

## Tooling and repository conventions

- Use `gh` for all GitHub operations.
- Use Open Liberty as the only supported application server for this demo.
- If local Java or Maven validation becomes necessary, use Java 17 for this
  fixture unless the relevant task explicitly proves otherwise.
- Java environment bootstrap:

  ```bash
  export JAVA_HOME="/usr/lib/jvm/msopenjdk-17-amd64"
  export ANT_HOME="/usr/share/ant"
  export M2_HOME="/usr/share/maven"
  export PATH="${M2_HOME}/bin:${ANT_HOME}/bin:${JAVA_HOME}/bin:${PATH}"
  ```

- Maven invocations must stream stdout and stderr through `tee` to an exact
  timestamped `YYYYMMDD-HHMM-job-logs.txt` file and that exact file must be
  inspected afterward.
- Do not commit or push diagnostic changes unless the user requests it.

## Expected successful terminal state

A successful run should leave:

- Campaign issue `#1`.
- Five ordered implementation issues, all closed.
- Five implementation PRs merged serially into
  `edburns/dd-3016202-cargotracker-devoxx-be-2026-add-feature-control`.
- Successful substantive Open Liberty Maven CI.
- A successful Stage 25 run record.
- A Stage 50 post-mortem.
- Final machine-readable experiment summary and preserved logs.
- `campaign-lessons.md` retaining its initial placeholder because lesson
  propagation is `off`.
- No automatic cleanup of the checkout, control worktree, branches, issues,
  PRs, or evidence.

