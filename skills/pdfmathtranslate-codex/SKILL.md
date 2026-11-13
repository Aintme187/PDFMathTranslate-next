---
name: pdfmathtranslate-codex
description: Translate PDF documents with layout preservation using PDFMathTranslate-next and its Codex CLI translator. Use when a user asks to translate a PDF while retaining its structure and wants the translated PDF output.
metadata:
  short-description: Translate PDFs with Codex CLI
---

# PDFMathTranslate with Codex

Use the PDFMathTranslate-next Codex translator adapter to translate PDF files and generate the requested PDF outputs. PDF parsing, layout reconstruction, placeholder handling, and PDF writing stay in PDFMathTranslate/BabelDOC; Codex CLI supplies translations.

## Understand the request before asking

Use the user's message, prior turns in the same task, provided files, and local environment to resolve settings. Do not ask for information already supplied or that can be determined reliably. For example, if the user says “translate `paper.pdf` into Chinese,” use that file and infer Chinese as the target language without asking either question.

Infer the source language from the PDF's text/content when practical, not from its filename alone. Infer the target language from an explicit request first, then the user's language and expressed preferences. The upstream defaults `en` and `zh` are fallback values only; they are not mandatory defaults. If source or target language remains ambiguous, ask about one language at a time and show the best inferred value as the first choice.

Ask **one concise question per turn** only for a material choice that is both unresolved and not safely covered by an ordinary default. Wait for the answer before asking another question. Never send a numbered questionnaire, bundle unrelated choices, or ask the user to repeat known details. Do not turn every optional upstream setting into a question: absence of a glossary or custom prompt means none; use normal defaults for automatic glossary extraction, glossary saving, and worker count unless context suggests a different preference.

Use this decision order, skipping resolved or safely defaulted items:

1. **Input PDF path(s)** — ask only if no file/attachment/path was provided and none can be identified in the task workspace.
2. **Source language**, then **target language** — infer as above; ask separately only if uncertain. Offer language names rather than requiring language codes.
3. **Pages** — use all pages unless the user specified a range or the request/context indicates a subset; if subset intent is clear but the range is missing, ask for the range. Accept a page list/range supported by upstream syntax, e.g. `1,2,5-8`.
4. **PDF output type** — if unspecified, ask one question with bilingual, monolingual, and both (upstream default) as choices. Honor context if the user already requested a deliverable type.
5. **Output location** — default to the input PDF's containing directory. Ask only if the user requested a different destination ambiguously; offer “next to the input PDF” as the first/default choice.
6. **Glossary CSV** — use provided CSV file(s); if none were supplied, proceed without a glossary without asking.
7. **Custom system prompt** — use the user's translation instructions if provided; otherwise leave unset without asking.
8. **Automatic term extraction / saving** — defaults are extraction enabled and saving disabled. Use those without asking unless the request or document needs an explicit choice. Saving is only applicable when extraction is enabled.
9. **Codex model** — inspect the current Codex CLI catalog with `codex debug models`. Parse the JSON and use only each model's `slug`, `display_name`, `description`, `visibility`, and `priority`; never print or interpret the full raw catalog (it contains unrelated fields). Prefer the active/configured Codex CLI default unless the user requests a choice or the current default cannot be established. When a model choice is needed, offer a short list using display names and plain-language descriptions, with the recommended available choice first; do not ask the user to type a model identifier. Pass the selected slug to `codex_model`. If the catalog command is unavailable, keep the CLI default or state that availability could not be checked; do not invent model names.
10. **Translation worker concurrency** — use the upstream default (4 workers via `qps`) unless the user asks to adjust speed/resource use or context makes the default unsuitable. If asking, offer the default and a small number of reasonable numeric choices. This controls concurrent Codex CLI translation requests, not Agent subagents.

Original layout preservation is inherent to this workflow, not a question. `codex_path` is a runtime setting: use the default `codex` executable when available, and consult setup guidance only if it is missing. Do not ask for unrelated provider credentials or service settings.

Read [references/setup-and-install.md](references/setup-and-install.md) when the skill or PDFMathTranslate runtime is not installed, or when the environment is not ready. Do not ask for provider credentials: the adapter uses the user's existing Codex CLI login.

## Run

1. Locate the PDFMathTranslate-next checkout with the Codex adapter and the `pdf2zh_next` command. Confirm `codex --version` and `pdf2zh_next --help` work. If either is missing, follow the setup reference before proceeding.
2. Once the necessary questions are answered, use the inferred and collected values directly. Do not ask for a final confirmation. Keep original page layout enabled; it is the purpose of this workflow and is not a configurable question here.
3. Run `pdf2zh_next` with the Codex engine and the agreed settings. Use argument arrays / correctly quoted paths; never alter the source PDF. For output location/type, pages, language, glossary, prompts, automatic glossary, model, and worker count, use only options exposed by the installed `pdf2zh_next --help` and its Codex adapter. Do not substitute another translation provider.
4. Wait for the command to finish. Inspect its exit status and output paths; report failures with the relevant diagnostic instead of claiming success. Do not launch another translation run automatically after a failure.
5. Verify every requested output exists and is a readable PDF. When practical, render pages from the result and inspect for clipping, overlap, missing translated text, or broken formulas. Report any visible issue and the exact output paths.

Return links to the output PDFs, source/target languages, page range, output type(s), selected Codex model or “Codex CLI default,” and any warnings. Do not report token usage unless the command provides it.
