---
name: azure-devops-pr-reviewer
description: "Comprehensive review of Azure DevOps Pull Requests against linked Work Items and coding excellence standards. Trigger: When the user asks to review, analyze, or audit a PR or User Story implementation."
---

<!-- skill-metadata
author: genai-skills-kit
version: "2.0"
scope: root
auto_invoke:
  - "Reviewing Azure DevOps pull requests"
  - "Validating code against acceptance criteria"
  - "Auditing PR functional compliance"
  - "Checking for technical debt in PRs"
-->

## Skill Metadata

| Field | Value |
|-------|-------|
| Author | genai-skills-kit |
| Version | 2.0 |
| MCP Required | `azure-devops` |
| Primary Focus | Functional Compliance & Code Quality |

## Auto-Invoke Triggers

- "Review PR <id> from <project>"
- "Does this PR meet the acceptance criteria of the story?"
- "Analyze code changes in pull request <id>"
- "Check if PR <id> is ready for merge"

---

## Prerequisite: The Autonomous Clone Strategy
To ensure **any reviewer** can audit a PR from **any repository** regardless of their current VS Code workspace, this skill relies on an **Isolated Git Strategy**:
1. **The Management Brain (Azure DevOps MCP)**: Used strictly to fetch business rules, Acceptance Criteria, PR status, and team discussions.
2. **The Code Brain (Isolated Local Git)**: The actual code review is performed by locally fetching the diff using `git`.

**CRITICAL**: If the user's current terminal/workspace does not match the PR's repository, the agent MUST clone the repository into a temporary directory (e.g., `C:\tmp\pr-review-<id>`) to generate the diff, and then delete the folder afterwards.

---

## When to Use
- Validating a developer's changes fulfill the complete intent of the User Story (Work Item) from any local workspace.
- Identifying functional gaps between the isolated code diff and the **Full Description**, technical notes, and Acceptance Criteria.
- Enforcing best practices, performance optimizations, and bug detection in new code.

---

## Critical Rules

- **Language**: ALWAYS respond in English. NO emojis. Professional, technical tone.
- **Independence**: Perform the review regardless of the PR state (ACTIVE, COMPLETED, or ABANDONED).
- **Independent Analysis (Blind Review)**: The agent MUST perform its own code review BEFORE reading PR threads or comments. Findings must be categorized as "Independent" (found by AI) or "Correlated" (discussed by humans).
- **Mandatory Code Access**: If the agent cannot retrieve code content via `search_code`, it MUST NOT proceed with a review. Inferring findings from commit messages or comments is strictly FORBIDDEN.
- **Evidence-Based**: Every observation in the report MUST include a reference to a specific file and, if possible, a line range.
- **Narrative Over Checkbox**: Prioritize the "Functional Mission" (from the Description) over the Acceptance Criteria. If the code works but violates the spirit of the Story, it requires changes.
- **Performance & Security**: Always check for common pitfalls (unoptimized queries, hardcoded secrets, missing validations) even if not explicitly mentioned in the US.
- **Comparative Analysis**: ALWAYS compare the source branch (PR) against the target branch (usually `dev` or `main`) to identify actual changes.
- **No Fabrications**: Only report issues found in the actual diff.
- **Completeness**: If a Work Item has multiple acceptance criteria, verify EVERY one of them individually.

---

## Decision Tree

```
User requests a PR review?
├── Resolve Project and Repository IDs
│   └── Tool: repo_get_repo_by_name_or_id
├── Fetch Pull Request Data
│   └── Tool: repo_get_pull_request_by_id
├── Identify Linked Work Items
│   ├── Found? → Fetch Details & Comments
│   │   └── Tools: wit_get_work_item, wit_list_work_item_comments
│   └── Not Found? → Proceed with Code-Only Review (Note missing WI)
├── Functional Mapping (Via Azure MCP)
│   ├── READ Full Description (System.Description)
│   ├── Extract Acceptance Criteria (AC)
│   └── **Synthesize Functional Mission**: Define the "Core Logic" to be validated.
├── Code Review (Via Isolated Git Diff)
│   ├── Check current local repository against PR repository.
│   ├── Matches? → run `git fetch` and `git diff` locally.
│   ├── Different? → Clone repo to temp folder, run diff, and delete folder.
│   └── **Primary Audit**: Evaluate the EXACT `git diff` output against the Functional Mission.
├── Thread/Comment Correlation (Via Azure MCP)
│   └── Read `repo_list_pull_request_threads` to see if existing discussions missed anything or if findings were already addressed.
└── Final Report Generation
    └── Output structured findings to console
```

---

## Execution Instructions (MCP Tools)

### 1. Context Retrieval & Mission Synthesis (Azure MCP)
- Call `repo_get_pull_request_by_id`. 
  - **CRITICAL STATUS MAPPING**: In Azure DevOps, State `1` = ACTIVE, `2` = ABANDONED, `3` = COMPLETED.
- Call `wit_get_work_item`. Read the entire `System.Description`.
- Extract `Microsoft.VSTS.Common.AcceptanceCriteria`.
- Read `wit_list_work_item_comments` to detect "in-flight" requirement changes.
- **Synthesize**: State clearly what the code is *supposed* to achieve before evaluating the files.

### 2. Code Review (Source of Truth: Isolated Git Diff)
- **CRITICAL**: Do NOT use the `search_code` MCP tool to find PR changes. The MCP does not download code.
- You **MUST** use local terminal commands to generate the diff.
- **Execution Steps**:
  1. Determine the PR repository URL (format: `https://copavsts.visualstudio.com/<project>/_git/<repository>`).
  2. If your current working directory is NOT the target repository:
     - Run `git clone --bare https://copavsts.visualstudio.com/<project>/_git/<repository> C:\tmp\pr-review-<id>` (or use `\AppData\Local\Temp`).
     - Change directory to the temp folder.
  3. Run `git fetch origin <targetBranch>` and `git fetch origin <sourceBranch>`.
  4. Generate the diff: `git diff origin/<targetBranch>...origin/<sourceBranch>`.
  5. Analyze the diff output directly. This represents the EXACT additions and deletions.
  6. If you used a temp folder, **delete it** after the review logic is complete.

### 3. Reporting Rules
- Evaluate the implementation against the **Story Mission** and the `git diff`.
- If the Description mentions a specific edge case that isn't in the AC, and the code misses it, it is a **BLOCKER**.

---

## Expected Output Format

### PR Review: #{pr_id} - {title}

**Target Branch**: `{target}` | **Source Branch**: `{source}`
**Work Item**: #{wi_id} - {wi_title}
**Verdict**: {VERDICT}

#### Functional Mission
{A 2-3 sentence synthesis of the goal described in the Work Item Description. This demonstrates the agent understands the 'why' and the 'how' before the 'what'.}

#### Functional Alignment
| Requirement Source | Status | Observation & Evidence |
|--------------------|--------|------------------------|
| **Story Description** | ✅ Aligned / ❌ Gaps | {Analysis of core logic. **Cite specific files/lines** as evidence.} |
| **Acceptance Criteria** | ✅ Met / ❌ Missing | {Verification of AC flags. **Cite specific files/lines**.} |

#### Agent Findings & Code Proposals (Independent Audit)
*The following issues were identified through independent code analysis BEFORE reviewing existing PR threads.*

| Category | File:Line | Finding | Proposal |
|----------|-----------|---------|----------|
| {BUG/OPT} | `{file}:{L}` | {Unique finding by the agent} | See Code Block Below |

{For each NEW finding above, provide a specific code proposal}

#### Team Discussion Review (Azure Threads Correlation)
*Verification of issues already discussed by the human team.*

| Discussion | Status | AI Assessment |
|------------|--------|---------------|
| {Topic}    | {Resolved/Open} | {Does the AI agree with the resolution? Is the fix complete in the code?} |
| BUG      | `{file}` | {Description} | {Fix} |
| OPTIMIZE | `{file}` | {Description} | {Improvement} |
| STYLE    | `{file}` | {Description} | {Standard} |

#### Summary
{Concise summary of why the PR is approved or requires changes.}