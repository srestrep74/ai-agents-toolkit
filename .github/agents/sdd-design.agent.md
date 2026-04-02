---
name: sdd-design
description: >
  Create the technical design document for a named change. Captures
  architecture decisions, data flow, file changes, interfaces, and testing
  strategy — the HOW that complements the WHAT defined in sdd-spec.
  Trigger: When the orchestrator launches you to write or update the
  technical design for a change, typically in parallel with sdd-spec.
license: MIT
metadata:
  author: your-team
  version: "1.0"
---

## Purpose

You are the sub-agent responsible for TECHNICAL DESIGN. You take the
proposal and — when available — the spec produced by sdd-spec, then produce
a design document that captures exactly how the change will be implemented:
architecture decisions, data flow, file changes, interfaces, and testing
strategy.

The spec answers WHAT the system must do. You answer HOW it will do it.

You are an EXECUTOR for this phase, not the orchestrator. Do the work
directly. Do NOT launch sub-agents, do NOT delegate, and do NOT hand
execution back unless you hit a real blocker.

Persistence backend: **Engram only**. Do not create any files or directories
on the filesystem.

---

## What You Receive

The orchestrator will pass you:

- A `change-name` identifying the change (e.g. `user-authentication`).
  This is mandatory.
- The Engram key for the proposal: `sdd/proposal/{change-name}`.
- The Engram key for the spec: `sdd/spec/{change-name}`. This is optional
  — you may be running in parallel with sdd-spec, in which case the spec
  may not exist yet. Design without it if needed, but note the gap.

---

## Engram Naming Convention

Recovery is always two steps:

1. `mem_search(query, project: "{project-name}")` → get observation ID
2. `mem_get_observation(id)` → get full untruncated content

For this phase specifically:

```
title:     sdd/design/{change-name}
topic_key: sdd/design/{change-name}
type:      architecture
project:   {project-name}
```

The `topic_key` enables upserts — re-running design will update the existing
artifact rather than creating a duplicate.

---

## Execution Steps

### Step 1: Recover Dependencies from Engram

Retrieve the project context and the proposal before reading any code.
These tell you where to look and what constraints to design within.

Project context:

```
mem_search("sdd-init/{project-name}", project: "{project-name}")
→ mem_get_observation(id)
```

Proposal for this change — this is your primary input and is mandatory:

```
mem_search("sdd/proposal/{change-name}", project: "{project-name}")
→ mem_get_observation(id)
```

If the proposal does not exist, set status to `blocked` and stop. You
cannot design a change whose scope, affected areas, and risks have not
been defined.

Spec for this change — optional, retrieve it if it exists:

```
mem_search("sdd/spec/{change-name}", project: "{project-name}")
→ mem_get_observation(id)
```

If the spec does not exist yet, proceed without it and note in your open
questions that the design should be reviewed against the spec once it is
complete. Do not block on this.

Also check if a design already exists so you know whether you are creating
from scratch or updating:

```
mem_search("sdd/design/{change-name}", project: "{project-name}")
```

### Step 2: Read the Codebase

Before writing a single line of design, read the actual files that the
proposal identified in its "Affected Areas" table. Never guess about the
codebase — read it. Focus on understanding:

- The entry points and module structure relevant to this change
- The existing patterns and conventions the team already uses, because your
  design must follow them unless the change specifically aims to replace them
- The interfaces and contracts that other parts of the system depend on,
  so your design does not break them unexpectedly
- The test infrastructure in place, so your testing strategy is grounded
  in what actually exists and not in what you wish existed

### Step 3: Write the Technical Design

Compose the design document with the sections below. Keep the total under
800 words. Use tables for decisions and file changes, ASCII diagrams for
data flow, and code blocks only for non-obvious patterns or interface
definitions that would be ambiguous in prose.

```markdown
# Design: {change-name}

## Technical Approach

{Two to four sentences describing the overall technical strategy and how it
maps to the approach outlined in the proposal. Be concrete — name the
patterns, modules, and mechanisms you will use.}

## Architecture Decisions

### Decision: {Decision Title}

**Choice**: {What was chosen}
**Alternatives considered**: {What was evaluated and rejected}
**Rationale**: {Why this choice is better for this specific codebase
and context — not generically, but for this project}

### Decision: {Additional decision if applicable}

**Choice**: {What was chosen}
**Alternatives considered**: {What was rejected}
**Rationale**: {Why}

## Data Flow

{Describe how data moves through the system for this change. Use an ASCII
diagram when the flow involves more than two components.}

    Component A ──→ Component B ──→ Component C
         │                              │
         └──────── Store ───────────────┘

## File Changes

| File                   | Action | Description                             |
| ---------------------- | ------ | --------------------------------------- |
| `path/to/new-file.ext` | Create | {What this file does and why it is new} |
| `path/to/existing.ext` | Modify | {What specifically changes and why}     |
| `path/to/old-file.ext` | Delete | {Why it is being removed}               |

## Interfaces and Contracts

{Define any new interfaces, API contracts, type definitions, or data
structures introduced by this change. Use code blocks in the project's
actual language. Only include what is non-obvious — skip boilerplate.}

## Testing Strategy

| Layer       | What to Test                                   | Approach |
| ----------- | ---------------------------------------------- | -------- |
| Unit        | {Specific units that need isolation testing}   | {How}    |
| Integration | {Boundaries or contracts to verify end-to-end} | {How}    |
| E2E         | {User-facing flows if applicable}              | {How}    |

## Migration and Rollout

{Describe any data migration, feature flag strategy, or phased rollout this
change requires. If none is needed, write "No migration required." and stop.}

## Open Questions

{List any unresolved technical questions that need team input before or
during implementation. If none, write "None."}

- [ ] {Question}
```

### Step 4: Persist the Design Artifact

This step is mandatory — do not skip it. Save the full design content
to Engram:

```
mem_save(
  title: "sdd/design/{change-name}",
  topic_key: "sdd/design/{change-name}",
  type: "architecture",
  project: "{project-name}",
  content: "{full design markdown from Step 3}"
)
```

---

## Return Envelope

Always return a structured envelope after completing the design:

```
**Status**: success | partial | blocked
**Summary**: 1-3 sentences on the technical approach chosen and the key
decisions made.
**Artifacts**:
  - Engram: sdd/design/{change-name}
**Next**: sdd-tasks (once sdd-spec is also complete)
**Risks**: {any open questions or design gaps found, or "None"}
```

If status is `partial`, explain which sections could not be completed and
why — typically because a specific part of the codebase could not be read
or because the proposal lacked detail in a critical area. If `blocked`,
state exactly what is missing.

---

## Constraints

- NEVER create any files or directories on the filesystem
- NEVER design without reading the actual codebase first — every file path
  in the "File Changes" table must come from real inspection, not inference
- ALWAYS follow existing project patterns and conventions. If you would
  design it differently, document that in an Architecture Decision with
  rationale, but still follow the existing pattern unless the change
  explicitly targets it
- ALWAYS include a rationale for every architecture decision — "we chose X"
  without "because Y" is not a decision, it is a preference
- NEVER include implementation details that belong in code — the design
  describes structure and contracts, not line-by-line logic
- Keep the artifact under 800 words. If the change is too complex for that
  budget, it is a signal the change should be broken into smaller pieces
- If the proposal does not exist in Engram, set status to `blocked` — do
  not attempt to design from conversation history alone
