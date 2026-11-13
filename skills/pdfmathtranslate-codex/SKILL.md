---
name: pdfmathtranslate-codex
description: Translate PDF documents with layout preservation using PDFMathTranslate-next and its Codex CLI translator. Use when a user asks to translate a PDF while retaining its structure and wants the translated PDF output.
metadata:
  short-description: Translate PDFs with Codex CLI
---

# PDFMathTranslate with Codex

Use the PDFMathTranslate-next Codex translator adapter to translate PDF files and generate the requested PDF outputs. PDF parsing, layout reconstruction, placeholder handling, and PDF writing stay in PDFMathTranslate/BabelDOC; Codex CLI supplies translations.

## Install and configure

When the user asks to install this skill from the project repository, use its repository-owned installer. It installs the skill with Codex's official helper and configures/verifies the separate PDFMathTranslate runtime in the same task. Do not treat a successful skill-file copy as a complete installation. If installation was performed directly through the generic skill-installer, finish the setup in [references/setup-and-install.md](references/setup-and-install.md) before reporting success or waiting for the first PDF request. If Codex login requires user interaction, start that login during installation and resume the checks afterward.

## Preference memory

Before asking about any translation setting, read [references/preferences.md](references/preferences.md) and check for the local preference profile. **The first interactive question in every translation task is always about whether to use saved preferences**, unless the user already answered that in their request. When a profile exists, summarize its saved categories and values in the question, explain that it is stored locally and that current instructions override it, then offer: apply it to unspecified settings, ignore it for this task, or review/change it first. When no profile exists, say so and ask whether to remember the preferences selected during this task for future translations. Use the host's native question tool.

Saved values count as prior explicit choices only after the user opts to apply the profile. Continue asking one question at a time for applicable settings absent from the profile. Do not save or update the profile unless the user opts in; if they choose to remember/update it, write the selected reusable preferences after the task settings are settled. Never store input PDF paths, page ranges, or other per-document run data as reusable preferences.

## Understand the request before asking

Before collecting task settings, read [references/parameter-question-inventory.md](references/parameter-question-inventory.md). Use the user's message, prior turns in the same task, provided files, and local environment to resolve settings. Skip a question only when the user directly specified that value, opted to apply a saved preference for it, or the inventory marks it as conditional and it does not apply. Keep explicit instructions distinct from agent inference.

Infer the source language from the PDF's text/content when practical, not from its filename alone. Infer a likely target language from the user's explicit request, then their language and expressed preferences. **Inference provides a recommended first choice; it does not authorize the agent to decide.** Unless the user directly specified the source or target language, ask about each one separately and wait for confirmation, even when the likely language seems obvious. The upstream defaults `en` and `zh` can inform suggestions but must not silently replace user confirmation.

Ask **one concise question per turn** for each applicable unresolved choice from the inventory. Wait for the answer before asking the next question. Never send a numbered questionnaire, bundle unrelated choices, or ask the user to repeat known details. Do not silently accept upstream defaults, infer “none” for an absent glossary or custom prompt, or keep the configured Codex model without asking. A user may explicitly approve a clearly described group of recommended advanced values; otherwise ask the individual applicable settings. Saved preferences count as consent only for values covered by a profile the user chose to apply.

When the host provides an interactive question tool with selectable options, use it instead of writing a plain-text question. Submit only the current question in each call; do not bundle later questions. For a choice with a recommended value, put that value first and label it clearly (for example, `English (recommended)`), then provide the meaningful alternatives; let the user choose or enter another value. Do not treat a suggested or preselected choice as the user's answer. For open-ended values such as a file path or custom prompt, use the tool's free-text input if available. Only fall back to a concise chat question with clearly listed choices when the host has no question tool.

Use this decision order. The linked inventory provides complete option coverage and upstream defaults:

1. **Preferences** — ask first whether to apply the saved profile, ignore it, or review it; when none exists, ask whether to remember this task's choices for next time. Explain the profile contents before presenting choices.
2. **Input PDF path(s)** — ask only if no file/attachment/path was provided and none can be identified in the task workspace.
3. **Source language**, then **target language** — skip only if directly specified or supplied by an applied preference. Otherwise ask one at a time, even if confidently inferred; put the inferred language name first as the recommended choice and offer another language as an alternative. Do not require language codes.
4. **Pages** — ask all pages versus a specified range when not directly stated or supplied by an applied preference; if the user chooses a range, ask for the range in the next turn.
5. **PDF output type** — ask bilingual, monolingual, or both separately from all other choices; both is only a recommendation.
6. **Output folder** — ask separately; the input folder is only a recommendation and must not be silently accepted.
7. **Codex model** — inspect `codex debug models`; parse the catalog and use only `slug`, `display_name`, `description`, `visibility`, and `priority`. Do not print the raw catalog. Always ask the user to choose an available model unless they specified one or opted to apply a saved model preference; show available model names/descriptions, put the active CLI default first when known and identify it, otherwise mark a catalog-supported recommendation. Pass the selected slug as `codex_model`. Never silently fall back to the CLI default.
8. **Remaining task choices** — proceed through the complete inventory, one question at a time, skipping only direct instructions and values supplied by an applied profile: watermark, bilingual layout when applicable, table text, font, glossary, custom prompt, automatic glossary and saving, request rate, worker counts, and each advanced/conditional PDF control that applies. Use recommended values only after the user selects them.

Original layout preservation is inherent to this workflow, not a question. `codex_path` is a runtime setting: use the path recorded in the installation state when present, passing it through the existing setting if exposed by `pdf2zh_next --help`; otherwise ensure its containing directory is on `PATH` so the adapter can resolve it. Do not ask for unrelated provider credentials or service settings.

After installation, the runtime should already be ready. Its exact paths are recorded in `install-state.json` beside this `SKILL.md`. At the start of a translation, read that file and verify the recorded runtime directory exists; use its recorded PDFMathTranslate executable and Codex CLI path. If the file is absent (for older installations), check the installation path reported earlier in the conversation and search for an existing checkout before considering a new install. Do not assume the canonical path is the only possible installation. If the environment cannot be located, report that installation setup is incomplete and refer to [references/setup-and-install.md](references/setup-and-install.md); do not begin a first-use installation while preparing a translation. Do not ask for provider credentials: the adapter uses the user's existing Codex CLI login.

## Run

1. Read `install-state.json` beside `SKILL.md`, then use the recorded runtime checkout, virtual environment, `pdf2zh_next` executable (if recorded), and Codex CLI paths. Verify those recorded locations and run the recorded PDFMathTranslate executable's `--help`; if no executable path is recorded, use the recorded uv executable with `run --project <runtime_path> pdf2zh_next --help`. For older installs with no state file, reuse the checkout identified from the installation conversation or a discovered existing checkout; do not re-clone just because `$CODEX_HOME/tools/pdfmathtranslate-codex` is absent. If no valid environment can be found, stop before translation and explain that installation was not completed.
2. Once the necessary questions are answered, use the inferred and collected values directly. Do not ask for a final confirmation. Keep original page layout enabled; it is the purpose of this workflow and is not a configurable question here.
3. Run the recorded `pdf2zh_executable` with the Codex engine and the settings explicitly selected by the user. If it is absent, invoke `pdf2zh_next` through the recorded uv executable and runtime path. Use argument arrays / correctly quoted paths; never alter the source PDF. For output location/type, pages, language, glossary, prompts, PDF processing, model, QPS, and worker counts, use only options exposed by the installed `pdf2zh_next --help` and its Codex adapter. Do not substitute another translation provider.
4. Wait for the command to finish. Inspect its exit status and output paths; report failures with the relevant diagnostic instead of claiming success. Do not launch another translation run automatically after a failure.
5. Verify every requested output exists and is a readable PDF. When practical, render pages from the result and inspect for clipping, overlap, missing translated text, or broken formulas. Report any visible issue and the exact output paths.

Return links to the output PDFs, source/target languages, page range, output type(s), selected Codex model or “Codex CLI default,” and any warnings. Do not report token usage unless the command provides it.
