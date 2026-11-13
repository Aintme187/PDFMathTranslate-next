# Instructions for coding agents

## Installing the PDFMathTranslate Codex skill

This repository root is the PDFMathTranslate application, not a Codex skill. The skill lives at `skills/pdfmathtranslate-codex/`.

When a user asks to install the Codex skill from this repository:

1. On Windows, run `scripts/install-codex-skill.ps1` from the repository checkout. It invokes Codex's built-in skill-installer for `skills/pdfmathtranslate-codex/`, configures the separate runtime, verifies it, and publishes the skill only after setup succeeds.
2. Do not install the repository root as a skill. The root is the PDFMathTranslate application; only `skills/pdfmathtranslate-codex/` is the skill.
3. If the repository-owned installer cannot run on the current operating system, follow `skills/pdfmathtranslate-codex/references/setup-and-install.md` in the same installation task and complete all listed environment checks before reporting success. Do not stop after saying the skill will be available next turn. If interactive login or an environment issue blocks setup, report the exact remaining step and keep installation incomplete.

The user should not need to separately remind the agent to install or check the runtime.
