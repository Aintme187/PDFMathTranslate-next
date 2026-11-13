# Instructions for coding agents

## Installing the PDFMathTranslate Codex skill

This repository root is the PDFMathTranslate application, not a Codex skill. The skill lives at `skills/pdfmathtranslate-codex/`.

When a user asks to install the Codex skill from this repository:

1. Install only `skills/pdfmathtranslate-codex/`; do not treat the repository root as the skill.
2. Copying the skill files is only the first part of installation. In the same task, read `skills/pdfmathtranslate-codex/references/setup-and-install.md` and configure the PDFMathTranslate runtime, Python/uv dependencies, and authenticated Codex CLI.
3. Verify the commands listed in that setup guide before saying installation is complete. Do not stop after reporting that the skill will be available next turn. If setup is blocked by interactive login or an environment issue, say exactly what remains and keep the installation status incomplete.

The user should not need to separately remind the agent to install or check the runtime.
