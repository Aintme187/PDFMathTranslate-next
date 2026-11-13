[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

function Invoke-Checked {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $true)][string[]]$ArgumentList,
        [Parameter(Mandatory = $true)][string]$Description
    )

    Write-Host "`n==> $Description"
    & $FilePath @ArgumentList
    if ($LASTEXITCODE -ne 0) {
        throw "$Description failed with exit code $LASTEXITCODE."
    }
}

function Find-CommandPath {
    param([Parameter(Mandatory = $true)][string]$Name)
    $command = Get-Command $Name -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($command) { return $command.Source }
    return $null
}

function Refresh-UserPath {
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $env:Path = @($machinePath, $userPath, $env:Path) -join ";"
}

$repo = "Aintme187/PDFMathTranslate-next"
$ref = "codex-translator-adapter"
$skillPath = "skills/pdfmathtranslate-codex"
$codexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME ".codex" }
$skillInstaller = Join-Path $codexHome "skills/.system/skill-installer/scripts/install-skill-from-github.py"
$skillParent = Join-Path $codexHome "skills"
$skillTarget = Join-Path $skillParent "pdfmathtranslate-codex"
$runtimeParent = Join-Path $codexHome "tools"
$runtime = Join-Path $runtimeParent "pdfmathtranslate-codex"
$stageRoot = Join-Path ([IO.Path]::GetTempPath()) ("pdfmathtranslate-skill-" + [guid]::NewGuid().ToString("N"))
$stageSkill = Join-Path $stageRoot "skills"

if (Test-Path -LiteralPath $skillTarget) {
    throw "Skill already exists at '$skillTarget'. The official installer does not overwrite existing skills; remove/update it explicitly before installing again."
}

$git = Find-CommandPath "git"
if (-not $git) { throw "Git is required to provision the PDFMathTranslate runtime. Install Git, then rerun this installer." }
if (-not (Test-Path -LiteralPath $skillInstaller)) {
    throw "Codex's official skill-installer helper was not found at '$skillInstaller'. Confirm CODEX_HOME and install the built-in skill-installer first."
}

New-Item -ItemType Directory -Force -Path $runtimeParent, $skillParent, $stageSkill | Out-Null
try {
    # Keep the full application checkout and its virtual environment outside the skill folder.
    if (-not (Test-Path -LiteralPath (Join-Path $runtime ".git"))) {
        if (Test-Path -LiteralPath $runtime) {
            throw "Runtime destination '$runtime' exists but is not a Git checkout. Move it aside before installation; the installer will not overwrite it."
        }
        Invoke-Checked -FilePath $git -ArgumentList @(
            "clone", "--depth", "1", "--branch", $ref,
            "https://github.com/$repo.git", $runtime
        ) -Description "Clone the PDFMathTranslate runtime"
    } else {
        $origin = (& git -C $runtime remote get-url origin).Trim()
        if ($LASTEXITCODE -ne 0 -or $origin -notmatch "github\.com[:/]Aintme187/PDFMathTranslate-next(?:\.git)?$") {
            throw "Existing runtime '$runtime' is not the expected repository. It was left untouched."
        }
        $branch = (& git -C $runtime branch --show-current).Trim()
        if ($LASTEXITCODE -ne 0 -or $branch -ne $ref) {
            throw "Existing runtime '$runtime' is on branch '$branch', expected '$ref'. It was left untouched."
        }
        $changes = (& git -C $runtime status --porcelain).Trim()
        if ($LASTEXITCODE -ne 0 -or $changes) {
            throw "Existing runtime '$runtime' has local changes. Commit or move them before installation; the installer will not discard them."
        }
        Write-Host "Reusing existing clean checkout: $runtime"
    }

    $uv = Find-CommandPath "uv"
    if (-not $uv) {
        Write-Host "`n==> Install uv using Astral's official Windows installer"
        $uvInstall = Invoke-RestMethod https://astral.sh/uv/install.ps1
        Invoke-Expression $uvInstall
        Refresh-UserPath
        $uv = Find-CommandPath "uv"
        if (-not $uv) {
            $uvCandidates = @(
                (Join-Path $HOME ".local/bin/uv.exe"),
                (Join-Path $env:LOCALAPPDATA "Programs/uv/uv.exe")
            )
            $uv = $uvCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
        }
        if (-not $uv) { throw "uv installation completed, but uv.exe was not found. Restart the terminal and rerun this installer." }
    }

    Invoke-Checked -FilePath $uv -ArgumentList @("python", "install", "3.12") -Description "Install the project's Python 3.12 runtime"
    $python = (& $uv python find "3.12").Trim()
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $python)) {
        throw "uv installed Python 3.12 but its executable could not be located."
    }
    Invoke-Checked -FilePath $uv -ArgumentList @("sync", "--python", "3.12", "--project", $runtime) -Description "Install PDFMathTranslate and locked Python dependencies"

    $codex = Find-CommandPath "codex"
    if (-not $codex) {
        $npm = Find-CommandPath "npm"
        if (-not $npm) { throw "Codex CLI is missing and npm is unavailable. Install Node.js/npm and rerun this installer." }
        Invoke-Checked -FilePath $npm -ArgumentList @("install", "--global", "@openai/codex@latest") -Description "Install the official Codex CLI package"
        Refresh-UserPath
        $codex = Find-CommandPath "codex"
        if (-not $codex) { throw "Codex CLI was installed but is not available on PATH. Restart the terminal and rerun this installer." }
    }

    Invoke-Checked -FilePath $codex -ArgumentList @("--version") -Description "Verify Codex CLI"
    & $codex login status
    if ($LASTEXITCODE -ne 0) {
        Write-Host "`nCodex CLI needs an interactive sign-in. Starting 'codex login'; finish the browser/device flow, then return here."
        Invoke-Checked -FilePath $codex -ArgumentList @("login") -Description "Authenticate Codex CLI"
        Invoke-Checked -FilePath $codex -ArgumentList @("login", "status") -Description "Verify Codex CLI authentication"
    } else {
        Write-Host "Codex CLI authentication is available."
    }

    $modelOutput = & $codex debug models 2>&1
    if ($LASTEXITCODE -ne 0 -or -not $modelOutput) {
        throw "'codex debug models' did not return a model catalog; runtime setup is incomplete."
    }
    Write-Host "Codex model catalog is available."

    Invoke-Checked -FilePath $uv -ArgumentList @("run", "--project", $runtime, "pdf2zh_next", "--help") -Description "Verify the PDFMathTranslate command"

    # Stage the skill with Codex's own helper. Publish it only after runtime checks pass.
    Invoke-Checked -FilePath $python -ArgumentList @(
        $skillInstaller, "--repo", $repo, "--path", $skillPath,
        "--ref", $ref, "--dest", $stageSkill
    ) -Description "Install the skill with Codex's official skill-installer"
    $stagedSkill = Join-Path $stageSkill "pdfmathtranslate-codex"
    if (-not (Test-Path -LiteralPath (Join-Path $stagedSkill "SKILL.md"))) {
        throw "The official installer did not produce the expected skill folder at '$stagedSkill'."
    }
    $registerScript = Join-Path $stagedSkill "scripts/register-runtime.ps1"
    if (-not (Test-Path -LiteralPath $registerScript)) {
        throw "The installed skill is missing its runtime registration helper: '$registerScript'."
    }
    & $registerScript -RuntimePath $runtime -UvPath $uv -CodexPath $codex

    if (Test-Path -LiteralPath $skillTarget) {
        throw "Skill destination '$skillTarget' appeared during installation. The staged skill was not published."
    }
    Move-Item -LiteralPath $stagedSkill -Destination $skillTarget
    Write-Host "`nInstallation complete."
    Write-Host "Skill:   $skillTarget"
    Write-Host "Runtime: $runtime"
    Write-Host "State:   $(Join-Path $skillTarget 'install-state.json')"
    Write-Host "The install-state.json records the exact runtime, Python, uv, and Codex CLI paths for future sessions."
    Write-Host "Verified: Python 3.12 + uv dependencies, Codex CLI authentication/model catalog, pdf2zh_next --help"
    Write-Host "Restart or reload Codex if the skill is not yet visible."
}
finally {
    if (Test-Path -LiteralPath $stageRoot) {
        Remove-Item -LiteralPath $stageRoot -Recurse -Force
    }
}
