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
│   ├── copilot/                      # Metadata for Copilot
│   │   ├── [agent].yml
│   └── cursor/                       # Metadata for Cursor
│       ├── [agent].yml
└── scripts/
    ├── install.sh                    # Linux/Mac Installer
    └── install.ps1                   # Windows Installer
```

---

## 🛠️ Agent Specific Mappings

### 1. GitHub Copilot CLI (Extension)
- **Installation Path**: `.github/agents/`
- **Orchestrator Path**: `.github/AGENTS.md`
- **File Format**: `sdd-[name].agent.md`
- **Metadata Required**:
  ```yaml
  ---
  name: sdd-[name]
  description: ...
  ---
  ```

### 2. Cursor (Native Rules)
- **Installation Path**: `.cursor/rules/`
- **Orchestrator Path**: `.cursorrules`
- **File Format**: `sdd-[name].md`
- **Metadata Required**:
  ```yaml
  ---
  description: ...
  globs: **/*
  ---
  ```

---

## ⚡ Installation Logic (`install.sh` / `install.ps1`)

The script is responsible for injecting the agent-specific headers. The flow is as follows:

1.  **Target Selection**: User specifies `copilot` or `cursor`.
2.  **File Processing**:
    - **For Copilot**: Iterates through `src/agents/*.md`, prepends the Copilot YAML header, renames to `sdd-[name].agent.md`, and copies it to `.github/agents/`.
    - **For Cursor**: Iterates through `src/agents/*.md`, prepends the Cursor YAML header (including `globs`), renames to `sdd-[name].md`, and copies it to `.cursor/rules/`.
3.  **Orchestrator Setup**:
    - Copies `base-orchestrator.md` to the appropriate destination (`.github/AGENTS.md` or `.cursorrules`).

---

## ✅ Benefits of the Agnostic Approach

1.  **Single Source of Truth**: If you improve a prompt in any phase, you only change it in `src/agents/` once.
2.  **Portability**: Use the same framework in the terminal (Copilot CLI) for fast workflows and in the IDE (Cursor) for intensive coding sessions.
3.  **Modularity**: Makes it easy to add support for new agents (like Windsurf or Trae) simply by adding a new metadata template.
