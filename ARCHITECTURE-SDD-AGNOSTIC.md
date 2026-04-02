# Agnostic SDD Framework: Architecture & Setup

This document defines how to structure the SDD framework as a standalone repository that can be "installed" into different AI agents (Copilot CLI vs. Cursor).

---

## 📂 Repository Structure (Source)

```text
sdd-framework/
├── src/
│   ├── orchestrator/
│   │   └── base-orchestrator.md      # Core routing logic
│   └── agents/
│       ├── init.md                   # Core init prompts
│       ├── explore.md                # Core exploration prompts
│       ├── propose.md                # Core proposal prompts
│       ├── spec.md                   # Core spec prompts
│       ├── design.md                 # Core design prompts
│       ├── tasks.md                  # Core task prompts
│       ├── apply.md                  # Core implementation prompts
│       └── verify.md                 # Core verification prompts
├── templates/
│   ├── copilot/                      # Copilot YAML headers (name + description)
│   │   └── [agent].yml
│   └── cursor/                       # Cursor YAML headers (name + description + model + readonly)
│       └── [agent].yml
└── scripts/
    ├── install.sh                    # Linux/Mac Installer
    └── install.ps1                   # Windows Installer
```

---

## 🛠️ Agent-Specific Mappings

### 1. GitHub Copilot CLI

| Item | Location |
| :--- | :--- |
| **Orchestrator** | `.github/AGENTS.md` |
| **Sub-agents** | `.github/agents/sdd-[name].agent.md` |
| **YAML Schema** | `name`, `description` |

```yaml
---
name: sdd-explore
description: Deep Trace of the entire functional flow...
---
```

### 2. Cursor (Native Subagents)

> [!IMPORTANT]
> Cursor sub-agents go in **`.cursor/agents/`**, NOT `.cursor/rules/`. The `/rules/` folder is for passive, always-on style rules (like linting conventions). **Subagents** require `.cursor/agents/` to run with isolated context and full autonomy.

| Item | Location |
| :--- | :--- |
| **Orchestrator** | `.cursor/rules/sdd-orchestrator.md` |
| **Sub-agents** | `.cursor/agents/sdd-[name].md` |
| **YAML Schema** | `name`, `description`, `model`, `readonly` |

```yaml
---
name: sdd-explore
description: "Use when the user runs /sdd-explore. Always use for deep tracing..."
model: inherit
readonly: true
---
```

Key Cursor-specific YAML fields:

| Field | Options | Usage in SDD |
| :--- | :--- | :--- |
| `model` | `inherit`, `fast`, or model ID | `fast` for `tasks`; `inherit` for all others |
| `readonly` | `true` / `false` | `true` for all phases except `init` and `apply` |
| `is_background` | `true` / `false` | Can be `true` for parallel `spec` + `design` |

---

## ⚡ How Cursor Auto-Delegation Works

When the Orchestrator runs, it reads the `description` of all files in `.cursor/agents/`. If the description contains trigger phrases like *"Use when the user runs /sdd-explore"*, Cursor will **automatically invoke** that sub-agent without manual intervention.

The sub-agent runs with an **empty, isolated context window** — it receives only what the parent passes in. When done, it returns its result to the Orchestrator automatically.

---

## ⚡ Installation Logic

Run the script to deploy the full agent suite to your project.

**Windows:**
```powershell
.\scripts\install.ps1 -Target copilot   # Or: -Target cursor
```

**Linux/Mac:**
```bash
./scripts/install.sh copilot            # Or: cursor
```

The script:
1. Prepends the tool-specific YAML header to each `src/agents/*.md` source file.
2. Copies the assembled file to the correct target directory.
3. Copies the orchestrator to its tool-specific entry point.

---

## ✅ Benefits of the Agnostic Approach

1.  **Single Source of Truth**: Improve a prompt in `src/agents/` once — run the installer to propagate everywhere.
2.  **Portability**: Same framework on the terminal (Copilot CLI) and in the IDE (Cursor).
3.  **Real Subagent Isolation**: In Cursor, each SDD phase runs with its own context window via the native `.cursor/agents/` mechanism.
4.  **Modularity**: Add support for new tools (Windsurf, Trae, etc.) by adding a new template folder.
