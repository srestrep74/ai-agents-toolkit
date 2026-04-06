# Installation & Setup 🛠️

The SDD framework is designed to be "zero-touch". The installers handle agent deployment, environment setup, and tool configuration automatically.

## 📋 Prerequisites

- **Python 3.x**: Required for skill execution (e.g., AWS/ECS comparisons).
- **PowerShell** (Windows) or **Bash** (Mac/Linux).
- **GitHub Copilot CLI** or **Cursor IDE**.

## 🚀 Installation

Run the installer from the root of this repository, specifying your target tool:

### Windows (PowerShell)
```powershell
# For Cursor IDE
.\scripts\install.ps1 -Target cursor

# For GitHub Copilot CLI
.\scripts\install.ps1 -Target copilot
```

### Linux / macOS (Bash)
```bash
# For Cursor IDE
./scripts/install.sh cursor

# For GitHub Copilot CLI
./scripts/install.sh copilot
```

## 🛠️ What the Installer Does

1.  **Agent Deployment**: Assembles the core agent logic with tool-specific headers and copies them to `.cursor/` or `.github/`.
2.  **Skill Bank Sync**: Deploys all functional skills to the target directory.
3.  **Python Automation**:
    - Creates a `.venv` inside the `.github/` directory.
    - Installs dependencies from `src/skills/pyproject.toml` (e.g., `boto3`).
4.  **Engram Installation**: Checks for the Engram binary; if missing, it downloads and installs the latest version from GitHub.
5.  **MCP Auto-Configuration**: Generates `mcp.json` (Cursor) or a global `mcp-config.json` (Copilot) with dynamic user paths.

## ✅ Validation

To ensure everything is working correctly:

1.  **Check MCP Servers**: 
    - In **Cursor**: Go to *Settings > MCP* and verify `engram` and `azure-devops` are active.
    - In **Copilot**: Run `copilot --version` and check your config.
2.  **Verify Venv**: Check that a `.venv` folder exists in your `.github/` directory.
3.  **Test an Agent**: 
    - Mention `@sdd-init` or `@sdd-orchestrator` in your tool.
    - If it responds with the SDD protocol, you are ready to go!

---
[← Back to README](../README.md) | [Architecture →](architecture.md)
