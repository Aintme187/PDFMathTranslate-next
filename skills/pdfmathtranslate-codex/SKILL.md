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

## Understand the request before asking

Use the user's message, prior turns in the same task, provided files, and local environment to resolve settings. Skip a question only when the user directly specified that value or the setting is safely covered by the no-question defaults below. Keep explicit instructions distinct from agent inference.

Infer the source language from the PDF's text/content when practical, not from its filename alone. Infer a likely target language from the user's explicit request, then their language and expressed preferences. **Inference provides a recommended first choice; it does not authorize the agent to decide.** Unless the user directly specified the source or target language, ask about each one separately and wait for confirmation, even when the likely language seems obvious. The upstream defaults `en` and `zh` can inform suggestions but must not silently replace user confirmation.

Ask **one concise question per turn** only for a material choice that is both unresolved and not safely covered by an ordinary default. Wait for the answer before asking another question. Never send a numbered questionnaire, bundle unrelated choices, or ask the user to repeat known details. Do not turn every optional upstream setting into a question: absence of a glossary or custom prompt means none; use normal defaults for automatic glossary extraction, glossary saving, and worker count unless context suggests a different preference.

When the host provides an interactive question tool with selectable options, use it instead of writing a plain-text question. Submit only the current question in each call; do not bundle later questions. For a choice with a recommended value, put that value first and label it clearly (for example, `English (recommended)`), then provide the meaningful alternatives; let the user choose or enter another value. Do not treat a suggested or preselected choice as the user's answer. For open-ended values such as a file path or custom prompt, use the tool's free-text input if available. Only fall back to a concise chat question with clearly listed choices when the host has no question tool.

Use this decision order, skipping resolved or safely defaulted items:

1. **Input PDF path(s)** — ask only if no file/attachment/path was provided and none can be identified in the task workspace.
2. **Source language**, then **target language** — skip only if the user directly stated the language. Otherwise ask one at a time, even if confidently inferred; put the inferred language name first as the recommended choice and offer another language as an alternative. Do not require language codes.
3. **Pages** — use all pages unless the user specified a range or the request/context indicates a subset; if subset intent is clear but the range is missing, ask for the range. Accept a page list/range supported by upstream syntax, e.g. `1,2,5-8`.
4. **PDF output type** — if unspecified, ask one question with bilingual, monolingual, and both (upstream default) as choices. Honor context if the user already requested a deliverable type.
5. **Output location** — if the user did not specify one, ask with the interactive question tool. Offer the input PDF's containing directory as the recommended first option and a separate “choose another folder” option; if the user chooses another folder, ask for that path in the next turn. Do not silently use the recommendation as the answer. For multiple input PDFs, recommend their shared containing directory only when they all have the same parent; otherwise ask for one output directory for the batch.
6. **Glossary CSV** — use provided CSV file(s); if none were supplied, proceed without a glossary without asking.
7. **Custom system prompt** — use the user's translation instructions if provided; otherwise leave unset without asking.
8. **Automatic term extraction / saving** — defaults are extraction enabled and saving disabled. Use those without asking unless the request or document needs an explicit choice. Saving is only applicable when extraction is enabled.
9. **Codex model** — inspect the current Codex CLI catalog with `codex debug models`. Parse the JSON and use only each model's `slug`, `display_name`, `description`, `visibility`, and `priority`; never print or interpret the full raw catalog (it contains unrelated fields). Prefer the active/configured Codex CLI default unless the user requests a choice or the current default cannot be established. When a model choice is needed, offer a short list using display names and plain-language descriptions, with the recommended available choice first; do not ask the user to type a model identifier. Pass the selected slug to `codex_model`. If the catalog command is unavailable, keep the CLI default or state that availability could not be checked; do not invent model names.
10. **Translation worker concurrency** — use the upstream default (4 workers via `qps`) unless the user asks to adjust speed/resource use or context makes the default unsuitable. If asking, offer the default and a small number of reasonable numeric choices. This controls concurrent Codex CLI translation requests, not Agent subagents.

Original layout preservation is inherent to this workflow, not a question. `codex_path` is a runtime setting: use the path recorded in the installation state when present, passing it through the existing setting if exposed by `pdf2zh_next --help`; otherwise ensure its containing directory is on `PATH` so the adapter can resolve it. Do not ask for unrelated provider credentials or service settings.

After installation, the runtime should already be ready. Its exact paths are recorded in `install-state.json` beside this `SKILL.md`. At the start of a translation, read that file and verify the recorded runtime directory exists; use its recorded PDFMathTranslate executable and Codex CLI path. If the file is absent (for older installations), check the installation path reported earlier in the conversation and search for an existing checkout before considering a new install. Do not assume the canonical path is the only possible installation. If the environment cannot be located, report that installation setup is incomplete and refer to [references/setup-and-install.md](references/setup-and-install.md); do not begin a first-use installation while preparing a translation. Do not ask for provider credentials: the adapter uses the user's existing Codex CLI login.

## Run

1. Read `install-state.json` beside `SKILL.md`, then use the recorded runtime checkout, virtual environment, `pdf2zh_next` executable (if recorded), and Codex CLI paths. Verify those recorded locations and run the recorded PDFMathTranslate executable's `--help`; if no executable path is recorded, use the recorded uv executable with `run --project <runtime_path> pdf2zh_next --help`. For older installs with no state file, reuse the checkout identified from the installation conversation or a discovered existing checkout; do not re-clone just because `$CODEX_HOME/tools/pdfmathtranslate-codex` is absent. If no valid environment can be found, stop before translation and explain that installation was not completed.
2. Once the necessary questions are answered, use the inferred and collected values directly. Do not ask for a final confirmation. Keep original page layout enabled; it is the purpose of this workflow and is not a configurable question here.
3. Run the recorded `pdf2zh_executable` with the Codex engine and the agreed settings. If it is absent, invoke `pdf2zh_next` through the recorded uv executable and runtime path. Use argument arrays / correctly quoted paths; never alter the source PDF. For output location/type, pages, language, glossary, prompts, automatic glossary, model, and worker count, use only options exposed by the installed `pdf2zh_next --help` and its Codex adapter. Do not substitute another translation provider.
4. Wait for the command to finish. Inspect its exit status and output paths; report failures with the relevant diagnostic instead of claiming success. Do not launch another translation run automatically after a failure.
5. Verify every requested output exists and is a readable PDF. When practical, render pages from the result and inspect for clipping, overlap, missing translated text, or broken formulas. Report any visible issue and the exact output paths.

Return links to the output PDFs, source/target languages, page range, output type(s), selected Codex model or “Codex CLI default,” and any warnings. Do not report token usage unless the command provides it.
