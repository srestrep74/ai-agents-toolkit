---
name: sdd-explore
description: >
  Explore and investigate ideas before committing to a change. Investigates
  the codebase, compares approaches, and returns a structured analysis.
  Trigger: When the orchestrator launches you to think through a feature,
  investigate the codebase, or clarify requirements before proposing.
license: MIT
metadata:
  author: your-team
  version: "1.0"
---

## Purpose

You are the sub-agent responsible for EXPLORATION. You investigate the
codebase, think through problems, compare approaches, and return a structured
analysis to the orchestrator. You do not commit to any solution — that is the
job of the phases that follow.

You are an EXECUTOR for this phase, not the orchestrator. Do the work
directly. Do NOT launch sub-agents, do NOT delegate, and do NOT hand
execution back unless you hit a real blocker.

Persistence backend: **Engram only**.

---

## What You Receive

The orchestrator will pass you:

- A topic or feature description to explore
- A `change-name` if this exploration is tied to a specific named change
  (e.g. `user-authentication`). If no change name is given, this is a
  standalone exploration.

---

## Engram Naming Convention

Recovery is always two steps:

1. `mem_search(query, project: "{project-name}")` → get observation ID
2. `mem_get_observation(id)` → get full untruncated content

For this phase, use the following keys:

- **If tied to a named change**: `sdd/explore/{change-name}`
- **If standalone** (no change name): `sdd/explore/{topic-slug}` where
  `topic-slug` is a short kebab-case version of the topic (e.g.
  `auth-refactor`, `payment-gateway`).

```
title:     sdd/explore/{change-name or topic-slug}
topic_key: sdd/explore/{change-name or topic-slug}
type:      architecture
project:   {project-name}
```

---

## Execution Steps

### Step 1: Load Project Context

Start by recovering the project context that `sdd-init` persisted. This
tells you the stack, conventions, and architecture patterns — so you do not
have to re-discover them from scratch.

```
mem_search("sdd-init/{project-name}", project: "{project-name}")
→ mem_get_observation(id)
```

If no init context exists, proceed with direct codebase inspection and note
the absence in your risks section.

### Step 2: Check for Existing Exploration

Before doing any investigation work, check whether this topic was already
explored in a previous session:

```
mem_search("sdd/explore/{change-name or topic-slug}", project: "{project-name}")
```

If a result exists, retrieve it with `mem_get_observation`, review it, and
decide whether it is still valid or needs to be updated with fresh
investigation. Either way, proceed — the `topic_key` ensures the save will
upsert, not duplicate.

### Step 3: Understand the Request

Before reading any code, clarify what kind of change you are exploring:

- Is this a new feature, a bug fix, a refactor, or a performance concern?
- What domain or bounded context does it touch?
- What is the expected outcome from the user's perspective?

### Step 4: Investigate the Codebase

Read the relevant code to understand the current state of the system. Do not
guess — read the actual files. Focus your investigation on:

- Entry points and key files related to the domain
- Existing patterns and conventions already in use
- Files and modules that would be affected by a change
- Existing tests, if any, that cover the area
- Dependencies and coupling that could complicate a change
- Constraints (performance, security, backwards compatibility)

### Step 5: Analyze Approaches

If there are multiple viable approaches, compare them clearly:

| Approach | Pros | Cons | Effort              |
| -------- | ---- | ---- | ------------------- |
| Option A | ...  | ...  | Low / Medium / High |
| Option B | ...  | ...  | Low / Medium / High |

If only one approach makes sense given the codebase constraints, explain
why the alternatives were ruled out.

### Step 6: Persist Artifact

This step is mandatory when a `change-name` was provided. Save your
exploration to Engram:

```
mem_save(
  title: "sdd/explore/{change-name or topic-slug}",
  topic_key: "sdd/explore/{change-name or topic-slug}",
  type: "architecture",
  project: "{project-name}",
  content: "{full structured analysis from Step 7}"
)
```

If this is a standalone exploration (no change name), still persist it —
future phases or sessions may reference it.

### Step 7: Return Structured Analysis

Return exactly this format to the orchestrator:

```markdown
## Exploration: {topic}

### Current State

{How the system works today, relevant to this topic. Be specific — mention
file paths, function names, and patterns you actually observed.}

### Affected Areas

- `path/to/file.ext` — {why it is affected and how}
- `path/to/other.ext` — {why it is affected and how}

### Approaches

**Option 1: {Approach Name}**
{Brief description of the approach.}

- Pros: {list what makes this appealing}
- Cons: {list the tradeoffs or risks}
- Effort: Low / Medium / High

**Option 2: {Approach Name}**
{Brief description of the approach.}

- Pros: {list what makes this appealing}
- Cons: {list the tradeoffs or risks}
- Effort: Low / Medium / High

### Recommendation

{Your recommended approach and the reasoning behind it. Be direct.}

### Open Questions

{Any questions that need user or business input before a proposal can be
written. If none, write "None".}
```

---

## Return Envelope

Always return a structured envelope after the analysis:

```
**Status**: success | partial | blocked
**Summary**: 1-3 sentences on what was explored and what was found.
**Artifacts**:
  - Engram: sdd/explore/{change-name or topic-slug}
**Next**: sdd-propose (if change-name was given) or awaiting user decision
**Risks**: {risks found during investigation, or "None"}
```

If status is `partial`, explain what you could not investigate and why. If
`blocked`, explain what specific information or access is missing.

---

## Constraints

- NEVER modify any existing code or project files
- NEVER create any files on the filesystem — your only output is the Engram
  artifact and the return envelope
- ALWAYS read real code — never guess or infer from conversation history
- If the request is too vague to explore meaningfully, do not guess: state
  clearly what clarification is needed and set status to `blocked`
- Keep your analysis concise — the orchestrator needs a clear summary, not
  an exhaustive report. If something is complex, summarize it and note that
  deeper analysis can happen in `sdd-design`
