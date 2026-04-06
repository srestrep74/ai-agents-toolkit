# SDD Framework Agnostic Installer (PowerShell)
# Usage: .\scripts\install.ps1 -Target [copilot|cursor]

param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("copilot", "cursor")]
    [string]$Target
)

Write-Host "Installing SDD Framework for $Target..." -ForegroundColor Cyan

$agents = @("init", "explore", "propose", "spec", "design", "tasks", "apply", "verify")

# --- 1. Framework Components ---
if ($Target -eq "copilot") {
    $copilotDir = ".github"
    if (!(Test-Path $copilotDir)) { New-Item -ItemType Directory -Path $copilotDir -Force | Out-Null }
    
    $agentDir = "$copilotDir/agents"
    if (!(Test-Path $agentDir)) { New-Item -ItemType Directory -Path $agentDir -Force | Out-Null }
    
    # Orchestrator (Copilot instructions)
    Copy-Item "src/orchestrator/base-orchestrator.md" ".github/copilot-instructions.md" -Force
    
    # Agents
    foreach ($agent in $agents) {
        $header = Get-Content "templates/copilot/$agent.yml" -Raw
        $body = Get-Content "src/agents/$agent.md" -Raw
        $content = $header + "`n" + $body
        Set-Content -Path "$agentDir/sdd-$agent.agent.md" -Value $content -Force
    }

    # Skills: deploy from src/skills/ to .copilot/skills/
    if (Test-Path "src/skills") {
        $skillTarget = "$copilotDir/skills"
        if (!(Test-Path $skillTarget)) { New-Item -ItemType Directory -Path $skillTarget -Force | Out-Null }
        $skillsFolders = Get-ChildItem -Path "src/skills" -Directory
        foreach ($folder in $skillsFolders) {
            Copy-Item -Path $folder.FullName -Destination $skillTarget -Recurse -Force
        }
    }
}
else {
    # Cursor uses .cursor/agents/ for native subagents
    $agentDir = ".cursor/agents"
    if (!(Test-Path $agentDir)) { New-Item -ItemType Directory -Path $agentDir -Force | Out-Null }
    
    # Orchestrator as a global rule
    $cursorRulesDir = ".cursor/rules"
    if (!(Test-Path $cursorRulesDir)) { New-Item -ItemType Directory -Path $cursorRulesDir -Force | Out-Null }
    
    # Clean up stale agent files
    Get-ChildItem "$cursorRulesDir/sdd-*.md" -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "sdd-orchestrator.mdc" } | Remove-Item -Force
    Remove-Item "$cursorRulesDir/sdd-orchestrator.md" -ErrorAction SilentlyContinue
    
    Copy-Item "src/orchestrator/base-orchestrator.md" "$cursorRulesDir/sdd-orchestrator.mdc" -Force
    
    # Subagents
    foreach ($agent in $agents) {
        $header = Get-Content "templates/cursor/$agent.yml" -Raw
        $body = Get-Content "src/agents/$agent.md" -Raw
        $content = $header + "`n" + $body
        Set-Content -Path "$agentDir/sdd-$agent.md" -Value $content -Force
    }

    # Skills: sync from src/skills/ (source) to .cursor/skills/ (Cursor native)
    if (Test-Path "src/skills") {
        $skillTarget = ".cursor/skills"
        if (!(Test-Path $skillTarget)) { New-Item -ItemType Directory -Path $skillTarget -Force | Out-Null }
        $skillsFolders = Get-ChildItem -Path "src/skills" -Directory
        foreach ($folder in $skillsFolders) {
            Copy-Item -Path $folder.FullName -Destination $skillTarget -Recurse -Force
        }
    }
}

# --- 2. Python venv setup for skills ---
if (Test-Path "scripts/setup-venv.ps1") {
    $copilotDir = ".github"
    if (!(Test-Path $copilotDir)) { New-Item -ItemType Directory -Path $copilotDir -Force | Out-Null }
    $targetVenv = Join-Path $copilotDir ".venv"
    & "powershell" -ExecutionPolicy Bypass -File "scripts/setup-venv.ps1" -VenvDir $targetVenv
}

# --- 3. Engram Installation ---
Write-Host "`n--- Ensuring Engram is installed ---" -ForegroundColor Cyan
$engramDir = "$HOME\AppData\Local\Programs\Engram"
$dbDir = "$HOME\AppData\Local\Engram"
$engramExe = Join-Path $engramDir "engram.exe"

if (!(Test-Path $engramExe)) {
    Write-Host "Engram not found. Downloading latest release..." -ForegroundColor Yellow
    try {
        New-Item -Path $engramDir -ItemType Directory -Force | Out-Null
        New-Item -Path $dbDir -ItemType Directory -Force | Out-Null
        
        $repo = "Gentleman-Programming/engram"
        $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases/latest"
        $asset = $release.assets | Where-Object { $_.name -match "windows_amd64.zip" }
        
        if ($asset) {
            $zipPath = Join-Path $env:TEMP "engram.zip"
            Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zipPath
            Expand-Archive -Path $zipPath -DestinationPath $engramDir -Force
            Remove-Item $zipPath
            Write-Host "Engram installed successfully at $engramExe" -ForegroundColor Green
        }
    } catch {
        Write-Warning "Failed to install Engram automatically: $($_.Exception.Message)"
    }
} else {
    Write-Host "Engram is already installed." -ForegroundColor Green
}

# --- 4. MCP Configuration Automation ---
Write-Host "`n--- Configuring MCP Servers ---" -ForegroundColor Cyan

$engramConfig = @{
    command = $engramExe
    args = @("mcp", "--tools=all")
    env = @{
        ENGRAM_DATA_DIR = $dbDir
    }
}

$azureConfig = @{
    command = "npx"
    args = @("-y", "@azure-devops/mcp", "copavsts")
}

$mcpServers = @{
    engram = $engramConfig
    "azure-devops" = $azureConfig
}

$mcpRoot = @{
    mcpServers = $mcpServers
}

$jsonConfig = $mcpRoot | ConvertTo-Json -Depth 10

if ($Target -eq "cursor") {
    $mcpFile = ".cursor/mcp.json"
    if (!(Test-Path ".cursor")) { New-Item -ItemType Directory -Path ".cursor" -Force | Out-Null }
    Set-Content -Path $mcpFile -Value $jsonConfig -Force
    Write-Host "  → Cursor MCP configured in: $mcpFile" -ForegroundColor DarkCyan
} else {
    $globalCopilotDir = Join-Path $HOME ".copilot"
    if (!(Test-Path $globalCopilotDir)) { New-Item -ItemType Directory -Path $globalCopilotDir -Force | Out-Null }
    $mcpFile = Join-Path $globalCopilotDir "mcp-config.json"
    Set-Content -Path $mcpFile -Value $jsonConfig -Force
    Write-Host "  → Copilot MCP configured globally in: $mcpFile" -ForegroundColor DarkCyan
}

Write-Host ""
Write-Host "Installation complete! 🚀" -ForegroundColor Green
if ($Target -eq "cursor") {
    Write-Host "  → Subagents installed in: .cursor/agents/" -ForegroundColor DarkCyan
    Write-Host "  → Orchestrator installed in: .cursor/rules/sdd-orchestrator.mdc" -ForegroundColor DarkCyan
    Write-Host "  → Skills synced to: .cursor/skills/" -ForegroundColor DarkCyan
}
else {
    Write-Host "  → Agents installed in: .github/agents/" -ForegroundColor DarkCyan
    Write-Host "  → Orchestrator installed in: .github/copilot-instructions.md" -ForegroundColor DarkCyan
    Write-Host "  → Skills deployed to: .github/skills/" -ForegroundColor DarkCyan
}
