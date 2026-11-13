# Translation preference profile

The profile is an optional, local file. Never create or change it without the user's explicit choice.

## Location and scope

Use:

```text
${CODEX_HOME}/pdfmathtranslate-codex/preferences.json
```

If `CODEX_HOME` is unset, use `~/.codex/pdfmathtranslate-codex/preferences.json` (on Windows, `%USERPROFILE%\.codex\pdfmathtranslate-codex\preferences.json`). Create the parent folder only after the user opts to remember preferences.

Before the first settings question in every translation task, check this location. The preference question is always first unless the user already answered it in the request.

## First question

If the file exists and is valid, summarize the saved values in the question, grouping them in plain language: languages; output type and folder rule; watermark and bilingual layout; glossary and custom prompt; automatic term extraction and saving; Codex model; request rate and worker concurrency; font and PDF-processing choices. Tell the user:

- this profile is stored locally at the path above;
- it is applied only if they choose to use it;
- instructions in the current request override saved values;
- input PDF paths and page ranges are not saved.

Offer these separate options through the native question tool:

1. Apply the saved profile to settings not specified in this request; leave the profile unchanged.
2. Apply it and update it from choices made in this task.
3. Ignore it for this task; ask about every applicable unspecified setting.
4. Review/change the profile before proceeding.

If no valid profile exists, state that no preferences are saved, describe the categories listed above, and ask whether to remember the reusable choices selected during this task or keep this task unremembered. Store nothing until the user chooses the remember option.

## Profile contents

Save only reusable settings selected by the user or explicitly covered by their “remember these choices” instruction. Use a versioned JSON object with `schema_version`, `updated_at`, and `preferences`. Preference keys should map to the task settings in [parameter-question-inventory.md](parameter-question-inventory.md), for example:

- `translation.lang_in`, `translation.lang_out`
- `pdf.no_dual`, `pdf.no_mono`, `pdf.watermark_output_mode`, `pdf.dual_translate_first`, `pdf.use_alternating_pages_dual`
- a reusable output-folder rule (`same_as_input`) or a fixed `translation.output` path
- `translation.glossaries`, `translation.custom_system_prompt`, `translation.no_auto_extract_glossary`, `translation.save_auto_extracted_glossary`
- `translate_engine_settings.codex_model`
- `translation.qps`, `translation.pool_max_workers`, and, when configured, term-extraction rate/workers
- `translation.primary_font_family` and selected advanced `PDFSettings` values

Never save `basic.input_files`, `pdf.pages`, per-document OCR decisions, cache/run status, or temporary paths. Do not turn settings that the user skipped into saved preferences. If the user chooses “apply but leave unchanged,” do not write the profile. If they choose “apply and update,” merge only the newly selected reusable preferences and preserve other profile entries.

## Applying and validating preferences

- Current-task instructions take precedence over the profile. A profile value fills only an otherwise unspecified setting.
- An applied profile is explicit consent for the values it contains; do not ask those settings again unless the user wants to override them.
- Validate values against the installed tool before use. If a model slug is no longer available, a path is missing, a value is invalid, or the installed version no longer supports a setting, do not substitute silently; ask the user to choose a replacement.
- When there is no profile, the user declines memory, or the user ignores the profile for this task, follow the full question inventory and do not save the answers automatically.
- After saving, tell the user which reusable categories were remembered and where the file is. Do not print a custom prompt or other long values back unless needed to clarify a change.
