# SDD Agentic Framework 🚀

**Spec-Driven Development (SDD)** is a professional engineering framework designed to transform AI Coding Agents (like Cursor and GitHub Copilot) from simple chat assistants into autonomous software engineers.

## 🌟 The Vision

Most AI interactions are reactive: "fix this bug" or "add this field". SDD flips the script by enforcing a disciplined architectural lifecycle:
**Think** → **Propose** → **Specify** → **Design** → **Plan** → **Implement** → **Verify**.

By using this framework, you ensure that every line of code is traceable to a requirement, and every requirement is validated against a technical specification.

## 🏗️ Framework Highlights

- **Tool-Agnostic**: One source of truth for prompts, deployed natively to **Cursor** and **GitHub Copilot CLI**.
- **Engram Integration**: Uses a persistent memory layer (MCP) to ensure agents never "forget" project context or design decisions.
- **Micro-Agents**: Specialized sub-agents (Explore, Spec, Design, etc.) with isolated context windows for maximum reasoning power.
- **Zero-Touch Setup**: Automated installers for Windows, Mac, and Linux.

## 📚 Documentation

- [**Installation Guide**](docs/installation.md): How to set up the framework, Python environment, and Engram MCP.
- [**Architecture & Sub-Agents**](docs/architecture.md): Deep dive into the SDD methodology and the role of each agent.
- [**User Workflow**](docs/workflow.md): How to start a change, coordinate the lifecycle, and interact with the orchestrator.

## 🛠️ Quick Start

To enable SDD in your current project:

```powershell
# Windows
.\scripts\install.ps1 -Target cursor  # or 'copilot'
```

```bash
# Linux / macOS
./scripts/install.sh cursor           # or 'copilot'
```

---
*Developed by the SDD Core Team*
