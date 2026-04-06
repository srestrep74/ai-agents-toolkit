# 🧠 Developer's Guide: Creating & Managing Skills

This guide explains how to extend the SDD Framework by adding new specialized **Skills**. A Skill is a set of instructions, scripts, and resources that give the AI specific capabilities (e.g., "Review a PR", "Compare AWS Environments", "Create Scala endpoint", etc).

---

## 📁 Directory Structure

Skills are organized into self-contained folders. 

### Core Framework Skills
Located in `src/skills/`. Use these for shared, team-wide capabilities.
```text
src/skills/
├── my-new-skill/
│   ├── SKILL.md          # Main instruction file (Required)
│   ├── scripts/          # Python/Shell scripts
│   └── resources/        # Templates, JSON schemas, etc.
└── pyproject.toml        # Shared Python dependencies
```

### Project-Specific Skills (Local)
Located in your project's root `skills/`, `.cursor/skills/`, or `.github/skills/`.
```text
{project-root}/
└── skills/
    └── project-logic/
        └── SKILL.md
```

---

## 📝 The `SKILL.md` Format

Every skill **must** have a `SKILL.md` file with specific frontmatter.

```markdown
---
name: my-new-skill
description: "Brief summary of what it does. Trigger: When user says 'run my skill' or 'do X'."
---

## Purpose
Detailed explanation of what this skill achieves.

## Critical Rules
- Rule 1: Always do X.
- Rule 2: Never do Y.

## Execution Steps
1. ...
2. ...
```

> [!IMPORTANT]
> **The TRIGGER is critical.** The `description` field in the frontmatter must contain a `Trigger: ...` phrase. Our **Skill Resolver Protocol** uses this to automatically inject the correct compact rules into sub-agents.

---

## 🐍 Managing Dependencies (Python)

To keep the installation fast and clean, all core skills share a single Python virtual environment managed in `src/skills/pyproject.toml`.

1. **Add your dependency**: Add the library to `src/skills/pyproject.toml`.
2. **Re-install**: Run `.\scripts\install.ps1 -Target cursor` to update the `.venv`.
3. **Use it in scripts**: Your scripts in `my-skill/scripts/*.py` can now import that library.

---

## 🤖 Core Agent Templates

The `templates/` directory is **NOT** for skills. It contains the "blueprints" for the nine SDD sub-agents.

- **`templates/cursor/`**: `.md` files used for Cursor (Rules/Agents).
- **`templates/copilot/`**: `.yml` files used for GitHub Copilot Agents.

If you want to change the **global behavior** of an agent (e.g., add a mandatory step to `sdd-spec`), modify the corresponding template. The installer will then propagate these changes to the final `.cursor/agents/` or `.copilot/agents/` directories.

---

## 🔄 Skill Registry & Resolver

The framework uses a **Skill Registry** (`.atl/skill-registry.md`) to avoid reading every `SKILL.md` file at runtime (which would waste the context window).

- **Registry Build**: Done once during `sdd-init` or by calling the `skill-registry` skill.
- **Resolver**: When you launch a sub-agent (e.g., `@sdd-spec`), the Orchestrator checks the registry for matching triggers and injects **Compact Rules** (5-15 line summaries) directly into the agent's prompt.

### Tips for Better Skills:
1. **Be Concise**: Instruct the AI on *how* to do it, not *why*.
2. **Use Rules**: "Always use X", "Never use Y".
3. **Handle Errors**: Define what to do if a script fails.
