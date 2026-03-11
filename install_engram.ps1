$ErrorActionPreference = "Stop"

# 1. Define clean and isolated paths
$engramDir = "$HOME\AppData\Local\Programs\Engram"
$dbDir = "$HOME\AppData\Local\Engram"
$dbPath = "$dbDir\data.db"

Write-Host "--- Preparing directories ---" -ForegroundColor Cyan
New-Item -Path $engramDir -ItemType Directory -Force | Out-Null
New-Item -Path $dbDir -ItemType Directory -Force | Out-Null

# 2. Fetch the latest release from GitHub
Write-Host "--- Fetching the latest Engram binary from GitHub ---" -ForegroundColor Cyan
$repo = "Gentleman-Programming/engram"
$releaseUrl = "https://api.github.com/repos/$repo/releases/latest"
$release = Invoke-RestMethod -Uri $releaseUrl

# Find Windows binary
$asset = $release.assets | Where-Object { $_.name -match "windows_amd64.zip" }

if (-not $asset) {
    Write-Error "Error: Windows binary not found in the latest release."
    exit
}

# 3. Download and extract
$zipPath = "$env:TEMP\engram.zip"
Write-Host "Downloading $($asset.name)..." -ForegroundColor Yellow
Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zipPath

Write-Host "Extracting the executable..." -ForegroundColor Yellow
Expand-Archive -Path $zipPath -DestinationPath $engramDir -Force
Remove-Item $zipPath

Write-Host "--- Installation Complete ---" -ForegroundColor Green
Write-Host "Binary installed at: $engramDir\engram.exe"
Write-Host "Database located at: $dbPath"

# 4. Generate configuration for Copilot CLI
Write-Host "`nCopy the following JSON block into your .copilot/mcp-config.json file:" -ForegroundColor Magenta

$mcpConfig = @"
    ,
    "engram": {
      "command": "$($engramDir -replace '\\', '\\')\\engram.exe",
      "args": ["--db", "$($dbPath -replace '\\', '\\')"]
    }
"@
$mcpConfig