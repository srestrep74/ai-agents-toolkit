#!/bin/bash
# SDD Framework Agnostic Installer (Bash)
# Usage: ./install.sh [copilot|cursor]

TARGET=$1

if [ "$TARGET" != "copilot" ] && [ "$TARGET" != "cursor" ]; then
    echo "Usage: ./install.sh [copilot|cursor]"
    exit 1
fi

echo "Installing SDD Framework for $TARGET..."

AGENTS=("init" "explore" "propose" "spec" "design" "tasks" "apply" "verify")

# --- 1. Framework Components ---
if [ "$TARGET" == "copilot" ]; then
    COPILOT_DIR=".copilot"
    mkdir -p "$COPILOT_DIR/agents"
    # Orchestrator
    cp src/orchestrator/base-orchestrator.md .copilot-instructions.md
    # Agents
    for agent in "${AGENTS[@]}"; do
        { cat "templates/copilot/$agent.yml"; echo; cat "src/agents/$agent.md"; } > "$COPILOT_DIR/agents/sdd-$agent.agent.md"
    done
    # Skills
    if [ -d "src/skills" ]; then
        mkdir -p "$COPILOT_DIR/skills"
        cp -r src/skills/* "$COPILOT_DIR/skills/"
    fi
else
    # Cursor
    mkdir -p .cursor/agents
    mkdir -p .cursor/rules
    # Clean up stale agent files
    find .cursor/rules -name 'sdd-*.md' -delete 2>/dev/null
    find .cursor/rules -name 'sdd-*.mdc' ! -name 'sdd-orchestrator.mdc' -delete 2>/dev/null
    # Orchestrator
    cp src/orchestrator/base-orchestrator.md .cursor/rules/sdd-orchestrator.mdc
    # Subagents
    for agent in "${AGENTS[@]}"; do
        { cat "templates/cursor/$agent.yml"; echo; cat "src/agents/$agent.md"; } > ".cursor/agents/sdd-$agent.md"
    done
    # Skills
    if [ -d "src/skills" ]; then
        mkdir -p .cursor/skills
        cp -r src/skills/* .cursor/skills/
    fi
fi

# --- 2. Python venv setup for skills ---
SKILLS_DIR="src/skills"
if [ -f "$SKILLS_DIR/pyproject.toml" ]; then
    VENV_DIR=".copilot/.venv"
    mkdir -p ".copilot"
    if [ ! -d "$VENV_DIR" ]; then
        echo ""
        echo "📦 Creating Python venv for skills..."
        python3 -m venv "$VENV_DIR"
    fi
    echo "📦 Installing skill dependencies..."
    source "$VENV_DIR/bin/activate"
    pip install -q --upgrade pip
    pip install -q -e "$SKILLS_DIR"
    echo "  → Python venv ready at: $VENV_DIR/"
fi

# --- 3. Engram Installation ---
echo ""
echo "--- Ensuring Engram is installed ---"
ENGRAM_BIN_DIR="$HOME/.local/bin"
ENGRAM_DATA_DIR="$HOME/.local/share/engram"
mkdir -p "$ENGRAM_BIN_DIR"
mkdir -p "$ENGRAM_DATA_DIR"

if ! command -v engram &> /dev/null && [ ! -f "$ENGRAM_BIN_DIR/engram" ]; then
    echo "Engram not found. Downloading latest release..."
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)
    if [ "$ARCH" == "x86_64" ]; then ARCH="amd64"; fi
    if [ "$ARCH" == "aarch64" ] || [ "$ARCH" == "arm64" ]; then ARCH="arm64"; fi
    
    REPO="Gentleman-Programming/engram"
    LATEST_RELEASE=$(curl -s https://api.github.com/repos/$REPO/releases/latest)
    DOWNLOAD_URL=$(echo "$LATEST_RELEASE" | grep "browser_download_url" | grep "$OS" | grep "$ARCH" | grep "tar.gz" | head -n 1 | cut -d '"' -f 4)
    
    if [ -n "$DOWNLOAD_URL" ]; then
        echo "Downloading $DOWNLOAD_URL..."
        curl -L "$DOWNLOAD_URL" -o engram.tar.gz
        tar -xzf engram.tar.gz -C "$ENGRAM_BIN_DIR"
        rm engram.tar.gz
        chmod +x "$ENGRAM_BIN_DIR/engram"
        echo "Engram installed at $ENGRAM_BIN_DIR/engram"
    else
        echo "Warning: Could not find a compatible Engram binary for $OS-$ARCH."
    fi
else
    echo "Engram is already installed."
fi

# --- 4. MCP Configuration Automation ---
echo ""
echo "--- Configuring MCP Servers ---"

ENGRAM_PATH="engram"
if [ -f "$ENGRAM_BIN_DIR/engram" ]; then ENGRAM_PATH="$ENGRAM_BIN_DIR/engram"; fi

# Simple JSON generation (without requiring jq)
MCP_JSON=$(cat <<EOF
{
  "mcpServers": {
    "engram": {
      "command": "$ENGRAM_PATH",
      "args": ["mcp", "--tools=all"],
      "env": {
        "ENGRAM_DATA_DIR": "$ENGRAM_DATA_DIR"
      }
    },
    "azure-devops": {
      "command": "npx",
      "args": ["-y", "@azure-devops/mcp", "copavsts"]
    }
  }
}
EOF
)

if [ "$TARGET" == "cursor" ]; then
    mkdir -p .cursor
    echo "$MCP_JSON" > .cursor/mcp.json
    echo "  → Cursor MCP configured in: .cursor/mcp.json"
else
    GLOBAL_COPILOT_DIR="$HOME/.copilot"
    mkdir -p "$GLOBAL_COPILOT_DIR"
    echo "$MCP_JSON" > "$GLOBAL_COPILOT_DIR/mcp-config.json"
    echo "  → Copilot MCP configured globally in: $GLOBAL_COPILOT_DIR/mcp-config.json"
fi

echo ""
echo "Installation complete! 🚀"
if [ "$TARGET" == "cursor" ]; then
    echo "  → Subagents installed in: .cursor/agents/"
    echo "  → Orchestrator installed in: .cursor/rules/sdd-orchestrator.mdc"
    echo "  → Skills synced to: .cursor/skills/"
else
    echo "  → Agents installed in: .copilot/agents/"
    echo "  → Orchestrator installed in: .copilot-instructions.md"
    echo "  → Skills deployed to: .copilot/skills/"
fi
