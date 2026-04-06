---
name: pr-reviewer
description: "Senior Code Reviewer that audits Azure DevOps PRs based on linked Work Items and actual code changes."
---

# 🤖 PR Reviewer Skill

The `pr-reviewer` is an advanced, autonomous agentic skill designed for GitHub Copilot CLI and Cursor. It acts as a Senior Code Reviewer, performing deep, independent audits of Azure DevOps Pull Requests by combining business logic from Work Items with actual code changes.

## 🌟 Architecture & Design

This skill is built upon a **"Split-Brain" (Hybrid) Architecture**, leveraging two distinct sources of truth to perform professional-grade reviews:

### 1. The Management Brain: Azure DevOps MCP
To understand the *intent* and *business rules* of a PR, the agent connects to Azure DevOps via the `azure-devops` Model Context Protocol (MCP) server. 

### 2. The Code Brain: Isolated Local Git Strategy
To understand the *actual changes*, the agent acts autonomously:
- It uses a temporary directory for isolation.
- It performs a precise `git diff` between the source and target branches.

---

## 🚀 How It Works (The Workflow)

When invoked, the agent executes the following autonomous sequence:

1. **Phase 1: Context & Business Rules**: Connects to Azure DevOps MCP to retrieve PR metadata and linked User Story details (Acceptance Criteria).
2. **Phase 2: Independent Code Audit**: Performs a local `git diff` and analyzes it strictly against the Functional Mission.
3. **Phase 3: Team Correlation**: Reads human discussion threads via MCP to identify missed points or consensus.

## 📋 The "PRO" Output Standard

The agent produces a structured, emoji-free, English-only report divided into critical sections:

1. **Functional Mission**: A synthesized summary of what the code is *supposed* to achieve.
2. **Functional Alignment**: A strict Table mapping Acceptance Criteria and implicit requirements against concrete code evidence (`file:line`).
3. **Agent Findings & Code Proposals (Independent Audit)**: Pure AI-driven insights (bugs, performance risks, architectural suggestions).
4. **Team Discussion Review (Azure Threads Correlation)**: Evaluates if team discussions address the agent's findings.
5. **Critical Observations & Summary**: Final verdict and action items.

## 🛠️ Requirements
- `azure-devops` MCP server configured and connected.
- Local `git` installation available in the system PATH.
