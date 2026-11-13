# Setup and installation

This reference is for installing the skill or diagnosing a runtime that is missing after installation. A skill folder copy alone does not install the PDF translation application or its dependencies.

## Recommended installation on Windows

The repository root is the PDFMathTranslate application, not a skill. Clone this branch and run its installer:

```powershell
git clone --branch codex-translator-adapter https://github.com/Aintme187/PDFMathTranslate-next.git
cd PDFMathTranslate-next
.\scripts\install-codex-skill.ps1
```

The script calls Codex's built-in `skill-installer` with the explicit GitHub repository, branch, and skill subdirectory. It provisions a runtime checkout at `$CODEX_HOME/tools/pdfmathtranslate-codex`, installs Python 3.12 and the locked dependencies using `uv`, verifies Codex CLI authentication/model discovery and `pdf2zh_next --help`, then saves the actual paths in `install-state.json` beside the installed `SKILL.md`. The skill is copied from the official helper's staging directory into `$CODEX_HOME/skills/pdfmathtranslate-codex` only after these checks pass. A failure leaves the installation incomplete and gives a diagnostic; do not claim success or defer setup until the first translation.

The state file records the runtime checkout, its `.venv`, the Python executable used by that environment, the `pdf2zh_next` executable, the `uv` executable when available, the Codex CLI executable, and the verified repository branch/commit. At the end of installation, report these paths to the user. In later sessions, read this state file first and use those exact paths; do not assume that `CODEX_HOME/tools` is the only possible location.

The installer requires Git and Codex's built-in `skill-installer`. It installs `uv` and Python 3.12 when needed, then runs the official helper with that managed Python. If Codex CLI is absent and npm is available, it installs the official `@openai/codex` package. If the user is not signed in, it starts `codex login` during installation and verifies the resulting session.

## Other operating systems or direct generic-installer use

The repository-owned automated installer currently targets Windows PowerShell. On another operating system, or if the skill was copied directly with the generic `$skill-installer`, finish the runtime setup during that same installation task:

1. Keep the skill at `$CODEX_HOME/skills/pdfmathtranslate-codex` (normally `~/.codex/skills/pdfmathtranslate-codex`).
2. Clone `https://github.com/Aintme187/PDFMathTranslate-next.git`, branch `codex-translator-adapter`, into `$CODEX_HOME/tools/pdfmathtranslate-codex`. Do not overwrite an existing checkout with local changes.
3. Install `uv` from Astral's official installer if needed; use `uv python install 3.12` and `uv sync --python 3.12` in the checkout.
4. Ensure the official Codex CLI is installed and authenticated. If missing, install `@openai/codex` through npm where available. If signed out, run `codex login` and complete the interactive flow.
5. Verify `codex --version`, `codex login status`, `codex debug models`, and `uv run --project "$CODEX_HOME/tools/pdfmathtranslate-codex" pdf2zh_next --help`. Check command exit status. Do not expose the full model catalog; use only the fields needed to present available model choices.
6. Register the actual runtime paths on Windows PowerShell by running `& '<skill-folder>\scripts\register-runtime.ps1' -RuntimePath '<runtime-checkout>' -CodexPath '<codex-executable>'`. Add `-UvPath '<uv-executable>'` when using uv. The helper verifies the commands and writes `install-state.json` beside `SKILL.md`. On systems without PowerShell, create the same state file with the absolute runtime, virtual environment, Python, `pdf2zh_next`, uv (if present), and Codex CLI paths, plus repository branch and commit.

Do not ask the user to provide provider credentials. The adapter uses their existing Codex CLI authentication. Installation is complete only after runtime and command checks pass; if an interactive login cannot be completed, state that exact blocker and leave installation incomplete.

## Runtime lookup during translation

The canonical runtime checkout is `$CODEX_HOME/tools/pdfmathtranslate-codex`, but the authoritative paths for an installed skill are in its `install-state.json`. For an older installation without a state file, first reuse the path reported during installation or a checkout already found in the user's workspaces; only use the canonical path if that is where the checkout actually exists. Run the recorded `pdf2zh_executable` directly and select its Codex translator. The optional `codex_model` selects a model; when omitted, the CLI's configured default is used. Worker concurrency uses the upstream `pool_max_workers` option; the default is four workers. Output choices are described in `SKILL.md`.
