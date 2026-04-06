# scripts/setup-venv.ps1
# Automates Python venv creation and dependency installation for SDD skills.

$skillsDir = "src/skills"
$pyProject = Join-Path $skillsDir "pyproject.toml"

if (!(Test-Path $pyProject)) {
    Write-Host "No pyproject.toml found in $skillsDir. Skipping venv setup."
    exit 0
}

$venvDir = ".venv"
if (!(Test-Path $venvDir)) {
    Write-Host "Creating Python venv for skills..."
    python -m venv $venvDir
}

Write-Host "Installing skill dependencies from $pyProject..."

$pipPath = Join-Path $venvDir "bin/pip"
if ($env:OS -like "*Windows*") {
    $pipPath = Join-Path $venvDir "Scripts/pip.exe"
}

if (Test-Path $pipPath) {
    & $pipPath install -q --upgrade pip
    & $pipPath install -q -e $skillsDir
    Write-Host "Python venv ready at: $venvDir/"
}
else {
    Write-Warning "Could not find pip at $pipPath. Skipping dependency installation."
}
