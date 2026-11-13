# PDFMathTranslate task-choice inventory

Use this inventory before translating. It is based on the current upstream `SettingsModel`, `PDFSettings`, and `CodexSettings`, plus the fields passed to BabelDOC by `create_babeldoc_config`. Recheck the installed `pdf2zh_next --help` before using an option whose CLI spelling may have changed.

## Asking rule

- Ask one question per turn with the host's native question tool. Do not begin translation until every applicable choice below has either been directly specified by the user or explicitly answered. Do not replace several independent settings with a vague “use defaults?” question; if the user explicitly asks to use all upstream recommendations, record that instruction as consent for the applicable listed values.
- An upstream default or an agent inference is a recommendation, never consent. Put the recommended value first, show its actual value where useful, and wait for the user's selection. Do not silently use a default because it seems ordinary or because a choice is preselected in the UI.
- Skip only a directly specified choice or a conditional choice whose feature does not apply. If the user says “use the recommended settings” for a clearly enumerated set, that is explicit consent for those settings.
- Use the CLI's actual available Codex model catalog for model options. Do not silently use the CLI's current model. Do not ask the user to type a model slug when selectable choices can be shown.
- If the user asks to translate a directory, list the PDFs found and treat “all PDFs in this directory” as explicit file scope. If the request is ambiguous about which discovered files, ask before processing.

## Questions for each translation task

The preference-use question in [preferences.md](preferences.md) comes before this list and is always the first interactive question unless answered by the user. Then ask these in order, skipping a value only when the user stated it directly, chose to apply a saved profile that supplies it, or its conditional feature does not apply. If a question has a conditional follow-up, ask that only after the preceding answer.

1. **Input PDFs** (`basic.input_files`): ask for the path only if no file, attachment, or directory was provided. For a directory request, inspect it and report the matching PDF list; ask which files only if “all files” was not clear.
2. **Source language** (`translation.lang_in`): when not explicit, ask separately. Put the language inferred from PDF text first as “recommended”; include “another language” / free text. Do not rely on the filename alone.
3. **Target language** (`translation.lang_out`): when not explicit, ask separately. Recommend from the user's request and conversation language, but wait for selection.
4. **Page scope** (`pdf.pages`): when not explicit, ask “all pages” versus “a page range”. If the user chooses a range, ask for the range in the next turn. All pages is the upstream default/recommendation, not implied consent.
5. **PDF output types** (`pdf.no_dual`, `pdf.no_mono`): when not explicit, offer bilingual, monolingual, or both (the upstream default). Do not infer output type from a generic request to translate.
6. **Output folder** (`translation.output`): when not explicit, ask. Offer the source PDF's folder (or shared parent for a same-folder batch) as recommended and “another folder” as the alternative. If another folder is chosen, ask for its path in the next turn. Never silently place results next to the input.
7. **Watermark output** (`pdf.watermark_output_mode`): ask watermarked (upstream default), no watermark, or both watermarked and clean outputs.
8. **Bilingual layout** (`pdf.dual_translate_first`, `pdf.use_alternating_pages_dual`): ask only if a bilingual PDF is requested. Offer source pages followed by translated pages (upstream default), translated pages first, or alternating source/translated pages. Map the answer to the corresponding upstream flags.
9. **Table text** (`pdf.translate_table_text`): ask yes/no when tables are present or may contain text; recommend yes (upstream default). If no tables are present, explain that it has no effect and ask only if the user still wants to set it.
10. **Translated-text font family** (`translation.primary_font_family`): ask automatic selection (upstream default), serif, sans-serif, or script/italic.
11. **Glossary CSVs** (`translation.glossaries`): if none was provided, ask whether to proceed without a glossary or use one or more CSV files. Ask for file paths after the user chooses to provide them.
12. **Custom translation prompt** (`translation.custom_system_prompt`): if none was supplied, ask whether to use the standard prompt or add custom translation instructions. If custom is chosen, ask for the text in the next turn.
13. **Automatic term extraction** (`translation.no_auto_extract_glossary`): ask enable/disable; recommend enabled (upstream default). If enabled, ask whether to save the extracted glossary (`translation.save_auto_extracted_glossary`, default no).
14. **Codex model** (`translate_engine_settings.codex_model`): unless the user specified one or opted to apply a saved preference for it, always show the available model choices and ask. Put the active CLI default first when it can be identified; otherwise recommend an available model using only the catalog's display name and description. “Use Codex CLI default” is a choice, not an implicit fallback.
15. **Translation request rate** (`translation.qps`): ask whether to use 4 requests/second (upstream default/recommendation) or another supported positive value.
16. **Translation worker count** (`translation.pool_max_workers`): ask whether to use 4 concurrent Codex requests (the effective upstream default) or another positive count. This is application worker concurrency, not Agent subagent count.
17. **Term-extraction rate and workers** (`translation.term_qps`, `translation.term_pool_max_workers`): only if automatic extraction is enabled, ask whether each should follow the selected translation rate/worker count (upstream behavior) or be set separately. If separate is selected, ask the numeric value in the next turn.

## Conditional and advanced PDF-processing choices

The agent may inspect the PDF to decide which conditional questions are relevant, but inspection results are recommendations, not user consent. Ask each applicable advanced setting one at a time, with the current upstream value as the recommended option and a custom choice. If the user directly asks to use all upstream recommendations, that instruction covers the listed values; otherwise do not bundle independent controls into one question.

| Setting / upstream field | Upstream value | When to ask / choices to present |
|---|---:|---|
| Minimum text length, `translation.min_text_length` | `5` characters | Include in advanced settings; explain that shorter text blocks may be skipped. Offer 5 (recommended), 0, or custom nonnegative integer. |
| Split long documents, `pdf.max_pages_per_part` | unset (no split) | Ask for large documents or when chunking is useful. Offer no split (recommended) or split by a user-chosen number of pages (minimum 50). |
| Formula font regex, `pdf.formular_font_pattern` | unset | Ask when formula recognition customization is relevant or in individual advanced configuration. Offer upstream automatic handling or custom regex. |
| Formula character regex, `pdf.formular_char_pattern` | unset | Same as formula font regex; ask separately if advanced settings are being customized. |
| Split short lines, `pdf.split_short_lines` | off | Ask when the document has short-line segmentation issues or in individual advanced configuration. Offer off (recommended) / on. |
| Short-line threshold, `pdf.short_line_split_factor` | `0.8` | Ask only if short-line splitting is on. Offer 0.8 (recommended) or custom value (minimum 0.1). |
| Skip PDF cleaning, `pdf.skip_clean` | off | Include in advanced PDF processing choices. Offer keep cleaning (recommended) / skip cleaning. |
| Disable rich-text translation, `pdf.disable_rich_text_translate` | off | Include in advanced PDF processing choices. Offer rich-text translation on (recommended) / disable it. |
| Compatibility enhancement, `pdf.enhance_compatibility` | off | Include in advanced PDF processing choices. If enabled, explain that upstream also sets `skip_clean=true` and `disable_rich_text_translate=true`; do not ask for contradictory subchoices afterward. |
| Scan detection, `pdf.skip_scanned_detection` | detection on | Ask when the PDF contains scanned pages or when the user customizes advanced OCR handling. Offer detection on (recommended) / skip detection. |
| Forced OCR workaround, `pdf.ocr_workaround` | off | Ask when scanned pages are present or in individual advanced configuration. Explain it forces translated text to black on a white background. Offer off (recommended) / on. |
| Automatic OCR workaround, `pdf.auto_enable_ocr_workaround` | off | Ask when scanned pages are present or in individual advanced configuration. Offer off (upstream default) / detect heavy scans and enable automatically. Explain this overrides the manual workaround and requires scan detection. |
| Only translated pages in output, `pdf.only_include_translated_page` | off | Ask only when a subset of pages was selected. Offer include all pages (recommended) / only requested translated pages. |
| Merge alternating line numbers, `not pdf.no_merge_alternating_line_numbers` | on | Ask when the document uses alternating line-number/text paragraphs or in individual advanced configuration. Offer merge (upstream behavior) / do not merge. |
| Remove non-formula lines inside formula regions, `not pdf.no_remove_non_formula_lines` | on | Ask for formula-heavy documents or in individual advanced configuration. Offer remove (upstream behavior) / retain. |
| Non-formula-line IoU threshold, `pdf.non_formula_line_iou_threshold` | `0.9` | Ask only when the preceding formula-region handling is relevant and the user chooses custom advanced settings. Offer 0.9 or a custom value from 0 to 1. |
| Figure/table protection threshold, `pdf.figure_table_protection_threshold` | `0.9` | Ask for documents with dense figures/tables or in individual advanced configuration. Explain it controls which lines in protected regions are left untouched; offer 0.9 or a custom value from 0 to 1. |
| Formula offset calculation, `pdf.skip_formula_offset_calculation` | calculate (skip off) | Ask for formula-heavy PDFs or in individual advanced configuration. Offer calculate (recommended) / skip calculation. |
| Cache, `translation.ignore_cache` | reuse valid cache | Ask only when this input has an existing translation cache or the user requested a rerun. Offer reuse cached translations (recommended) / ignore cache and retranslate. |

## Settings that are not translation-task questions

Do not turn application/runtime configuration into user preference questions: GUI/server options; debug/version/warmup/offline-asset modes; config-file selection and report interval; external layout-model endpoint `rpc_doclayout`; translation provider/API credentials; the Codex executable path (use `install-state.json`); term-extraction provider selection (the Codex engine is used); and service-specific parameters from unrelated translator implementations. They are not task choices for this skill. Original layout preservation is the purpose of the tool, not a toggle.
