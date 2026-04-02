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
        cat "templates/copilot/$agent.yml" "src/agents/$agent.md" > ".github/agents/sdd-$agent.agent.md"
    done
else
    mkdir -p .cursor/rules
    # Orchestrator
    cp src/orchestrator/base-orchestrator.md .cursorrules
    # Agents
    for agent in "${AGENTS[@]}"; do
        cat "templates/cursor/$agent.yml" "src/agents/$agent.md" > ".cursor/rules/sdd-$agent.md"
    done
fi

echo "Installation complete! 🚀"
