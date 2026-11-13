---
name: pdfmathtranslate-codex
description: Translate PDF documents with layout preservation using PDFMathTranslate-next and its Codex CLI translator. Use when a user asks to translate a PDF while retaining its structure and wants the translated PDF output.
metadata:
  short-description: Translate PDFs with Codex CLI
---

# PDFMathTranslate with Codex

Use the PDFMathTranslate-next Codex translator adapter to translate PDF files and generate the requested PDF outputs. PDF parsing, layout reconstruction, placeholder handling, and PDF writing stay in PDFMathTranslate/BabelDOC; Codex CLI supplies translations.

## Before starting

Gather missing settings interactively, **one question per turn**. Ask the next applicable question only after the user answers the current one. Never combine several missing settings into a checklist or multi-part question. Skip any setting the user has already specified. Include the actual upstream default as an easy answer. When all applicable settings are resolved, proceed without another confirmation.

Ask in this order:

1. **Input PDF path(s)** — open-ended; ask for the file(s) if not provided.
2. **Source language** — ask for a language code/name; default `en`. Do not offer auto-detect: this upstream setting has no auto-detect mode.
3. **Target language** — ask for a language code/name; default `zh`.
4. **Pages** — offer all pages (default) or a page list/range supported by the upstream syntax, e.g. `1,2,5-8`.
5. **PDF outputs** — offer bilingual, monolingual, or both (default both).
6. **Output directory** — offer the current working directory (upstream default) or a path.
7. **Glossary** — offer no glossary (default) or one/more CSV file paths.
8. **Custom system prompt** — offer none (default) or a prompt string.
9. **Automatic term extraction** — offer enabled (default) or disabled.
10. **Save extracted glossary** — ask only if automatic extraction is enabled; offer no (default) or yes.
11. **Codex model** — offer the model configured as the Codex CLI default (default) or an explicit model name.
12. **Translation worker concurrency** — offer the upstream default of 4 workers or an explicit worker count. This controls concurrent Codex CLI translation requests; it does not create Agent subagents.

Original layout preservation is inherent to this workflow, not a question. `codex_path` is a runtime setting: use the default `codex` executable when available, and consult setup guidance only if it is missing. Do not ask for unrelated provider credentials or service settings.

Read [references/setup-and-install.md](references/setup-and-install.md) when the skill or PDFMathTranslate runtime is not installed, or when the environment is not ready. Do not ask for provider credentials: the adapter uses the user's existing Codex CLI login.

## Run

1. Locate the PDFMathTranslate-next checkout with the Codex adapter and the `pdf2zh_next` command. Confirm `codex --version` and `pdf2zh_next --help` work. If either is missing, follow the setup reference before proceeding.
2. Once the sequential questions are complete, use the collected values directly. Keep original page layout enabled; it is the purpose of this workflow and is not a configurable question here.
3. Run `pdf2zh_next` with the Codex engine and the agreed settings. Use argument arrays / correctly quoted paths; never alter the source PDF. For output location/type, pages, language, glossary, prompts, automatic glossary, model, and worker count, use only options exposed by the installed `pdf2zh_next --help` and its Codex adapter. Do not substitute another translation provider.
4. Wait for the command to finish. Inspect its exit status and output paths; report failures with the relevant diagnostic instead of claiming success. Do not launch another translation run automatically after a failure.
5. Verify every requested output exists and is a readable PDF. When practical, render pages from the result and inspect for clipping, overlap, missing translated text, or broken formulas. Report any visible issue and the exact output paths.

Return links to the output PDFs, source/target languages, page range, output type(s), selected Codex model or “Codex CLI default,” and any warnings. Do not report token usage unless the command provides it.
