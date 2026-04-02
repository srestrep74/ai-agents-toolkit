# SDD Framework Agnostic Installer (PowerShell)
# Usage: .\scripts\install.ps1 -Target [copilot|cursor]

param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("copilot", "cursor")]
    [string]$Target
)

Write-Host "Installing SDD Framework for $Target..." -ForegroundColor Cyan

$agents = @("init", "explore", "propose", "spec", "design", "tasks", "apply", "verify")

if ($Target -eq "copilot") {
    $agentDir = ".github/agents"
    if (!(Test-Path $agentDir)) { New-Item -ItemType Directory -Path $agentDir -Force | Out-Null }
    
    # Orchestrator
    Copy-Item "src/orchestrator/base-orchestrator.md" ".github/AGENTS.md" -Force
    
    # Agents
    foreach ($agent in $agents) {
        $header = Get-Content "templates/copilot/$agent.yml" -Raw
        $body = Get-Content "src/agents/$agent.md" -Raw
        $content = $header + "`n" + $body
        Set-Content -Path "$agentDir/sdd-$agent.agent.md" -Value $content -Force
    }
}
else {
    # Cursor uses .cursor/agents/ for native subagents (NOT .cursor/rules/)
    $agentDir = ".cursor/agents"
    if (!(Test-Path $agentDir)) { New-Item -ItemType Directory -Path $agentDir -Force | Out-Null }
    
    # Orchestrator as global rules
    $cursorRulesDir = ".cursor/rules"
    if (!(Test-Path $cursorRulesDir)) { New-Item -ItemType Directory -Path $cursorRulesDir -Force | Out-Null }
    Copy-Item "src/orchestrator/base-orchestrator.md" "$cursorRulesDir/sdd-orchestrator.md" -Force
    
    # Subagents
    foreach ($agent in $agents) {
        $header = Get-Content "templates/cursor/$agent.yml" -Raw
        $body = Get-Content "src/agents/$agent.md" -Raw
        $content = $header + "`n" + $body
        Set-Content -Path "$agentDir/sdd-$agent.md" -Value $content -Force
    }
}

Write-Host ""
Write-Host "Installation complete! 🚀" -ForegroundColor Green
if ($Target -eq "cursor") {
    Write-Host "  → Subagents installed in: .cursor/agents/" -ForegroundColor DarkCyan
    Write-Host "  → Orchestrator installed in: .cursor/rules/sdd-orchestrator.md" -ForegroundColor DarkCyan
} else {
    Write-Host "  → Agents installed in: .github/agents/" -ForegroundColor DarkCyan
    Write-Host "  → Orchestrator installed in: .github/AGENTS.md" -ForegroundColor DarkCyan
}
