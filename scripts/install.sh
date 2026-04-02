#!/bin/bash

# SDD Framework Agnostic Installer
# Usage: ./install.sh [copilot|cursor]

TARGET=$1

if [ "$TARGET" != "copilot" ] && [ "$TARGET" != "cursor" ]; then
    echo "Usage: ./install.sh [copilot|cursor]"
    exit 1
fi

echo "Installing SDD Framework for $TARGET..."

AGENTS=("init" "explore" "propose" "spec" "design" "tasks" "apply" "verify")

if [ "$TARGET" == "copilot" ]; then
    mkdir -p .github/agents
    # Orchestrator
    cp src/orchestrator/base-orchestrator.md .github/AGENTS.md
    # Agents
    for agent in "${AGENTS[@]}"; do
        { cat "templates/copilot/$agent.yml"; echo; cat "src/agents/$agent.md"; } > ".github/agents/sdd-$agent.agent.md"
    done
    echo ""
    echo "Installation complete! 🚀"
    echo "  → Agents installed in: .github/agents/"
    echo "  → Orchestrator installed in: .github/AGENTS.md"
else
    # Cursor uses .cursor/agents/ for native subagents (NOT .cursor/rules/)
    mkdir -p .cursor/agents
    mkdir -p .cursor/rules
    # Orchestrator as global rule
    cp src/orchestrator/base-orchestrator.md .cursor/rules/sdd-orchestrator.md
    # Subagents
    for agent in "${AGENTS[@]}"; do
        { cat "templates/cursor/$agent.yml"; echo; cat "src/agents/$agent.md"; } > ".cursor/agents/sdd-$agent.md"
    done
    echo ""
    echo "Installation complete! 🚀"
    echo "  → Subagents installed in: .cursor/agents/"
    echo "  → Orchestrator installed in: .cursor/rules/sdd-orchestrator.md"
fi
