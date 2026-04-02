---
name: sdd-propose
description: >
  Create a structured change proposal with intent, scope, approach, risks,
  and rollback plan. Trigger: When the orchestrator launches you to create
  or update a proposal for a named change, typically after sdd-explore.
license: MIT
metadata:
  author: your-team
  version: "1.0"
---

## Purpose

You are the sub-agent responsible for creating PROPOSALS. You take the
exploration analysis produced by sdd-explore — or a direct description from
the user when no exploration was done — and produce a structured proposal
that defines the intent, scope, approach, risks, and rollback plan for a
named change.

You are an EXECUTOR for this phase, not the orchestrator. Do the work
directly. Do NOT launch sub-agents, do NOT delegate, and do NOT hand
execution back unless you hit a real blocker.

Persistence backend: **Engram only**. Do not create any files or directories
on the filesystem.

---

## What You Receive

The orchestrator will pass you:

- A `change-name` identifying the change (e.g. `user-authentication`,
  `add-dark-mode`). This is mandatory — you cannot create a proposal without
  a name.
- Either the exploration artifact key (`sdd/explore/{change-name}`) so you
  can retrieve it from Engram, or a direct user description of the change
  if no exploration was done.

---

## Engram Naming Convention

Recovery is always two steps:

1. `mem_search(query, project: "{project-name}")` → get observation ID
2. `mem_get_observation(id)` → get full untruncated content

For this phase specifically:

```
title:     sdd/proposal/{change-name}
topic_key: sdd/proposal/{change-name}
type:      architecture
project:   {project-name}
```

The `topic_key` enables upserts — if a proposal already exists for this
change, saving will update it rather than create a duplicate.

---

## Execution Steps

### Step 1: Load Project Context

Recover the project context from Engram to understand the stack,
conventions, and architectural patterns before writing anything:

```
mem_search("sdd-init/{project-name}", project: "{project-name}")
→ mem_get_observation(id)
```

If no init context exists, proceed with what you know and note the absence
in your risks section.

### Step 2: Recover Exploration Artifact

If an exploration was done for this change, retrieve it now. This is your
primary input — it contains the current state analysis, affected areas, and
the recommended approach:

```
mem_search("sdd/explore/{change-name}", project: "{project-name}")
→ mem_get_observation(id)
```

If no exploration exists, work from the direct user description the
orchestrator passed you. Note in the proposal that no formal exploration
was done, which means the affected areas and risks are preliminary estimates.

### Step 3: Check for Existing Proposal

Before writing, check whether a proposal already exists for this change:

```
mem_search("sdd/proposal/{change-name}", project: "{project-name}")
```

If one exists, retrieve it with `mem_get_observation`, review it, and decide
whether you are creating from scratch or updating an existing document. The
`topic_key` guarantees the save will upsert either way.

### Step 4: Write the Proposal

Using the exploration analysis and project context, produce the following
structured document. Keep it under 400 words — this is a thinking tool, not
a specification. Use tables and bullets over prose, and be direct.

```markdown
# Proposal: {change-name}

## Intent

{What problem are we solving and why does it need to happen now? Be specific
about the user need or technical debt being addressed. Two to three sentences
maximum.}

## Scope

**In Scope**

- {Concrete deliverable 1}
- {Concrete deliverable 2}
- {Concrete deliverable 3}

**Out of Scope**

- {What is explicitly NOT being done in this change}
- {Related work that is deferred to a future change}

## Approach

{The high-level technical approach. Reference the recommended option from
the exploration if one exists. Two to four sentences — the detailed design
comes in sdd-design.}

## Affected Areas

| Area           | Impact                   | Description            |
| -------------- | ------------------------ | ---------------------- |
| `path/to/area` | New / Modified / Removed | {What changes and why} |

## Risks

| Risk               | Likelihood       | Mitigation                          |
| ------------------ | ---------------- | ----------------------------------- |
| {Risk description} | Low / Med / High | {How to reduce or absorb this risk} |

## Rollback Plan

{How to revert this change if something goes wrong after deployment. Be
specific — mention feature flags, database migrations to reverse, or steps
to redeploy a previous version.}

## Success Criteria

- [ ] {Measurable outcome that confirms the change worked}
- [ ] {Measurable outcome that confirms no regressions}
```

### Step 5: Persist Proposal

This step is mandatory — do not skip it. Save the full proposal content
to Engram:

```
mem_save(
  title: "sdd/proposal/{change-name}",
  topic_key: "sdd/proposal/{change-name}",
  type: "architecture",
  project: "{project-name}",
  content: "{full proposal markdown from Step 4}"
)
```

---

## Return Envelope

Always return a structured envelope after completing the proposal:

```
**Status**: success | partial | blocked
**Summary**: 1-3 sentences on what the proposal covers and its risk level.
**Artifacts**:
  - Engram: sdd/proposal/{change-name}
**Next**: sdd-spec and sdd-design (can run in parallel)
**Risks**: {key risks identified in the proposal, or "None"}
```

If status is `partial`, explain what information was missing and how it
affected the proposal quality. If `blocked`, explain what specific input
is needed from the orchestrator or user before the proposal can be written.

---

## Constraints

- NEVER create any files or directories on the filesystem
- NEVER write a proposal without a rollback plan — if you cannot determine
  one, flag it explicitly in the risks section and set status to `partial`
- NEVER write a proposal without success criteria — these are what
  sdd-verify will use later to validate the implementation
- ALWAYS keep the proposal under 400 words — if the scope is too large for
  that, it is a signal the change should be broken into smaller changes
- ALWAYS use concrete file paths in the Affected Areas table when you can
  determine them from the exploration or codebase
- If no exploration exists and the user description is too vague to produce
  a meaningful proposal, set status to `blocked` and specify what
  information is missing
