---
name: ado-reader
description: "Advanced data extraction skill. Instructs agents on how to navigate the Azure DevOps MCP, query nested references, and strip HTML to produce pristine Markdown."
---

# 🤖 ADO Reader Skill

The `ado-reader` is a specialized skill optimally designed for GitHub Copilot. It provides strict guidelines on how to operate the `@azure-devops/mcp` tools efficiently, as the Azure DevOps API structures can be complex and often return deeply nested or dirty HTML data.

## 🌟 Architecture & Design

This skill enforces a **3-Phase Extraction Pattern** to ensure the agent gathers the complete context of an Azure DevOps Work Item, preventing information loss from implicit relationships (comments and child tasks).

## 🚀 How It Works (The Workflow)

To build a complete ticket context, you must execute the following sequence:

### Phase 1: Core Details (`workitems_get_work_item` or similar)
Invoke the tool to fetch the primary Work Item details. 
*Note: If the user provides `US-4821`, pass only the numeric ID `4821` to the tool.*
**Key extractions**:
- `System.Title`, `System.State`, `System.WorkItemType`
- `System.IterationPath`, `System.AssignedTo`, `Microsoft.VSTS.Scheduling.StoryPoints`
- `System.Description` & `Microsoft.VSTS.Common.AcceptanceCriteria` (Treat these as dirty HTML)

### Phase 2: Hierarchy & Task Discovery (`workitems_get_links` or via `relations`)
Check the response from Phase 1 for an array named `relations` (or use a dedicated link tool). 
- Look for `rel`: `System.LinkTypes.Hierarchy-Forward`. These represent child tasks.
- If child IDs are found in the relations, invoke the tool again to fetch the titles of those specific internal Tasks to populate the `## Tasks / Child Items` checklist.

### Phase 3: Business Context via Comments (`workitems_get_comments`)
Discussions are critical for uncovering implicit requirements. 
- Call the appropriate tool to fetch comments associated with the ID.
- Ignore automated bot comments or state-change logs if possible.
- Extract the author, date, and comment text (Treat this as dirty HTML).

---

## 📋 The "Pristine Markdown" Standard (CRITICAL)

Azure DevOps returns rich text fields (Description, Acceptance Criteria, Comments) as messy HTML injected by its WYSIWYG editor.

**STRICT RULE**: NEVER save HTML in the final artifact.
- Transform `<div>...</div>` to plain text.
- Transform `<br>` to `\n` line breaks.
- Transform `<ul><li>` structures to Markdown lists (`- `).
- Remove inline styles, font tags, span tags, and colors entirely.

If HTML is not aggressively cleaned up, subsequent agents (`sdd-explore`, `sdd-requirements`) will suffer from context pollution and hallucinate.

---

## 📚 Examples Reference

To ensure strict compliance with the output format, you must study the reference files located in the `examples/` directory of this skill. 

- **[ticket-us4821.md](examples/ticket-us4821.md)**: The "Happy Path". A standard User Story with clear Acceptance Criteria, Tasks, and Comments.
- **[ticket-bug1024-missing-data.md](examples/ticket-bug1024-missing-data.md)**: Edge case handling. Shows how gracefully handle missing fields (e.g., no ACs, no story points) without breaking the Markdown structure.
- **[ticket-epic900-complex.md](examples/ticket-epic900-complex.md)**: Complex hierarchy. Demonstrates handling of dense descriptions and a long sequence of team discussions.
- **[ticket-us840049-observability.md](examples/ticket-us840049-observability.md)**: Real-world messy ticket. Shows how to extract the core value, mappings, and ACs from a ticket filled with boilerplate headers, JSON payloads, and dirty HTML artifacts.

Always strive to match the brevity and structural integrity of these examples.

## 🛠️ Requirements
- `azure-devops` MCP server configured, enabled, and connected.
- GitHub Copilot CLI or IDE extension.
