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
    if (!(Test-Path $agentDir)) { New-Item -ItemType Directory -Path $agentDir -Force }
    
    # Orchestrator
    Copy-Item "src/orchestrator/base-orchestrator.md" ".github/AGENTS.md" -Force
    
    # Agents
    foreach ($agent in $agents) {
        $header = Get-Content "templates/copilot/$agent.yml" -Raw
        $body = Get-Content "src/agents/$agent.md" -Raw
        $content = $header + $body
        Set-Content -Path ".github/agents/sdd-$agent.agent.md" -Value $content -Force
    }
}
else {
    $agentDir = ".cursor/rules"
    if (!(Test-Path $agentDir)) { New-Item -ItemType Directory -Path $agentDir -Force }
    
    # Orchestrator
    Copy-Item "src/orchestrator/base-orchestrator.md" ".cursorrules" -Force
    
    # Agents
    foreach ($agent in $agents) {
        $header = Get-Content "templates/cursor/$agent.yml" -Raw
        $body = Get-Content "src/agents/$agent.md" -Raw
        $content = $header + $body
        Set-Content -Path ".cursor/rules/sdd-$agent.md" -Value $content -Force
    }
}

Write-Host "Installation complete! 🚀" -ForegroundColor Green
