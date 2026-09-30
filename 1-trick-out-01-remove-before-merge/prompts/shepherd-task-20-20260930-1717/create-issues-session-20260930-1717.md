# Copilot CLI Session

> [!NOTE]
> - **Session ID:** `9b6667f8-4cfe-4ffd-9829-ddefac32f44f`  
> - **Started:** 9/30/2026, 5:18:02 PM  
> - **Duration:** 3m 2s  
> - **Exported:** 9/30/2026, 5:21:05 PM  

---

<sub>5s</sub>

### User

Invoke skill `shepherd-task-20-create-issues-from-plan` with these inputs:

- CAMPAIGN_ID: 474aebe4-23f7-45cf-a841-e214bdcdd132
- LESSON_PROPAGATION: off
- REPO: edburns/dd-3016202-cargotracker-devoxx-be-2026
- BASE_BRANCH: edburns/dd-3016202-cargotracker-devoxx-be-2026-experiment
- PARENT_ISSUE: 1
- PLAN_DIRECTORY: 1-trick-out-01-remove-before-merge
- PLAN_FILE_NAME: trick-out-01-ignorance-reduction-plan.md
- QUESTIONS_SECTION: ## Phase 1 — Ignorance reduction: questions to resolve before creating issues
- IMPLEMENTATION_SECTION: ## Phase 2 — Implementation
- EXPECTED_TASK_COUNT: 7
- BASE_REMOTE: origin
- LOG_DIRECTORY: /home/edburns/workareas/dd-3016202-cargotracker-devoxx-be-2026-02/1-trick-out-01-remove-before-merge/prompts/shepherd-task-20-20260930-1717
- DRAFT_VALIDATOR: /home/edburns/.copilot/plugins/shepherd-task/scripts/validate-stage20-drafts.sh
- ISSUE_BODY_VERIFIER: /home/edburns/.copilot/plugins/shepherd-task/scripts/verify-github-issue-body.sh
- CHILD_LINK_VERIFIER: /home/edburns/.copilot/plugins/shepherd-task/scripts/verify-stage20-child-links.sh

---

<sub>6s</sub>

### `skill`

**shepherd-task-20-create-issues-from-plan**

<details>
<summary>Arguments</summary>

```json
{
  "skill": "shepherd-task-20-create-issues-from-plan"
}
```

</details>

```
Skill "shepherd-task-20-create-issues-from-plan" loaded successfully. Follow the instructions in the skill context.
```


---

<sub>10s</sub>

### Copilot

I’ll validate the campaign inputs, plan structure, GitHub target, and drafting conventions before making any repository mutation.

---

<sub>16s</sub>

### `bash`

**Validate remotes branch logs scripts**

$ set -e
printf '%s\n' '--- remotes ---'
git remote -v
printf '%s\n' '--- default branch and base branch ---'
git branch -r --list 'origin/HEAD' 'origin/edburns/dd-3016202-cargotracker-devoxx-be-2026-experiment'
git show-ref --verify --quiet refs/heads/edburns/dd-3016202-cargotracker-devoxx-be-2026-experiment && echo local-base-present || true
printf '%s\n' '--- log/scripts ---'
test -d '/home/edburns/workareas/dd-3016202-cargotracker-devoxx-be-2026-02/1-trick-out-01-remove-before-merge/prompts/shepherd-task-20-20260930-1717'
test -w '/home/edburns/workareas/dd-3016202-cargotracker-devoxx-be-2026-02/1-trick-out-01-remove-before-merge/prompts/shepherd-task-20-20260930-1717'
mkdir -p '/home/edburns/workareas/dd-3016202-cargotracker-devoxx-be-2026-02/1-trick-out-01-remove-before-merge/prompts/shepherd-task-20-20260930-1717/issue-bodies'
for f in '/home/edburns/.copilot/plugins/shepherd-task/scripts/validate-stage20-drafts.sh' '/home/edburns/.copilot/plugins/shepherd-task/scripts/verify-github-issue-body.sh' '/home/edburns/.copilot/plugins/shepherd-task/scripts/verify-stage20-child-links.sh'; do test -x "$f" && printf 'executable %s\n' "$f"; done

<details>
<summary>12 lines</summary>

```
--- remotes ---
origin	git@github.com:edburns/dd-3016202-cargotracker-devoxx-be-2026.git (fetch)
origin	git@github.com:edburns/dd-3016202-cargotracker-devoxx-be-2026.git (push)
--- default branch and base branch ---
  origin/HEAD -> origin/edburns/dd-3016202-cargotracker-devoxx-be-2026-01
  origin/edburns/dd-3016202-cargotracker-devoxx-be-2026-experiment
local-base-present
--- log/scripts ---
executable /home/edburns/.copilot/plugins/shepherd-task/scripts/validate-stage20-drafts.sh
executable /home/edburns/.copilot/plugins/shepherd-task/scripts/verify-github-issue-body.sh
executable /home/edburns/.copilot/plugins/shepherd-task/scripts/verify-stage20-child-links.sh
<shellId: 2 completed with exit code 0>
```

</details>


---

<sub>16s</sub>

### `bash`

**Read plan from base branch**

$ git show 'edburns/dd-3016202-cargotracker-devoxx-be-2026-experiment:1-trick-out-01-remove-before-merge/trick-out-01-ignorance-reduction-plan.md'

<details>
<summary>12 lines</summary>

```
Output too large to read at once (85.4 KB). Saved to: /tmp/1790788699095-copilot-tool-output-43388-05f20cfa-6d01-491e-85f0-3747b9ba3a60.txt
Consider using tools like rg (for searching), head/tail (for viewing start/end), view with view_range (for specific sections), or jq (for JSON) to examine portions of the output.

Preview (first 500 chars):
# Implementation plan: Trick out Cargo Tracker for agent-safe Java development (dd-3070726 / campaign #1)

Human DRI: Ed Burns<br>
Campaign: `1-trick-out-01-remove-before-merge`<br>
Campaign ID: `474aebe4-23f7-45cf-a841-e214bdcdd132`<br>
Repository: `edburns/dd-3016202-cargotracker-devoxx-be-2026`<br>
Campaign base branch: `edburns/dd-3016202-cargotracker-devoxx-be-2026-experiment`<br>
Campaign issue: https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/issues/1<br>
Azure DevOps wor
<shellId: 0 completed with exit code 0>
```

</details>


---

<sub>16s</sub>

### `bash`

**Read campaign manifest**

$ git show 'edburns/dd-3016202-cargotracker-devoxx-be-2026-experiment:1-trick-out-01-remove-before-merge/shepherd-campaign.json' && printf '\n--- lessons existence ---\n' && git cat-file -e 'edburns/dd-3016202-cargotracker-devoxx-be-2026-experiment:1-trick-out-01-remove-before-merge/campaign-lessons.md' && echo present

<details>
<summary>19 lines</summary>

```
{
  "schemaVersion": 1,
  "campaignId": "474aebe4-23f7-45cf-a841-e214bdcdd132",
  "campaignIssueNumber": 1,
  "campaignShortname": "trick-out-01",
  "repository": "edburns/dd-3016202-cargotracker-devoxx-be-2026",
  "baseBranch": "edburns/dd-3016202-cargotracker-devoxx-be-2026-experiment",
  "lessonPropagation": "off",
  "campaignMetadataDirectory": "1-trick-out-01-remove-before-merge",
  "lessonsFile": "campaign-lessons.md",
  "createdBy": {
    "shepherdTaskVersion": "1.0.4",
    "stageOutcomeProtocolVersion": 1
  },
  "createdAt": "2026-09-29T00:33:25Z"
}

--- lessons existence ---
present
<shellId: 1 completed with exit code 0>
```

</details>


---

<sub>16s</sub>

### `view`

**view the file at /home/edburns/.copilot/skills/shepherd-task-20-create-issues-from-plan/examples/01-1682-java-tool-ergonomics.md.**

/home/edburns/.copilot/skills/shepherd-task-20-create-issues-from-plan/examples/01-1682-java-tool-ergonomics.md

<details>
<summary>15 lines</summary>

```
# Example 01: 1682-java-tool-ergonomics-prompts-remove-before-merge

Read `copilot-sdk/1682-java-tool-ergonomics-prompts-remove-before-merge/dd-3018003-ignorance-reduction-for-implementation-plan.md` (the plan) to get the context.

✅✅Pay very close attention to each **Resolution:** to the questions in `Phase 3 — Ignorance reduction: questions to answer before writing code`.

In this session, we are creating issues of type **Task** as children of Epic https://github.com/github/copilot-sdk/issues/1682 . These issues correspond to the sub-sections in `## Phase 4 — Implementation (the build order)`.

I want you to use `gh` to create issues as sub-issues of 1682.

- I will dispatch these issues by assigning them to an agent. Leave them unassigned for now.

- The description you put in the issues you create is the specification for the work the agent assigned to the issue must do. Therefore, you need to be very specific and targeted when writing the description.

- Set the type to **Task**.

- Each issue will be worked on and resolved in serial. You can assume:
  - All issues will operate in this topic branch of `upstream`: `edburns/1682-java-tool-ergonomics`.

  - The assignee agent has access to the topic branch and, most importantly, to the prompts in the directory `1682-java-tool-ergonomics-prompts-remove-before-merge`, which includes the plan. Therefore, you can instruct the agent to access the plan by reference, you don't need to reference it by value directly in the issue.

- The sub-sections of `## Phase 4 — Implementation (the build order)` have essential details for each corresponding **Task**.

- Instruct the agent to read the entire plan before working.

- Instruct the agent to carefully re-read the relevant sections of the plan. ❌❌You can't just say, "read the relevant sections of the plan". ✅✅In the description of the issue, list exactly what sections of the plan apply to this particular issue.
- Though the sub-sections of `## Phase 4 — Implementation (the build order)` have essential details for each corresponding **Task**, I want you to carefully consider if there are additional gating tests you can add so that as the agent proceeds from one task to the next, the likelihood of rework is reduced.
```

</details>


---

<sub>16s</sub>

### `view`

**view the file at /home/edburns/.copilot/skills/shepherd-task-20-create-issues-from-plan/examples/02-1810-java-tool-as-lambda.md.**

/home/edburns/.copilot/skills/shepherd-task-20-create-issues-from-plan/examples/02-1810-java-tool-as-lambda.md

<details>
<summary>12 lines</summary>

```
# Example 02: 1810-java-tool-ergonomics-tool-as-lambda-remove-before-merge

Carefully read the plan `copilot-sdk/1810-java-tool-ergonomics-tool-as-lambda-remove-before-merge/1810-ignorance-reduction-for-implementation-plan.md`.

We have completed Phases 1 - 3. We are now on Phase 4.

For each sub item in Phase 4, file a child issue of Feature #1810.

Use `gh` to look at Epic #1682 and its child issues for the standard of verbosity and concreteness for issue descriptions.

The issue should be assignable to a coding agent and there must be sufficient detail in the description for the agent to proceed to completion.

Pull out the specific relevant content from Phase 3 as it applies to this current issue in Phase 4.

Tell the agent to take `edburns/1810-java-tool-ergonomics-tool-as-lambda` as the base branch. When I assign the issue to the coding agent, I will set this as the base branch.

Tell the agent to read `1810-java-tool-ergonomics-tool-as-lambda-remove-before-merge/1810-ignorance-reduction-for-implementation-plan.md`, which is present on the branch, for context.

Tell the agent which sub-item within Phase 4 they are solving.

Tell the agent that each issue will be assigned, resolved and merged to the base branch in the order in which they appear in the plan.

No work is to start until I assign each issue to the coding agent, in turn.
```

</details>


---

<sub>16s</sub>

### `view`

**view the file at /home/edburns/.copilot/skills/shepherd-task-20-create-issues-from-plan/examples/03-dd-3017826-java-real-estate-demo.md.**

/home/edburns/.copilot/skills/shepherd-task-20-create-issues-from-plan/examples/03-dd-3017826-java-real-estate-demo.md

<details>
<summary>14 lines</summary>

```
# Example 03: dd-3017826-java-real-estate-demo-remove-before-merge

Read `dd-3017826-java-real-estate-demo-remove-before-merge\dd-3017826-java-real-estate-demo-ignorance-reduction-plan.md` (the plan) to get the context.

✅✅Pay very close attention to each **Resolution:** to the questions in `Phase 2 — Ignorance reduction: questions to answer before writing code`.

In this session, we are creating sub-issues as children of https://github.com/edburns/Build26-BRK206-your-agent-anywhere-multiclient-multidevice-with-github-copilot-sdk/issues/2 . These issues correspond to the sub-sections in `## Phase 3 — Implementation (build order)`.

I want you to use `gh` to create issues as sub-issues of #2.

- I will dispatch these issues by assigning them to an agent. Leave them unassigned for now.

- The description you put in the issues you create is the specification for the work the agent assigned to the issue must do. Therefore, you need to be very specific and targeted when writing the description.

- Each issue will be worked on and resolved in serial. You can assume:
  - All issues will operate in this topic branch of `origin`: `edburns/2-build-out-demo`.

  - The assignee agent has access to the topic branch and, most importantly, to the prompts in the directory `dd-3017826-java-real-estate-demo-remove-before-merge`, which includes the plan. Therefore, you can instruct the agent to access the plan by reference, you don't need to reference it by value directly in the issue.

- The sub-sections of `## Phase 3 — Implementation (build order)` have essential details for each corresponding sub-issue.

- Instruct the agent to read the entire plan before working.

- Instruct the agent to carefully re-read the relevant sections of the plan. ❌❌You can't just say, "read the relevant sections of the plan". ✅✅In the description of the issue, list exactly what sections of the plan apply to this particular issue.
- Though the sub-sections of `## Phase 3 — Implementation (build order)` have essential details for each corresponding sub-issue, I want you to carefully consider if there are additional gating tests you can add so that as the agent proceeds from one task to the next, the likelihood of rework is reduced.
```

</details>


---

<sub>16s</sub>

### `view`

**view the file at /home/edburns/.copilot/skills/shepherd-task-20-create-issues-from-plan/examples/04-28-python-agent-demo.md.**

/home/edburns/.copilot/skills/shepherd-task-20-create-issues-from-plan/examples/04-28-python-agent-demo.md

<details>
<summary>16 lines</summary>

```
# Example 04: 28-python-agent-demo-remove-before-merge

Read `28-python-agent-demo-remove-before-merge/28-python-agent-demo-ignorance-reduction-plan.md` (the plan) to get the context.

✅✅Pay very close attention to each **Resolution:** to the questions in `Phase 2 — Ignorance reduction: questions to answer before writing code`. These pertain to the implementation tasks in Phase 3. ✅✅✅ Include relevant spike findings as self-contained prose in the issue description; do not direct the agent to spike directories or source files.

In this session, we are creating sub-issues as children of https://github.com/edburns/Build26-BRK206-your-agent-anywhere-multiclient-multidevice-with-github-copilot-sdk/issues/28 . These issues correspond to the sub-sections in `## Phase 3 — Implementation (build order)`.

I want you to use `gh` to create issues as sub-issues of #28

- I will dispatch these issues by assigning them to an agent. Leave them unassigned for now.

- The description you put in the issues you create is the specification for the work the agent assigned to the issue must do. Therefore, you need to be very specific and targeted when writing the description.

- Again, ✅✅For each **Resolution:** to the questions in `Phase 2 — Ignorance reduction: questions to answer before writing code`, include the relevant Resolution values in the issue description. These pertain to the implementation tasks in Phase 3. ✅✅✅ State relevant spike findings directly in the issue body with enough detail to implement them without reading spike code.

- For tasks dealing with the UI, make sure to refer to the relevant screengrabs, but only ones within `28-python-agent-demo-remove-before-merge/`.

- Each issue will be worked on and resolved in serial. You can assume:
  - All issues will operate in this topic branch of `origin`: `edburns/28-python-agent-demo`.

  - The assignee agent has access to the topic branch and, most importantly, to the prompts in the directory `28-python-agent-demo-remove-before-merge/`, which includes the plan. Therefore, you can instruct the agent to access the plan by reference, you don't need to reference it by value directly in the issue.

- The sub-sections of `## Phase 3 — Implementation (build order)` have essential details for each corresponding sub-issue.

- Instruct the agent to read the entire plan before working.

- Instruct the agent to carefully re-read the relevant sections of the plan. ❌❌You can't just say, "read the relevant sections of the plan". ✅✅In the description of the issue, list exactly what sections of the plan apply to this particular issue.
- Though the sub-sections of `## Phase 3 — Implementation (build order)` have essential details for each corresponding sub-issue, I want you to carefully consider if there are additional gating tests you can add so that as the agent proceeds from one task to the next, the likelihood of rework is reduced.
```

</details>


---

<sub>19s</sub>

### Copilot

The local campaign manifest and branch invariants match, and all three required validators are executable. I’m now extracting the seven implementation specifications and confirming the parent, issue-type capability, and pre-existing child baseline.

---

<sub>24s</sub>

### `rg`

**^## Phase 1|^## Phase 2|^### |^#### |^\*\*Resolution:\*\*|^Resolution:**

"^## Phase 1|^## Phase 2|^### |^#### |^\*\*Resolution:\*\*|^Resolution:" (1-trick-out-01-remove-before-merge/trick-out-01-ignorance-reduction-plan.md)

<details>
<summary>54 matches</summary>

```
[grep content: 52 matches across 1 file(s) under 1-trick-out-01-remove-before-merge]

trick-out (52 match(es)):
  01- ignorance-reduction-plan.md:38:### Baseline technology contract
  01- ignorance-reduction-plan.md:53:### Reasons exercised by this campaign
  01- ignorance-reduction-plan.md:68:### Success criteria
  01- ignorance-reduction-plan.md:93:### Phase 0.1 ✅ — Establish campaign state
  01- ignorance-reduction-plan.md:102:### Phase 0.2 ✅ — Establish the evidence-capture structure
  01- ignorance-reduction-plan.md:110:### Phase 0.3 ✅ — Establish the known green starting behavior
  01- ignorance-reduction-plan.md:119:### Phase 0.4 ✅ — Bound concurrency and Azure scope
  01- ignorance-reduction-plan.md:129:## Phase 1 — Ignorance reduction: questions to resolve before creating issues
  01- ignorance-reduction-plan.md:135:### 1.1 — Authoritative experiment-branch CI path
  01- ignorance-reduction-plan.md:164:**Resolution:**
  01- ignorance-reduction-plan.md:178:### 1.2 — Required job topology and fail-fast order
  01- ignorance-reduction-plan.md:204:**Resolution:**
  01- ignorance-reduction-plan.md:208:### 1.3 — Canonical local and CI Maven commands
  01- ignorance-reduction-plan.md:231:**Resolution:**
  01- ignorance-reduction-plan.md:269:### 1.4 — Maven and dependency-governance rules
  01- ignorance-reduction-plan.md:297:**Resolution:**
  01- ignorance-reduction-plan.md:322:### 1.5 — Reproducibility and dependency-security evidence
  01- ignorance-reduction-plan.md:349:**Resolution:**
  01- ignorance-reduction-plan.md:356:### 1.6 — Executable Java 17 and Java EE 7 compatibility contract
  01- ignorance-reduction-plan.md:395:**Resolution:**
  01- ignorance-reduction-plan.md:405:### 1.7 — Repository-level instructions for agents
  01- ignorance-reduction-plan.md:431:**Resolution:**
  01- ignorance-reduction-plan.md:477:### POSIX (bash/zsh) pattern
  01- ignorance-reduction-plan.md:483:### PowerShell pattern
  01- ignorance-reduction-plan.md:503:### 1.8 — Spotless baseline and ratchet semantics
  01- ignorance-reduction-plan.md:522:**Resolution:**
  01- ignorance-reduction-plan.md:532:### 1.9 — Compiler diagnostics and type-system evidence
  01- ignorance-reduction-plan.md:552:**Resolution:**
  01- ignorance-reduction-plan.md:572:### 1.10 — Static analyzer and legacy-debt strategy
  01- ignorance-reduction-plan.md:593:**Resolution:**
  01- ignorance-reduction-plan.md:597:### 1.11 — Actual test inventory and dormant-test disposition
  01- ignorance-reduction-plan.md:620:**Resolution:**
  01- ignorance-reduction-plan.md:627:### 1.12 — Behavioral safety net for the later deadline feature
  01- ignorance-reduction-plan.md:658:**Resolution:**
  01- ignorance-reduction-plan.md:666:### 1.13 — Open Liberty lifecycle and acceptance-test boundary
  01- ignorance-reduction-plan.md:682:**Resolution:**
  01- ignorance-reduction-plan.md:706:### 1.14 — Runtime observability mechanism
  01- ignorance-reduction-plan.md:724:**Resolution:**
  01- ignorance-reduction-plan.md:728:### 1.15 — Repeatable performance workload and resource envelope
  01- ignorance-reduction-plan.md:778:**Resolution:**
  01- ignorance-reduction-plan.md:786:### 1.16 — `java` versus `jaz`, GC logs, and JFR capture
  01- ignorance-reduction-plan.md:840:**Resolution:**
  01- ignorance-reduction-plan.md:852:### 1.17 — Artifact naming, retention, and merge evidence
  01- ignorance-reduction-plan.md:882:**Resolution:**
  01- ignorance-reduction-plan.md:962:## Phase 2 — Implementation
  01- ignorance-reduction-plan.md:978:### 2.1 — Establish the Open Liberty-only baseline
  01- ignorance-reduction-plan.md:1022:### 2.2 — Make CI authoritative and establish the Maven/dependency foundation
  01- ignorance-reduction-plan.md:1121:### 2.3 — Enforce the Java 17 and Java EE 7 compatibility contract
  01- ignorance-reduction-plan.md:1206:### 2.4 — Strengthen formatting, compiler, type, and static-analysis gates
  01- ignorance-reduction-plan.md:1289:### 2.5 — Build the behavioral safety net
  01- ignorance-reduction-plan.md:1382:### 2.6 — Add CI observability and diagnostic artifacts
  01- ignorance-reduction-plan.md:1486:### 2.7 — Add bounded JVM performance and `jaz` evidence
```

</details>


---

<sub>24s</sub>

### `bash`

**Validate GitHub parent and children**

$ set -e
REPO='edburns/dd-3016202-cargotracker-devoxx-be-2026'
printf '%s\n' '--- repository ---'
gh api "repos/$REPO" --jq '{default_branch,owner:{login:.owner.login,type:.owner.type}}'
printf '%s\n' '--- parent ---'
gh api "repos/$REPO/issues/1" --jq '{number,state,title,repository_url,assignees:[.assignees[].login]}'
printf '%s\n' '--- children ---'
gh api "repos/$REPO/issues/1/sub_issues" --paginate --jq '.[] | {id,number,title,url:.html_url}'

<details>
<summary>6 lines</summary>

```
--- repository ---
{"default_branch":"edburns/dd-3016202-cargotracker-devoxx-be-2026-01","owner":{"login":"edburns","type":"User"}}
--- parent ---
{"assignees":[],"number":1,"repository_url":"https://api.github.com/repos/edburns/dd-3016202-cargotracker-devoxx-be-2026","state":"open","title":"Top level container issue for tricking out `edburns/dd-3016202-cargotracker-devoxx-be-2026-experiment` according to the abstract"}
--- children ---
<shellId: 4 completed with exit code 0>
```

</details>


---

<sub>24s</sub>

### `bash`

**Inspect campaign resources and worktree**

$ git status --short && printf '%s\n' '--- supporting resources ---' && find '1-trick-out-01-remove-before-merge' -maxdepth 3 -type f -printf '%p\n' | sort

<details>
<summary>179 lines</summary>

```
?? 1-trick-out-01-remove-before-merge/prompts/
--- supporting resources ---
1-trick-out-01-remove-before-merge/campaign-lessons.md
1-trick-out-01-remove-before-merge/evidence-matrix.md
1-trick-out-01-remove-before-merge/prompts/shepherd-task-20-20260930-1717/20260930-1717-invoke-shepherd-task-20-create-issues-from-plan-skill.md
1-trick-out-01-remove-before-merge/prompts/shepherd-task-20-20260930-1717/20260930-1717-invoke-shepherd-task-20-create-issues-from-plan-skill.sh
1-trick-out-01-remove-before-merge/prompts/shepherd-task-20-20260930-1717/create-issues-otel-20260930-1717.jsonl
1-trick-out-01-remove-before-merge/prompts/shepherd-task-20-20260930-1717/create-issues-session-20260930-1717.jsonl
1-trick-out-01-remove-before-merge/shepherd-campaign.json
1-trick-out-01-remove-before-merge/spike_1_10_static-analyzer/README.md
1-trick-out-01-remove-before-merge/spike_1_10_static-analyzer/finding-classification.tsv
1-trick-out-01-remove-before-merge/spike_1_10_static-analyzer/reports/pmd-baseline-findings.tsv
1-trick-out-01-remove-before-merge/spike_1_10_static-analyzer/reports/pmd-baseline.xml
1-trick-out-01-remove-before-merge/spike_1_10_static-analyzer/reports/pmd-fixture-findings.tsv
1-trick-out-01-remove-before-merge/spike_1_10_static-analyzer/reports/pmd-fixture.xml
1-trick-out-01-remove-before-merge/spike_1_10_static-analyzer/reports/spotbugs-baseline-findings.tsv
1-trick-out-01-remove-before-merge/spike_1_10_static-analyzer/reports/spotbugs-baseline.xml
1-trick-out-01-remove-before-merge/spike_1_10_static-analyzer/reports/spotbugs-fixture-findings.tsv
1-trick-out-01-remove-before-merge/spike_1_10_static-analyzer/reports/spotbugs-fixture.xml
1-trick-out-01-remove-before-merge/spike_1_10_static-analyzer/run-spike.sh
1-trick-out-01-remove-before-merge/spike_1_10_static-analyzer/run-summary.tsv
1-trick-out-01-remove-before-merge/spike_1_12_behavior_saftey_net/README.md
1-trick-out-01-remove-before-merge/spike_1_12_behavior_saftey_net/logs/20260929-1821-spike-1-12-test-logs.txt
1-trick-out-01-remove-before-merge/spike_1_12_behavior_saftey_net/logs/20260929-1826-spike-1-12-mutation-logs.txt
1-trick-out-01-remove-before-merge/spike_1_12_behavior_saftey_net/logs/20260929-1827-spike-1-12-package-logs.txt
1-trick-out-01-remove-before-merge/spike_1_12_behavior_saftey_net/logs/20260929-1827-spike-1-12-restored-test-logs.txt
1-trick-out-01-remove-before-merge/spike_1_12_behavior_saftey_net/logs/20260929-1828-spike-1-12-http-logs.txt
1-trick-out-01-remove-before-merge/spike_1_12_behavior_saftey_net/logs/20260929-1832-spike-1-12-liberty-start-help-logs.txt
1-trick-out-01-remove-before-merge/spike_1_12_behavior_saftey_net/reports/http-probe.txt
1-trick-out-01-remove-before-merge/spike_1_12_behavior_saftey_net/resolution.md
1-trick-out-01-remove-before-merge/spike_1_12_behavior_saftey_net/run-http-acceptance.sh
1-trick-out-01-remove-before-merge/spike_1_12_behavior_saftey_net/run-summary.tsv
1-trick-out-01-remove-before-merge/spike_1_13_acceptance_tests/README.md
1-trick-out-01-remove-before-merge/spike_1_13_acceptance_tests/http-summary.tsv
1-trick-out-01-remove-before-merge/spike_1_13_acceptance_tests/inventories/application-started-marker.txt
1-trick-out-01-remove-before-merge/spike_1_13_acceptance_tests/inventories/ci-http-readiness.txt
1-trick-out-01-remove-before-merge/spike_1_13_acceptance_tests/inventories/clean-ci-http-readiness.txt
1-trick-out-01-remove-before-merge/spike_1_13_acceptance_tests/inventories/clean-package-server-files.txt
1-trick-out-01-remove-before-merge/spike_1_13_acceptance_tests/inventories/clean-package-start-result.txt
1-trick-out-01-remove-before-merge/spike_1_13_acceptance_tests/inventories/clean-package-target-files.txt
1-trick-out-01-remove-before-merge/spike_1_13_acceptance_tests/inventories/environment.txt
1-trick-out-01-remove-before-merge/spike_1_13_acceptance_tests/inventories/liberty-ready-marker.txt
1-trick-out-01-remove-before-merge/spike_1_13_acceptance_tests/inventories/stopped-state.txt
1-trick-out-01-remove-before-merge/spike_1_13_acceptance_tests/logs/liberty-console.log
1-trick-out-01-remove-before-merge/spike_1_13_acceptance_tests/logs/liberty-messages.log
1-trick-out-01-remove-before-merge/spike_1_13_acceptance_tests/responses/cargo-rest.body
1-trick-out-01-remove-before-merge/spike_1_13_acceptance_tests/responses/cargo-rest.headers
1-trick-out-01-remove-before-merge/spike_1_13_acceptance_tests/responses/ci-cargo-rest.body
1-trick-out-01-remove-before-merge/spike_1_13_acceptance_tests/responses/ci-cargo-rest.headers
1-trick-out-01-remove-before-merge/spike_1_13_acceptance_tests/responses/clean-ci-cargo-rest.body
1-trick-out-01-remove-before-merge/spike_1_13_acceptance_tests/responses/clean-ci-cargo-rest.headers
1-trick-out-01-remove-before-merge/spike_1_13_acceptance_tests/responses/dashboard.body
1-trick-out-01-remove-before-merge/spike_1_13_acceptance_tests/responses/dashboard.headers
1-trick-out-01-remove-before-merge/spike_1_13_acceptance_tests/responses/root.body
1-trick-out-01-remove-before-merge/spike_1_13_acceptance_tests/responses/root.headers
1-trick-out-01-remove-before-merge/spike_1_13_acceptance_tests/results.json
1-trick-out-01-remove-before-merge/spike_1_13_acceptance_tests/run-spike.sh
1-trick-out-01-remove-before-merge/spike_1_13_acceptance_tests/run-summary.tsv
1-trick-out-01-remove-before-merge/spike_1_15_capture_repeatable_performance_envelope/README.md
1-trick-out-01-remove-before-merge/spike_1_15_capture_repeatable_performance_envelope/reports/environment.txt
1-trick-out-01-remove-before-merge/spike_1_15_capture_repeatable_performance_envelope/reports/jfr-configuration.txt
1-trick-out-01-remove-before-merge/spike_1_15_capture_repeatable_performance_envelope/reports/liberty-runtime-manifest.sha256
1-trick-out-01-remove-before-merge/spike_1_15_capture_repeatable_performance_envelope/reports/liberty-version.txt
1-trick-out-01-remove-before-merge/spike_1_15_capture_repeatable_performance_envelope/reports/profile-without-environment.jfc
1-trick-out-01-remove-before-merge/spike_1_15_capture_repeatable_performance_envelope/reports/request-distribution.tsv
1-trick-out-01-remove-before-merge/spike_1_15_capture_repeatable_performance_envelope/reports/results.json
1-trick-out-01-remove-before-merge/spike_1_15_capture_repeatable_performance_envelope/reports/run-summary.tsv
1-trick-out-01-remove-before-merge/spike_1_15_capture_repeatable_performance_envelope/reports/server-xml.sha256
1-trick-out-01-remove-before-merge/spike_1_15_capture_repeatable_performance_envelope/reports/statistics.tsv
1-trick-out-01-remove-before-merge/spike_1_15_capture_repeatable_performance_envelope/reports/war.sha256
1-trick-out-01-remove-before-merge/spike_1_15_capture_repeatable_performance_envelope/reports/workload-contract.txt
1-trick-out-01-remove-before-merge/spike_1_15_capture_repeatable_performance_envelope/run-spike.sh
1-trick-out-01-remove-before-merge/spike_1_16_java_vs_jaz/README.md
1-trick-out-01-remove-before-merge/spike_1_16_java_vs_jaz/reports/environment.txt
1-trick-out-01-remove-before-merge/spike_1_16_java_vs_jaz/reports/experiment-contract.txt
1-trick-out-01-remove-before-merge/spike_1_16_java_vs_jaz/reports/jaz-dry-run-bypass.txt
1-trick-out-01-remove-before-merge/spike_1_16_java_vs_jaz/reports/jaz-dry-run-bypass.txt.status
1-trick-out-01-remove-before-merge/spike_1_16_java_vs_jaz/reports/jaz-dry-run-tuned.txt
1-trick-out-01-remove-before-merge/spike_1_16_java_vs_jaz/reports/jaz-dry-run-tuned.txt.status
1-trick-out-01-remove-before-merge/spike_1_16_java_vs_jaz/reports/jaz-dry-run-user-tuning.txt
1-trick-out-01-remove-before-merge/spike_1_16_java_vs_jaz/reports/jaz-dry-run-user-tuning.txt.status
1-trick-out-01-remove-before-merge/spike_1_16_java_vs_jaz/reports/jaz-dry-run-xlog.txt
1-trick-out-01-remove-before-merge/spike_1_16_java_vs_jaz/reports/jaz-dry-run-xlog.txt.status
1-trick-out-01-remove-before-merge/spike_1_16_java_vs_jaz/reports/jaz-java-wrapper.sh
1-trick-out-01-remove-before-merge/spike_1_16_java_vs_jaz/reports/jaz-package-check.txt
1-trick-out-01-remove-before-merge/spike_1_16_java_vs_jaz/reports/jaz-package-metadata.txt
1-trick-out-01-remove-before-merge/spike_1_16_java_vs_jaz/reports/jaz-preflight-summary.txt
1-trick-out-01-remove-before-merge/spike_1_16_java_vs_jaz/reports/jaz-version.txt
1-trick-out-01-remove-before-merge/spike_1_16_java_vs_jaz/reports/jfr-configuration.txt
1-trick-out-01-remove-before-merge/spike_1_16_java_vs_jaz/reports/liberty-runtime-manifest.sha256
1-trick-out-01-remove-before-merge/spike_1_16_java_vs_jaz/reports/liberty-version.txt
1-trick-out-01-remove-before-merge/spike_1_16_java_vs_jaz/reports/mode-statistics.tsv
1-trick-out-01-remove-before-merge/spike_1_16_java_vs_jaz/reports/paired-comparison.tsv
1-trick-out-01-remove-before-merge/spike_1_16_java_vs_jaz/reports/paired-delta-statistics.tsv
1-trick-out-01-remove-before-merge/spike_1_16_java_vs_jaz/reports/profile-without-environment.jfc
1-trick-out-01-remove-before-merge/spike_1_16_java_vs_jaz/reports/request-distribution.tsv
1-trick-out-01-remove-before-merge/spike_1_16_java_vs_jaz/reports/results.json
1-trick-out-01-remove-before-merge/spike_1_16_java_vs_jaz/reports/run-order.tsv
1-trick-out-01-remove-before-merge/spike_1_16_java_vs_jaz/reports/run-summary.tsv
1-trick-out-01-remove-before-merge/spike_1_16_java_vs_jaz/reports/section-1.15-inputs.sha256
1-trick-out-01-remove-before-merge/spike_1_16_java_vs_jaz/reports/section-1.15-workload-contract.txt
1-trick-out-01-remove-before-merge/spike_1_16_java_vs_jaz/reports/selected-jvm-flags.tsv
1-trick-out-01-remove-before-merge/spike_1_16_java_vs_jaz/reports/server-xml.sha256
1-trick-out-01-remove-before-merge/spike_1_16_java_vs_jaz/reports/war.sha256
1-trick-out-01-remove-before-merge/spike_1_16_java_vs_jaz/run-spike.sh
1-trick-out-01-remove-before-merge/spike_1_1_authoritative_ci_path/README.md
1-trick-out-01-remove-before-merge/spike_1_1_authoritative_ci_path/observed-state.json
1-trick-out-01-remove-before-merge/spike_1_3_validation_tier_selection/README.md
1-trick-out-01-remove-before-merge/spike_1_3_validation_tier_selection/attempt-1-worktree-formatting-failure/run-summary.tsv
1-trick-out-01-remove-before-merge/spike_1_3_validation_tier_selection/candidate-cold-inventories/build-contract.txt
1-trick-out-01-remove-before-merge/spike_1_3_validation_tier_selection/candidate-cold-inventories/canonical-package.txt
1-trick-out-01-remove-before-merge/spike_1_3_validation_tier_selection/candidate-cold-inventories/deployable-package.txt
1-trick-out-01-remove-before-merge/spike_1_3_validation_tier_selection/candidate-cold-inventories/integration.txt
1-trick-out-01-remove-before-merge/spike_1_3_validation_tier_selection/candidate-cold-inventories/unit.txt
1-trick-out-01-remove-before-merge/spike_1_3_validation_tier_selection/candidate-cold-summary.tsv
1-trick-out-01-remove-before-merge/spike_1_3_validation_tier_selection/candidate-inventories/build-contract.txt
1-trick-out-01-remove-before-merge/spike_1_3_validation_tier_selection/candidate-inventories/canonical-package.txt
1-trick-out-01-remove-before-merge/spike_1_3_validation_tier_selection/candidate-inventories/deployable-package.txt
1-trick-out-01-remove-before-merge/spike_1_3_validation_tier_selection/candidate-inventories/integration.txt
1-trick-out-01-remove-before-merge/spike_1_3_validation_tier_selection/candidate-inventories/unit.txt
1-trick-out-01-remove-before-merge/spike_1_3_validation_tier_selection/candidate-summary.tsv
1-trick-out-01-remove-before-merge/spike_1_3_validation_tier_selection/inventories/cold-environment.txt
1-trick-out-01-remove-before-merge/spike_1_3_validation_tier_selection/inventories/cold-formatting.txt
1-trick-out-01-remove-before-merge/spike_1_3_validation_tier_selection/inventories/cold-package.txt
1-trick-out-01-remove-before-merge/spike_1_3_validation_tier_selection/inventories/cold-test.txt
1-trick-out-01-remove-before-merge/spike_1_3_validation_tier_selection/inventories/cold-verify.txt
1-trick-out-01-remove-before-merge/spike_1_3_validation_tier_selection/inventories/warm-environment.txt
1-trick-out-01-remove-before-merge/spike_1_3_validation_tier_selection/inventories/warm-formatting.txt
1-trick-out-01-remove-before-merge/spike_1_3_validation_tier_selection/inventories/warm-package.txt
1-trick-out-01-remove-before-merge/spike_1_3_validation_tier_selection/inventories/warm-test.txt
1-trick-out-01-remove-before-merge/spike_1_3_validation_tier_selection/inventories/warm-verify.txt
1-trick-out-01-remove-before-merge/spike_1_3_validation_tier_selection/results.json
1-trick-out-01-remove-before-merge/spike_1_3_validation_tier_selection/run-candidate-tiers.sh
1-trick-out-01-remove-before-merge/spike_1_3_validation_tier_selection/run-spike.sh
1-trick-out-01-remove-before-merge/spike_1_3_validation_tier_selection/run-summary.tsv
1-trick-out-01-remove-before-merge/spike_1_4_dependency_governance/README.md
1-trick-out-01-remove-before-merge/spike_1_4_dependency_governance/generated-poms/banned-dependencies.xml
1-trick-out-01-remove-before-merge/spike_1_4_dependency_governance/generated-poms/dependency-convergence.xml
1-trick-out-01-remove-before-merge/spike_1_4_dependency_governance/generated-poms/no-duplicate-declarations.xml
1-trick-out-01-remove-before-merge/spike_1_4_dependency_governance/generated-poms/no-project-repositories.xml
1-trick-out-01-remove-before-merge/spike_1_4_dependency_governance/generated-poms/reject-banned-dependency.xml
1-trick-out-01-remove-before-merge/spike_1_4_dependency_governance/generated-poms/reject-duplicate-declaration.xml
1-trick-out-01-remove-before-merge/spike_1_4_dependency_governance/generated-poms/reject-java-version.xml
1-trick-out-01-remove-before-merge/spike_1_4_dependency_governance/generated-poms/reject-maven-version.xml
1-trick-out-01-remove-before-merge/spike_1_4_dependency_governance/generated-poms/reject-project-repository.xml
1-trick-out-01-remove-before-merge/spike_1_4_dependency_governance/generated-poms/reject-unversioned-plugin.xml
1-trick-out-01-remove-before-merge/spike_1_4_dependency_governance/generated-poms/require-java-version.xml
1-trick-out-01-remove-before-merge/spike_1_4_dependency_governance/generated-poms/require-maven-version.xml
1-trick-out-01-remove-before-merge/spike_1_4_dependency_governance/generated-poms/require-plugin-versions.xml
1-trick-out-01-remove-before-merge/spike_1_4_dependency_governance/generated-poms/require-upper-bound-deps.xml
1-trick-out-01-remove-before-merge/spike_1_4_dependency_governance/generated-poms/selected-plugin-version-policy.xml
1-trick-out-01-remove-before-merge/spike_1_4_dependency_governance/run-spike.sh
1-trick-out-01-remove-before-merge/spike_1_4_dependency_governance/run-summary.tsv
1-trick-out-01-remove-before-merge/spike_1_8_spotless/README.md
1-trick-out-01-remove-before-merge/spike_1_8_spotless/inventories/advanced-malformed-baseline.txt
1-trick-out-01-remove-before-merge/spike_1_8_spotless/inventories/historical-clean.txt
1-trick-out-01-remove-before-merge/spike_1_8_spotless/inventories/historical-fixture.txt
1-trick-out-01-remove-before-merge/spike_1_8_spotless/inventories/proposed-clean.txt
1-trick-out-01-remove-before-merge/spike_1_8_spotless/inventories/proposed-fixture.txt
1-trick-out-01-remove-before-merge/spike_1_8_spotless/inventories/whole-tree.txt
1-trick-out-01-remove-before-merge/spike_1_8_spotless/run-spike.sh
1-trick-out-01-remove-before-merge/spike_1_8_spotless/run-summary.tsv
1-trick-out-01-remove-before-merge/spike_1_9_compiler_options/README.md
1-trick-out-01-remove-before-merge/spike_1_9_compiler_options/inventories/category-rawtypes.txt
1-trick-out-01-remove-before-merge/spike_1_9_compiler_options/inventories/category-serial.txt
1-trick-out-01-remove-before-merge/spike_1_9_compiler_options/inventories/explicit-serial-version-uids.txt
1-trick-out-01-remove-before-merge/spike_1_9_compiler_options/inventories/generated-serial-version-uids.txt
1-trick-out-01-remove-before-merge/spike_1_9_compiler_options/inventories/runtime-classpath.txt
1-trick-out-01-remove-before-merge/spike_1_9_compiler_options/inventories/type-failure.txt
1-trick-out-01-remove-before-merge/spike_1_9_compiler_options/inventories/xlint-all-werror.txt
1-trick-out-01-remove-before-merge/spike_1_9_compiler_options/inventories/xlint-all.txt
1-trick-out-01-remove-before-merge/spike_1_9_compiler_options/inventories/xlint-clean-subset.txt
1-trick-out-01-remove-before-merge/spike_1_9_compiler_options/proposed-warning-fixes.patch
1-trick-out-01-remove-before-merge/spike_1_9_compiler_options/results.json
1-trick-out-01-remove-before-merge/spike_1_9_compiler_options/run-spike.sh
1-trick-out-01-remove-before-merge/spike_1_9_compiler_options/run-summary.tsv
1-trick-out-01-remove-before-merge/spike_1_9_compiler_options/warnings.tsv
1-trick-out-01-remove-before-merge/trick-out-01-ignorance-reduction-plan.md
<shellId: 3 completed with exit code 0>
```

</details>


---

<sub>24s</sub>

### `view`

**view the file at /home/edburns/workareas/dd-3016202-cargotracker-devoxx-be-2026-02/1-trick-out-01-remove-before-merge/trick-out-01-ignorance-reduction-plan.md.**

/home/edburns/workareas/dd-3016202-cargotracker-devoxx-be-2026-02/1-trick-out-01-remove-before-merge/trick-out-01-ignorance-reduction-plan.md (lines 1-450)

<details>
<summary>240 lines</summary>

````
# Implementation plan: Trick out Cargo Tracker for agent-safe Java development (dd-3070726 / campaign #1)

Human DRI: Ed Burns<br>
Campaign: `1-trick-out-01-remove-before-merge`<br>
Campaign ID: `474aebe4-23f7-45cf-a841-e214bdcdd132`<br>
Repository: `edburns/dd-3016202-cargotracker-devoxx-be-2026`<br>
Campaign base branch: `edburns/dd-3016202-cargotracker-devoxx-be-2026-experiment`<br>
Campaign issue: https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/issues/1<br>
Azure DevOps work item: https://devdiv.visualstudio.com/DevDiv/_workitems/edit/3070726<br>
Campaign metadata: `1-trick-out-01-remove-before-merge/shepherd-campaign.json`<br>
Campaign evidence: `1-trick-out-01-remove-before-merge/evidence-matrix.md`<br>
Campaign lessons: `1-trick-out-01-remove-before-merge/campaign-lessons.md`<br>
Talk abstract: `dd-3032592-10-boring-reasons-abstract.md`<br>
Application root: `demo/`<br>
Primary workflow: `.github/workflows/main.yml`<br>

---

## Goal

Create a tagged, feature-absent Cargo Tracker baseline whose Java 17 build,
compatibility rules, deterministic source gates, behavioral tests,
observability, and JVM diagnostics give later coding agents fast and useful
feedback.

The baseline will be used by a separate Shepherd Task campaign that adds the
Change Arrival Deadline feature. This campaign does not prove the talk's
hypothesis merely by installing tools. It creates the guardrails and durable
artifact paths needed to observe whether those guardrails execute, detect
mistakes, prevent mistakes, or materially improve the later agents' work.

Every increment must preserve required green GitHub Actions CI before the next
serial issue begins. The campaign must prefer a small number of attributable,
reliable controls over a broad collection of noisy checks.

This is the demo app accompanying a presentation whose abstract is in `dd-3032592-10-boring-reasons-abstract.md`.

### Baseline technology contract

| Concern | Current contract |
|---|---|
| Java runtime and compiler | Microsoft Build of OpenJDK 17 in CI; `maven.compiler.release` 17 |
| Enterprise API | Java EE 7 through `javax:javaee-api:7.0`; no migration to `jakarta.*` |
| Packaging | Maven WAR named `cargo-tracker.war` |
| Runtime | Open Liberty 26.0.0.8 with `javaee-7.0` |
| Data | Embedded Derby for the demo and Open Liberty tests |
| UI | JSF and PrimeFaces 8 |
| Build entry point | Maven Wrapper from the repository; commands run in `demo/` |
| Existing fast gate | Spotless with Google Java Format and a historical ratchet |
| Existing tests | JUnit 5 domain tests plus Arquillian/Open Liberty integration tests; some scenario and routing tests appear dormant and require verification |
| Existing CI | `formatting` followed by `build` in `.github/workflows/main.yml` |

### Reasons exercised by this campaign

| Abstract reason | Planned treatment |
|---|---|
| 1. Type system | Make compilation and useful compiler diagnostics explicit and attributable |
| 2. Testing ecosystem | Strengthen domain, application, architecture, Open Liberty, and HTTP verification |
| 3. Backwards compatibility culture | Enforce Java 17, Java EE 7, `javax.*`, WAR, and Open Liberty boundaries |
| 4. Deep static analysis | Add one useful analyzer at a time with a controlled legacy baseline |
| 5. Build system maturity and dependency management | Add reproducibility, Maven, plugin, dependency, and repository rules |
| 6. Code formatting and style enforcement | Preserve and clarify the existing Spotless gate |
| 7. Virtual threads and structured concurrency | No code spike in this campaign; explain on slides because the demo remains on JDK 17 |
| 8. Observability stack | Capture diagnosable logs, metrics, and traces as durable CI artifacts |
| 9. JVM performance tuning | Capture repeatable startup, memory, GC, JFR, and `java` versus `jaz` evidence |
| 10. Breadth of deployment options | Outside this campaign; tracked separately by dd-3070761 |

### Success criteria

1. Pushes and pull requests for the experiment branch receive an authoritative
   workflow run.
2. Each generated implementation issue is independently useful and leaves all
   required checks green.
3. The Maven build rejects violations of the resolved Java, Java EE, packaging,
   dependency, plugin, and repository contract.
4. Formatting, compiler, static-analysis, unit, integration, runtime, and
   performance results are distinguishable by job, step, log, and artifact.
5. Expensive or noisy checks do not obscure earlier deterministic failures.
6. Runtime and performance jobs use bounded waits and cannot hang indefinitely.
7. Every issue updates and merges the campaign evidence matrix before the next
   issue begins.
8. Reason 7 remains a slide-only discussion; this plan introduces no Java 21
   source set, module, branch, or workflow.
9. Reason 10 remains in the separate Azure deployment risk-reduction thread and
   does not block this trick-out campaign.
10. The final tagged baseline is created only from a commit whose complete
    required workflow set is green.

---

## Completed phases

### Phase 0.1 ✅ — Establish campaign state

- Shepherd Task 1.0.4 initialized campaign
  `474aebe4-23f7-45cf-a841-e214bdcdd132`.
- The campaign base branch is
  `edburns/dd-3016202-cargotracker-devoxx-be-2026-experiment`.
- Lesson propagation is disabled; reusable lessons remain available in
  `campaign-lessons.md` but are not automatically injected into later issues.

### Phase 0.2 ✅ — Establish the evidence-capture structure

- `evidence-matrix.md` contains the ten canonical reasons in the abstract's
  original order.
- Every reason begins at `Not exercised`.
- The matrix defines durable artifact expectations and an append-only
  per-issue evidence log.

### Phase 0.3 ✅ — Establish the known green starting behavior

- Known green GitHub Actions runs `36182474700` and `36183229399` executed the
  existing `formatting` and `build` jobs.
- The existing workflow uses Microsoft Build of OpenJDK 17.
- The current push trigger does not name the experiment branch; pull-request
  and manual dispatch paths exist, but an authoritative per-increment path
  still must be resolved.

### Phase 0.4 ✅ — Bound concurrency and Azure scope

- The Cargo Tracker application remains on JDK 17.
- Reason 7 will be covered with slides rather than a Java 21 implementation
  spike.
- Azure deployment risk reduction is tracked separately by dd-3070761 and is
  not part of the ordered implementation below.

---

## Phase 1 — Ignorance reduction: questions to resolve before creating issues

Resolve these questions in order. Earlier answers constrain later tool
selection and workflow design. Each `Resolution:` field is intentionally empty
for human completion.

### 1.1 — Authoritative experiment-branch CI path

**Question:** Which GitHub Actions event and branch rules will prove that each
commit merged into
`edburns/dd-3016202-cargotracker-devoxx-be-2026-experiment` passed the complete
required workflow set?

The current workflow runs automatically for pushes to the non-demo
`...-01` branch, for pull requests, and for manual dispatch. That is not enough
to establish an automatic experiment-branch invariant unless the operating
procedure always creates a qualifying pull request and verifies its exact head
SHA.

| Option | Shape | Trade-off |
|---|---|---|
| A | Add the experiment branch to the existing `push.branches` list | Smallest change; validates every pushed increment but may duplicate PR runs |
| B | Make PR validation authoritative and require an exact-head workflow before merge | Strong merge gate; depends on repository branch-protection configuration outside the workflow file |
| C | Use only `workflow_dispatch` and record the selected SHA | Flexible but human-dependent and easiest to forget |
| D | Use A for continuous evidence and B for merge protection | Strongest coverage but produces more workflow activity |

**Recommendation:** Use option D when repository rulesets permit it: add the
experiment branch to `push`, retain PR validation, and make stable job names
required. At minimum, use option A so every experiment-branch increment gets an
automatic run.

**Failure example:** Push a harmless branch-only change to an isolated test
branch with equivalent trigger configuration and verify the workflow starts
for the exact SHA. Do not manufacture a red commit on the campaign base branch.

**Resolution:**

Completed spike 1.1 and stored the results in:

```
1-trick-out-01-remove-before-merge/spike_1_1_authoritative_ci_path/
   README.md
   observed-state.json
```

Result: Select option D. Add automatic experiment-branch `push` validation, retain PR validation, and create a ruleset requiring `formatting` and `build`. PR runs validate GitHub’s synthetic merge ref, while push runs validate the exact merged campaign-base SHA, so the two paths are complementary. GitHub rulesets can require named status checks before merging. 

The repository currently has no rulesets or branch protection and previously had no experiment-branch workflow runs. I manually dispatched `Main Build` against experiment SHA `3016bc265e6301edb591b2c352363ccf75b18b63`; run `36619468411` completed successfully with both `formatting` and `build` green.  The report includes proposed text for the plan’s human-owned `Resolution:` field, which remains unchanged.

### 1.2 — Required job topology and fail-fast order

**Question:** Should the workflow remain a strictly serial chain, or should
independent jobs fan out after a common build-contract job?

The desired diagnostic order is:

1. formatting;
2. build and dependency contract;
3. compatibility and compiler checks;
4. static analysis;
5. unit tests;
6. Open Liberty integration and HTTP acceptance;
7. observability;
8. performance evidence.

A fully serial workflow is easy to understand but can be slow. A fully parallel
workflow is faster but may spend time on expensive runtime jobs after a cheap
gate has already failed.

**Recommendation:** Keep formatting first. Make a build-contract job depend on
formatting. Fan out compiler/static analysis and unit tests after the contract
job. Make Open Liberty acceptance depend on unit tests, observability depend on
acceptance, and performance depend on the stable runtime workload. Preserve
stable job and check names for branch protection and slide evidence.

**Resolution:**

For simplicity keep the workflows as fully serial.

### 1.3 — Canonical local and CI Maven commands

**Question:** What exact command set defines the green baseline for each validation
tier, given that the `openliberty` profile is active by default and binds
Liberty creation and feature installation to `compile`?

The current workflow runs:

```bash
./mvnw spotless:check
./mvnw clean package --file pom.xml
```

The active Open Liberty profile means even apparently simple Maven phases may
download and configure a Liberty runtime. The plan needs commands that are
honest about what they exercise and avoid repeating expensive setup
unnecessarily.

**Recommendation:** Define named command tiers in repository documentation and
workflow steps: `format`, `contract`, `unit`, `integration`, and `package`.
Reuse the Maven local repository cache but never reuse generated `target/`
output as proof of a clean build.

**Resolution:**

Completed spike 1.3 in:

```
1-trick-out-01-remove-before-merge/spike_1_3_validation_tier_selection/
```

Selected commands:

```
┌──────────────────┬─────────────────────────────────────────────────────────────────────────────────────────────┬─────────────────────────────────────────────────────────┐
│ Tier             │ Command                                                                                     │ Liberty behavior                                        │
├──────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────┤
│ Environment      │ ./mvnw -version                                                                             │ None                                                    │
├──────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────┤
│ Formatting       │ ./mvnw spotless:check                                                                       │ None, but currently fails in linked worktrees because   │
│                  │                                                                                             │ Spotless cannot locate the Git ratchet repository       │
├──────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────┤
│ Build            │ ./mvnw '-P!openliberty' -DskipTests clean compile                                           │ No download, creation, or startup                       │
│ contract/compile │                                                                                             │                                                         │
├──────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────┤
│ Unit tests       │ ./mvnw '-P!openliberty'                                                                     │ Runs 24 tests without Liberty                           │
│                  │ -Dtest=CargoTest,ItineraryTest,RouteSpecificationTest,HandlingEventTest,HandlingHistoryTest │                                                         │
│                  │ clean test                                                                                  │                                                         │
├──────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────┤
│ Integration      │ ./mvnw -Popenliberty -Dtest=BookingServiceTest clean test                                   │ Downloads, creates, and starts Liberty; runs four tests │
│ tests            │                                                                                             │                                                         │
├──────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────┤
│ Packaging        │ ./mvnw -Popenliberty -Dskip=true -DskipTests clean package                                  │ Produces the canonical WAR without downloading,         │
│                  │                                                                                             │ creating, or starting Liberty                           │
└──────────────────┴─────────────────────────────────────────────────────────────────────────────────────────────┴─────────────────────────────────────────────────────────┘
```

The default `clean test`, `clean package`, and `-Popenliberty verify` commands all start Liberty and run the same 28 tests; `verify` adds no distinct verification. The package command above preserves the Open Liberty profile’s Jackson dependencies and produced the canonical 8,233,001-byte WAR.

Detailed results, cold/warm measurements, Maven logs, inventories, scripts, proposed resolution text, and machine-readable results are in `README.md` and `results.json`.

### 1.4 — Maven and dependency-governance rules

**Question:** Which Maven Enforcer and dependency checks provide strong,
low-noise evidence without turning the legacy application into a dependency
modernization project?

Candidate rules include:

| Rule | Value | Principal risk |
|---|---|---|
| `requireJavaVersion` | Enforces Java 17 | Accidentally accepting a newer developer JDK without release discipline |
| `requireMavenVersion` | Makes wrapper/tool assumptions explicit | Choosing a minimum incompatible with the checked-in wrapper |
| `requirePluginVersions` | Prevents implicit plugin drift | May expose lifecycle plugins not explicitly versioned |
| `dependencyConvergence` | Finds conflicting dependency graphs | Arquillian and Liberty test graphs may contain legitimate conflicts |
| `requireUpperBoundDeps` | Detects older transitive selections | Often noisy on mature Java EE dependency graphs |
| `banDuplicatePomDependencyVersions` | Rejects ambiguous POM declarations | Low risk and deterministic |
| `bannedDependencies` | Prevents Jakarta/Spring/runtime migration | Patterns must avoid banning required test/runtime artifacts |
| `externalRules` or repository checks | Restricts unapproved repositories | Must account for Maven Central and any Liberty-specific artifact source |

**Recommendation:** Start with Java/Maven version, plugin version,
duplicate-declaration, and narrowly scoped banned-dependency rules. Add
convergence or upper-bound enforcement only if the baseline can be made green
with small, understandable dependency-management changes.

**Failure example:** In a temporary POM copy, add an unapproved dependency or
an unversioned plugin and verify the resolved rule fails with an actionable
message.

**Resolution:**

The spike tells us to adopt a small, Open Liberty-only governance policy—not every candidate rule.

Select:

- `requireJavaVersion` → `[17,18)`
- `requireMavenVersion` → `[3.9.9,4.0.0)`
- strict `requirePluginVersions`
- pin only `maven-clean-plugin` `3.2.0`
- pi

[Output truncated. Use view_range=[308, ...] to continue reading. In your next response, you may batch this with other view calls. File has at least 1677 lines.]
````

</details>


---

<sub>24s</sub>

### `view`

**view the file at /home/edburns/workareas/dd-3016202-cargotracker-devoxx-be-2026-02/1-trick-out-01-remove-before-merge/trick-out-01-ignorance-reduction-plan.md.**

/home/edburns/workareas/dd-3016202-cargotracker-devoxx-be-2026-02/1-trick-out-01-remove-before-merge/trick-out-01-ignorance-reduction-plan.md (lines 451-900)

<details>
<summary>255 lines</summary>

````
  - "**/pom.xml"
  - "**/.mvn/**"
  - "**/mvnw"
  - "**/mvnw.cmd"
  - "**/build.gradle"
  - "**/build.gradle.kts"
  - "**/settings.gradle"
  - "**/settings.gradle.kts"
  - "**/gradlew"
  - "**/gradlew.bat"
```

```markdown
## 3) Maven execution: tee-to-log (required)

Whenever you invoke `mvn` (including via `./mvnw`), you must:

- pipe **both stdout and stderr** through `tee` to a log file
- this streams output to the console AND saves it to the file simultaneously
- use this log naming pattern: `YYYYMMDD-HHMM-job-logs.txt` (local time)
- look at the log file to evaluate the success or failure of the command
- note the exact log filename and always use that exact filename to check results — do NOT guess with `ls -t`, glob sorting, or similar
- ❌ do not use background `&` + `tail -f` (breaks under VS Code sandbox regime)
- ❌ do not use any other output redirecting or tailing scheme
- ✅ Use `requestUnsandboxedExecution` so the environment variables stick. See below.

### POSIX (bash/zsh) pattern

mvn [YOUR_GOALS] 2>&1 | tee "$(date +%Y%m%d-%H%M)-job-logs.txt"

Replace \[YOUR GOALS\] with whatever `mvn` goals are appropriate in your particular case.

### PowerShell pattern

function Invoke-WithTeeLog {
    param(
        [Parameter(ValueFromRemainingArguments=$true)]
        [string[]]$Command
    )
    $log = "$(Get-Date -Format 'yyyyMMdd-HHmm')-job-logs.txt"
    Write-Host "Log file: $((Resolve-Path -Path '.' | Join-Path -ChildPath $log))" -ForegroundColor Cyan
    $cmdString = $Command -join ' '
    Invoke-Expression "$cmdString 2>&1" | Tee-Object -FilePath $log
}
Set-Alias -Name runt -Value Invoke-WithTeeLog

then

runt mvn [YOUR GOALS]
```


### 1.8 — Spotless baseline and ratchet semantics

**Question:** Should the existing Spotless `ratchetFrom` remain pinned to
`1fd1c340fa56c6c77a601d2fbba20294afa46dd9`, move to the tagged trick-out
baseline, or be replaced by whole-tree formatting?

Keeping the historical ratchet minimizes churn but can make it hard to explain
which files are checked. Reformatting the whole legacy tree creates a large,
low-value diff and may obscure subsequent agent changes. Moving the ratchet too
early may silently grandfather files that should remain in scope.

**Recommendation:** Preserve the current ratchet through the trick-out issues
unless it fails to cover later modified Java files. Document its semantics and
keep `formatting` as the first required job. Reconsider the ratchet only when
tagging the completed pre-feature baseline.

**Failure example:** Format a temporary Java fixture incorrectly and verify
`spotless:check` reports the file and remediation command.

**Resolution:**

The repeatable six-case spike, logs, inventories, summary, are in `1-trick-out-01-remove-before-merge/spike_1_8_spotless/`. The campaign worktree’s Java sources were not modified.

Keep `ratchetFrom` pinned to `1fd1c340fa56c6c77a601d2fbba20294afa46dd9` throughout the trick-out implementation issues, with `formatting` remaining the first required CI job.

Do not adopt whole-tree formatting: it rewrote 95 of 106 Java files, with 5,245 added and 5,184 deleted lines. The historical ratchet and a simulated ratchet at current HEAD behaved identically because no tracked Java files currently differ between them. Both detected and repaired a modified legacy file and a newly added Java file.

Do not advance the ratchet early. The spike committed malformed Java and moved the ratchet to that commit; both `spotless:check` and `spotless:apply` then passed without touching the malformed files. Advance it only after the complete feature-absent trick-out baseline passes all gates and is tagged. Validate that commit using the old ratchet, then update `ratchetFrom` in a following POM-only commit to the tag’s immutable full commit SHA.

### 1.9 — Compiler diagnostics and type-system evidence

**Question:** Which compiler warnings can be enabled and enforced without
creating a large legacy-cleanup issue or conflating external analyzer findings
with Java's type system?

Candidates include `-Xlint:all`, selected `-Xlint` categories, deprecation
reporting, parameter metadata, and `-Werror`. The project uses Java EE 7 APIs,
older libraries, reflection, and serialization patterns that may produce
warnings unrelated to agent-created errors.

**Recommendation:** Keep compilation as its own named step and enable the
largest actionable warning subset that is clean. Do not use Error Prone,
NullAway, or another compiler replacement unless a spike proves compatibility
with Java 17, Java EE 7, annotation processing, and the existing Maven build.

**Failure example:** Compile an isolated fixture that calls a nonexistent
method or crosses a typed API boundary and preserve the compiler diagnostic as
an example; do not intentionally break campaign CI.

**Resolution:**

Completed Spike 1.9 in:

`1-trick-out-01-remove-before-merge/spike_1_9_compiler_options/`

The incorrectly created `spike_1_8_spotless/compiler-diagnostics-1.9` directory was removed. The independent Section 1.8 Spotless artifacts remain intact.

Enable the full javac warning set rather than a reduced subset. On experiment baseline `cf19be6029aad88ce792e544cc4dd8135867723f`, `-Xlint:all` reported 14 warnings: 12 `serial` warnings and two `rawtypes` warnings. Both categories failed independently under `-Werror`; disabling exactly those categories made the remaining full warning set pass.

All 14 warnings fit in one small implementation issue and require no permanent baseline. Correct the raw `ArrayList` construction in `SampleVoyages` with the diamond operator and change `ChangeDestinationDialog.handleReturn` to accept `SelectEvent<?>`. Add explicit `serialVersionUID` fields to the 12 serializable classes, using the current generated values captured by `serialver` rather than arbitrary `1L` values so existing serialization identities are preserved.

After those corrections, both 95 main sources and 11 test sources compiled successfully with `-Xlint:all -Werror`. Configure `maven-compiler-plugin` with `showWarnings`, `-Xlint:all`, and `-Werror`, and keep:

./mvnw '-P!openliberty' -DskipTests clean compile

as a distinct named CI compilation check. Preserve a validation path that also reaches `testCompile`. Do not add Error Prone, NullAway, or another compiler replacement during this campaign.

The controlled failure fixture called nonexistent `Cargo.agentInventedMethod(String)` and javac rejected it with a precise `cannot find symbol` diagnostic. The repeatable harness, warning inventory, proposed source patch, UID compatibility evidence, results JSON, and logs are retained in the spike directory. No Open Liberty runtime was downloaded, created, or started.

### 1.10 — Static analyzer and legacy-debt strategy

**Question:** Which single initial analyzer best finds meaningful defects in
this Cargo Tracker codebase with acceptable runtime and baseline complexity?

| Candidate | Strength | Risk |
|---|---|---|
| SpotBugs | Bytecode-level bug patterns, familiar Maven integration | Java EE/container patterns may require exclusions; runs after compilation |
| PMD | Source-level correctness and maintainability rules | Default rulesets can produce broad style debt overlapping Spotless |
| Checkstyle | Precise source/style rules | Duplicates formatting and is weaker evidence for "deep" analysis |
| ArchUnit | Enforces package/layer architecture in tests | Best treated as behavioral architecture verification rather than the sole general analyzer |

**Recommendation:** Prefer SpotBugs as the first general analyzer if its
baseline is tractable. Keep style rules in Spotless, architecture rules in
tests, and dependency vulnerability analysis in the build/dependency issue.
Check in every exclusion with a narrow match and rationale.

**Failure example:** Use an analyzer-provided test fixture or temporary class
containing a known null-dereference/resource bug and assert that the selected
rules detect it.

**Resolution:**

Spike 1.10 is complete. Decision: select SpotBugs and defer PMD. The artifacts, repeatable harness, reports, classification, and resolution are in `1-trick-out-01-remove-before-merge/spike_1_10_static-analyzer/`.

### 1.11 — Actual test inventory and dormant-test disposition

**Question:** Which existing tests execute in the canonical Maven build, and
what should happen to test-shaped classes whose methods lack JUnit 5
annotations or setup hooks?

The current tree contains:

- focused JUnit 5 domain tests;
- Arquillian/Open Liberty tests such as `BookingServiceTest`;
- `CargoLifecycleScenarioTest`, whose scenario method and setup method do not
  currently carry JUnit 5 annotations;
- `ExternalRoutingServiceTest`, whose test method also appears unannotated and
  whose setup is commented out.

It is unsafe to describe the project as having scenario or routing coverage
until execution reports prove those tests run.

**Recommendation:** Classify every existing test as active, intentionally
dormant, or repairable. Repair only tests that can express stable behavior
without reconstructing obsolete infrastructure. Remove no test-shaped code
without documenting why it cannot provide reliable coverage.

**Resolution:**

Classify every existing test as active, intentionally
dormant, or repairable. Repair only tests that can express stable behavior
without reconstructing obsolete infrastructure. Remove no test-shaped code
without documenting why it cannot provide reliable coverage.

### 1.12 — Behavioral safety net for the later deadline feature

**Question:** What minimum behavioral contracts must exist before the
five-issue Change Arrival Deadline campaign begins?

The later feature crosses:

1. the cargo aggregate and route specification;
2. the `BookingService` application boundary;
3. the booking facade and DTO boundary;
4. JSF backing state;
5. the PrimeFaces Administration UI.

The trick-out campaign must not implement that feature, but it should ensure
the existing behavior around booking, routing, destination changes, cargo
lookup, and Administration startup is protected.

**Recommendation:** Add or strengthen:

- focused domain tests for route specification and itinerary invariants;
- application/Arquillian tests around `BookingService`;
- architecture checks that prevent domain types from leaking into the web
  layer and prevent domain code from depending on application/interfaces;
- an Open Liberty HTTP smoke test for `/cargo-tracker/`;
- a stable Administration-page or REST interaction that proves the deployed
  application is usable.

**Failure example:** Mutate an assertion or temporary fixture so a cargo route
violates a known invariant; verify the intended test layer reports a concise
failure.

**Resolution:**

Spike 1.12 is complete. Decision: retain the existing JUnit 5 and Arquillian
foundation, add a production-WAR HTTP acceptance boundary using seeded cargo
`ABC123`, and defer browser automation. The artifacts, repeatable harness,
reports, findings, and resolution are in
`1-trick-out-01-remove-before-merge/spike_1_12_behavior_saftey_net/`.

### 1.13 — Open Liberty lifecycle and acceptance-test boundary

**Question:** Should Open Liberty acceptance reuse Arquillian's managed server,
or should CI start the packaged application once and run black-box HTTP checks
against it?

Arquillian is appropriate for in-container integration tests, but black-box
acceptance should validate the same packaged WAR and `server.xml` used by the
demo. Starting Liberty separately for every test class would be slow and
fragile.

**Recommendation:** Keep Arquillian for focused in-container tests. Add one
bounded workflow job that packages the WAR, starts Open Liberty once, waits for
a positive readiness signal, runs HTTP checks, captures logs, and always stops
the server. Use explicit timeouts and print server logs on failure.

**Resolution:**

Accept the existing recommendation. Keep Arquillian for focused in-container tests and use one black-box acceptance job with this verified lifecycle:

./mvnw -DskipTests clean package
./mvnw liberty:deploy
./mvnw -Dapplications=cargo-tracker -DserverStartTimeout=90 liberty:start

   > # Run bounded HTTP checks
./mvnw liberty:stop

Key findings:

- `liberty:deploy` is required; `clean package` creates the WAR and runtime but does not deploy the application.
- `liberty:start` waits for both `CWWKF0011I`—“is ready to run a smarter planet”—and `CWWKZ0001I` for `cargo-tracker`.
- Use `GET /cargo-tracker/rest/cargo` as readiness. Require HTTP 200, JSON content type, and seeded content such as `"trackingId":"ABC123"`.
- Do not gate on `liberty:status` exit status: it returned zero both while running and after reporting the server stopped.
- `liberty:run` works for development, but its foreground lifecycle is unsuitable for CI orchestration.
- The repeatable harness always invokes `liberty:stop` through an exit trap and preserves Maven, Liberty, and HTTP evidence.

The final harness passed root-page, dashboard, REST-content, and JSON content-type checks. Liberty was stopped and scratch runtimes were removed. The paste-ready resolution, `results.json`, logs, negative missing-deployment experiment, responses, and runnable `run-spike.sh` are retained in the spike directory.

Fully examine the complete spike in `1-trick-out-01-remove-before-merge/spike_1_13_acceptance_tests/`.

### 1.14 — Runtime observability mechanism

**Question:** What is the smallest observability design that produces useful
logs, metrics, and traces in GitHub Actions without making CI depend on Azure?

Options include:

| Option | Shape | Trade-off |
|---|---|---|
| A | Existing `java.util.logging` plus Liberty logs | Lowest change; weak correlation and no traces |
| B | OpenTelemetry Java agent plus local collector | No application API migration; produces standard traces/metrics/log correlation |
| C | Add MicroProfile Telemetry/Metrics features | Strong Liberty integration but may conflict with the Java EE 7 feature contract or require source changes |
| D | Application Insights Java agent | Relevant to Azure but makes generic CI evidence depend on an Azure-oriented agent and possibly an external resource |

**Recommendation:** Prefer option B for this campaign. Preserve Liberty logs
and use Azure Monitor/Application Insights only in the separate deployment
thread or as optional follow-on evidence.

**Resolution:**

Select option B for the agentic inner loop. Attach a pinned OpenTelemetry Java agent to the Java 17 Open Liberty runtime without changing application APIs or adding MicroProfile features. Run a pinned local OpenTelemetry Collector alongside Liberty in GitHub Actions, export traces and metrics to local machine-readable files, and preserve Liberty console and `messages.log` output as build artifacts. After Liberty is ready, exercise the stable `/cargo-tracker/rest/cargo` endpoint and fail the observability check unless it produces a successful server trace and non-empty JVM/runtime metric samples. Archive the collector configuration, telemetry output, Liberty logs, and diagnostic output needed to explain a failed assertion. The inner loop must require no Azure resource, credentials, or external telemetry service and must remain reproducible locally with the same commands used in CI. Keep sampling deterministic for the exercised request, pin the agent and collector versions or image digest, and treat missing telemetry or collector failure as an explicit test failure. Azure Monitor, Application Insights, and triggered JFR profiling belong to the separate deployed-system feedback loop and do not replace or gate this local inner-loop evidence.

### 1.15 — Repeatable performance workload and resource envelope

**Question:** What exact bounded workload, controlled JVM/runner context,
measurement protocol, repetition count, and failure policy will produce
comparable JVM performance evidence in hosted CI despite normal runner
variability?

The purpose is to define and validate the experiment that section 1.16 will
reuse unchanged. It is not to introduce containerization, tune Cargo Tracker,
select a benchmark winner, or enforce narrow latency regressions.

The workload contract must resolve:

- the exact WAR checksum and Open Liberty configuration under test;
- the launch-to-readiness boundary, using the lifecycle and readiness signal
  established in resolution 1.13;
- the warm-up request sequence;
- the measured HTTP endpoints, request data, request count, concurrency, and
  pacing;
- the shutdown and cleanup sequence;
- the maximum duration for startup, workload, diagnostics, and the complete
  repetition.

The execution context must remain non-containerized. Run Open Liberty directly
on a fresh GitHub-hosted Linux runner with Microsoft Build of OpenJDK 17.
Record rather than synthesize the runner's CPU, memory, operating system,
kernel, and `/sys/fs/cgroup` view. Do not impose Docker/OCI limits or create a
privileged nested cgroup. Because section 1.16 must allow `jaz` to select JVM
tuning, do not make `-X*` or `-XX*` tuning flags part of the workload contract.
Diagnostic flags that do not suppress `jaz` tuning may be retained.

Each repetition must capture:

- process-launch-to-readiness duration;
- workload success, response validation, and request-duration summary;
- peak process RSS and process CPU time;
- effective JVM command and flags;
- heap and GC evidence available without changing the launch policy;
- explicit GC logging;
- a bounded JFR recording started dynamically after launch;
- total repetition duration, exit status, and cleanup result.

**Recommendation:** Use the direct Open Liberty lifecycle established in
resolution 1.13 and the stable `/cargo-tracker/rest/cargo` acceptance path as
the initial candidate. Treat measurements as diagnostic evidence. Fail only
on crashes, out-of-memory errors, readiness or workload failure, invalid
responses, missing or unparseable diagnostics, cleanup failure, or a generous
gross-duration/resource bound justified by the spike. Report ordinary timing
and resource variation without turning it into a brittle required threshold.

**Resolution:**

See `1-trick-out-01-remove-before-merge/spike_1_15_capture_repeatable_performance_envelope`.

Select the non-containerized Open Liberty workload implemented by this spike as the shared baseline for section 1.16. Build and deploy one WAR and Liberty runtime, then restore a pristine `defaultServer` for each repetition. Measure startup through validated HTTP readiness, issue five warm-up requests, dynamically record a 10-second JFR, and issue 30 sequential validated requests at 200-millisecond intervals. Repeat the workload five times per launch mode on the same CI runner. Do not use containers, synthetic cgroup limits, fixed heap or processor settings, or other JVM tuning flags that could interfere with the `java`/`jaz` comparison.

The spike’s five direct-`java` repetitions all completed successfully and produced the required JVM, process, heap, GC, JFR, HTTP, Liberty, and timing evidence. However, several aggregate measurements varied by approximately 15–23%, and individual request timings were noisier. Therefore, treat the results as comparative diagnostic evidence rather than microbenchmark data or narrow regression thresholds. Fail only on functional or diagnostic failure, crash or OOM, startup beyond 90 seconds, a complete repetition beyond 120 seconds, cleanup failure, or a provisional gross peak-RSS bound of 2 GiB. Use a redacted JFR configuration and calibrate the broad resource bounds during the first GitHub-hosted run without changing the workload contract.

### 1.16 — `java` versus `jaz`, GC logs, and JFR capture

**Question:** How should CI compare direct JVM launch with Azure Command
Launcher for Java (`jaz`) on the same GitHub-hosted Linux VM while proving that
the application artifact, Liberty runtime, workload, diagnostics, and host
resource view are otherwise unchanged?

The comparison must use the workload and measurement protocol resolved in
section 1.15. Containerization and synthetic cgroup limits are out of scope.
The GitHub-hosted VM is the shared resource envelope; record its host and
cgroup data as evidence rather than attempting to alter it.

Required launch modes:

1. direct `java`;
2. `jaz` with `JAZ_BYPASS=1`, to measure the launcher path without tuning;
3. normal `jaz`, allowing it to select its tun

[Output truncated. Use view_range=[803, ...] to continue reading. In your next response, you may batch this with other view calls. File has at least 1677 lines.]
````

</details>


---

<sub>24s</sub>

### `view`

**view the file at /home/edburns/workareas/dd-3016202-cargotracker-devoxx-be-2026-02/1-trick-out-01-remove-before-merge/trick-out-01-ignorance-reduction-plan.md.**

/home/edburns/workareas/dd-3016202-cargotracker-devoxx-be-2026-02/1-trick-out-01-remove-before-merge/trick-out-01-ignorance-reduction-plan.md (lines 901-1400)

<details>
<summary>371 lines</summary>

````
```

Use one immutable upload per artifact name in a workflow run. Do not append to
or overwrite an artifact after upload. Set `if-no-files-found: error` for
required evidence and `retention-days: 90` explicitly on every campaign
artifact. Ninety days is the campaign retention contract even if repository
settings permit a longer value. Treat workflow logs, check runs, and artifact
URLs as expiring evidence; the evidence matrix is the durable index.

Every artifact must contain `artifact-metadata.json` at its root with:

- schema version `1`;
- concern and artifact name;
- repository, branch or ref, and exact commit SHA tested;
- workflow name, run ID, run attempt, run URL, and job name;
- triggering event and pull request number when applicable;
- runner OS and architecture;
- Java, Maven, Open Liberty, and relevant tool or instrumentation versions;
- UTC start and end timestamps in ISO 8601 format;
- the exact commands executed, represented as an ordered array;
- an inventory of included files with relative path, byte size, and SHA-256
  digest.

Generate the metadata from the same job that creates the evidence. Fail the job
if required identity fields, commands, or file inventory entries cannot be
produced. Do not use placeholders such as `unknown` for required fields.

Upload reports and bounded diagnostic evidence, not caches or installed
runtimes. Never upload the Maven repository, the entire `target/` tree, the
Open Liberty installation, raw environment dumps, credentials, or unredacted
request data. Include only the WAR inventory and checksum rather than a second
WAR copy unless a task explicitly requires the deployable WAR. Include bounded,
redacted JFR recordings, GC logs, test reports, analyzer reports, telemetry,
Liberty logs, command transcripts, and summaries required by the applicable
issue. Run the issue's redaction and nonempty-file checks before upload.

Give every upload step an `id`. Record its `artifact-id`, `artifact-url`, and
`artifact-digest` outputs in the GitHub Actions job summary together with the
artifact name and tested commit SHA. Because those values are produced only
after the archive is created, do not attempt to embed them in that artifact's
own metadata file.

Before an implementation PR is merged, its evidence-matrix update must identify
the issue and PR, the exact tested commit SHA, workflow run URL and ID, job or
check name, artifact name, artifact URL or ID, artifact digest, and the
specific file inside the artifact that supports the observation. It must also
record the observed event, confidence, and slide implication required by the
cross-cutting campaign gate. A citation to a successful implementation commit
is valid even when a later documentation-only commit updates the matrix; do not
pretend a pre-merge document can know the future merge commit SHA.

After merge, verify that the evidence-matrix update is present on the campaign
base branch and that the cited workflow run and artifacts are still available.
Do not start the next serial issue until that verification succeeds. If an
artifact would exceed practical upload limits, reduce it to the smallest
diagnostic subset that preserves the finding and record the omitted material;
do not silently drop required evidence or upload a cache/runtime archive as a
substitute.

---

## Phase 2 — Implementation

Create these as ordered serial issues. Every issue inherits the evidence-matrix
gate later in this document. Stage 20 may refine titles after all Phase 1
resolutions are filled, but it must preserve this dependency order.

Every issue must include text that informs the agent that this is the demo app accompanying a presentation whose abstract is in `dd-3032592-10-boring-reasons-abstract.md`.

Every Phase 2 issue includes a **Required Phase 1 evidence lookup** block.
Stage 20 must preserve that block in the generated issue body. The assigned
agent must read the named Phase 1 resolutions and spike artifacts before
implementation. Spike decisions are part of the issue specification: do not
repeat candidate selection, substitute a different mechanism, or contradict a
resolved constraint without explicitly documenting the new evidence and
obtaining human approval.

### 2.1 — Establish the Open Liberty-only baseline

**Required Phase 1 evidence lookup:** Before implementation, read resolutions
1.3, 1.4, 1.6, and 1.13, then fully examine:

- `1-trick-out-01-remove-before-merge/spike_1_3_validation_tier_selection/README.md`
- `1-trick-out-01-remove-before-merge/spike_1_4_dependency_governance/README.md`
- `1-trick-out-01-remove-before-merge/spike_1_13_acceptance_tests/README.md`
- `1-trick-out-01-remove-before-merge/spike_1_13_acceptance_tests/run-spike.sh`

Preserve the selected canonical packaging and Open Liberty lifecycle while
removing alternate-server paths. In particular, do not treat
`clean package` as deployment, do not use `liberty:status` exit status as
readiness, and do not invalidate the selected validation tiers without
updating their documentation and evidence.

The existing Payara/Cargo/GlassFish paths materially distort Maven dependency
analysis, plugin governance, documentation, and Arquillian configuration.
Later agents could reasonably mistake them for supported compatibility
requirements.

Scope:

- Remove the Payara profile, Payara Arquillian dependency, Cargo plugin, and
  Payara download properties from `demo/pom.xml`.
- Remove the Payara container from
  `demo/src/test/resources/arquillian.xml`.
- Delete `demo/src/main/webapp/WEB-INF/glassfish-web.xml`.
- Remove Payara setup, testing, Java 8, and Eclipse instructions from
  `demo/README.md`.
- Rewrite the GlassFish/WebLogic-specific source comment in runtime-neutral
  terms.
- Preferably flatten the `openliberty` profile into the main POM so Open
  Liberty is the build, not one selectable server profile.
- Search for and remove remaining Payara, GlassFish, WebLogic, Cargo-plugin,
  WildFly, and Tomcat runtime guidance.
- Preserve Java EE 7 application APIs; this is **runtime cleanup**, not Jakarta
  migration.

**Gate:** Spotless passes, `./mvnw clean package` passes from a clean `target/`,
the Open Liberty test/runtime path passes, the WAR remains deployable, and a
repository search finds no unsupported-server build configuration or
instructions.

### 2.2 — Make CI authoritative and establish the Maven/dependency foundation

**Required Phase 1 evidence lookup:** Before implementation, read resolutions
1.1 through 1.5 and 1.8, then fully examine:

- `1-trick-out-01-remove-before-merge/spike_1_1_authoritative_ci_path/README.md`
- `1-trick-out-01-remove-before-merge/spike_1_1_authoritative_ci_path/observed-state.json`
- `1-trick-out-01-remove-before-merge/spike_1_3_validation_tier_selection/README.md`
- `1-trick-out-01-remove-before-merge/spike_1_3_validation_tier_selection/results.json`
- `1-trick-out-01-remove-before-merge/spike_1_4_dependency_governance/README.md`
- `1-trick-out-01-remove-before-merge/spike_1_4_dependency_governance/run-summary.tsv`
- `1-trick-out-01-remove-before-merge/spike_1_8_spotless/README.md`

Implement the selected experiment-branch push/PR authority, serial job
topology, validation-tier commands, and low-noise Enforcer policy from those
artifacts. Do not rerun tool selection or broaden dependency remediation beyond
the resolved baseline.

**Reasons exercised:** 5. Build system maturity and dependency management;
6. Code formatting and style enforcement.

**What to build:**

- Make `.github/workflows/main.yml` authoritative for experiment-branch
  increments according to resolutions 1.1 and 1.2.
- Preserve the existing Microsoft Build of OpenJDK 17 `formatting` and `build`
  behavior.
- Give jobs and steps stable, descriptive names.
- Define and document canonical Maven command tiers.
- Add the resolved low-noise Maven Enforcer rules.
- Add the resolved dependency/security report without turning historical debt
  into an unrelated remediation project.
- Generate reproducibility evidence: effective POM, dependency tree, plugin
  information, WAR contents, and WAR checksum.
- Upload build and dependency reports with commit/run metadata.

**Files to modify:**

- `.github/workflows/main.yml`
- `demo/pom.xml`
- `.mvn/wrapper/maven-wrapper.properties` only if the resolved Maven minimum
  requires a wrapper change
- `demo/README.md` or the existing nearest developer documentation

**Files to create when selected by the resolutions:**

- `demo/config/dependency-check-suppressions.xml`
- `demo/scripts/ci/write-build-metadata.sh`
- `demo/scripts/ci/verify-build-contract.sh`

**Tests and validation:**

- Run Spotless before every more expensive job.
- Run every selected Enforcer rule against the current baseline.
- Verify a clean package from a fresh `target/`.
- Verify `cargo-tracker.war` exists and record its SHA-256 checksum.
- Verify dependency and effective-POM reports are generated and uploaded.
- Exercise each new rule against a temporary invalid POM fixture or copy and
  assert a clear nonzero result.
- Trigger the workflow for the exact experiment-branch commit and record its
  run URL and job names.

**Expected failure evidence:**

- Unapproved Java/Maven version;
- missing plugin version;
- banned or newly vulnerable dependency;
- dependency-convergence violation when that rule is selected;
- formatting failure;
- package or artifact-checksum failure.

**Required artifacts:**

- effective POM;
- dependency tree;
- dependency/security report;
- Enforcer output;
- WAR file list and checksum;
- workflow metadata file.

**Rollback considerations:**

- Introduce rules individually so a noisy rule can be reverted without
  removing authoritative branch validation.
- Do not remove the existing formatting or package commands.
- If vulnerability data feeds are unavailable, fail or degrade exactly as
  specified by the resolution; never emit a success-shaped empty report.
- Do not upgrade application dependencies merely to make a broad scanner
  report empty.

**Issue gate:**

- The exact issue commit receives the authoritative workflow.
- Existing formatting and package behavior remains green.
- Every selected build/dependency rule is green on the baseline and has a
  verified actionable failure mode.
- Required reports are downloadable from the run.
- The evidence-matrix update is merged and visible on the campaign base branch.

### 2.3 — Enforce the Java 17 and Java EE 7 compatibility contract

**Required Phase 1 evidence lookup:** Before implementation, read resolutions
1.4, 1.6, 1.7, and 1.13, then fully examine:

- `1-trick-out-01-remove-before-merge/spike_1_4_dependency_governance/README.md`
- `1-trick-out-01-remove-before-merge/spike_1_9_compiler_options/README.md`
- `1-trick-out-01-remove-before-merge/spike_1_13_acceptance_tests/README.md`

Use the resolved Java/Maven ranges, direct-dependency bans, Java 17 compiler
contract, and verified production-WAR startup/readiness path. Keep this issue
on Java EE 7 and `javax.*`; none of the spike findings authorize Jakarta EE,
Spring, or alternate-server migration.

**Reasons exercised:** 3. Backwards compatibility culture; 1. Type system;
5. Build system maturity and dependency management.

**What to build:**

- Encode the resolved contract for Java 17, Java EE 7, `javax.*`, WAR
  packaging, Open Liberty, and `javaee-7.0`.
- Reject production `jakarta.*` imports and banned framework/runtime
  dependencies.
- Add concise repository instructions for coding agents.
- Verify the packaged application still deploys with the existing
  `server.xml`.
- Make compatibility failures name the violated boundary.

**Files to modify:**

- `demo/pom.xml`
- `demo/src/main/liberty/config/server.xml` only when needed to make the
  existing contract explicit without changing it
- `.github/workflows/main.yml`

**Files to create:**

- `.github/copilot-instructions.md`
- The resolved contract test or script, for example:
  `demo/src/test/java/org/eclipse/cargotracker/architecture/CompatibilityContractTest.java`
  or `demo/scripts/ci/verify-compatibility-contract.sh`

**Tests and validation:**

- Assert compiler release 17.
- Assert `javax:javaee-api:7.0` remains provided scope.
- Assert WAR packaging and final name.
- Assert `server.xml` includes `javaee-7.0`, the expected WAR, and the
  `/cargo-tracker` context root.
- Scan production source for forbidden `jakarta.*` imports.
- Verify the current application packages and starts on Open Liberty.
- Run temporary negative fixtures for a Jakarta API dependency, a forbidden
  import, a changed compiler release, and changed packaging.

**Expected failure evidence:**

- `jakarta.*` source import;
- Jakarta EE platform dependency;
- Java release other than 17;
- JAR packaging or renamed WAR;
- Spring or alternative application-server dependency;
- removal of `javaee-7.0`.

**Required artifacts:**

- compatibility-contract report;
- compiler version and release output;
- Open Liberty feature and deployment excerpt;
- package/startup log.

**Rollback considerations:**

- Keep source scans narrow enough not to flag documentation or generated
  reports.
- Do not ban dependencies needed only by tooling without understanding their
  scope.
- Never "fix" a violation by migrating the application to Jakarta EE.

**Issue gate:**

- All compatibility assertions pass on the current application.
- Every negative fixture fails for the intended reason.
- The application packages and starts on JDK 17/Open Liberty.
- CI is green and the evidence-matrix update is merged.

### 2.4 — Strengthen formatting, compiler, type, and static-analysis gates

**Required Phase 1 evidence lookup:** Before implementation, read resolutions
1.3 and 1.8 through 1.10, then fully examine:

- `1-trick-out-01-remove-before-merge/spike_1_8_spotless/README.md`
- `1-trick-out-01-remove-before-merge/spike_1_8_spotless/run-summary.tsv`
- `1-trick-out-01-remove-before-merge/spike_1_9_compiler_options/README.md`
- `1-trick-out-01-remove-before-merge/spike_1_9_compiler_options/warnings.tsv`
- `1-trick-out-01-remove-before-merge/spike_1_9_compiler_options/proposed-warning-fixes.patch`
- `1-trick-out-01-remove-before-merge/spike_1_10_static-analyzer/README.md`
- `1-trick-out-01-remove-before-merge/spike_1_10_static-analyzer/finding-classification.tsv`

Implement the resolved Spotless ratchet semantics, full javac warning cleanup
and `-Werror` gate, and SpotBugs selection. Defer PMD, preserve the recorded
serialization identities, and do not replace focused suppressions with broad
exclusions.

**Reasons exercised:** 6. Code formatting and style enforcement; 1. Type
system; 4. Deep static analysis.

**What to build:**

- Preserve the resolved Spotless ratchet and first-job position.
- Enable the resolved actionable compiler diagnostics.
- Add the selected static analyzer and focused ruleset.
- Establish narrow, documented legacy suppressions only where necessary.
- Keep formatting, compilation, and analyzer reports separate so a later
  agent can identify which mechanism responded.
- Add controlled negative fixtures for formatting, compilation, and analyzer
  behavior without leaving red commits on the campaign branch.

**Files to modify:**

- `demo/pom.xml`
- `.github/workflows/main.yml`

**Files to create when selected:**

- `demo/config/spotbugs-exclude.xml`
- `demo/config/pmd-ruleset.xml`
- `demo/scripts/ci/verify-source-gates.sh`
- analyzer fixture sources under `demo/src/test/resources/analysis-fixtures/`

**Tests and validation:**

- Verify incorrectly formatted fixture code fails Spotless.
- Verify nonexistent method/incompatible type fixture fails compilation.
- Verify the analyzer detects at least one known fixture defect.
- Verify baseline application source passes all selected checks.
- Verify reports contain file, line, rule, and severity where supported.
- Measure runtime and confirm analyzer work does not repeat the full Open
  Liberty acceptance lifecycle.

**Expected failure evidence:**

- formatting drift;
- hallucinated API or incompatible type;
- selected null/resource/correctness analyzer defect;
- unauthorized suppression or malformed ruleset.

**Required artifacts:**

- compiler log;
- static-analysis XML/HTML report;
- source-gate metadata and duration;
- controlled negative-fixture transcript.

**Rollback considerations:**

- Add one warning category or analyzer rule family at a time.
- Revert a noisy rule rather than adding a blanket exclusion.
- Keep formatting concerns out of the deep analyzer.
- Do not enable `-Werror` until the selected warning set is proven clean.

**Issue gate:**

- Formatting, compiler, and analyzer jobs are independently attributable.
- Baseline source is green.
- Each mechanism has a verified controlled failure.
- Suppressions are narrow and documented.
- The evidence-matrix update is merged before behavioral-test work begins.

### 2.5 — Build the behavioral safety net

**Required Phase 1 evidence lookup:** Before implementation, read resolutions
1.3 and 1.11 through 1.13, then fully examine:

- `1-trick-out-01-remove-before-merge/spike_1_3_validation_tier_selection/README.md`
- `1-trick-out-01-remove-before-merge/spike_1_12_behavior_saftey_net/README.md`
- `1-trick-out-01-remove-before-merge/spike_1_12_behavior_saftey_net/resolution.md`
- `1-trick-out-01-remove-before-merge/spike_1_12_behavior_saftey_net/run-http-acceptance.sh`
- `1-trick-out-01-remove-before-merge/spike_1_13_acceptance_tests/README.md`
- `1-trick-out-01-remove-before-merge/spike_1_13_acceptance_tests/run-spike.sh`

Use the discovered active-test inventory, the deterministic seeded cargo
`ABC123`, the selected browser-free REST and Administration contracts, and the
verified `package` → `liberty:deploy` → bounded `liberty:start` → HTTP checks →
always-run `liberty:stop` lifecycle. Do not add browser automation, claim
dormant tests as coverage, or invent a different readiness mechanism.

**Reasons exercised:** 2. Testing ecosystem; 3. Backwards compatibility
culture; 1. Type system where tests compile against typed boundaries.

**What to build:**

- Produce a trustworthy inventory of active, skipped, dormant, and repaired
  tests.
- Preserve the existing domain JUnit tests.
- Repair selected dormant scenario or routing tests only when they can become
  deterministic with small changes.
- Strengthen application-service and Arquillian/Open Liberty coverage.
- Add the resolved architecture rules for DDD layer boundaries.
- Add one bounded black-box Open Liberty smoke/acceptance job.
- Protect behavior needed before the later Change Arrival Deadline feature
  without implementing that feature.

**Files to modify as required:**

- `demo/pom.xml`
- `.github/workflows/main.yml`
- existing tests under `demo/src/test/java/org/eclipse/cargotracker/`

**Files to create when selected:**

- `demo/src/test/java/org/eclipse/cargotracker/architecture/LayeringTest.java`
- `demo/src/test/java/org/eclipse/cargotracker/scenario/` focused scenario
  fixtures
- `demo/scripts/ci/start-liberty-and-wait.sh`
- `demo/scripts/ci/smoke-test.sh`
- `demo/scripts/ci/stop-liberty.sh`

**Tests and validation:**

- Assert the expected Surefire test count and preserve XML reports.
- Run active unit tests independently from managed-container tests where
  practical.
- Verify application-service behavior through Arquillian/Open Liberty.
- Verify architecture rules over production packages.
- Start the packaged WAR, wait with a bounded timeout, and request
  `/cargo-tracker/`.
- Exercise at least one stable seeded-cargo, tracking, REST, or Administration
  path selected by the resolution.
- Ensure server shutdown runs even after a failed smoke test.

**Expected failure evidence:**

- domain invariant regression;
- application-service behavior regression;
- package-layer dependency violation;
- Open Liberty startup failure;
- HTTP non-200, missing application, or readiness timeout.

**Required artifacts:**

- Surefire and Arquillian reports;
- test inventory and count;
- architecture-test report;
- smoke-test transcript;
- Liberty `messages.log`, `console.log`, and FFDC files when present.

**Rollback considerations:**

- Do not make flaky or nondeterministic browser automation required.
- Do not claim dormant tests as coverage.
- If a legacy test cannot be repaired within scope, document it and retain or
  remove it only according to the resolution.
- Use bounded retries only for server readine

[Output truncated. Use view_range=[1374, ...] to continue reading. In your next response, you may batch this with other view calls. File has at least 1677 lines.]
````

</details>


---

<sub>32s</sub>

### `view`

**view the file at /home/edburns/workareas/dd-3016202-cargotracker-devoxx-be-2026-02/1-trick-out-01-remove-before-merge/trick-out-01-ignorance-reduction-plan.md.**

/home/edburns/workareas/dd-3016202-cargotracker-devoxx-be-2026-02/1-trick-out-01-remove-before-merge/trick-out-01-ignorance-reduction-plan.md (lines 269-502)

<details>
<summary>179 lines</summary>

````
### 1.4 — Maven and dependency-governance rules

**Question:** Which Maven Enforcer and dependency checks provide strong,
low-noise evidence without turning the legacy application into a dependency
modernization project?

Candidate rules include:

| Rule | Value | Principal risk |
|---|---|---|
| `requireJavaVersion` | Enforces Java 17 | Accidentally accepting a newer developer JDK without release discipline |
| `requireMavenVersion` | Makes wrapper/tool assumptions explicit | Choosing a minimum incompatible with the checked-in wrapper |
| `requirePluginVersions` | Prevents implicit plugin drift | May expose lifecycle plugins not explicitly versioned |
| `dependencyConvergence` | Finds conflicting dependency graphs | Arquillian and Liberty test graphs may contain legitimate conflicts |
| `requireUpperBoundDeps` | Detects older transitive selections | Often noisy on mature Java EE dependency graphs |
| `banDuplicatePomDependencyVersions` | Rejects ambiguous POM declarations | Low risk and deterministic |
| `bannedDependencies` | Prevents Jakarta/Spring/runtime migration | Patterns must avoid banning required test/runtime artifacts |
| `externalRules` or repository checks | Restricts unapproved repositories | Must account for Maven Central and any Liberty-specific artifact source |

**Recommendation:** Start with Java/Maven version, plugin version,
duplicate-declaration, and narrowly scoped banned-dependency rules. Add
convergence or upper-bound enforcement only if the baseline can be made green
with small, understandable dependency-management changes.

**Failure example:** In a temporary POM copy, add an unapproved dependency or
an unversioned plugin and verify the resolved rule fails with an actionable
message.

**Resolution:**

The spike tells us to adopt a small, Open Liberty-only governance policy—not every candidate rule.

Select:

- `requireJavaVersion` → `[17,18)`
- `requireMavenVersion` → `[3.9.9,4.0.0)`
- strict `requirePluginVersions`
- pin only `maven-clean-plugin` `3.2.0`
- pin only `maven-resources-plugin` `3.3.1`
- exempt unused Maven defaults for `install`, `deploy`, and `site`
- `dependencyConvergence`
- `banDuplicatePomDependencyVersions`
- direct-dependency bans for Jakarta, Spring, Payara, WildFly/JBoss, and Tomcat
- `requireNoRepositories`, allowing Maven Central

Reject:

- `requireUpperBoundDeps`: it passes, but adds no useful evidence once `dependencyConvergence` is enforced.
- `banMavenDefaults=false`: it also allowed a deliberately unversioned custom plugin, making it too permissive. Apache documents that this option delegates standard plugin versions to Maven; the spike demonstrated that it weakens this project’s desired guard. 
- Any Payara or alternate-server validation.

The practical conclusion is that the Open Liberty dependency graph is already clean. No dependency changes, modernization, or Enforcer exclusions are needed. The only POM correction is pinning the two implicit plugins actually used by the demo. The selected policy then passes, while all negative controls fail with actionable messages. The corrected decision and paste-ready Resolution text are now in `spike_1_4_dependency_governance/README.md`; the final harness has 15/15 expected outcomes.

### 1.5 — Reproducibility and dependency-security evidence

**Question:** Which outputs should be preserved to demonstrate a controlled
dependency graph and supply-chain posture without requiring the campaign to
remediate every historical vulnerability?

Possible evidence:

- effective POM;
- dependency tree;
- dependency convergence report;
- resolved plugin list;
- packaged WAR checksum and contents;
- GitHub dependency review for pull requests;
- a vulnerability report with a documented baseline and severity policy.

The application intentionally retains old Java EE 7-era dependencies such as
PrimeFaces 8 and Joda-Time. A vulnerability scanner may report substantial
legacy debt. Failing immediately on every historical finding would violate the
incremental-green requirement and obscure whether later agents introduce new
risk.

**Recommendation:** Preserve the dependency tree, effective POM, WAR checksum,
and vulnerability report as artifacts. Enforce no newly introduced
high-severity dependency findings or use GitHub dependency review on PR deltas;
do not make wholesale legacy remediation part of this campaign.

**Resolution:**

Preserve the dependency tree, effective POM, WAR checksum,
and vulnerability report as artifacts. Enforce no newly introduced
high-severity dependency findings or use GitHub dependency review on PR deltas;
do not make wholesale legacy remediation part of this campaign.

### 1.6 — Executable Java 17 and Java EE 7 compatibility contract

**Question:** How should the repository reject accidental migration away from
Java 17, Java EE 7, `javax.*`, WAR packaging, and Open Liberty's `javaee-7.0`
feature?

The contract currently exists in several independent places:

```xml
<maven.compiler.release>17</maven.compiler.release>
<javaee_api.version>7.0</javaee_api.version>
<groupId>javax</groupId>
<artifactId>javaee-api</artifactId>
<packaging>war</packaging>
```

and:

```xml
<feature>javaee-7.0</feature>
<webApplication location="cargo-tracker.war"
                contextRoot="/cargo-tracker" />
```

Possible enforcement mechanisms include Maven Enforcer banned dependencies,
source-package scans for `jakarta.*`, XML assertions over `pom.xml` and
`server.xml`, and runtime checks against the deployed application.

**Recommendation:** Use multiple narrow checks because no single tool covers
the contract: Maven Enforcer for dependencies and Java version, a small
JUnit-based repository contract test or script for POM/server configuration,
and the Open Liberty acceptance job for runtime proof. Ban production imports
from `jakarta.*` while allowing no exceptions unless a resolved question
documents one.

**Failure example:** In an isolated temporary fixture, substitute
`jakarta.platform:jakarta.jakartaee-api` or change `javaee-7.0`; verify the
contract check identifies the exact boundary that changed.

**Resolution:**

Use multiple narrow checks because no single tool covers
the contract: Maven Enforcer for dependencies and Java version, a small
JUnit-based repository contract test or script for POM/server configuration,
and the Open Liberty acceptance job for runtime proof. Ban production imports
from `jakarta.*` while allowing no exceptions unless a resolved question
documents one.


### 1.7 — Repository-level instructions for agents

**Question:** Which compatibility and validation rules must be written into
repository instructions so coding agents understand the contract before CI
rejects their work?

The repository currently has no discovered Copilot instruction file. Build
rules alone provide feedback after a change, but the experiment should also
test whether concise repository guidance prevents predictable mistakes.

The instructions must cover at least:

- Java 17 only;
- Java EE 7 and `javax.*`, not Jakarta EE;
- Maven Wrapper commands run from `demo/`;
- WAR and Open Liberty assumptions;
- required green CI before proceeding;
- no broad dependency upgrades;
- no replacement with Spring or another application server;
- required evidence-matrix update timing.

**Recommendation:** Add a short `.github/copilot-instructions.md` that states
invariants and canonical validation commands without duplicating the entire
plan. Treat instruction effectiveness as evidence only when a later agent
actually follows, misunderstands, or violates it.

**Resolution:**

Add an explicit, not necessarily short, `.github/copilot-instructions.md` containing at least these: 

- Java 17 only;
- Java EE 7 and `javax.*`, not Jakarta EE;
- Maven Wrapper commands run from `demo/`;
- WAR and Open Liberty assumptions;
- required green CI before proceeding;
- no broad dependency upgrades;
- no replacement with Spring or another application server;
- required evidence-matrix update timing.

With this `applyTo:`

```yaml
applyTo:
  - "**/*.java"
  - "**/*.kt"
  - "**/*.groovy"
  - "**/pom.xml"
  - "**/.mvn/**"
  - "**/mvnw"
  - "**/mvnw.cmd"
  - "**/build.gradle"
  - "**/build.gradle.kts"
  - "**/settings.gradle"
  - "**/settings.gradle.kts"
  - "**/gradlew"
  - "**/gradlew.bat"
```

```markdown
## 3) Maven execution: tee-to-log (required)

Whenever you invoke `mvn` (including via `./mvnw`), you must:

- pipe **both stdout and stderr** through `tee` to a log file
- this streams output to the console AND saves it to the file simultaneously
- use this log naming pattern: `YYYYMMDD-HHMM-job-logs.txt` (local time)
- look at the log file to evaluate the success or failure of the command
- note the exact log filename and always use that exact filename to check results — do NOT guess with `ls -t`, glob sorting, or similar
- ❌ do not use background `&` + `tail -f` (breaks under VS Code sandbox regime)
- ❌ do not use any other output redirecting or tailing scheme
- ✅ Use `requestUnsandboxedExecution` so the environment variables stick. See below.

### POSIX (bash/zsh) pattern

mvn [YOUR_GOALS] 2>&1 | tee "$(date +%Y%m%d-%H%M)-job-logs.txt"

Replace \[YOUR GOALS\] with whatever `mvn` goals are appropriate in your particular case.

### PowerShell pattern

function Invoke-WithTeeLog {
    param(
        [Parameter(ValueFromRemainingArguments=$true)]
        [string[]]$Command
    )
    $log = "$(Get-Date -Format 'yyyyMMdd-HHmm')-job-logs.txt"
    Write-Host "Log file: $((Resolve-Path -Path '.' | Join-Path -ChildPath $log))" -ForegroundColor Cyan
    $cmdString = $Command -join ' '
    Invoke-Expression "$cmdString 2>&1" | Tee-Object -FilePath $log
}
Set-Alias -Name runt -Value Invoke-WithTeeLog

then

runt mvn [YOUR GOALS]
```
````

</details>


---

<sub>32s</sub>

### `view`

**view the file at /home/edburns/workareas/dd-3016202-cargotracker-devoxx-be-2026-02/1-trick-out-01-remove-before-merge/trick-out-01-ignorance-reduction-plan.md.**

/home/edburns/workareas/dd-3016202-cargotracker-devoxx-be-2026-02/1-trick-out-01-remove-before-merge/trick-out-01-ignorance-reduction-plan.md (lines 786-977)

<details>
<summary>154 lines</summary>

````
### 1.16 — `java` versus `jaz`, GC logs, and JFR capture

**Question:** How should CI compare direct JVM launch with Azure Command
Launcher for Java (`jaz`) on the same GitHub-hosted Linux VM while proving that
the application artifact, Liberty runtime, workload, diagnostics, and host
resource view are otherwise unchanged?

The comparison must use the workload and measurement protocol resolved in
section 1.15. Containerization and synthetic cgroup limits are out of scope.
The GitHub-hosted VM is the shared resource envelope; record its host and
cgroup data as evidence rather than attempting to alter it.

Required launch modes:

1. direct `java`;
2. `jaz` with `JAZ_BYPASS=1`, to measure the launcher path without tuning;
3. normal `jaz`, allowing it to select its tuning.

Build the WAR and Liberty runtime once and use their checksums for every mode.
Run all modes sequentially in the same job and alternate their order across
repetitions to reduce temporal and cache bias. Use a fresh Liberty output/data
directory for every launch.

The experiment must not pass JVM tuning flags such as `-Xms`, `-Xmx`,
`-XX:ActiveProcessorCount`, or `-XX:StartFlightRecording`; those flags would
prevent or interfere with evaluation of `jaz` tuning. Use `-Xlog` for GC
diagnostics, start JFR dynamically with `jcmd JFR.start`, and capture effective
settings with `jcmd VM.command_line` and `jcmd VM.flags`.

Required evidence:

- pinned `jaz` version and installation source;
- `JAZ_DRY_RUN=1` output showing the command selected for the tuned mode;
- direct, bypassed, and tuned effective JVM commands and flags;
- recorded runner CPU, memory, OS, kernel, and cgroup view;
- startup time, peak RSS, process CPU time, GC log, bounded JFR, workload
  result, total duration, and exit status for each repetition;
- paired comparison summary with run order and variance;
- confirmation that each mode used the same WAR, Liberty runtime, request data,
  readiness condition, workload, and artifact naming.

**Recommendation:** Compare the three modes on the same non-containerized
runner and treat selected JVM flags and measured differences as observations.
Fail on installation failure, inability to launch or stop Liberty, artifact or
workload mismatch, suppressed or unverifiable tuning, missing diagnostics, or
functional failure. Do not enforce a performance winner unless repeated paired
runs establish a defensible bound. Validate `jaz` under real AKS pod limits in
the separate Azure deployment thread rather than synthesizing container limits
in this campaign.

**Failure example:** Add an isolated user-provided JVM tuning flag and verify
that the harness detects that normal `jaz` tuning was suppressed; do not retain
that flag in the comparison workload.

**Resolution:**

Reuse the workload, bounds, request protocol, diagnostics, and redacted JFR configuration resolved by spike 1.15. Install and checksum-pin `jaz` 1.0.4, then compare direct `java`, `JAZ_BYPASS=1`, and tuned `jaz` in five alternating-order cycles on the same non-containerized runner. Build the WAR and Open Liberty runtime once and restore a pristine server before every launch.

Integrate `jaz` through Liberty’s `server.env` using a `JAVA_HOME` that mirrors the real JDK and replaces only `bin/java`; keep Maven and diagnostic tools on the real JDK. Capture `JAZ_DRY_RUN=1`, effective JVM commands and flags, launcher/child-process evidence, server-PID GC logs, dynamically started JFR, workload results, and cleanup status.

All 15 spike launches passed. Bypassed `jaz` retained default heap and GC behavior but added native-memory tracking and error-file configuration. Tuned `jaz` selected a roughly 10.0–10.5 GB maximum heap, 10/50 heap-free ratios, time-based G1 heap sizing, native-memory tracking, and 10-second periodic GC. It consistently produced more GC pauses, but other performance differences were inconsistent or within the spike 1.15 noise floor.

Use this comparison to verify launcher integration, selected tuning, functional equivalence, diagnostics, and cleanup—not to declare a performance winner. Fail on installation or checksum failure, launcher substitution failure, suppressed or unverifiable tuning, artifact or workload mismatch, missing diagnostics, functional failure, or incomplete cleanup. Evaluate `jaz` under real AKS pod limits in the separate Azure deployment work.

Completely read `dd-3016202-cargotracker-devoxx-be-2026-02/1-trick-out-01-remove-before-merge/spike_1_16_java_vs_jaz/` for the complete details.

### 1.17 — Artifact naming, retention, and merge evidence

**Question:** What stable naming and retention scheme will let the later
feature campaign and slide author locate evidence without reading arbitrary
workflow logs?

**Recommendation:** Upload artifacts using names that include the concern but
not a hard-coded run number, commit SHA, issue number, or timestamp:

```text
build-contract
dependency-reports
source-gates
test-reports-unit
test-reports-liberty
liberty-logs
otel-telemetry
performance-java
performance-jaz-bypassed
performance-jaz-tuned
performance-comparison
```

Set an explicit 90-day retention period. Each artifact should contain a
machine-readable metadata file with the exact tested commit, workflow/run/job
identity, tool versions, UTC timestamps, commands, and a checksummed file
inventory. Record the upload action's artifact ID, URL, and digest in the job
summary and evidence matrix. Upload bounded reports and diagnostics, not
caches, installed runtimes, raw environment dumps, or unredacted data.

**Resolution:**

Use concern-based artifact names that remain stable across workflow runs. The
workflow run is the namespace; do not put a run number, commit SHA, issue
number, or timestamp in the artifact name. Use these names where the
corresponding evidence exists:

```text
build-contract
dependency-reports
source-gates
test-reports-unit
test-reports-liberty
liberty-logs
otel-telemetry
performance-java
performance-jaz-bypassed
performance-jaz-tuned
performance-comparison
```

Use one immutable upload per artifact name in a workflow run. Do not append to
or overwrite an artifact after upload. Set `if-no-files-found: error` for
required evidence and `retention-days: 90` explicitly on every campaign
artifact. Ninety days is the campaign retention contract even if repository
settings permit a longer value. Treat workflow logs, check runs, and artifact
URLs as expiring evidence; the evidence matrix is the durable index.

Every artifact must contain `artifact-metadata.json` at its root with:

- schema version `1`;
- concern and artifact name;
- repository, branch or ref, and exact commit SHA tested;
- workflow name, run ID, run attempt, run URL, and job name;
- triggering event and pull request number when applicable;
- runner OS and architecture;
- Java, Maven, Open Liberty, and relevant tool or instrumentation versions;
- UTC start and end timestamps in ISO 8601 format;
- the exact commands executed, represented as an ordered array;
- an inventory of included files with relative path, byte size, and SHA-256
  digest.

Generate the metadata from the same job that creates the evidence. Fail the job
if required identity fields, commands, or file inventory entries cannot be
produced. Do not use placeholders such as `unknown` for required fields.

Upload reports and bounded diagnostic evidence, not caches or installed
runtimes. Never upload the Maven repository, the entire `target/` tree, the
Open Liberty installation, raw environment dumps, credentials, or unredacted
request data. Include only the WAR inventory and checksum rather than a second
WAR copy unless a task explicitly requires the deployable WAR. Include bounded,
redacted JFR recordings, GC logs, test reports, analyzer reports, telemetry,
Liberty logs, command transcripts, and summaries required by the applicable
issue. Run the issue's redaction and nonempty-file checks before upload.

Give every upload step an `id`. Record its `artifact-id`, `artifact-url`, and
`artifact-digest` outputs in the GitHub Actions job summary together with the
artifact name and tested commit SHA. Because those values are produced only
after the archive is created, do not attempt to embed them in that artifact's
own metadata file.

Before an implementation PR is merged, its evidence-matrix update must identify
the issue and PR, the exact tested commit SHA, workflow run URL and ID, job or
check name, artifact name, artifact URL or ID, artifact digest, and the
specific file inside the artifact that supports the observation. It must also
record the observed event, confidence, and slide implication required by the
cross-cutting campaign gate. A citation to a successful implementation commit
is valid even when a later documentation-only commit updates the matrix; do not
pretend a pre-merge document can know the future merge commit SHA.

After merge, verify that the evidence-matrix update is present on the campaign
base branch and that the cited workflow run and artifacts are still available.
Do not start the next serial issue until that verification succeeds. If an
artifact would exceed practical upload limits, reduce it to the smallest
diagnostic subset that preserves the finding and record the omitted material;
do not silently drop required evidence or upload a cache/runtime archive as a
substitute.

---

## Phase 2 — Implementation

Create these as ordered serial issues. Every issue inherits the evidence-matrix
gate later in this document. Stage 20 may refine titles after all Phase 1
resolutions are filled, but it must preserve this dependency order.

Every issue must include text that informs the agent that this is the demo app accompanying a presentation whose abstract is in `dd-3032592-10-boring-reasons-abstract.md`.

Every Phase 2 issue includes a **Required Phase 1 evidence lookup** block.
Stage 20 must preserve that block in the generated issue body. The assigned
agent must read the named Phase 1 resolutions and spike artifacts before
implementation. Spike decisions are part of the issue specification: do not
repeat candidate selection, substitute a different mechanism, or contradict a
resolved constraint without explicitly documenting the new evidence and
obtaining human approval.
````

</details>


---

<sub>32s</sub>

### `view`

**view the file at /home/edburns/workareas/dd-3016202-cargotracker-devoxx-be-2026-02/1-trick-out-01-remove-before-merge/trick-out-01-ignorance-reduction-plan.md.**

/home/edburns/workareas/dd-3016202-cargotracker-devoxx-be-2026-02/1-trick-out-01-remove-before-merge/trick-out-01-ignorance-reduction-plan.md (lines 1289-1677)

<details>
<summary>305 lines</summary>

```
### 2.5 — Build the behavioral safety net

**Required Phase 1 evidence lookup:** Before implementation, read resolutions
1.3 and 1.11 through 1.13, then fully examine:

- `1-trick-out-01-remove-before-merge/spike_1_3_validation_tier_selection/README.md`
- `1-trick-out-01-remove-before-merge/spike_1_12_behavior_saftey_net/README.md`
- `1-trick-out-01-remove-before-merge/spike_1_12_behavior_saftey_net/resolution.md`
- `1-trick-out-01-remove-before-merge/spike_1_12_behavior_saftey_net/run-http-acceptance.sh`
- `1-trick-out-01-remove-before-merge/spike_1_13_acceptance_tests/README.md`
- `1-trick-out-01-remove-before-merge/spike_1_13_acceptance_tests/run-spike.sh`

Use the discovered active-test inventory, the deterministic seeded cargo
`ABC123`, the selected browser-free REST and Administration contracts, and the
verified `package` → `liberty:deploy` → bounded `liberty:start` → HTTP checks →
always-run `liberty:stop` lifecycle. Do not add browser automation, claim
dormant tests as coverage, or invent a different readiness mechanism.

**Reasons exercised:** 2. Testing ecosystem; 3. Backwards compatibility
culture; 1. Type system where tests compile against typed boundaries.

**What to build:**

- Produce a trustworthy inventory of active, skipped, dormant, and repaired
  tests.
- Preserve the existing domain JUnit tests.
- Repair selected dormant scenario or routing tests only when they can become
  deterministic with small changes.
- Strengthen application-service and Arquillian/Open Liberty coverage.
- Add the resolved architecture rules for DDD layer boundaries.
- Add one bounded black-box Open Liberty smoke/acceptance job.
- Protect behavior needed before the later Change Arrival Deadline feature
  without implementing that feature.

**Files to modify as required:**

- `demo/pom.xml`
- `.github/workflows/main.yml`
- existing tests under `demo/src/test/java/org/eclipse/cargotracker/`

**Files to create when selected:**

- `demo/src/test/java/org/eclipse/cargotracker/architecture/LayeringTest.java`
- `demo/src/test/java/org/eclipse/cargotracker/scenario/` focused scenario
  fixtures
- `demo/scripts/ci/start-liberty-and-wait.sh`
- `demo/scripts/ci/smoke-test.sh`
- `demo/scripts/ci/stop-liberty.sh`

**Tests and validation:**

- Assert the expected Surefire test count and preserve XML reports.
- Run active unit tests independently from managed-container tests where
  practical.
- Verify application-service behavior through Arquillian/Open Liberty.
- Verify architecture rules over production packages.
- Start the packaged WAR, wait with a bounded timeout, and request
  `/cargo-tracker/`.
- Exercise at least one stable seeded-cargo, tracking, REST, or Administration
  path selected by the resolution.
- Ensure server shutdown runs even after a failed smoke test.

**Expected failure evidence:**

- domain invariant regression;
- application-service behavior regression;
- package-layer dependency violation;
- Open Liberty startup failure;
- HTTP non-200, missing application, or readiness timeout.

**Required artifacts:**

- Surefire and Arquillian reports;
- test inventory and count;
- architecture-test report;
- smoke-test transcript;
- Liberty `messages.log`, `console.log`, and FFDC files when present.

**Rollback considerations:**

- Do not make flaky or nondeterministic browser automation required.
- Do not claim dormant tests as coverage.
- If a legacy test cannot be repaired within scope, document it and retain or
  remove it only according to the resolution.
- Use bounded retries only for server readiness, not to hide test failures.

**Issue gate:**

- The active test inventory is explicit and reproducible.
- Unit, integration, architecture, and acceptance layers have distinct output.
- Open Liberty starts, serves the selected path, and stops reliably.
- Required CI is green and the evidence-matrix update is merged.

### 2.6 — Add CI observability and diagnostic artifacts

**Required Phase 1 evidence lookup:** Before implementation, read resolutions
1.12 through 1.14 and the completed issue 2.5 implementation, then fully
examine:

- `1-trick-out-01-remove-before-merge/spike_1_12_behavior_saftey_net/README.md`
- `1-trick-out-01-remove-before-merge/spike_1_12_behavior_saftey_net/reports/http-probe.txt`
- `1-trick-out-01-remove-before-merge/spike_1_13_acceptance_tests/README.md`
- `1-trick-out-01-remove-before-merge/spike_1_13_acceptance_tests/run-spike.sh`

Reuse the resolved `/cargo-tracker/rest/cargo` request, seeded response
assertions, and bounded Open Liberty lifecycle as the telemetry stimulus.
Layer the resolved OpenTelemetry agent and local collector onto that proven
acceptance path; do not create a second server lifecycle or make Azure
resources part of required CI.

**Reasons exercised:** 8. Observability stack; 2. Testing ecosystem through
diagnosable runtime failures.

**What to build:**

- Add the OpenTelemetry Java agent and local collector selected in resolution
  1.14.
- Use a fixed CI-only request identifier to correlate the smoke-test
  transcript, HTTP path and status, trace/span identifiers,
  application/Liberty logs, and collector export.
- Exercise both a successful request and a controlled invalid request.
- Export telemetry in machine-readable JSON or text and include metadata with
  the workflow run ID, commit SHA, job name, instrumentation versions, and
  commands executed.
- Preserve Liberty `messages.log`, `console.log`, and the smoke-test
  transcript.
- Do not log request bodies, credentials, environment secrets, or cargo data.
  Run an explicit redaction check before uploading only durable diagnostic
  outputs.
- Keep Azure Monitor/Application Insights optional and outside required CI.

**Files to modify:**

- `.github/workflows/main.yml`
- `demo/pom.xml` only if the selected mechanism needs build integration
- `demo/src/main/liberty/config/server.xml` or
  `demo/src/main/liberty/config/bootstrap.properties` only for resolved,
  portable configuration

**Files to create:**

- `demo/observability/otel-collector-config.yaml`
- `demo/scripts/ci/run-observability-check.sh`
- `demo/scripts/ci/redact-artifacts.sh`
- `demo/observability/README.md`

**Tests and validation:**

- Start the collector before Liberty and use bounded health checks.
- Start Liberty with the selected instrumentation.
- Send a successful request with a fixed CI correlation identifier.
- Send a deliberately invalid request.
- Verify exported telemetry contains the expected service name, operation,
  status, timestamps, and trace identifier.
- Verify the successful and invalid requests can each be followed from the
  smoke-test transcript through the exported trace and relevant
  application/Liberty log lines.
- Verify the artifact metadata identifies the workflow run, commit, job,
  instrumentation versions, and commands.
- Search staged artifacts for configured secret patterns before upload.
- Stop both Liberty and the collector in an always-run cleanup step.

**Expected failure evidence:**

- collector unavailable;
- agent incompatible with Liberty;
- missing spans or metrics;
- failed correlation;
- accidental secret-like content in an artifact;
- invalid request with no diagnosable error signal.

**Required artifacts:**

- collector output;
- telemetry JSON/text;
- Liberty `messages.log` and `console.log`;
- successful and failed request transcripts;
- workflow, commit, job, version, timestamp, and command metadata;
- redaction-check result.

**Rollback considerations:**

- Instrumentation must be removable through configuration without changing
  application behavior.
- Do not make CI depend on an Azure resource or secret.
- Do not upload raw environment dumps.
- If logs cannot be routed through OpenTelemetry reliably, retain Liberty logs
  as a separate correlated artifact rather than pretending log export worked.

**Issue gate:**

- A successful and failed request both produce correlated durable evidence.
- The uploaded evidence identifies the exact workflow run and commit.
- No Azure resource is required.
- Secret/redaction checks pass.
- Required CI is green and the evidence-matrix update is merged.

### 2.7 — Add bounded JVM performance and `jaz` evidence

**Required Phase 1 evidence lookup:** Before implementation, read resolutions
1.13 and 1.15 through 1.17, then fully examine:

- `1-trick-out-01-remove-before-merge/spike_1_13_acceptance_tests/README.md`
- `1-trick-out-01-remove-before-merge/spike_1_15_capture_repeatable_performance_envelope/README.md`
- `1-trick-out-01-remove-before-merge/spike_1_15_capture_repeatable_performance_envelope/run-spike.sh`
- `1-trick-out-01-remove-before-merge/spike_1_16_java_vs_jaz/README.md`
- `1-trick-out-01-remove-before-merge/spike_1_16_java_vs_jaz/run-spike.sh`
- `1-trick-out-01-remove-before-merge/spike_1_16_java_vs_jaz/reports/run-order.tsv`
- `1-trick-out-01-remove-before-merge/spike_1_16_java_vs_jaz/reports/run-summary.tsv`
- `1-trick-out-01-remove-before-merge/spike_1_16_java_vs_jaz/reports/selected-jvm-flags.tsv`

Treat the spike workload, repetition count, time bounds, diagnostic capture,
launcher integration, and three-mode comparison as the issue specification.
Pin and checksum-verify `jaz` 1.0.4 exactly as resolved. Integrate it through
Liberty `server.env` with a `JAVA_HOME` that mirrors the real JDK and replaces
only `bin/java`; keep Maven, `jcmd`, and other diagnostic tools on the real
JDK. Set `JAZ_EXIT_WITHOUT_FLUSH=1` for bypassed and tuned modes, do not set
`JAZ_IGNORE_USER_TUNING`, and reject tuned runs whose effective flags do not
show the expected `jaz` settings. Run five alternating-order cycles containing
direct, bypassed, and tuned modes, verify launcher/child process relationships
and complete cleanup, and repeat the unchanged comparison on one GitHub-hosted
VM before treating it as hosted-runner evidence. Use the result to prove
launcher integration, functional equivalence, selected tuning, diagnostics,
and cleanup—not to declare a performance winner. Do not redesign the workload,
introduce containers or synthetic cgroup limits, pass JVM tuning flags that
suppress `jaz`, or impose narrow hosted-runner performance thresholds.

**Reasons exercised:** 9. JVM performance tuning; 8. Observability stack.

**What to build:**

- Create the resolved repeatable workload and non-containerized runner/JVM
  measurement harness.
- Run the same WAR and Liberty runtime through direct `java`, bypassed `jaz`,
  and tuned `jaz` launch modes on the same GitHub-hosted VM.
- Capture effective JVM settings, runner and cgroup metadata, startup time,
  peak RSS, process CPU time, GC logs, bounded JFR recordings, workload
  results, total duration, and exit status.
- Upload comparable artifacts without introducing brittle microbenchmark
  thresholds.
- Use observability from issue 2.6 to explain failures or anomalies.

**Files to modify:**

- `.github/workflows/main.yml`
- `demo/pom.xml` only for resolved packaging or launch support

**Files to create:**

- `demo/performance/run-workload.sh`
- `demo/performance/run-liberty-java.sh`
- `demo/performance/run-liberty-jaz.sh`
- `demo/performance/collect-process-metadata.sh`
- `demo/performance/README.md`

**Tests and validation:**

- Build the WAR and Liberty runtime once and use the same checksums for all
  three launch modes.
- Pin and record the `jaz` installation.
- Record the runner CPU, memory, OS, kernel, and `/sys/fs/cgroup` view.
- Run all three launch modes sequentially in one job, alternating order across
  repetitions and using a fresh Liberty output/data directory for each launch.
- Do not pass JVM tuning flags that suppress or replace `jaz` tuning.
- Capture `JAZ_DRY_RUN=1` output for the tuned mode.
- Use explicit GC logging and start a bounded JFR dynamically with `jcmd`.
- Capture effective command lines and JVM flags for every mode.
- Wait for the same readiness condition.
- Execute the same request count and request data.
- Record at least the spike-determined number of repetitions.
- Verify JFR and GC artifacts are nonempty and parseable.
- Verify direct, bypassed, and tuned modes use the same WAR, Liberty runtime,
  workload, and host resource view.
- Fail on crash, out-of-memory, readiness failure, missing diagnostics, or
  workload failure; report timing differences without enforcing a narrow
  winner unless the resolution establishes a repeatable bound.

**Expected failure evidence:**

- JVM cannot become ready within the bound;
- out-of-memory or abnormal process termination;
- `jaz` cannot replace the Liberty Java launcher or relay signals/exit status;
- user-provided JVM tuning suppresses the intended `jaz` tuning;
- direct, bypassed, and tuned modes use different application or runtime
  artifacts;
- missing or empty JFR/GC output;
- workload fails under any launch mode.

**Required artifacts:**

- direct-Java metadata, GC log, JFR, and workload result;
- bypassed-`jaz` metadata, GC log, JFR, and workload result;
- tuned-`jaz` dry-run output, selected settings, GC log, JFR, and workload
  result;
- WAR checksum;
- Liberty runtime checksum;
- runner and cgroup metadata;
- comparison summary with variance and timestamps.

**Rollback considerations:**

- Keep performance evidence downstream of correctness and observability.
- Do not make hosted-runner timing noise a strict required threshold.
- Pin or verify `jaz` installation according to the resolution.
- Do not introduce Docker/OCI execution or privileged cgroup manipulation for
  this comparison.
- Do not change application code merely to make one launch path look faster.

**Issue gate:**

- All three launch modes use the identical application artifact, Liberty
  runtime, workload, and recorded host resource envelope.
- All three complete the resolved workload or produce precise diagnostic
  failure.
- JFR, GC, and metadata artifacts are durable and comparable.
- The complete required workflow is green.
- The evidence-matrix update is merged before the tricked-out baseline is
  tagged.

---

## Cross-cutting campaign gate

Evidence matrix is a serial campaign gate

The campaign evidence matrix is:

`1-trick-out-01-remove-before-merge/evidence-matrix.md`

Every implementation issue must update this file. Evidence capture is part of the implementation work, not optional follow-up documentation.

Required workflow for every implementation issue

1. Before implementation, read the current evidence matrix from the campaign base branch. Identify which of the ten reasons the issue is intended to exercise. Do not overwrite evidence recorded by earlier issues.
2. Complete the issue’s implementation, local validation, required CI, and review-feedback resolution.
3. After the technical work and validation are complete, but before the issue is considered complete or its PR is merged, update the evidence matrix with what actually happened during this issue.
4. Commit the evidence-matrix update in the same task PR as the implementation. The PR must not merge without this update.
5. After merge, verify that the evidence-matrix update is present on the campaign base branch.
6. Do not assign, dispatch, or begin the next serial implementation issue until the preceding issue’s evidence-matrix update is merged and visible on the campaign base branch.

Required content

For every reason materially touched by the issue, update all applicable fields:

- Implementation task: Identify the issue and PR that introduced, exercised, or verified the mechanism.
- Observed campaign event: Describe a concrete event that actually occurred. Examples include a compiler rejection, failed test, analyzer finding, formatting failure, dependency rule violation, review correction, runtime diagnostic, trace, JFR recording, or performance observation.
- Artifact: Record durable evidence sufficient for another person to inspect the claim. Include exact issue numbers, PR numbers, commit SHAs, GitHub Actions run URLs, job names, check names, artifact paths, log paths, telemetry files, screenshots, traces, profiles, or post-mortem sections as applicable.
- Confidence: Classify the evidence as `Strong`, `Moderate`, `Weak`, `Unsupported`, or `Not exercised`.
- Slide implication: Classify the result as `Main slide`, `Brief mention`, `Appendix`, or `Cut`.

Preserve the abstract’s original reason numbering and ordering.

Evidence quality rules

- Record observations, not intentions.
- Do not claim that a safeguard helped merely because its tool was installed or its check passed.
- Distinguish between:
- a mechanism being present;
- a mechanism being executed;
- a mechanism detecting or preventing a problem; and
- a mechanism materially improving the agent’s work.
- If a mechanism ran but produced no meaningful event, state that explicitly.
- If the issue did not exercise an expected reason, record `Not exercised` rather than inventing evidence.
- If evidence is inconclusive, record `Weak` or `Unsupported` and explain why.
- Negative evidence is valid. Record cases where an agent bypassed, misunderstood, or received no benefit from a safeguard.
- Do not remove or rewrite earlier observations unless correcting a factual error. Add the new issue’s evidence so the campaign history remains understandable.
- Do not put reusable implementation guidance in the evidence matrix. Validated guidance for later issues belongs in `campaign-lessons.md`; the evidence matrix records what occurred and what supports the presentation.

Completion gate

An implementation issue is incomplete unless:

- its implementation and validation are complete;
- required CI is green;
- review feedback is resolved;
- its evidence-matrix update is committed in the task PR;
- the update contains durable references to the available evidence; and
- the merged campaign base branch contains that update.

The absence of meaningful evidence is not a reason to skip the update. Record the result as `Not exercised`, `Weak`, or `Unsupported`, with a concise explanation, before proceeding to the next issue.

---

## Reference material

- `dd-3032592-10-boring-reasons-abstract.md`
- `.github/workflows/` and all children
- `demo` and all children
```

</details>


---

<sub>32s</sub>

### `view`

**view the file at /home/edburns/workareas/dd-3016202-cargotracker-devoxx-be-2026-02/1-trick-out-01-remove-before-merge/spike_1_4_dependency_governance/README.md.**

/home/edburns/workareas/dd-3016202-cargotracker-devoxx-be-2026-02/1-trick-out-01-remove-before-merge/spike_1_4_dependency_governance/README.md (lines 1-260)

<details>
<summary>119 lines</summary>

````
# Spike 1.4: Maven and dependency-governance rules

Date: 2026-09-29

Plan question:
`1-trick-out-01-remove-before-merge/trick-out-01-ignorance-reduction-plan.md`,
section 1.4.

## Decision

Add one Maven Enforcer `3.6.3` execution bound to `validate` with:

1. `requireJavaVersion` set to `[17,18)`.
2. `requireMavenVersion` set to `[3.9.9,4.0.0)`.
3. `requirePluginVersions`, after explicitly pinning:
   - `maven-clean-plugin` `3.2.0`;
   - `maven-resources-plugin` `3.3.1`.
4. `dependencyConvergence`.
5. `banDuplicatePomDependencyVersions`.
6. `bannedDependencies` for direct Jakarta, Spring, Payara, WildFly/JBoss,
   and Tomcat dependencies.
7. `requireNoRepositories`, allowing only repository ID `central`.

Do **not** add `requireUpperBoundDeps`. It passes, but
`dependencyConvergence` is the stricter selected graph invariant and makes the
upper-bound rule redundant for this campaign.

Do **not** validate, preserve, or accommodate Payara or any other application
server. Open Liberty is the only supported demo path. The bans on other
server families make that boundary explicit.

## What the spike established

The current Open Liberty graph is already clean:

- `dependencyConvergence` passes without exclusions;
- the stricter-scope `requireUpperBoundDeps` candidate also passes, confirming
  that there is no hidden lower-version selection;
- there are no duplicate dependency declarations;
- there are no direct dependencies from the prohibited migration or
  non-Liberty server families;
- the project and its parents do not add repositories outside Maven Central.

The current POM has one small reproducibility defect relevant to the demo:
Maven supplies implicit versions for `maven-clean-plugin` and
`maven-resources-plugin`. Pinning the versions already selected by Maven 3.9.9
fixes the defect without upgrading or modernizing anything.

The spike also showed why `requirePluginVersions` must remain strict:

- setting `banMavenDefaults=false` made the baseline green;
- but it also allowed a deliberately added, unversioned
  `build-helper-maven-plugin`;
- therefore the selected policy keeps strict checking, pins the two plugins
  used by the demo lifecycle, and explicitly exempts only the unused Maven
  defaults for `install`, `deploy`, and `site`.

With those two pins and three narrow exemptions, the selected plugin policy
passes. Adding an unversioned project plugin then fails with the plugin
coordinate and Maven-selected version.

## Candidate disposition

| Candidate | Result | Decision |
|---|---|---|
| `requireJavaVersion` | Baseline passes; impossible-range control fails | Select `[17,18)` |
| `requireMavenVersion` | Wrapper Maven 3.9.9 passes; impossible-range control fails | Select `[3.9.9,4.0.0)` |
| `requirePluginVersions` | Baseline identifies clean/resources defaults; selected policy passes; unversioned-plugin control fails | Select targeted strict policy |
| `dependencyConvergence` | Open Liberty graph passes without exclusions | Select |
| `requireUpperBoundDeps` | Open Liberty graph passes even with `test` and `provided` included | Reject as redundant |
| `banDuplicatePomDependencyVersions` | Baseline passes; duplicate control fails with exact coordinate | Select |
| `bannedDependencies` | Baseline passes; Jakarta control fails with exact coordinate | Select direct-dependency guard |
| `requireNoRepositories` | Baseline passes; repository control fails with POM and repository ID | Select POM-level guard |

No baseline dependency finding requires an exclusion. No tool false positive
was observed.

## Selected plugin-version policy

`requirePluginVersions` unexpectedly discovers the Maven defaults for
`install`, `deploy`, and `site` even though the configured phase list is
limited to the demo build lifecycle. Those phases are not used by the demo,
so the selected configuration:

- pins `maven-clean-plugin` `3.2.0`;
- pins `maven-resources-plugin` `3.3.1`;
- leaves the already explicit compiler, WAR, Surefire, Spotless, Liberty, and
  Cargo plugin versions unchanged;
- places only these unused defaults in `unCheckedPluginList`:
  - `org.apache.maven.plugins:maven-install-plugin`;
  - `org.apache.maven.plugins:maven-deploy-plugin`;
  - `org.apache.maven.plugins:maven-site-plugin`.

Do not use `banMavenDefaults=false`; the negative control proved it is too
permissive for this POM.

## Banned direct dependencies

Use `searchTransitive=false` and these patterns:

```text
jakarta.*:*
org.springframework*:*
fish.payara*:*
org.wildfly*:*
org.jboss.as:*
org.apache.tomcat*:*
```

This prevents an accidental Jakarta/Spring migration or addition of another
application server without turning historical transitive dependencies into
campaign work. Open Liberty dependencies remain allowed.

## Reproduction

Run from the repository root:

```bash
1-trick-out-01-remove-before-merge/spike_1_4_dependency_governance/run-spike.sh
```

The harness:

- copies `demo/pom.xml`; it never edits the application POM;
- tests only the default Open Liberty path;
- runs every rule independently;
- creates targeted failure controls;
- regenerates `generated-poms/`, `logs/`, and `run-summary.tsv`;
- exits nonzero if a case differs from its classified expectation.

The final run contains 15 expected outcomes.

## Proposed text for the plan's Resolution field

Select an Open Liberty-only Maven Enforcer policy. Bind Maven Enforcer `3.6.3`
to `validate` and enable `requireJavaVersion` `[17,18)`,
`requireMavenVersion` `[3.9.9,4.0.0)`, strict `requirePluginVersions`,
`dependencyConvergence`, `banDuplicatePomDependencyVersions`, narrowly scoped
direct `bannedDependencies`, and `requireNoRepositories`. Pin only the two
implicit lifecycle plugins used by the demo: `maven-clean-plugin` `3.2.0` and
`maven-resources-plugin` `3.3.1`. Exempt the unused Maven defaults for
`install`, `deploy`, and `site`; do not use `banMavenDefaults=false`, because
the spike proved that it permits an unversioned project plugin. Select
`dependencyConvergence` as the single dependency-graph invariant and omit
`requireUpperBoundDeps` as redundant; both passed the Open Liberty graph
without dependency exclusions, including test and provided scopes for the
upper-bound candidate. Ban direct Jakarta, Spring, Payara, WildFly/JBoss, and
Tomcat dependencies so Open Liberty remains the only supported application
server. The duplicate-dependency, banned-dependency, repository, Java/Maven
version, and unversioned-plugin negative controls all failed with actionable
messages. No dependency modernization, broad exclusion, Payara validation, or
other application-server accommodation is required.
````

</details>


---

<sub>32s</sub>

### `view`

**view the file at /home/edburns/workareas/dd-3016202-cargotracker-devoxx-be-2026-02/1-trick-out-01-remove-before-merge/spike_1_10_static-analyzer/README.md.**

/home/edburns/workareas/dd-3016202-cargotracker-devoxx-be-2026-02/1-trick-out-01-remove-before-merge/spike_1_10_static-analyzer/README.md (lines 1-260)

<details>
<summary>148 lines</summary>

````
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
````

</details>


---

<sub>32s</sub>

### `view`

**view the file at /home/edburns/workareas/dd-3016202-cargotracker-devoxx-be-2026-02/1-trick-out-01-remove-before-merge/spike_1_12_behavior_saftey_net/README.md.**

/home/edburns/workareas/dd-3016202-cargotracker-devoxx-be-2026-02/1-trick-out-01-remove-before-merge/spike_1_12_behavior_saftey_net/README.md (lines 1-260)

<details>
<summary>192 lines</summary>

````
# Spike 1.12: Behavioral safety-net readiness

Date: 2026-09-29

## Verdict

The repository is **at the starting line for domain and application-service
behavioral tests**, but it is **not yet at the starting line for the complete
Section 1.12 safety net**.

The existing JUnit 5 and Arquillian foundation is working:

- `mvn test` executes 28 tests successfully.
- 24 tests exercise domain behavior.
- 4 Arquillian tests exercise `BookingService` with Open Liberty, JPA, and the
  application service implementation.
- A temporary mutation of the missed-deadline assertion produced a concise,
  targeted failure, and the restored test passed.

However, the normal Maven test lifecycle has no executable coverage for the
booking facade/DTO boundary, JSF backing state, the deployed application HTTP
surface, the Administration page, or architecture boundaries. This spike now
contains a runnable production-WAR HTTP acceptance prototype, but it is not
yet part of Maven or CI. Three source files whose names imply tests are not
discovered as tests.

The campaign therefore does **not** need to invent a test stack. It does need a
small enabling slice that turns the already working stack into a full-application
behavioral safety net.

## Existing executable test inventory

| Layer | Executed tests | Current value | Important gap |
|---|---:|---|---|
| Cargo domain | 9 | Delivery and routing status, handling progress, misdirection | No focused route-change/deadline-change contract |
| Itinerary domain | 3 | Expected events and constructor guards | `testNextExpectedEvent` is empty but passes |
| Route specification | 4 | Origin, destination, and deadline satisfaction | Good direct starting point for deadline behavior |
| Handling domain | 8 | Handling-event construction and history | Some tests are explicitly described as trivial |
| `BookingService` Arquillian | 4 | Book, request routes, assign route, change destination | Ordered/static-state coupling; no facade or HTTP boundary |
| Full application HTTP/UI | 0 in Maven; spike harness available | Production-WAR root, Administration, detail, and REST checks | Not integrated into Maven or CI |
| Architecture | 0 | None | No architecture-test dependency or tests |
| Browser | 0 | None | No browser automation dependency or harness |

The six discovered test classes are:

1. `BookingServiceTest`
2. `CargoTest`
3. `ItineraryTest`
4. `RouteSpecificationTest`
5. `HandlingEventTest`
6. `HandlingHistoryTest`

Maven compiles 11 test source files, but these three test-looking classes are
not discovered because they have no JUnit 5 `@Test` methods:

- `CargoLifecycleScenarioTest`
- `HandlingEventServiceTest`
- `ExternalRoutingServiceTest`

The remaining two compiled test sources are Arquillian deployment helpers.

## What `mvn test` actually proves

The default Open Liberty profile is active during `mvn test`.
`BookingServiceTest` starts Open Liberty and deploys a ShrinkWrap-generated
`cargo-tracker-test.war`. That is useful application-service integration
coverage, but it is not a deployment test of the production
`cargo-tracker.war`.

The test run logs this warning before the Arquillian deployment:

```text
CWWKZ0014W: The application cargo-tracker could not be started as it could not
be found at location cargo-tracker.war.
```

The generated test WAR then starts successfully and all four
`BookingServiceTest` methods pass. Consequently, a green `mvn test` or current
CI package job does not prove that the real root page, Administration page,
REST endpoint, JSF wiring, or production WAR startup works.

## Existing contracts relevant to Change Arrival Deadline

Useful contracts already exist:

- `RouteSpecificationTest.testIsNotSatisfiedByMissedDeadline` proves that an
  itinerary arriving after the deadline does not satisfy the specification.
- `BookingServiceTest.testRegisterNew` proves a newly booked cargo retains its
  requested arrival deadline.
- `BookingServiceTest.testAssignRoute` proves the assigned route arrives before
  that deadline.
- `BookingServiceTest.testChangeDestination` proves changing destination
  preserves the deadline and makes the existing itinerary misrouted.
- `BookingServiceTest` proves cargo lookup through `CargoRepository` after
  application-service operations.

These are a credible base for deadline-change tests. They do not protect:

- a future `BookingService.changeArrivalDeadline` operation;
- facade and DTO propagation of a changed deadline;
- JSF backing-state behavior;
- rendered Administration behavior;
- production application startup and seeded-data usability.

## Deterministic deployed-application path

The full application was packaged and started with Open Liberty. These paths
all returned HTTP 200:

| Path | Deterministic evidence |
|---|---|
| `/cargo-tracker/` | Rendered `Cargo Tracker` |
| `/cargo-tracker/admin/dashboard.xhtml` | Rendered `Cargo Dashboard` and `ABC123` |
| `/cargo-tracker/admin/show.xhtml?trackingId=ABC123` | Rendered seeded cargo `ABC123` |
| `/cargo-tracker/rest/cargo` | JSON contained `ABC123`, `DEF789`, `JKL567`, and `MNO456` |

The best no-browser safety-net path is:

```text
GET /cargo-tracker/rest/cargo
```

It is stable, machine-readable, requires no session choreography, and proves
that the production WAR, JPA, startup seeding, repository, and JAX-RS boundary
are usable.

For an Administration-specific assertion, use:

```text
GET /cargo-tracker/admin/dashboard.xhtml
```

and assert HTTP 200 plus `Cargo Dashboard` and `ABC123`. A stronger cargo-detail
check is:

```text
GET /cargo-tracker/admin/show.xhtml?trackingId=ABC123
```

The four tracking IDs are deterministic. Their date values are not fixed:
`SampleDataGenerator` calculates deadlines and itinerary dates relative to
`LocalDate.now()`. Tests should assert identities, statuses, locations, and
date relationships rather than literal dates.

## Automated HTTP acceptance prototype

Run:

```bash
./1-trick-out-01-remove-before-merge/spike_1_12_behavior_saftey_net/run-http-acceptance.sh
```

The script:

1. packages the production `cargo-tracker.war`;
2. prepares and deploys it with the Open Liberty Maven plugin;
3. starts Open Liberty and waits for the `cargo-tracker` application;
4. asserts the root page, Administration dashboard, seeded cargo detail, and
   cargo REST contracts;
5. writes response bodies, headers, a TSV summary, and Maven logs into the
   spike directory; and
6. stops Open Liberty on both success and failure.

It deliberately uses `liberty:start` and `liberty:stop` rather than placing a
Maven process in the background. The harness requires only the repository's
Maven wrapper, Java 17, `curl`, and standard POSIX command-line tools.

## Browser-test decision

Do **not** add browser automation as part of the initial safety net.

Server-rendered JSF pages and the JSON endpoint provide enough value to prove
startup, seeded cargo lookup, Administration rendering, and the deployed
application boundary. Adding Playwright, Selenium, or another browser stack
would introduce runtime installation, synchronization, and CI maintenance
without protecting a behavior that cannot first be covered more cheaply.

A small browser test becomes justified only when the later feature needs to
prove PrimeFaces dialog/Ajax behavior that cannot be expressed through:

1. domain tests;
2. `BookingService`/facade tests; and
3. direct HTTP rendering checks.

## Architecture-test readiness

There is no architecture-testing dependency or architecture test.
Furthermore, a strict version of the proposed rules fails against the current
code:

- tracking web classes directly import domain model and repository types;
- `BookingBackingBean` is physically located in the domain package while
  importing the booking facade, DTOs, JSF, PrimeFaces, and application utility
  code.

Architecture checks must therefore either:

- establish an explicit baseline/allowlist for known violations and prevent
  new ones; or
- first move `BookingBackingBean` and resolve the intentional tracking-web
  exception.

Adding a blanket “interfaces never depend on domain” or “domain never depends
on interfaces/application” rule immediately would fail before the deadline
feature begins.

## Failure-signal experiment

The assertion in
`RouteSpecificationTest.testIsNotSatisfiedByMissedDeadline` was temporarily
changed from `assertFalse` to `assertTrue`.

The targeted command failed in 7.6 seconds with:

```text
RouteSpecificationTest.testIsNotSatisfiedByMissedDeadline:85
expected: <true> but was: <false>
```

The source was restored, the same targeted test passed, and `git diff` showed
no remaining change to the test file.

This demonstrates that the domain test layer gives the concise failure signal
requested by Section 1.12.

## Work required before the complete safety net

The minimum enabling work is:

1. Promote the spike's `run-http-acceptance.sh` production-WAR lifecycle into
   the repository's supported test/CI entry points.
2. Add direct tests for `DefaultBookingServiceFacade` and the relevant DTO
   assembly so arrival-deadline behavior is protected across the interface
   boundary without requiring a browser.
3. Add an architecture-test facility with a documented baseline for current
   violations, then prohibit new domain-to-interface/application dependencies
   and new web-to-domain leakage outside the accepted legacy tracking path.
4. Decide explicitly whether to revive or delete the three undiscovered legacy
   test classes; they currently create false confidence from their names.
5. Replace the empty `ItineraryTest.testNextExpectedEvent` placeholder with a
   real assertion or remove it from the test count.

After those steps, the later Change Arrival Deadline campaign can add behavior
tests at each crossed boundary without first building new infrastructure.

## Evidence

- `resolution.md` — decision and required safety-net scope
- `logs/20260929-1821-spike-1-12-test-logs.txt` — successful 28-test baseline
- `logs/20260929-1826-spike-1-12-mutation-logs.txt` — expected mutation failure
- `logs/20260929-1827-spike-1-12-restored-test-logs.txt` — restored test passes
- `logs/20260929-1827-spike-1-12-package-logs.txt` — production WAR package
- `logs/20260929-1828-spike-1-12-http-logs.txt` — production Open Liberty startup
- `reports/http-probe.txt` — deployed endpoint results
- `run-http-acceptance.sh` — automated production-WAR HTTP acceptance prototype
- `reports/http-acceptance-20260929-183256/` — successful automated run evidence
````

</details>


---

<sub>32s</sub>

### `view`

**view the file at /home/edburns/workareas/dd-3016202-cargotracker-devoxx-be-2026-02/1-trick-out-01-remove-before-merge/spike_1_15_capture_repeatable_performance_envelope/README.md.**

/home/edburns/workareas/dd-3016202-cargotracker-devoxx-be-2026-02/1-trick-out-01-remove-before-merge/spike_1_15_capture_repeatable_performance_envelope/README.md (lines 1-260)

<details>
<summary>203 lines</summary>

````
# Spike 1.15: Repeatable performance workload and resource envelope

Date: 2026-09-30

Plan question:
`1-trick-out-01-remove-before-merge/trick-out-01-ignorance-reduction-plan.md`,
section 1.15.

## Decision

Select a non-containerized, diagnostic workload built on the Open Liberty
lifecycle established in section 1.13.

Build and deploy the WAR once. For each independent repetition:

1. restore a pristine `defaultServer` directory;
2. start Liberty with the Maven plugin;
3. measure from launch invocation through a successful seeded REST response;
4. send five unmeasured warm-up requests;
5. start a 10-second JFR dynamically with `jcmd`;
6. send 30 measured sequential requests to
   `/cargo-tracker/rest/cargo`, paced by 200 milliseconds;
7. capture JVM, process, heap, GC, JFR, HTTP, Liberty, and timing evidence;
8. stop Liberty and verify cleanup.

Use five repetitions for the initial direct-`java` baseline and for each launch
mode compared by section 1.16. Do not use a container, synthetic cgroup,
fixed heap, processor-count override, or other JVM tuning flag as part of this
workload contract.

This workload is repeatable for functional and diagnostic evidence. It is not
stable enough to support narrow latency, startup, CPU, heap, or GC regression
thresholds on a shared or hosted machine.

## Environment

The final spike ran against commit
`cf19be6029aad88ce792e544cc4dd8135867723f` with:

- Microsoft Build of OpenJDK 17.0.18;
- Maven Wrapper 3.9.9;
- Liberty Maven Plugin 3.12.1;
- Open Liberty 26.0.0.8;
- eight visible processors;
- approximately 16 GiB of host memory;
- a WSL2 Linux VM with cgroup v2 membership `/init.scope`;
- no Docker/OCI runtime or synthetic cgroup limits.

The WAR SHA-256 was:

```text
6a238acffd4938b52fe49a00cd41cc599774e937bcdcedc348a94d6821b0780d
```

The harness records the complete environment and cgroup view in
`reports/environment.txt`. These measurements establish the workload and its
local noise floor. The implementation issue must run the unchanged harness on
the GitHub-hosted runner before treating runner-specific gross bounds as
required CI policy.

## Workload contract

| Property | Selected value |
|---|---|
| Artifact | One prebuilt `cargo-tracker.war` and one Open Liberty runtime |
| Freshness | Restore a pristine server directory for each repetition |
| Readiness | HTTP 200 from `/cargo-tracker/rest/cargo` containing `ABC123` |
| Warm-up | 5 sequential validated requests |
| Measured workload | 30 sequential validated requests |
| Pacing | 200 ms after each measured request |
| Concurrency | 1 |
| Startup bound | 90 seconds |
| Request timeout | 10 seconds |
| JFR | 10 seconds, started dynamically after warm-up |
| Repetitions | 5 per launch mode |
| Shutdown | `liberty:stop`, required after every repetition |
| Containerization | None |

The exact machine-readable contract is in
`reports/workload-contract.txt`.

## Results

All five repetitions:

- started Liberty successfully;
- returned all 30 measured HTTP responses with status 200 and seeded content;
- produced process samples, JVM command lines, complete flag inventories,
  heap summaries, a server-PID-specific GC log, a parseable JFR, and Liberty
  logs;
- stopped Liberty successfully;
- removed the disposable clone.

### Run results

| Run | Startup ms | Request median ms | Peak RSS KiB | CPU seconds | Heap before KiB | Heap after KiB | GC pauses | GC pause ms | Total ms |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 36,821 | 9.918 | 758,064 | 113.120 | 129,834 | 154,294 | 48 | 473.043 | 61,292 |
| 2 | 49,523 | 13.996 | 708,676 | 160.920 | 122,181 | 146,380 | 42 | 565.772 | 73,638 |
| 3 | 57,137 | 13.364 | 859,464 | 177.180 | 217,860 | 171,211 | 42 | 637.322 | 76,392 |
| 4 | 33,702 | 9.037 | 752,956 | 108.760 | 183,164 | 123,566 | 36 | 429.074 | 51,676 |
| 5 | 37,144 | 8.518 | 808,096 | 118.460 | 139,447 | 164,137 | 38 | 378.193 | 56,936 |

### Cross-run variation

| Metric | Median | Range | CV |
|---|---:|---:|---:|
| Startup | 37,144 ms | 23,435 ms | 20.898% |
| Per-run request median | 9.918 ms | 5.478 ms | 20.691% |
| Peak RSS | 758,064 KiB | 150,788 KiB | 6.652% |
| Process CPU | 118.460 s | 68.420 s | 20.555% |
| Heap before workload | 139,447 KiB | 95,679 KiB | 22.985% |
| Heap after workload | 154,294 KiB | 47,645 KiB | 10.863% |
| GC pause count | 42 | 12 | 9.996% |
| Total GC pause time | 473.043 ms | 259.129 ms | 18.827% |
| Complete repetition | 61,292 ms | 24,716 ms | 14.918% |

Across all 150 measured requests:

- median: 10.459 ms;
- p90: 20.177 ms;
- p95: 23.077 ms;
- p99: 39.919 ms;
- maximum: 87.100 ms;
- coefficient of variation: 66.024%.

The high individual-request CV and approximately 15–23% cross-run variation
for several aggregate measurements demonstrate that this is not a
microbenchmark. The useful invariant is that identical work completes and
produces comparable diagnostic evidence. Section 1.16 must use paired,
alternating repetitions on the same runner and treat differences within this
noise range as observations.

## Diagnostic evidence

Each run preserves:

- launch-to-readiness and total duration;
- 200-millisecond process samples with RSS and aggregate CPU ticks;
- `jcmd VM.command_line`;
- `jcmd VM.flags -all`;
- `jcmd GC.heap_info` before and after the workload;
- unified G1 GC logging for the actual Liberty server PID;
- a parseable 10-second JFR;
- JFR event summary;
- warm-up and measured request TSV files;
- readiness headers and response body;
- Liberty `messages.log` and `console.log`;
- Maven start and stop logs.

All five JFRs contained CPU, execution, allocation, and runtime events. The
harness derives its JFR configuration from the JDK profile but disables:

- `jdk.JVMInformation`;
- `jdk.InitialSystemProperty`;
- `jdk.OSInformation`;
- `jdk.InitialEnvironmentVariable`;
- `jdk.SystemProcess`.

Every final JFR summary reported zero events for those five types.

## Failure policy

Required CI should fail on:

- inability to build or deploy the fixed artifact;
- inability to discover and sample the Liberty JVM;
- startup or readiness exceeding 90 seconds;
- any warm-up or measured request that times out, returns a non-200 status, or
  lacks the seeded cargo content;
- abnormal JVM termination or an out-of-memory error;
- missing or unparseable process, command-line, flag, heap, GC, JFR, HTTP, or
  Liberty evidence;
- inability to stop Liberty or remove the disposable runtime;
- a complete repetition exceeding 120 seconds;
- peak sampled RSS exceeding a provisional gross bound of 2 GiB.

The 120-second and 2-GiB bounds are deliberately broad compared with observed
maxima of 76.392 seconds and 859,464 KiB. The first GitHub-hosted execution
must record its own environment and may widen a gross bound if the same
correct workload demonstrates that the local value is not portable.

Do not fail required CI on:

- startup-time changes within the observed noise floor;
- request latency, CPU time, heap use, GC counts, GC pause time, or RSS
  differences that do not breach a resolved gross bound;
- a `java` versus `jaz` performance difference without repeated paired
  evidence.

## Reproduction

From the repository root:

```bash
1-trick-out-01-remove-before-merge/\
spike_1_15_capture_repeatable_performance_envelope/run-spike.sh
```

Optional parameters:

```bash
RUN_COUNT=5 \
WARMUP_REQUESTS=5 \
MEASURED_REQUESTS=30 \
REQUEST_PACING_SECONDS=0.2 \
JFR_DURATION_SECONDS=10 \
MAX_STARTUP_MS=90000 \
MAX_TOTAL_MS=120000 \
MAX_RSS_KB=2097152 \
1-trick-out-01-remove-before-merge/\
spike_1_15_capture_repeatable_performance_envelope/run-spike.sh
```

The harness uses a disposable shared clone and never modifies application
sources or the campaign worktree's `demo/target`. It builds and deploys once,
restores the pristine deployed server for each repetition, and removes all
scratch state on success or failure.

## Proposed text for the plan's Resolution field

Select a non-containerized, diagnostic workload based on the Open Liberty
lifecycle resolved in section 1.13. Build and deploy one WAR and Liberty
runtime, record their checksums, and restore a pristine `defaultServer`
directory for each repetition. Measure from the `liberty:start` invocation
through HTTP 200 readiness from `/cargo-tracker/rest/cargo` with seeded cargo
`ABC123`. Run five validated warm-up requests, start a 10-second JFR
dynamically with `jcmd`, then run 30 sequential validated requests paced by
200 milliseconds. Use one request at a time and a 10-second request timeout.
Capture the effective JVM command and complete flags, 200-millisecond
RSS/CPU samples, heap summaries before and after the workload, server-PID GC
logs, parseable JFR, request TSV, Liberty logs, Maven logs, exit status, and
cleanup result. Repeat the complete workload five times per launch mode on the
same GitHub-hosted VM, using a fresh Liberty output/data directory each time.
Record the runner CPU, memory, OS, kernel, and cgroup view; do not use
Docker/OCI execution, synthetic cgroup limits, fixed heap/processor tuning, or
other `-X*`/`-XX*` workload flags that would interfere with the section 1.16
`jaz` comparison. The spike's five direct-`java` runs all passed, but startup,
per-run request median, CPU, heap-before, GC-pause-time, and total-duration
variation ranged from approximately 15% to 23%; individual request timing was
noisier. Treat these measurements as diagnostic evidence, not benchmark
thresholds. Fail on functional failure, crash or OOM, startup beyond 90
seconds, missing/unparseable diagnostics, cleanup failure, a complete
repetition beyond 120 seconds, or a provisional gross peak-RSS bound of 2
GiB. Do not fail on ordinary timing/resource variation or declare a
`java`/`jaz` winner without repeated paired evidence. Generate and preserve a
safe JFR configuration that disables JVM information, initial system
properties, OS information, initial environment variables, and system-process
events. Calibrate the broad gross bounds during the first GitHub-hosted run
without changing the workload contract.
````

</details>


---

<sub>32s</sub>

### `view`

**view the file at /home/edburns/workareas/dd-3016202-cargotracker-devoxx-be-2026-02/1-trick-out-01-remove-before-merge/spike_1_16_java_vs_jaz/README.md.**

/home/edburns/workareas/dd-3016202-cargotracker-devoxx-be-2026-02/1-trick-out-01-remove-before-merge/spike_1_16_java_vs_jaz/README.md (lines 1-300)

<details>
<summary>229 lines</summary>

````
# Spike 1.16: `java` versus `jaz`, GC logs, and JFR capture

Date: 2026-09-30

Plan question:
`1-trick-out-01-remove-before-merge/trick-out-01-ignorance-reduction-plan.md`,
section 1.16.

## Decision

Compare direct `java`, bypassed `jaz`, and tuned `jaz` on one
non-containerized runner using the workload resolved by spike 1.15 without
copying or independently redefining that workload.

The harness reads:

- `../spike_1_15_capture_repeatable_performance_envelope/reports/workload-contract.txt`;
- `../spike_1_15_capture_repeatable_performance_envelope/reports/profile-without-environment.jfc`.

It preserves copies and SHA-256 hashes of those inputs with the 1.16 evidence.
The request count, pacing, readiness condition, JFR duration, repetition
count, startup bound, total-duration bound, peak-RSS bound, container policy,
and redaction policy therefore remain the section 1.15 decisions.

Use this as a diagnostic comparison job, not as evidence that `jaz` should
replace direct `java` by default. The spike proves that `jaz` can launch,
supervise, diagnose, and stop this Open Liberty workload and that its selected
settings are observable. It does not establish a repeatable performance
winner on the unconstrained host.

Install a pinned `jaz` package without `sudo`, verify its SHA-256, and expose
it to Open Liberty through the per-server `JAVA_HOME` setting in
`server.env`. The `jaz` Java home must mirror the real JDK layout and override
only `bin/java`; a minimal directory containing only a launcher does not give
Liberty the JDK metadata it needs to add its Java 17 module-access options.

Use these modes:

1. `direct`: the real Microsoft OpenJDK 17 `JAVA_HOME`;
2. `bypass`: the mirrored Java home with `JAZ_BYPASS=1`;
3. `tuned`: the mirrored Java home with normal `jaz` tuning.

Set `JAZ_EXIT_WITHOUT_FLUSH=1` for both `jaz` modes so shutdown is not delayed
by telemetry flushing. Do not set `JAZ_IGNORE_USER_TUNING` and do not pass
heap, processor-count, GC-selection, or startup-JFR tuning options.

## Pinned launcher

| Property | Value |
|---|---|
| Product | Azure Command Launcher for Java |
| Version | 1.0.4 |
| Architecture | amd64 |
| Package | `jaz_1.0.4_amd64.deb` |
| SHA-256 | `3d479f11ff2a037790505746a44568e1408f2f79aac62300ea4c651c4969a710` |
| Source | Microsoft Ubuntu 24.04 package repository |

The harness downloads the package directly, verifies the pinned digest, and
extracts it into disposable scratch space with `dpkg-deb`. It does not modify
the runner's package database.

## Environment

The final spike ran against commit
`f493d6012f9c012999b82ca9a02d7c73ba44f9f2` with:

- Microsoft Build of OpenJDK 17.0.18;
- Maven Wrapper 3.9.9;
- Liberty Maven Plugin 3.12.1;
- Open Liberty 26.0.0.8;
- `jaz` 1.0.4;
- eight visible processors;
- approximately 16 GiB of host memory;
- a WSL2 Linux VM with cgroup v2 membership `/init.scope`;
- no container runtime or synthetic cgroup limits.

The WAR SHA-256 was:

```text
16f79447db08524486ae0cddae7a6cabf16fd5d8077cb28c4e7ed5c1d93a5d49
```

The experiment establishes launcher integration and the local paired noise
floor. The implementation issue must repeat the unchanged experiment on one
GitHub-hosted VM before treating the measurements as hosted-runner evidence.

## Launcher integration

Open Liberty's `server.env` is the substitution point. Maven and its Liberty
plugin continue to run with the real JDK. For the server process, direct mode
sets `JAVA_HOME` to the real JDK, while the two `jaz` modes set it to a
symlinked mirror whose `bin/java` wrapper executes the pinned `jaz` binary.

The wrapper records every invocation. For the tuned server launch it also
replays the exact Liberty JVM argument vector with `JAZ_DRY_RUN=1` before the
real launch. The harness then:

- identifies and samples the real child Java process rather than the
  supervising `jaz` process;
- records the `jaz` launcher PID and process relationship;
- confirms direct mode has no `jaz` ancestor;
- confirms both `jaz` modes retain a launcher ancestor while Liberty runs;
- confirms `liberty:stop` removes both the Java child and launcher;
- preserves Maven, Liberty, launcher, GC, JFR, JVM-command, JVM-flag, process,
  heap, HTTP, and timing evidence.

## Tuning and diagnostics semantics

Preflight dry runs establish the following:

- normal `jaz` selects its heap and G1 tuning;
- `-Xlog` is treated as diagnostic configuration and does not suppress
  tuning;
- `JAZ_BYPASS=1` suppresses heap and GC tuning but still adds launcher
  diagnostics, including native-memory tracking and an error-file location;
- a user-provided tuning option such as `-Xmx256m` suppresses normal `jaz`
  heap and GC tuning, while launcher diagnostics remain.

The last case is the required failure example. Required CI must reject a
tuned-mode run whose effective flags do not contain the expected `jaz`
settings. It must also reject direct or bypass mode if tuned heap/GC settings
appear unexpectedly.

GC logging remains the section 1.15 server-PID-specific unified log. JFR is
started dynamically with `jcmd` after warm-up using the redacted 1.15 profile;
it is not configured through a JVM startup option and therefore does not
interfere with `jaz` tuning.

## Experiment protocol

Build and deploy the WAR and Liberty runtime once. Record their hashes, retain
a pristine deployed `defaultServer`, and restore it before every launch. Run
five cycles with all three modes in each cycle. Rotate the mode order:

| Cycle | Order |
|---:|---|
| 1 | direct, bypass, tuned |
| 2 | bypass, tuned, direct |
| 3 | tuned, direct, bypass |
| 4 | direct, tuned, bypass |
| 5 | bypass, direct, tuned |

This produces five repetitions per mode and reduces position, cache, and
temporal bias. Each launch executes the unchanged section 1.15 workload and
must satisfy its functional, diagnostic, duration, memory, and cleanup gates.

## Results

All 15 launches passed. Every mode:

- used the same WAR, Liberty runtime, readiness condition, request workload,
  safe JFR profile, GC logging, and diagnostic protocol;
- returned all 30 measured responses with status 200 and seeded cargo content;
- produced parseable GC logs and JFR recordings;
- preserved effective JVM commands and complete flag inventories;
- stopped Liberty and removed the Java and launcher processes.

### Effective JVM policy

| Setting | Direct `java` | Bypassed `jaz` | Tuned `jaz` |
|---|---:|---:|---:|
| Maximum heap | 4,139,778,048 bytes | 4,139,778,048 bytes | 10,015,997,952–10,468,982,784 bytes |
| Minimum heap-free ratio | 40 | 40 | 10 |
| Maximum heap-free ratio | 70 | 70 | 50 |
| G1 periodic GC interval | 0 | 0 | 10,000 ms |
| Time-based G1 heap sizing | not enabled | not enabled | enabled |
| Native-memory tracking | off | summary | summary |
| GC | G1 | G1 | G1 |

The bypass mode therefore measures the launcher without heap or GC tuning,
but it is not byte-for-byte equivalent to direct `java`: `jaz` still enables
native-memory tracking and configures its error-file location.

### Median measurements

| Metric | Direct `java` | Bypassed `jaz` | Tuned `jaz` |
|---|---:|---:|---:|
| Startup | 25,469 ms | 30,498 ms | 28,790 ms |
| Per-run request median | 7.815 ms | 7.782 ms | 7.619 ms |
| Peak RSS | 810,748 KiB | 878,740 KiB | 790,644 KiB |
| Process CPU | 80.420 s | 99.500 s | 82.620 s |
| Heap before workload | 145,689 KiB | 178,298 KiB | 157,281 KiB |
| Heap after workload | 153,528 KiB | 142,759 KiB | 166,336 KiB |
| GC pause count | 37 | 36 | 44 |
| Total GC pause time | 277.522 ms | 333.112 ms | 341.114 ms |
| Complete repetition | 42,982 ms | 48,346 ms | 46,068 ms |

Across all 150 requests per mode, median request latency was 7.880 ms for
direct `java`, 8.158 ms for bypassed `jaz`, and 7.782 ms for tuned `jaz`.

### Paired interpretation

Paired cycle medians relative to direct `java` were:

| Metric | Bypassed `jaz` | Tuned `jaz` |
|---|---:|---:|
| Startup | +5.716% | -0.205% |
| Per-run request median | -0.361% | -2.176% |
| Peak RSS | +7.996% | +0.374% |
| Process CPU | +9.267% | -4.249% |
| GC pause count | -2.778% | +18.919% |
| Total GC pause time | +0.494% | +12.604% |
| Complete repetition | +5.274% | -0.501% |

Startup, total-duration, CPU, request, and RSS deltas changed sign across
cycles or remained within the broad variation established by spike 1.15.
Tuned request medians were lower than direct in four of five cycles, but the
paired median difference was only 0.182 ms. Tuned peak RSS was lower than
bypassed RSS in all five cycles, but it was not consistently lower than
direct RSS.

The repeatable behavioral difference was GC policy: tuned `jaz` enabled
10-second periodic GC and produced more GC pauses than both other modes in all
five cycles. The absolute additional pause time remained small for this
workload, but it is observable evidence of the selected tuning rather than a
performance victory.

The results do not justify a required CI assertion that one launcher is
faster, smaller, or more efficient. They do justify assertions that the
requested mode was actually used, the expected settings took effect, and all
functional and diagnostic evidence remained available.

## Failure policy

In addition to all section 1.15 failures, required CI must fail on:

- inability to download, verify, extract, or execute the pinned `jaz`;
- a package or version mismatch;
- inability to substitute the launcher through Liberty `server.env`;
- a `jaz` mode without a supervising `jaz` process;
- a direct mode with a `jaz` process;
- missing or invalid tuned-mode `JAZ_DRY_RUN=1` evidence;
- tuned-mode flags that do not show the expected tuning;
- bypass-mode flags that retain tuned heap or GC settings;
- a user-provided tuning option in the comparison workload;
- failure to relay Liberty output or start/stop status;
- a surviving Java or `jaz` process after cleanup;
- any difference in WAR, Liberty runtime, readiness condition, requests, JFR
  profile, or diagnostic protocol between modes.

Do not fail solely because one mode has better or worse startup, latency, CPU,
heap, RSS, or GC measurements. Interpret those measurements against the 1.15
noise floor and require repeated paired evidence before claiming a performance
winner.

## Reproduction

From the repository root:

```bash
1-trick-out-01-remove-before-merge/\
spike_1_16_java_vs_jaz/run-spike.sh
```

`RUN_COUNT=1` may be used only for harness development. The resolved
experiment uses the five repetitions imported from the 1.15 contract.

## Proposed text for the plan's Resolution field

Use the non-containerized workload, bounds, request protocol, and redacted JFR
configuration from spike 1.15 by reference rather than redefining them.
Install and checksum-pin `jaz` 1.0.4 from the Microsoft Ubuntu 24.04 package
repository without modifying the runner package database. Build and deploy
the WAR and Open Liberty runtime once, then compare direct `java`,
`JAZ_BYPASS=1`, and normal tuned `jaz` in five alternating-order cycles on the
same runner, restoring a pristine `defaultServer` before every launch.

Substitute `jaz` through Open Liberty `server.env` using a Java home that
mirrors the real JDK and overrides only `bin/java`; a minimal launcher-only
Java home omits JDK metadata Liberty needs for Java 17 module options. Keep
Maven, `jcmd`, and other tooling on the real JDK. Set
`JAZ_EXIT_WITHOUT_FLUSH=1`, capture tuned-mode `JAZ_DRY_RUN=1` output, preserve
launcher and child-JVM process evidence, and verify effective settings with
`jcmd VM.command_line` and `jcmd VM.flags`. Continue to use server-PID-specific
`-Xlog` GC output and start the bounded JFR dynamically after warm-up.

The spike's 15 launches all passed. Bypassed `jaz` retained default heap and
GC policy but still enabled native-memory tracking and an error-file location.
Tuned `jaz` selected an approximately 10.0–10.5 GB maximum heap, heap-free
ratios of 10/50, time-based G1 heap sizing, native-memory tracking, and
10-second periodic GC. It produced more GC pauses in all five paired cycles,
but startup, total duration, CPU, request latency, and RSS differences were
inconsistent or within the spike 1.15 noise floor. Therefore use the
three-mode job to prove launcher integration, effective tuning, diagnostics,
functional equivalence, and cleanup; do not fail CI or select a winner based
on performance differences alone. Fail on installation or checksum failure,
launcher substitution failure, suppressed or unverifiable tuning, artifact
or workload mismatch, missing GC/JFR/JVM/process evidence, functional failure,
or incomplete cleanup. Evaluate `jaz` under actual AKS pod limits in the
separate Azure deployment thread.
````

</details>


---

<sub>35s</sub>

### Copilot

All 17 gating questions have substantive resolutions, the implementation section has exactly seven direct tasks, the parent is open with no existing children, and this user-owned repository does not support organization issue types. The children will therefore be created **without an issue type**; I’m drafting all seven complete specifications before any GitHub mutation.

---

<sub>36s</sub>

### `view`

**view the file at /home/edburns/.copilot/plugins/shepherd-task/scripts/validate-stage20-drafts.sh.**

/home/edburns/.copilot/plugins/shepherd-task/scripts/validate-stage20-drafts.sh

<details>
<summary>65 lines</summary>

```
#!/usr/bin/env bash
# shepherd-task-version: 1.0.4

set -euo pipefail

[[ $# -eq 3 ]] || {
    echo "Usage: $0 <body-directory> <expected-count> <off|campaign>" >&2
    exit 1
}

body_directory="$1"
expected_count="$2"
lesson_propagation="$3"

[[ -d "$body_directory" ]] || {
    echo "Stage-20 body directory does not exist: $body_directory" >&2
    exit 1
}
[[ "$expected_count" =~ ^[1-9][0-9]*$ ]] || {
    echo "Expected count must be a positive integer." >&2
    exit 1
}
[[ "$lesson_propagation" == "off" || "$lesson_propagation" == "campaign" ]] || {
    echo "Lesson propagation must be off or campaign." >&2
    exit 1
}

body_files=()
for body_file in "$body_directory"/*-body.md; do
    [[ -f "$body_file" ]] || continue
    [[ "$body_file" != *-observed-body.md ]] || continue
    body_files+=("$body_file")
done
[[ ${#body_files[@]} -eq $expected_count ]] || {
    echo "Expected $expected_count persisted stage-20 body files; found ${#body_files[@]}." >&2
    exit 1
}

required_headings=(
    '## Campaign context and required reading'
    '## Branch and execution order'
    '## Implement'
    '## Completion gates'
    '## Out of scope'
)

for body_file in "${body_files[@]}"; do
    [[ -s "$body_file" && "$(awk 'END { print NR }' "$body_file")" -gt 1 ]] || {
        echo "Persisted issue body must contain physical Markdown lines: $body_file" >&2
        exit 1
    }
    first_nonblank="$(awk 'NF { print; exit }' "$body_file")"
    [[ "$first_nonblank" =~ ^##[[:space:]]+[^[:space:]] ]] || {
        echo "Persisted issue body must begin with a level-two heading: $body_file" >&2
        exit 1
    }
    for heading in "${required_headings[@]}"; do
        grep -Fqx -- "$heading" "$body_file" || {
            echo "Persisted issue body is missing the physical heading '$heading': $body_file" >&2
            exit 1
        }
    done
    if [[ "$lesson_propagation" == "campaign" ]]; then
        grep -Fqx -- '## Campaign lessons (REQUIRED)' "$body_file" || {
            echo "Treatment issue body is missing its campaign-lessons heading: $body_file" >&2
            exit 1
        }
    elif grep -Fqx -- '## Campaign lessons (REQUIRED)' "$body_file"; then
        echo "Control issue body unexpectedly contains a campaign-lessons heading: $body_file" >&2
        exit 1
    fi
done
```

</details>


---

<sub>36s</sub>

### `view`

**view the file at /home/edburns/.copilot/plugins/shepherd-task/scripts/verify-github-issue-body.sh.**

/home/edburns/.copilot/plugins/shepherd-task/scripts/verify-github-issue-body.sh (lines 1-220)

<details>
<summary>131 lines</summary>

```
#!/usr/bin/env bash
# shepherd-task-version: 1.0.4
set -euo pipefail

fail() {
    printf 'verify-github-issue-body: %s\n' "$*" >&2
    exit 1
}

[[ $# -ge 3 && $# -le 6 ]] ||
    fail "usage: $0 OWNER/REPO ISSUE_NUMBER EXPECTED_BODY_PATH [MAX_ATTEMPTS] [DELAY_SECONDS] [DIAGNOSTIC_PATH]"

repository="$1"
issue_number="$2"
expected_body_path="$3"
max_attempts="${4:-6}"
delay_seconds="${5:-5}"
diagnostic_path="${6:-}"
gh_command="${GH_COMMAND:-gh}"

[[ "$repository" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] ||
    fail "invalid repository: $repository"
[[ "$issue_number" =~ ^[1-9][0-9]*$ ]] ||
    fail "invalid issue number: $issue_number"
[[ "$max_attempts" =~ ^[1-9][0-9]*$ ]] ||
    fail "MAX_ATTEMPTS must be a positive integer"
[[ "$delay_seconds" =~ ^[0-9]+$ ]] ||
    fail "DELAY_SECONDS must be a non-negative integer"
[[ -f "$expected_body_path" ]] ||
    fail "expected issue body file not found: $expected_body_path"

temp_directory="$(mktemp -d)"
trap 'rm -rf "$temp_directory"' EXIT
response_path="$temp_directory/response.json"
actual_path="$temp_directory/actual.txt"
actual_normalized="$temp_directory/actual-normalized.txt"
expected_normalized="$temp_directory/expected-normalized.txt"

normalize_file() {
    jq -b -Rsj 'gsub("\r\n|\r"; "\n")' "$1" >"$2"
}

equivalent_files() {
    local actual="$1"
    local expected="$2"
    local candidate="$temp_directory/candidate.txt"

    cmp -s -- "$actual" "$expected" && return 0
    cp "$actual" "$candidate"
    printf '\n' >>"$candidate"
    cmp -s -- "$candidate" "$expected" && return 0
    cp "$expected" "$candidate"
    printf '\n' >>"$candidate"
    cmp -s -- "$actual" "$candidate"
}

sha256_file() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    else
        shasum -a 256 "$1" | awk '{print $1}'
    fi
}

write_diagnostic() {
    local reason="$1"
    local attempts="$2"
    [[ -n "$diagnostic_path" ]] || return 0

    mkdir -p "$(dirname "$diagnostic_path")"
    local expected_length actual_length expected_hash actual_hash first_offset
    expected_length="$(wc -c <"$expected_normalized" | tr -d ' ')"
    actual_length="$(wc -c <"$actual_normalized" | tr -d ' ')"
    expected_hash="$(sha256_file "$expected_normalized")"
    actual_hash="$(sha256_file "$actual_normalized")"
    first_offset="$( (cmp -l -- "$actual_normalized" "$expected_normalized" 2>/dev/null || true) | awk 'NR == 1 { print $1 - 1 }')"
    [[ -n "$first_offset" ]] || first_offset="null"

    jq -n \
        --arg repository "$repository" \
        --argjson issueNumber "$issue_number" \
        --arg endpoint "repos/$repository/issues/$issue_number" \
        --argjson attempts "$attempts" \
        --arg observedAt "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        --arg reason "$reason" \
        --argjson expectedLength "$expected_length" \
        --argjson actualLength "$actual_length" \
        --arg expectedSha256 "$expected_hash" \
        --arg actualSha256 "$actual_hash" \
        --argjson firstDifferenceOffset "$first_offset" \
        '{
            schemaVersion: 1,
            repository: $repository,
            issueNumber: $issueNumber,
            endpoint: $endpoint,
            attempts: $attempts,
            observedAt: $observedAt,
            reason: $reason,
            expectedLength: $expectedLength,
            actualLength: $actualLength,
            expectedSha256: $expectedSha256,
            actualSha256: $actualSha256,
            firstDifferenceOffset: $firstDifferenceOffset
        }' >"$diagnostic_path"
}

normalize_file "$expected_body_path" "$expected_normalized"
last_reason=""

for ((attempt = 1; attempt <= max_attempts; attempt++)); do
    set +e
    "$gh_command" api "repos/$repository/issues/$issue_number" >"$response_path" 2>"$temp_directory/error.txt"
    exit_code=$?
    set -e

    if [[ $exit_code -ne 0 ]]; then
        last_reason="GitHub REST request failed with exit code $exit_code."
        error_message="$(cat "$temp_directory/error.txt")"
        authentication_error_pattern='HTTP[[:space:]]+(401|403)|[Aa]uthentication|[Nn][Oo][Tt][[:space:]]authorized|[Rr]esource[[:space:]]not[[:space:]]accessible'
        if [[ "$error_message" =~ $authentication_error_pattern ]]; then
            : >"$actual_normalized"
            write_diagnostic "$last_reason" "$attempt"
            fail "unable to fetch issue #$issue_number from $repository: $error_message"
        fi
    elif ! jq -e 'type == "object" and has("body")' "$response_path" >/dev/null 2>&1; then
        last_reason="GitHub REST response was invalid JSON."
    else
        jq -b -j '.body // ""' "$response_path" >"$actual_path"
        normalize_file "$actual_path" "$actual_normalized"
        if equivalent_files "$actual_normalized" "$expected_normalized"; then
            cat "$response_path"
            exit 0
        fi
        last_reason="GitHub issue body differs from the persisted draft."
    fi

    if [[ $attempt -lt $max_attempts ]]; then
        printf 'verify-github-issue-body: %s Retrying issue #%s body verification (%s/%s).\n' \
            "$last_reason" "$issue_number" "$attempt" "$max_attempts" >&2
        ((delay_seconds > 0)) && sleep "$delay_seconds"
    fi
done

[[ -f "$actual_normalized" ]] || : >"$actual_normalized"
write_diagnostic "$last_reason" "$max_attempts"
diagnostic_suffix=""
[[ -z "$diagnostic_path" ]] || diagnostic_suffix=" Diagnostic: $diagnostic_path"
fail "issue #$issue_number body verification failed after $max_attempts attempts. $last_reason$diagnostic_suffix"
```

</details>


---

<sub>36s</sub>

### `view`

**view the file at /home/edburns/.copilot/plugins/shepherd-task/scripts/verify-stage20-child-links.sh.**

/home/edburns/.copilot/plugins/shepherd-task/scripts/verify-stage20-child-links.sh (lines 1-240)

<details>
<summary>30 lines</summary>

```
#!/usr/bin/env bash
# shepherd-task-version: 1.0.4

set -euo pipefail

if [[ $# -ne 3 ]]; then
    echo "Usage: $0 <PRE_CREATION_CHILDREN_JSON> <FINAL_CHILDREN_JSON> <CREATION_LEDGER_JSON>" >&2
    exit 2
fi

for command_name in jq; do
    command -v "$command_name" >/dev/null 2>&1 || {
        echo "Error: Required command '$command_name' was not found." >&2
        exit 1
    }
done

script_dir="$(cd "$(dirname "$0")" && pwd)"
filter_path="$script_dir/verify-stage20-child-links.jq"
[[ -f "$filter_path" ]] || {
    echo "Error: Stage-20 child-link verification filter was not found: $filter_path" >&2
    exit 1
}

for input_path in "$@"; do
    [[ -f "$input_path" ]] || {
        echo "Error: Stage-20 child-link verification input was not found: $input_path" >&2
        exit 1
    }
done

jq -n \
    --slurpfile baseline "$1" \
    --slurpfile final "$2" \
    --slurpfile ledger "$3" \
    -f "$filter_path"
```

</details>


---

<sub>1m 46s</sub>

### `apply_patch`

<details>
<summary>Arguments</summary>

```json
"*** Begin Patch\n*** Add File: 1-trick-out-01-remove-before-merge/prompts/shepherd-task-20-20260930-1717/issue-bodies/01-2-1-body.md\n+## Campaign context and required reading\n+\n+This is implementation subsection **2.1 — Establish the Open Liberty-only baseline**. This is the demo app accompanying a presentation whose abstract is in `dd-3032592-10-boring-reasons-abstract.md`.\n+\n+**On the `edburns/dd-3016202-cargotracker-devoxx-be-2026-experiment` branch, the directory `1-trick-out-01-remove-before-merge` contains the plan (`trick-out-01-ignorance-reduction-plan.md`) and supporting resources (diagrams, decision records). Spike subdirectories are research artifacts — read the plan's Resolution sections for findings, not the spike source code.**\n+\n+Before implementation, read the entire plan. Then re-read these exact sections:\n+\n+- `Baseline technology contract`\n+- `1.3 — Canonical local and CI Maven commands`\n+- `1.4 — Maven and dependency-governance rules`\n+- `1.6 — Executable Java 17 and Java EE 7 compatibility contract`\n+- `1.13 — Open Liberty lifecycle and acceptance-test boundary`\n+- `1.17 — Artifact naming, retention, and merge evidence`\n+- `2.1 — Establish the Open Liberty-only baseline`\n+- `Cross-cutting campaign gate`\n+\n+Resolved findings: Open Liberty 26.0.0.8 with `javaee-7.0` is the sole supported runtime; preserve Java 17, Java EE 7, `javax.*`, WAR packaging, and `cargo-tracker.war`. The canonical production lifecycle requires package, `liberty:deploy`, bounded `liberty:start`, HTTP readiness, and always-run `liberty:stop`; packaging alone does not deploy, and `liberty:status` exit status is not a readiness signal. The REST readiness contract is HTTP 200 JSON from `/cargo-tracker/rest/cargo` containing seeded cargo `ABC123`.\n+\n+## Branch and execution order\n+\n+Target `origin/edburns/dd-3016202-cargotracker-devoxx-be-2026-experiment`. This is task 1 of 7. Tasks are assigned, completed, reviewed, and merged serially in plan order. Do not start until assigned. No later task may begin until this task and its evidence-matrix update are merged and visible on the base branch.\n+\n+## Implement\n+\n+- Remove the Payara profile, Payara Arquillian dependency, Cargo plugin, and Payara download properties from `demo/pom.xml`.\n+- Remove the Payara container from `demo/src/test/resources/arquillian.xml`.\n+- Delete `demo/src/main/webapp/WEB-INF/glassfish-web.xml`.\n+- Remove Payara setup/testing, Java 8, and Eclipse instructions from `demo/README.md`.\n+- Rewrite GlassFish/WebLogic-specific source commentary in runtime-neutral terms.\n+- Flatten the `openliberty` profile into the main POM if this can be done while preserving the selected canonical commands and Open Liberty dependencies; Open Liberty must no longer appear to be one optional server among several.\n+- Remove remaining Payara, GlassFish, WebLogic, Cargo-plugin, WildFly, and Tomcat runtime configuration or guidance.\n+- Preserve all Java EE 7 application APIs and existing application behavior.\n+\n+Implement production changes from the findings above; do not copy research code or research-only helpers.\n+\n+## Completion gates\n+\n+- Run Spotless and a clean package from `demo/` with the repository Maven Wrapper.\n+- Prove the Open Liberty test/runtime path still passes and the canonical WAR is deployable.\n+- Exercise the production lifecycle through deploy, bounded start, the `ABC123` readiness assertion, and guaranteed stop.\n+- Search tracked build configuration, source comments, and documentation for unsupported-server guidance; only historical campaign research may retain such terms.\n+- Confirm no Jakarta migration, dependency modernization, or application behavior change occurred.\n+- Add discriminating negative checks showing unsupported-server configuration would be found.\n+- Update `1-trick-out-01-remove-before-merge/evidence-matrix.md` in this PR. Record observed events, exact commit and workflow run, job/check, artifact identity and digest, supporting file, confidence, and slide implication. Do not overwrite earlier evidence.\n+- Required CI and review feedback must be green/resolved, and the merged base branch must contain the evidence update before task 2.2 starts.\n+\n+## Out of scope\n+\n+- Jakarta EE migration, Spring adoption, dependency upgrades, or alternate-server support.\n+- Browser automation, observability, performance comparison, or later source-analysis work.\n+- Advancing the Spotless ratchet.\n+\n*** Add File: 1-trick-out-01-remove-before-merge/prompts/shepherd-task-20-20260930-1717/issue-bodies/02-2-2-body.md\n+## Campaign context and required reading\n+\n+This is implementation subsection **2.2 — Make CI authoritative and establish the Maven/dependency foundation**. This is the demo app accompanying a presentation whose abstract is in `dd-3032592-10-boring-reasons-abstract.md`.\n+\n+**On the `edburns/dd-3016202-cargotracker-devoxx-be-2026-experiment` branch, the directory `1-trick-out-01-remove-before-merge` contains the plan (`trick-out-01-ignorance-reduction-plan.md`) and supporting resources (diagrams, decision records). Spike subdirectories are research artifacts — read the plan's Resolution sections for findings, not the spike source code.**\n+\n+Read the entire plan, then re-read exactly: `1.1 — Authoritative experiment-branch CI path`, `1.2 — Required job topology and fail-fast order`, `1.3 — Canonical local and CI Maven commands`, `1.4 — Maven and dependency-governance rules`, `1.5 — Reproducibility and dependency-security evidence`, `1.8 — Spotless baseline and ratchet semantics`, `1.17 — Artifact naming, retention, and merge evidence`, `2.2 — Make CI authoritative and establish the Maven/dependency foundation`, and `Cross-cutting campaign gate`.\n+\n+Resolved findings: validate both PR synthetic merge refs and exact merged base-branch SHAs; keep workflow jobs fully serial and formatting first. Use Maven Wrapper tiers for formatting, Open-Liberty-disabled compile, focused unit tests, Open Liberty integration, and canonical packaging. Bind Maven Enforcer 3.6.3 to `validate` with Java `[17,18)`, Maven `[3.9.9,4.0.0)`, strict plugin versions, dependency convergence, duplicate-declaration rejection, direct bans for Jakarta/Spring/Payara/WildFly-JBoss/Tomcat, and no project repositories beyond Central. Pin only clean plugin 3.2.0 and resources plugin 3.3.1; exempt unused install/deploy/site defaults. Do not add upper-bound dependency enforcement. Preserve the Spotless ratchet at `1fd1c340fa56c6c77a601d2fbba20294afa46dd9`.\n+\n+## Branch and execution order\n+\n+Target `origin/edburns/dd-3016202-cargotracker-devoxx-be-2026-experiment`. This is task 2 of 7 and depends on merged task 2.1. Tasks are assigned, completed, reviewed, and merged serially. Do not start until assigned and 2.1 is visible on the base branch.\n+\n+## Implement\n+\n+- Make `.github/workflows/main.yml` automatically validate pushes to the experiment branch while retaining PR validation and stable `formatting` and `build` check names.\n+- Keep the workflow fully serial: cheap deterministic gates before expensive work.\n+- Document canonical Maven tiers in the nearest developer documentation.\n+- Add the resolved Enforcer policy to `demo/pom.xml` without broad dependency remediation.\n+- Generate effective POM, dependency tree, resolved plugin information, WAR inventory, SHA-256 checksum, and a vulnerability/dependency report. Enforce no newly introduced high-severity dependency finding rather than requiring historical debt to be empty.\n+- Add focused CI scripts under `demo/scripts/ci/` as needed for build metadata and contract verification.\n+- Upload immutable `build-contract` and `dependency-reports` artifacts with 90-day retention, `if-no-files-found: error`, and schema-1 `artifact-metadata.json`. Record upload ID, URL, digest, artifact name, and tested SHA in the job summary.\n+\n+## Completion gates\n+\n+- Baseline passes every selected Enforcer rule and produces a clean canonical WAR.\n+- Temporary invalid POM fixtures independently prove actionable failure for Java/Maven range, unversioned plugin, duplicate dependency, banned direct dependency, unauthorized repository, and artifact/checksum failure.\n+- Spotless remains first and its historical ratchet remains unchanged.\n+- Trigger and record an authoritative workflow for the exact experiment-branch commit.\n+- Required artifacts are nonempty, checksummed, and contain no caches, Maven repository, complete `target/`, runtime installation, raw environment, or secrets.\n+- Update and merge `evidence-matrix.md` with the issue/PR, tested SHA, workflow run and job, artifact URL/ID/digest, exact supporting file, observed event, confidence, and slide implication.\n+\n+## Out of scope\n+\n+- Historical vulnerability remediation, broad dependency upgrades, alternate runtimes, `requireUpperBoundDeps`, and changing the Spotless ratchet.\n+- Compatibility source scans, compiler warning cleanup, SpotBugs, behavioral, telemetry, or performance work assigned to later tasks.\n+\n*** Add File: 1-trick-out-01-remove-before-merge/prompts/shepherd-task-20-20260930-1717/issue-bodies/03-2-3-body.md\n+## Campaign context and required reading\n+\n+This is implementation subsection **2.3 — Enforce the Java 17 and Java EE 7 compatibility contract**. This is the demo app accompanying a presentation whose abstract is in `dd-3032592-10-boring-reasons-abstract.md`.\n+\n+**On the `edburns/dd-3016202-cargotracker-devoxx-be-2026-experiment` branch, the directory `1-trick-out-01-remove-before-merge` contains the plan (`trick-out-01-ignorance-reduction-plan.md`) and supporting resources (diagrams, decision records). Spike subdirectories are research artifacts — read the plan's Resolution sections for findings, not the spike source code.**\n+\n+Read the entire plan, then re-read exactly: `Baseline technology contract`, `1.4 — Maven and dependency-governance rules`, `1.6 — Executable Java 17 and Java EE 7 compatibility contract`, `1.7 — Repository-level instructions for agents`, `1.13 — Open Liberty lifecycle and acceptance-test boundary`, `1.17 — Artifact naming, retention, and merge evidence`, `2.3 — Enforce the Java 17 and Java EE 7 compatibility contract`, and `Cross-cutting campaign gate`.\n+\n+Resolved decisions: use multiple narrow checks rather than one broad tool. Enforcer owns Java and direct dependency constraints; a focused test or script owns POM/server/source assertions; deployed Open Liberty owns runtime proof. The fixed contract is compiler release 17, `javax:javaee-api:7.0` in provided scope, WAR named `cargo-tracker.war`, Open Liberty `javaee-7.0`, and context root `/cargo-tracker`. Production `jakarta.*` imports are forbidden.\n+\n+## Branch and execution order\n+\n+Target `origin/edburns/dd-3016202-cargotracker-devoxx-be-2026-experiment`. This is task 3 of 7 and depends on merged task 2.2. Work is assigned and merged serially; do not begin until assigned and the prior evidence update is visible.\n+\n+## Implement\n+\n+- Encode executable assertions for compiler release 17, Java EE 7 API coordinates/scope, WAR packaging/final name, Open Liberty feature, WAR location, and context root.\n+- Scan production source narrowly for forbidden `jakarta.*` imports.\n+- Retain the resolved direct-dependency bans and make failures name the changed boundary.\n+- Create `.github/copilot-instructions.md` with the exact `applyTo` patterns resolved in section 1.7. State Java 17, Java EE 7/`javax.*`, Maven Wrapper execution from `demo/`, WAR/Open Liberty assumptions, required green CI, no broad upgrades or server replacement, evidence-matrix timing, required Java environment bootstrap, and tee-to-log Maven discipline.\n+- Wire the compatibility report and deployed startup proof into the existing serial CI without duplicating the Open Liberty lifecycle.\n+\n+## Completion gates\n+\n+- Current application passes all contract assertions, packages, deploys, reaches the seeded REST readiness boundary, and stops cleanly.\n+- Isolated negative fixtures prove exact failures for a Jakarta import, Jakarta platform dependency, compiler release change, JAR packaging/renamed WAR, Spring or alternate-server dependency, and removal of `javaee-7.0`.\n+- Scope scans must exclude generated output, documentation, and campaign research.\n+- Upload a bounded compatibility report, compiler/release evidence, Liberty feature/deployment excerpt, and startup transcript using the artifact metadata/retention contract.\n+- Update and merge `evidence-matrix.md` with concrete observed events and durable workflow/artifact references before task 2.4 begins.\n+\n+## Out of scope\n+\n+- Migrating to Jakarta EE, Spring, another runtime, or a newer Java release.\n+- Banning tool-only dependencies without understanding their scope.\n+- Compiler warning cleanup, general static analysis, test expansion, observability, or performance comparison.\n+\n*** Add File: 1-trick-out-01-remove-before-merge/prompts/shepherd-task-20-20260930-1717/issue-bodies/04-2-4-body.md\n+## Campaign context and required reading\n+\n+This is implementation subsection **2.4 — Strengthen formatting, compiler, type, and static-analysis gates**. This is the demo app accompanying a presentation whose abstract is in `dd-3032592-10-boring-reasons-abstract.md`.\n+\n+**On the `edburns/dd-3016202-cargotracker-devoxx-be-2026-experiment` branch, the directory `1-trick-out-01-remove-before-merge` contains the plan (`trick-out-01-ignorance-reduction-plan.md`) and supporting resources (diagrams, decision records). Spike subdirectories are research artifacts — read the plan's Resolution sections for findings, not the spike source code.**\n+\n+Read the full plan and re-read exactly: `1.3 — Canonical local and CI Maven commands`, `1.8 — Spotless baseline and ratchet semantics`, `1.9 — Compiler diagnostics and type-system evidence`, `1.10 — Static analyzer and legacy-debt strategy`, `1.17 — Artifact naming, retention, and merge evidence`, `2.4 — Strengthen formatting, compiler, type, and static-analysis gates`, and `Cross-cutting campaign gate`.\n+\n+Resolved findings: retain the historical Spotless ratchet and formatting-first order. Enable `-Xlint:all -Werror`; remove two raw-type warnings and add explicit generated-compatible `serialVersionUID` values to the 12 identified serializable classes. Select SpotBugs Maven Plugin 4.10.4.1/SpotBugs 4.10.4 with `effort=Max`, `threshold=Low`, production classes, and correctness/security/multithreaded-correctness categories. Fix rather than suppress five shared `SimpleDateFormat` concurrency hazards, the permanently null booking-result field, and the unwritten cargo-route field. Exclude the noisy category families with rationale; defer PMD.\n+\n+## Branch and execution order\n+\n+Target `origin/edburns/dd-3016202-cargotracker-devoxx-be-2026-experiment`. This is task 4 of 7 and depends on merged task 2.3. Do not start until assigned. Preserve strict serial completion and evidence visibility.\n+\n+## Implement\n+\n+- Keep Spotless first and the ratchet pinned to the existing immutable SHA.\n+- Correct all 14 compiler warnings while preserving serialization identities and the existing textual date contract; do not migrate domain APIs to `java.time`.\n+- Configure compiler warnings and `-Werror`, including a path that reaches test compilation.\n+- Add the selected focused SpotBugs gate, fix all seven real findings, bind zero selected findings to `verify`, and check in a narrowly explained category filter.\n+- Keep formatting, compilation, and static-analysis steps/reports independently attributable.\n+- Add controlled fixtures for formatting drift, nonexistent/incompatible API usage, and an always-null dereference. Fixtures must not remain in production source or create a red campaign commit.\n+\n+## Completion gates\n+\n+- Baseline formatting, main/test compilation, and focused SpotBugs checks pass independently.\n+- Negative fixtures each fail through the intended mechanism with file, line, rule/category, and severity where supported.\n+- SpotBugs report contains zero selected production findings after fixes; any future suppression must be class-and-pattern-specific with rationale.\n+- Confirm source gates do not repeat the full Open Liberty acceptance lifecycle.\n+- Upload `source-gates` with compiler transcript, SpotBugs XML plus normalized report, controlled-failure transcript, metadata, and durations.\n+- Update and merge the evidence matrix with actual detections/corrections and durable evidence before behavioral-test work begins.\n+\n+## Out of scope\n+\n+- Whole-tree formatting or ratchet advancement.\n+- PMD, Error Prone, NullAway, broad analyzer exclusions, `Date` API migration, or unrelated cleanup.\n+- Behavioral test expansion, browser automation, telemetry, and performance evidence.\n+\n*** Add File: 1-trick-out-01-remove-before-merge/prompts/shepherd-task-20-20260930-1717/issue-bodies/05-2-5-body.md\n+## Campaign context and required reading\n+\n+This is implementation subsection **2.5 — Build the behavioral safety net**. This is the demo app accompanying a presentation whose abstract is in `dd-3032592-10-boring-reasons-abstract.md`.\n+\n+**On the `edburns/dd-3016202-cargotracker-devoxx-be-2026-experiment` branch, the directory `1-trick-out-01-remove-before-merge` contains the plan (`trick-out-01-ignorance-reduction-plan.md`) and supporting resources (diagrams, decision records). Spike subdirectories are research artifacts — read the plan's Resolution sections for findings, not the spike source code.**\n+\n+Read the entire plan, then re-read exactly: `1.3 — Canonical local and CI Maven commands`, `1.11 — Actual test inventory and dormant-test disposition`, `1.12 — Behavioral safety net for the later deadline feature`, `1.13 — Open Liberty lifecycle and acceptance-test boundary`, `1.17 — Artifact naming, retention, and merge evidence`, `2.5 — Build the behavioral safety net`, and `Cross-cutting campaign gate`.\n+\n+Resolved findings: the baseline runs 24 domain tests and four Arquillian `BookingService` tests, but three test-shaped classes are undiscovered and one itinerary test is empty. Green Arquillian tests use a generated test WAR and do not prove the production WAR. The stable browser-free acceptance boundary is `/cargo-tracker/rest/cargo` with `ABC123`; Administration checks can assert `/admin/dashboard.xhtml` and `/admin/show.xhtml?trackingId=ABC123`. Dates are relative, so assert relationships rather than literals. Architecture has known legacy violations and needs a documented baseline, not impossible blanket rules. Browser automation is deferred.\n+\n+## Branch and execution order\n+\n+Target `origin/edburns/dd-3016202-cargotracker-devoxx-be-2026-experiment`. This is task 5 of 7 and depends on merged task 2.4. Do not start until assigned and all prior evidence is merged.\n+\n+## Implement\n+\n+- Generate a reproducible inventory classifying active, skipped, dormant, repaired, and removed test-shaped sources.\n+- Preserve domain and Arquillian coverage. Repair dormant scenario/routing tests only when deterministic with small changes; otherwise document their disposition. Replace the empty itinerary test with real assertions or remove the false test count.\n+- Add focused facade/DTO tests for the existing arrival-deadline path without implementing Change Arrival Deadline.\n+- Add architecture checks with a narrow baseline for existing violations and prohibit new domain-to-interface/application dependencies and new web-to-domain leakage outside the accepted legacy path.\n+- Add one production-WAR acceptance lifecycle: package, deploy, bounded start, readiness and page/REST assertions, always-run stop.\n+- Keep unit, Arquillian, architecture, and acceptance results distinct.\n+\n+## Completion gates\n+\n+- Assert exact expected test counts and retain Surefire/Arquillian XML.\n+- Demonstrate concise failures for a domain invariant mutation, application-service regression, new package-layer violation, startup failure, HTTP non-200/missing content, and readiness timeout.\n+- Verify root, Administration, seeded detail, and REST contracts without browser tooling; always prove cleanup after forced smoke-test failure.\n+- Upload `test-reports-unit`, `test-reports-liberty`, and `liberty-logs` as applicable, with bounded FFDC, metadata, 90-day retention, and immutable names.\n+- Update and merge the evidence matrix with actual test/runtime observations before task 2.6 begins.\n+\n+## Out of scope\n+\n+- Implementing Change Arrival Deadline.\n+- Playwright/Selenium/browser automation, flaky retries, literal-date assertions, or claiming dormant classes as coverage.\n+- Pretending known architecture violations do not exist or introducing broad package allowlists.\n+\n*** Add File: 1-trick-out-01-remove-before-merge/prompts/shepherd-task-20-20260930-1717/issue-bodies/06-2-6-body.md\n+## Campaign context and required reading\n+\n+This is implementation subsection **2.6 — Add CI observability and diagnostic artifacts**. This is the demo app accompanying a presentation whose abstract is in `dd-3032592-10-boring-reasons-abstract.md`.\n+\n+**On the `edburns/dd-3016202-cargotracker-devoxx-be-2026-experiment` branch, the directory `1-trick-out-01-remove-before-merge` contains the plan (`trick-out-01-ignorance-reduction-plan.md`) and supporting resources (diagrams, decision records). Spike subdirectories are research artifacts — read the plan's Resolution sections for findings, not the spike source code.**\n+\n+Read the entire plan, then re-read exactly: `1.12 — Behavioral safety net for the later deadline feature`, `1.13 — Open Liberty lifecycle and acceptance-test boundary`, `1.14 — Runtime observability mechanism`, `1.17 — Artifact naming, retention, and merge evidence`, `2.5 — Build the behavioral safety net`, `2.6 — Add CI observability and diagnostic artifacts`, and `Cross-cutting campaign gate`. Also inspect the merged task 2.5 production acceptance entry points before changing them.\n+\n+Resolved decisions: attach a pinned OpenTelemetry Java agent to Java 17 Open Liberty without application API or MicroProfile migration. Run a pinned local collector; export traces and metrics to local machine-readable files; preserve Liberty logs separately. Stimulate telemetry with the proven seeded REST endpoint and fail on missing server trace, runtime metrics, collector failure, or missing correlation. Required CI must use no Azure resource, secret, or external telemetry service.\n+\n+## Branch and execution order\n+\n+Target `origin/edburns/dd-3016202-cargotracker-devoxx-be-2026-experiment`. This is task 6 of 7 and depends on merged task 2.5. Do not start until assigned and the behavioral lifecycle is stable on the base branch.\n+\n+## Implement\n+\n+- Add pinned agent and collector configuration under `demo/observability/` and document local reproduction.\n+- Layer instrumentation onto task 2.5's single bounded Liberty lifecycle; do not create another server lifecycle.\n+- Use a fixed CI request identifier to correlate request transcript, HTTP path/status, trace/span identifiers, Liberty/application logs, and collector output.\n+- Exercise one successful seeded request and one controlled invalid request.\n+- Export traces and nonempty JVM/runtime metrics in machine-readable form with deterministic sampling for the exercised requests.\n+- Add explicit artifact redaction and secret-pattern checks. Never retain request bodies, credentials, raw environment dumps, or unnecessary cargo data.\n+- Stop Liberty and the collector in always-run cleanup.\n+\n+## Completion gates\n+\n+- Collector health and Liberty readiness use bounded waits.\n+- Both requests can be traced from transcript through telemetry and relevant logs with service, operation, status, timestamp, and trace identity.\n+- Controlled failures prove explicit diagnostics for collector unavailable, incompatible instrumentation, missing telemetry, broken correlation, secret-like artifact content, and an invalid request without a diagnosable signal.\n+- Upload immutable `otel-telemetry` and applicable `liberty-logs` artifacts with schema-1 metadata, nonempty inventories, redaction result, and 90-day retention.\n+- Required CI is green and the evidence-matrix update records the exact run, SHA, job, artifact URL/ID/digest, supporting file, observed event, confidence, and slide implication.\n+\n+## Out of scope\n+\n+- Azure Monitor, Application Insights, Azure credentials/resources, MicroProfile feature migration, application API changes, or a second runtime lifecycle.\n+- Claiming OpenTelemetry log export works if only separately correlated Liberty logs are reliable.\n+- Performance comparison and JVM tuning, which belong to task 2.7.\n+\n*** Add File: 1-trick-out-01-remove-before-merge/prompts/shepherd-task-20-20260930-1717/issue-bodies/07-2-7-body.md\n+## Campaign context and required reading\n+\n+This is implementation subsection **2.7 — Add bounded JVM performance and `jaz` evidence**. This is the demo app accompanying a presentation whose abstract is in `dd-3032592-10-boring-reasons-abstract.md`.\n+\n+**On the `edburns/dd-3016202-cargotracker-devoxx-be-2026-experiment` branch, the directory `1-trick-out-01-remove-before-merge` contains the plan (`trick-out-01-ignorance-reduction-plan.md`) and supporting resources (diagrams, decision records). Spike subdirectories are research artifacts — read the plan's Resolution sections for findings, not the spike source code.**\n+\n+Read the entire plan, then re-read exactly: `1.13 — Open Liberty lifecycle and acceptance-test boundary`, `1.15 — Repeatable performance workload and resource envelope`, `1.16 — java versus jaz, GC logs, and JFR capture`, `1.17 — Artifact naming, retention, and merge evidence`, `2.6 — Add CI observability and diagnostic artifacts`, `2.7 — Add bounded JVM performance and jaz evidence`, and `Cross-cutting campaign gate`.\n+\n+Resolved findings: use one non-containerized runner, one checksummed WAR/runtime, a pristine server per launch, five warm-up requests, a dynamically started 10-second redacted JFR, and 30 sequential `ABC123`-validated requests paced 200 ms, repeated five times per mode. Compare direct Java, `JAZ_BYPASS=1`, and tuned `jaz` in alternating order. Pin `jaz` 1.0.4 amd64 to SHA-256 `3d479f11ff2a037790505746a44568e1408f2f79aac62300ea4c651c4969a710`; substitute only `bin/java` through a mirrored JDK home in Liberty `server.env`; keep Maven and `jcmd` on the real JDK and set `JAZ_EXIT_WITHOUT_FLUSH=1`. Bypass still adds diagnostics; tuned mode should show its resolved heap/G1 policy. Prior timing/resource variation was large enough that this is diagnostic evidence, not a microbenchmark or winner selection.\n+\n+## Branch and execution order\n+\n+Target `origin/edburns/dd-3016202-cargotracker-devoxx-be-2026-experiment`. This is task 7 of 7 and depends on merged task 2.6. Do not start until assigned and all preceding evidence updates are visible.\n+\n+## Implement\n+\n+- Add documented performance scripts under `demo/performance/` for the shared workload, direct launch, bypassed/tuned launcher integration, and process metadata.\n+- Build/deploy once; checksum WAR and Liberty runtime; restore a pristine server for each launch.\n+- Run five cycles ordered: direct/bypass/tuned, bypass/tuned/direct, tuned/direct/bypass, direct/tuned/bypass, bypass/direct/tuned.\n+- Record runner CPU, memory, OS, kernel, cgroup view, startup, request distribution, RSS, CPU, heap, GC, JFR, effective commands/flags, launch ancestry, exit status, duration, and cleanup.\n+- Capture tuned `JAZ_DRY_RUN=1`; reject user tuning, missing selected tuning, unexpected tuning in bypass/direct, artifact/workload mismatch, or surviving processes.\n+- Reuse task 2.6 diagnostics to explain anomalies.\n+\n+## Completion gates\n+\n+- Every mode uses identical artifacts, readiness, requests, JFR profile, diagnostics, and host envelope.\n+- Fail on startup beyond 90 seconds, request timeout/non-200/missing seed, crash/OOM, complete repetition beyond 120 seconds, provisional peak RSS above 2 GiB unless hosted evidence justifies widening, missing/unparseable diagnostics, or cleanup failure.\n+- Do not fail merely because one mode has different ordinary timing, CPU, heap, RSS, or GC measurements.\n+- Upload immutable `performance-java`, `performance-jaz-bypassed`, `performance-jaz-tuned`, and `performance-comparison` artifacts with metadata and safe bounded evidence.\n+- Complete required CI and merge the evidence-matrix update before tagging the tricked-out baseline.\n+\n+## Out of scope\n+\n+- Containers, synthetic/privileged cgroups, fixed heap/processor/GC tuning, startup JFR flags, `JAZ_IGNORE_USER_TUNING`, or changing application code to favor a launcher.\n+- Declaring a performance winner from hosted-runner noise.\n+- AKS-limit evaluation, which belongs to separate Azure deployment work.\n*** End Patch\n"
```

</details>

```
Added 7 file(s): /home/edburns/workareas/dd-3016202-cargotracker-devoxx-be-2026-02/1-trick-out-01-remove-before-merge/prompts/shepherd-task-20-20260930-1717/issue-bodies/01-2-1-body.md, /home/edburns/workareas/dd-3016202-cargotracker-devoxx-be-2026-02/1-trick-out-01-remove-before-merge/prompts/shepherd-task-20-20260930-1717/issue-bodies/02-2-2-body.md, /home/edburns/workareas/dd-3016202-cargotracker-devoxx-be-2026-02/1-trick-out-01-remove-before-merge/prompts/shepherd-task-20-20260930-1717/issue-bodies/03-2-3-body.md, /home/edburns/workareas/dd-3016202-cargotracker-devoxx-be-2026-02/1-trick-out-01-remove-before-merge/prompts/shepherd-task-20-20260930-1717/issue-bodies/04-2-4-body.md, /home/edburns/workareas/dd-3016202-cargotracker-devoxx-be-2026-02/1-trick-out-01-remove-before-merge/prompts/shepherd-task-20-20260930-1717/issue-bodies/05-2-5-body.md, /home/edburns/workareas/dd-3016202-cargotracker-devoxx-be-2026-02/1-trick-out-01-remove-before-merge/prompts/shepherd-task-20-20260930-1717/issue-bodies/06-2-6-body.md, /home/edburns/workareas/dd-3016202-cargotracker-devoxx-be-2026-02/1-trick-out-01-remove-before-merge/prompts/shepherd-task-20-20260930-1717/issue-bodies/07-2-7-body.md
```


---

<sub>1m 52s</sub>

### `apply_patch`

<details>
<summary>Arguments</summary>

```json
"*** Begin Patch\n*** Update File: 1-trick-out-01-remove-before-merge/prompts/shepherd-task-20-20260930-1717/issue-bodies/07-2-7-body.md\n@@\n-Read the entire plan, then re-read exactly: `1.13 — Open Liberty lifecycle and acceptance-test boundary`, `1.15 — Repeatable performance workload and resource envelope`, `1.16 — java versus jaz, GC logs, and JFR capture`, `1.17 — Artifact naming, retention, and merge evidence`, `2.6 — Add CI observability and diagnostic artifacts`, `2.7 — Add bounded JVM performance and jaz evidence`, and `Cross-cutting campaign gate`.\n+Read the entire plan, then re-read exactly: `1.13 — Open Liberty lifecycle and acceptance-test boundary`, `1.15 — Repeatable performance workload and resource envelope`, `1.16 — \\`java\\` versus \\`jaz\\`, GC logs, and JFR capture`, `1.17 — Artifact naming, retention, and merge evidence`, `2.6 — Add CI observability and diagnostic artifacts`, `2.7 — Add bounded JVM performance and \\`jaz\\` evidence`, and `Cross-cutting campaign gate`.\n*** End Patch\n"
```

</details>

```
Modified 1 file(s): /home/edburns/workareas/dd-3016202-cargotracker-devoxx-be-2026-02/1-trick-out-01-remove-before-merge/prompts/shepherd-task-20-20260930-1717/issue-bodies/07-2-7-body.md
```


---

<sub>1m 56s</sub>

### Copilot

The seven persisted drafts now contain the required structure, exact task scope, resolved constraints, serial prerequisites, discriminating gates, and evidence obligations. I’m running the mandatory draft validator and initializing the authoritative ledger/result and pre-creation snapshot before creating anything.

---

<sub>2m 1s</sub>

### `bash`

**Validate drafts and initialize stage**

$ set -euo pipefail
LOG='/home/edburns/workareas/dd-3016202-cargotracker-devoxx-be-2026-02/1-trick-out-01-remove-before-merge/prompts/shepherd-task-20-20260930-1717'
VALIDATOR='/home/edburns/.copilot/plugins/shepherd-task/scripts/validate-stage20-drafts.sh'
"$VALIDATOR" "$LOG/issue-bodies" 7 off
for path in "$LOG/creation-ledger.json" "$LOG/stage-20-result.json" "$LOG/pre-creation-children.json" "$LOG/final-children.json"; do
  if [[ -e "$path" ]]; then printf 'Refusing to overwrite existing stage artifact: %s\n' "$path" >&2; exit 1; fi
done
atomic_write() {
  local path="$1" content="$2" temp
  temp="$(mktemp "${path}.tmp.XXXXXX")"
  printf '%s\n' "$content" >"$temp"
  mv "$temp" "$path"
}
atomic_write "$LOG/creation-ledger.json" '[]'
atomic_write "$LOG/stage-20-result.json" '{"schemaVersion":1,"status":"in_progress","ledgerFile":"creation-ledger.json","operationError":null}'
gh api 'repos/edburns/dd-3016202-cargotracker-devoxx-be-2026/issues/1/sub_issues' --paginate | jq -s '[.[][] | {id,number,node_id,title,html_url}]' >"$LOG/pre-creation-children.json.tmp"
mv "$LOG/pre-creation-children.json.tmp" "$LOG/pre-creation-children.json"
printf 'Draft validation passed; initialized ledger and baseline with %s existing children.\n' "$(jq length "$LOG/pre-creation-children.json")"

```
Draft validation passed; initialized ledger and baseline with 0 existing children.
<shellId: 5 completed with exit code 0>
```


---

<sub>2m 10s</sub>

### Copilot

Draft validation passed with zero pre-existing children. I’m now creating, exact-body-verifying, and linking each issue one at a time in plan order, persisting the ledger after every state transition.

---

<sub>2m 36s</sub>

### `bash`

**Create verify and link issues**

$ set -Eeuo pipefail
REPO='edburns/dd-3016202-cargotracker-devoxx-be-2026'
PARENT=1
LOG='/home/edburns/workareas/dd-3016202-cargotracker-devoxx-be-2026-02/1-trick-out-01-remove-before-merge/prompts/shepherd-task-20-20260930-1717'
LEDGER="$LOG/creation-ledger.json"
RESULT="$LOG/stage-20-result.json"
VERIFY='/home/edburns/.copilot/plugins/shepherd-task/scripts/verify-github-issue-body.sh'
current_op='starting issue creation'
atomic_write() {
  local path="$1" content="$2" temp
  temp="$(mktemp "${path}.tmp.XXXXXX")"
  printf '%s\n' "$content" >"$temp"
  mv "$temp" "$path"
}
update_ledger_flag() {
  local number="$1" field="$2" value="$3" updated
  updated="$(
    jq \
      --argjson number "$number" \
      --arg field "$field" \
      --argjson value "$value" \
      'map(if .number == $number then .[$field] = $value else . end)' \
      "$LEDGER"
  )" || return 1
  atomic_write "$LEDGER" "$updated"
}
fail_stage() {
  local exit_code=$?
  trap - ERR
  set +e
  local reconcile="$LOG/failure-reconciled-children.json" children_status linked_json failed_json
  gh api "repos/$REPO/issues/$PARENT/sub_issues" --paginate | jq -s '[.[][] | {id,number,node_id,title,html_url}]' >"$reconcile"
  children_status=${PIPESTATUS[0]}
  if [[ $children_status -eq 0 ]]; then
    linked_json="$(jq --slurpfile children "$reconcile" 'map(. as $entry | .linked = any($children[0][]; .id == $entry.id))' "$LEDGER")"
    atomic_write "$LEDGER" "$linked_json"
  fi
  failed_json="$(jq -n --arg error "$current_op failed with exit code $exit_code" '{schemaVersion:1,status:"failed",ledgerFile:"creation-ledger.json",operationError:$error}')"
  atomic_write "$RESULT" "$failed_json"
  printf 'STAGE20_FAILURE: %s failed with exit code %s\n' "$current_op" "$exit_code" >&2
  jq . "$LEDGER" >&2
  exit "$exit_code"
}
trap fail_stage ERR

titles=(
  '2.1 — Establish the Open Liberty-only baseline'
  '2.2 — Make CI authoritative and establish the Maven/dependency foundation'
  '2.3 — Enforce the Java 17 and Java EE 7 compatibility contract'
  '2.4 — Strengthen formatting, compiler, type, and static-analysis gates'
  '2.5 — Build the behavioral safety net'
  '2.6 — Add CI observability and diagnostic artifacts'
  '2.7 — Add bounded JVM performance and jaz evidence'
)
subsections=('2.1' '2.2' '2.3' '2.4' '2.5' '2.6' '2.7')
body_files=("$LOG"/issue-bodies/*-body.md)

for index in "${!body_files[@]}"; do
  body_file="${body_files[$index]}"
  title="${titles[$index]}"
  subsection="${subsections[$index]}"
  current_op="creating subsection $subsection"
  issue_json="$(gh api "repos/$REPO/issues" -X POST -f title="$title" -F "body=@$body_file")"
  id="$(jq -er '.id' <<<"$issue_json")"
  number="$(jq -er '.number' <<<"$issue_json")"
  url="$(jq -er '.html_url' <<<"$issue_json")"
  relative_body="${body_file#"$LOG/"}"
  updated="$(jq \
    --arg subsection "$subsection" \
    --arg bodyFile "$relative_body" \
    --argjson id "$id" \
    --argjson number "$number" \
    --arg title "$title" \
    --arg url "$url" \
    '. + [{implementationSubsection:$subsection,bodyFile:$bodyFile,id:$id,number:$number,title:$title,url:$url,body_verified:false,linked:false}]' \
    "$LEDGER")"
  atomic_write "$LEDGER" "$updated"

  current_op="verifying body for issue #$number"
  "$VERIFY" "$REPO" "$number" "$body_file" 6 5 "$LOG/issue-$number-body-verification-failure.json" >/dev/null
  update_ledger_flag "$number" body_verified true

  current_op="linking issue #$number to parent #$PARENT"
  linked=false
  for attempt in 1 2 3; do
    if printf '{"sub_issue_id": %s}' "$id" | gh api "repos/$REPO/issues/$PARENT/sub_issues" -X POST --input - >/dev/null; then
      linked=true
      break
    fi
    [[ $attempt -eq 3 ]] || sleep 2
  done
  [[ "$linked" == true ]]
  update_ledger_flag "$number" linked true
  printf 'Created and linked #%s: %s\n' "$number" "$title"
done
trap - ERR
jq . "$LEDGER"

<details>
<summary>80 lines</summary>

```
Created and linked #2: 2.1 — Establish the Open Liberty-only baseline
Created and linked #3: 2.2 — Make CI authoritative and establish the Maven/dependency foundation
Created and linked #4: 2.3 — Enforce the Java 17 and Java EE 7 compatibility contract
Created and linked #5: 2.4 — Strengthen formatting, compiler, type, and static-analysis gates
Created and linked #6: 2.5 — Build the behavioral safety net
Created and linked #7: 2.6 — Add CI observability and diagnostic artifacts
Created and linked #8: 2.7 — Add bounded JVM performance and jaz evidence
[
  {
    "implementationSubsection": "2.1",
    "bodyFile": "issue-bodies/01-2-1-body.md",
    "id": 5650333337,
    "number": 2,
    "title": "2.1 — Establish the Open Liberty-only baseline",
    "url": "https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/issues/2",
    "body_verified": true,
    "linked": true
  },
  {
    "implementationSubsection": "2.2",
    "bodyFile": "issue-bodies/02-2-2-body.md",
    "id": 5650333784,
    "number": 3,
    "title": "2.2 — Make CI authoritative and establish the Maven/dependency foundation",
    "url": "https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/issues/3",
    "body_verified": true,
    "linked": true
  },
  {
    "implementationSubsection": "2.3",
    "bodyFile": "issue-bodies/03-2-3-body.md",
    "id": 5650334291,
    "number": 4,
    "title": "2.3 — Enforce the Java 17 and Java EE 7 compatibility contract",
    "url": "https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/issues/4",
    "body_verified": true,
    "linked": true
  },
  {
    "implementationSubsection": "2.4",
    "bodyFile": "issue-bodies/04-2-4-body.md",
    "id": 5650334782,
    "number": 5,
    "title": "2.4 — Strengthen formatting, compiler, type, and static-analysis gates",
    "url": "https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/issues/5",
    "body_verified": true,
    "linked": true
  },
  {
    "implementationSubsection": "2.5",
    "bodyFile": "issue-bodies/05-2-5-body.md",
    "id": 5650335266,
    "number": 6,
    "title": "2.5 — Build the behavioral safety net",
    "url": "https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/issues/6",
    "body_verified": true,
    "linked": true
  },
  {
    "implementationSubsection": "2.6",
    "bodyFile": "issue-bodies/06-2-6-body.md",
    "id": 5650335705,
    "number": 7,
    "title": "2.6 — Add CI observability and diagnostic artifacts",
    "url": "https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/issues/7",
    "body_verified": true,
    "linked": true
  },
  {
    "implementationSubsection": "2.7",
    "bodyFile": "issue-bodies/07-2-7-body.md",
    "id": 5650336184,
    "number": 8,
    "title": "2.7 — Add bounded JVM performance and jaz evidence",
    "url": "https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/issues/8",
    "body_verified": true,
    "linked": true
  }
]
<shellId: 6 completed with exit code 0>
```

</details>


---

<sub>2m 40s</sub>

### Copilot

All seven issues were created, body-verified, and linked in order. I’m performing the authoritative child-order/count check plus final body, open-state, and unassigned postconditions before marking the stage complete.

---

<sub>2m 54s</sub>

### `bash`

**Verify final issue postconditions**

$ set -Eeuo pipefail
REPO='edburns/dd-3016202-cargotracker-devoxx-be-2026'
PARENT=1
LOG='/home/edburns/workareas/dd-3016202-cargotracker-devoxx-be-2026-02/1-trick-out-01-remove-before-merge/prompts/shepherd-task-20-20260930-1717'
LEDGER="$LOG/creation-ledger.json"
RESULT="$LOG/stage-20-result.json"
VERIFY='/home/edburns/.copilot/plugins/shepherd-task/scripts/verify-github-issue-body.sh'
LINK_VERIFY='/home/edburns/.copilot/plugins/shepherd-task/scripts/verify-stage20-child-links.sh'
current_op='capturing final child snapshot'
atomic_write() {
  local path="$1" content="$2" temp
  temp="$(mktemp "${path}.tmp.XXXXXX")"
  printf '%s\n' "$content" >"$temp"
  mv "$temp" "$path"
}
fail_stage() {
  local exit_code=$?
  trap - ERR
  set +e
  local reconcile="$LOG/failure-reconciled-children.json" linked_json failed_json
  gh api "repos/$REPO/issues/$PARENT/sub_issues" --paginate | jq -s '[.[][] | {id,number,node_id,title,html_url}]' >"$reconcile"
  if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
    linked_json="$(jq --slurpfile children "$reconcile" 'map(. as $entry | .linked = any($children[0][]; .id == $entry.id))' "$LEDGER")"
    atomic_write "$LEDGER" "$linked_json"
  fi
  failed_json="$(jq -n --arg error "$current_op failed with exit code $exit_code" '{schemaVersion:1,status:"failed",ledgerFile:"creation-ledger.json",operationError:$error}')"
  atomic_write "$RESULT" "$failed_json"
  printf 'STAGE20_FAILURE: %s failed with exit code %s\n' "$current_op" "$exit_code" >&2
  jq . "$LEDGER" >&2
  exit "$exit_code"
}
trap fail_stage ERR

gh api "repos/$REPO/issues/$PARENT/sub_issues" --paginate | jq -s '[.[][] | {id,number,node_id,title,html_url}]' >"$LOG/final-children.json.tmp"
mv "$LOG/final-children.json.tmp" "$LOG/final-children.json"
current_op='authoritative child-link verification'
"$LINK_VERIFY" "$LOG/pre-creation-children.json" "$LOG/final-children.json" "$LEDGER"

while IFS=$'\t' read -r number body_rel; do
  current_op="final body verification for issue #$number"
  "$VERIFY" "$REPO" "$number" "$LOG/$body_rel" 6 5 "$LOG/issue-$number-final-body-verification-failure.json" >/dev/null
  current_op="open and unassigned verification for issue #$number"
  issue_json="$(gh api "repos/$REPO/issues/$number")"
  jq -e '.state == "open" and (.assignees | length) == 0' <<<"$issue_json" >/dev/null
done < <(jq -r '.[] | [.number,.bodyFile] | @tsv' "$LEDGER")

complete='{"schemaVersion":1,"status":"complete","ledgerFile":"creation-ledger.json","operationError":null}'
atomic_write "$RESULT" "$complete"
trap - ERR
printf 'Postconditions passed for %s new children; stage status is %s.\n' "$(jq length "$LEDGER")" "$(jq -r .status "$RESULT")"

<details>
<summary>16 lines</summary>

```
{
  "baselineCount": 0,
  "ledgerCount": 7,
  "finalCount": 7,
  "newIssueIds": [
    5650333337,
    5650333784,
    5650334291,
    5650334782,
    5650335266,
    5650335705,
    5650336184
  ]
}
Postconditions passed for 7 new children; stage status is complete.
<shellId: 7 completed with exit code 0>
```

</details>


---

<sub>2m 58s</sub>

### Copilot

Created and verified seven ordered child issues under #1. All are open, unassigned, linked exactly once in plan order, and created **without an issue type**.

| Subsection | Issue | Title |
|---|---:|---|
| 2.1 | [#2](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/issues/2) | Establish the Open Liberty-only baseline |
| 2.2 | [#3](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/issues/3) | Make CI authoritative and establish the Maven/dependency foundation |
| 2.3 | [#4](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/issues/4) | Enforce the Java 17 and Java EE 7 compatibility contract |
| 2.4 | [#5](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/issues/5) | Strengthen formatting, compiler, type, and static-analysis gates |
| 2.5 | [#6](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/issues/6) | Build the behavioral safety net |
| 2.6 | [#7](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/issues/7) | Add CI observability and diagnostic artifacts |
| 2.7 | [#8](https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/issues/8) | Add bounded JVM performance and jaz evidence |

**Ordered issue numbers for `shepherd-task-25-given-list`:** `2,3,4,5,6,7,8`

**Suggested next invocation:** invoke `shepherd-task-25-given-list` for campaign `474aebe4-23f7-45cf-a841-e214bdcdd132`, repository `edburns/dd-3016202-cargotracker-devoxx-be-2026`, plan directory `1-trick-out-01-remove-before-merge`, and ordered issues `2,3,4,5,6,7,8`. Stage 25 should derive lesson propagation from the campaign manifest.

---

<sub>Generated by [GitHub Copilot CLI](https://github.com/features/copilot/cli)</sub>
