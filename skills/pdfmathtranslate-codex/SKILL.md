---
name: pdfmathtranslate-codex
description: Translate PDF documents with layout preservation using PDFMathTranslate-next and its Codex CLI translator. Use when a user asks to translate a PDF while retaining its structure and wants the translated PDF output.
metadata:
  short-description: Translate PDFs with Codex CLI
---

# PDFMathTranslate with Codex

Use the PDFMathTranslate-next Codex translator adapter to translate PDF files and generate the requested PDF outputs. PDF parsing, layout reconstruction, placeholder handling, and PDF writing stay in PDFMathTranslate/BabelDOC; Codex CLI supplies translations.

## Before starting

Collect all missing task settings together at the beginning. Do not stop mid-run to ask about known settings. If the user gave no value for an applicable option, ask once and include its upstream default so the user can accept it. Once enough information is available, proceed without another confirmation.

- Input PDF path(s).
- Output directory (if omitted, use the application's default output location).
- Source and target language (`en` → `zh` are upstream defaults).
- Pages or page ranges (all pages by default).
- PDF output selection: bilingual, monolingual, or both (the upstream default is both).
- Glossary CSV file(s), if any.
- Custom system prompt, if any.
- Whether to disable automatic term extraction; whether to save the extracted glossary. Use upstream defaults if the user has no preference.
- Codex model (optional; the Codex CLI default is used when omitted).
- Translation worker concurrency (`pool_max_workers`) when the user wants to control concurrent Codex CLI calls; otherwise use the upstream default.

Read [references/setup-and-install.md](references/setup-and-install.md) when the skill or PDFMathTranslate runtime is not installed, or when the environment is not ready. Do not ask for provider credentials: the adapter uses the user's existing Codex CLI login.

## Run

1. Locate the PDFMathTranslate-next checkout with the Codex adapter and the `pdf2zh_next` command. Confirm `codex --version` and `pdf2zh_next --help` work. If either is missing, follow the setup reference before proceeding.
2. Summarize the collected values and their defaults in one concise confirmation. Keep original page layout enabled; it is the purpose of this workflow and is not a configurable question here.
3. Run `pdf2zh_next` with the Codex engine and the agreed settings. Use argument arrays / correctly quoted paths; never alter the source PDF. For output location/type, pages, language, glossary, prompts, automatic glossary, model, and worker count, use only options exposed by the installed `pdf2zh_next --help` and its Codex adapter. Do not substitute another translation provider.
4. Wait for the command to finish. Inspect its exit status and output paths; report failures with the relevant diagnostic instead of claiming success. Do not launch another translation run automatically after a failure.
5. Verify every requested output exists and is a readable PDF. When practical, render pages from the result and inspect for clipping, overlap, missing translated text, or broken formulas. Report any visible issue and the exact output paths.

Return links to the output PDFs, source/target languages, page range, output type(s), selected Codex model or “Codex CLI default,” and any warnings. Do not report token usage unless the command provides it.
