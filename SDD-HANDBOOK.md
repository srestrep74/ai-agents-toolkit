# SDD Framework: Handbook 🚀

This handbook describes how to use the Spec-Driven Development (SDD) framework. It is built for engineers who value architectural depth, testability, and autonomous execution.

---

## 🏛️ Fundamental Principles

1.  **Orchestrator as Router, Agents as Doers**: The orchestrator (`AGENTS.md`) is your air traffic controller. It doesn't read code; it launches specialized sub-agents who do.
2.  **Engram as the Shared Brain**: All knowledge (proposals, specs, designs) is persisted in the Engram MCP. If an agent "forgets" something, it re-reads it from the database.
3.  **Human as the Director**: You approve every phase. The agents propose; you dispose.
4.  **Layered Investigation**: Exploration must move from **API** → **Domain** → **Infrastructure**. No shallow fixes.
5.  **Traceability**: Every line of code must map 1:1 to a Requirement, which must map 1:1 to the **User Story (US)**.

---

## 🗺️ The SDD Lifecycle

### Phase 0: Initialization
Establish the project context in Engram once per repository.
- **Command**: `sdd-init` (in Chat/Plan mode)
- **Outcome**: Engram has a `sdd-init/{project}` memory with stack, conventions, and patterns.

### Phase 1: Deep Exploration & Proposal (`sdd-new`)
Define *what* you want to change and *why*. This is the **Technical Heart** of the SDD lifecycle.
- **Command**: `sdd-new <change-name> @US.md`
- **What happens**:
  1. `sdd-explore` performs a **Deep Trace** of the entire functional flow:
     - **API**: Perimeter validations and DTOs.
     - **Domain**: Business rules, Commands, and Query logic affected by the US.
     - **Infrastructure**: Protocols (REST/SOAP) and Persistence impact.
  2. `sdd-propose` generates a technical intent with a **Requirement Traceability Matrix**.
- **Human Review**: Inspect the proposal. Use `/sdd-show proposal <change-name>` to see the full markdown. Do not approve until the agent demonstrates it understands the *entire* impact path.

### Phase 2: Spec & Design (`sdd-ff` or `sdd-continue`)
Define *what* the system must do and *how* to build it.
- **Commands**: `sdd-spec` and `sdd-design` (often run in parallel with `/sdd-ff`).
- **What happens**:
  - `sdd-spec`: Writes Given/When/Then scenarios (Gherkin-style).
  - `sdd-design`: Maps the specific file changes and data structures.
- **Mode**: Use **Plan/Ask** mode.

### Phase 3: Task Breakdown (`sdd-tasks`)
Convert design into a granular implementation checklist.
- **Command**: `sdd-tasks <change-name>`
- **Outcome**: A phase-by-phase list (e.g., Phase 1: Core Fix, Phase 2: Configuration, Phase 3: Tests).

### Phase 4: Implementation (`sdd-apply`)
Autonomous code writing.
- **Command**: `sdd-apply <change-name>`
- **Mode**: **AGENT / AUTOPILOT**. Switch to the most powerful mode here.
- **Action**: The agent executes tasks, writes files, and runs unit tests.

### Phase 5: Verification (`sdd-verify`)
The Quality Gate.
- **Tools**: `sdd-verify`.
- **Action**: Deep static analysis against the spec compliance matrix.

---

## 🚀 Agnostic Deployment (Copilot vs. Cursor)

This framework is **tool-agnostic**. You can install it on either GitHub Copilot CLI or Cursor (or both) from the same source.

### 1. Installation

To install or sync the agents in your current project, run the installer from the framework directory:

#### **On Windows (PowerShell):**
```powershell
# For Copilot CLI
.\scripts\install.ps1 -Target copilot

# For Cursor
.\scripts\install.ps1 -Target cursor
```

#### **On Linux/Mac (Bash):**
```bash
# For Copilot CLI
./scripts/install.sh copilot

# For Cursor
./scripts/install.sh cursor
```

### 2. Usage Flow

| Agent | How to use in Copilot CLI | How to use in Cursor |
| :--- | :--- | :--- |
| **Orchestrator** | Acts as the entry point via `.github/AGENTS.md`. | Acts as global instructions via `.cursorrules`. |
| **Sub-agents** | Launched via `@sdd-[name]` in terminal extension. | Referenced via `@sdd-[name]` in Chat or Composer. |
| **Independence** | Agents run in isolated CLI sub-processes. | Agents run in isolated Chat/Composer sessions with fresh context. |

---

## 🧭 Helper Commands

| Command | Action |
| :--- | :--- |
| `/sdd-show <type>` | Prints the full Markdown of an artifact (e.g. `proposal`, `spec`). |
| `/sdd-continue` | Automatically triggers the next logical phase in the DAG. |
| `/sdd-explore <topic>` | Standalone exploration for "what-if" scenarios (no artifact persistence). |

---

## 💡 Best Practices

- **The US is the Manifesto**: Always provide the User Story as context in Step 1. The agents are instructed to treat it as the ultimate truth.
- **Feedback Loops**: If a proposal is wrong, don't ignore it. Give feedback: *"Re-propose without changing the SOAP schema"*.
- **Model Tiers**:
  - **Plan/Explore/Propose**: Use **Claude 3.5 Sonnet / Gemini 1.5 Pro**.
  - **Apply/Verify**: Use **Claude 3.5 Sonnet** (for reasoning) or **Haiku** (for simple bulk tasks).
- **Persistence**: If you close Copilot CLI, the data remains in `engram.db`. You can "continue" a change days later.

---
*Created by Antigravity — Professional SDD Agent Framework*
