[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$RuntimePath,
    [string]$UvPath,
    [Parameter(Mandatory = $true)][string]$CodexPath
)

$ErrorActionPreference = "Stop"

function Resolve-Executable {
    param([Parameter(Mandatory = $true)][string]$Value)
    if (Test-Path -LiteralPath $Value) {
        return (Resolve-Path -LiteralPath $Value).Path
    }
    $command = Get-Command $Value -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $command) { throw "Executable '$Value' was not found on PATH." }
    if ($command.Source) { return $command.Source }
    if ($command.Path) { return $command.Path }
    throw "Could not resolve the executable path for '$Value'."
}

function Invoke-QuietCheck {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $true)][string[]]$ArgumentList,
        [Parameter(Mandatory = $true)][string]$CheckName
    )
    $null = & $FilePath @ArgumentList 2>&1
    if ($LASTEXITCODE -ne 0) { throw "Runtime check failed: $CheckName (exit $LASTEXITCODE)." }
}

$runtime = (Resolve-Path -LiteralPath $RuntimePath).Path
$uv = if ($UvPath) { Resolve-Executable $UvPath } else { $null }
$codex = Resolve-Executable $CodexPath
$projectFile = Join-Path $runtime "pyproject.toml"
$gitPath = Get-Command git -ErrorAction SilentlyContinue | Select-Object -First 1

if (-not (Test-Path -LiteralPath $projectFile)) {
    throw "'$runtime' is not a PDFMathTranslate project checkout (pyproject.toml is missing)."
}
if (-not $gitPath) { throw "Git is required to record the runtime checkout revision." }

$remote = (& $gitPath.Source -C $runtime remote get-url origin).Trim()
if ($LASTEXITCODE -ne 0 -or $remote -notmatch "github\.com[:/]Aintme187/PDFMathTranslate-next(?:\.git)?$") {
    throw "Runtime checkout origin is '$remote'; expected Aintme187/PDFMathTranslate-next."
}
$branch = (& $gitPath.Source -C $runtime branch --show-current).Trim()
if ($LASTEXITCODE -ne 0 -or $branch -ne "codex-translator-adapter") {
    throw "Runtime checkout branch is '$branch'; expected codex-translator-adapter."
}
$commit = (& $gitPath.Source -C $runtime rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0 -or -not $commit) { throw "Could not read the runtime checkout commit." }

Invoke-QuietCheck -FilePath $codex -ArgumentList @("--version") -CheckName "Codex CLI version"
Invoke-QuietCheck -FilePath $codex -ArgumentList @("login", "status") -CheckName "Codex CLI login"
Invoke-QuietCheck -FilePath $codex -ArgumentList @("debug", "models") -CheckName "Codex model catalog"

$venv = Join-Path $runtime ".venv"
$python = Join-Path $venv "Scripts/python.exe"
$pdf2zh = Join-Path $venv "Scripts/pdf2zh_next.exe"
if (-not (Test-Path -LiteralPath $python) -or -not (Test-Path -LiteralPath $pdf2zh)) {
    if (-not $uv) {
        throw "The project's .venv executables were not found and no uv executable was supplied."
    }
    $pythonOutput = & $uv run --project $runtime python -c "import sys; print(sys.executable)" 2>&1
    if ($LASTEXITCODE -ne 0 -or -not $pythonOutput) {
        throw "Could not resolve the Python interpreter used by the PDFMathTranslate project environment."
    }
    $python = ($pythonOutput | Select-Object -Last 1).ToString().Trim()
    $helpOutput = & $uv run --project $runtime pdf2zh_next --help 2>&1
    if ($LASTEXITCODE -ne 0 -or -not $helpOutput) { throw "Runtime check failed: pdf2zh_next --help." }
    $pdf2zh = $null
} else {
    Invoke-QuietCheck -FilePath $pdf2zh -ArgumentList @("--help") -CheckName "pdf2zh_next command"
}

$state = [ordered]@{
    schema_version = 1
    repository = "Aintme187/PDFMathTranslate-next"
    branch = $branch
    commit = $commit
    runtime_path = $runtime
    virtual_environment_path = $venv
    python_executable = $python
    pdf2zh_executable = $pdf2zh
    uv_executable = $uv
    codex_executable = $codex
    verified_at_utc = [DateTime]::UtcNow.ToString("o")
}

$skillRoot = Split-Path -Parent $PSScriptRoot
$statePath = Join-Path $skillRoot "install-state.json"
$tempStatePath = "$statePath.tmp"
$state | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $tempStatePath -Encoding UTF8
Move-Item -LiteralPath $tempStatePath -Destination $statePath -Force

Write-Host "Runtime registration verified and saved: $statePath"
Write-Host "Runtime checkout: $runtime"
Write-Host "Python environment: $venv"
Write-Host "Python executable: $python"
if ($pdf2zh) { Write-Host "PDFMathTranslate command: $pdf2zh" }
if ($uv) { Write-Host "uv executable: $uv" }
Write-Host "Codex CLI: $codex"
Write-Host "Revision: $branch $commit"
