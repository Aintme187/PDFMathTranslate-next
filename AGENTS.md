# Instructions for coding agents

## Installing the PDFMathTranslate Codex skill

This repository root is the PDFMathTranslate application, not a Codex skill. The skill lives at `skills/pdfmathtranslate-codex/`.

When a user asks to install the Codex skill from this repository:

1. On Windows, run `scripts/install-codex-skill.ps1` from the repository checkout. It invokes Codex's built-in skill-installer for `skills/pdfmathtranslate-codex/`, configures the separate runtime, verifies it, and publishes the skill only after setup succeeds.
2. Do not install the repository root as a skill. The root is the PDFMathTranslate application; only `skills/pdfmathtranslate-codex/` is the skill.
3. If the repository-owned installer cannot run on the current operating system, install the skill with the official helper. Runtime setup may happen during installation or before the first translation; follow `skills/pdfmathtranslate-codex/references/setup-and-install.md` before invoking PDFMathTranslate. If interactive login or an environment issue blocks setup, report the exact remaining step and do not claim the translation is underway.

The user should not need to separately remind the agent to install or check the runtime.
